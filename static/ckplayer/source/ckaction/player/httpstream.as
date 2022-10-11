package ckaction.player {
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import ckaction.C.C;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.AsyncErrorEvent;
	import ckaction.act.script;
	import flash.media.SoundTransform;
	import flash.events.ErrorEvent;
	import ckaction.act.timeInterval;
	import ckaction.act.timeOut;

	public class httpstream {
		public var videoUrl: String = "";
		public var netStatus: Function = null,
			streamSendOut: Function = null,
			error: Function = null; //发送流状态的函数，发送流的函数，统一用来报错的函数
		public var NUM: int = -1; //发送区别编号
		public var usehardwareeecoder:Boolean=false;
		private var nc: NetConnection = null;
		private var ns: NetStream = null;
		private var videoMeta: Object = null;
		private var playUrl: String = ""; //实际要播放的视频地址
		private var startTime: Number = 0,
			startBytes: Number = 0; //用来修正播放时间
		private var startTimeNum: int = 0,startLoadNum:int=0; //用来做3次计数，用来确认是否需要修正时间
		private var isClear: Boolean = false; //默认不清除
		private var frist: Boolean = true;
		private var DRAG: String = "";
		private var duration: Number = 0,
			bytesTotal: Number = 0;
		private var stopTimer: timeInterval = null; //用来在提前结束的情况下最终发送stop的定时器
		private var sendStop = false;
		private var timeCorrect: Boolean = false;
		public function httpstream() {
			DRAG = C.CONFIG["flashvars"]["drag"];
			timeCorrect = C.CONFIG["config"]["timeCorrect"];
			//trace("DRAG", DRAG);
		}
		public function load(): void {
			if (isClear) { //如果已被清除，则不进行下面的动作
				return;
			}
			nc = new NetConnection();
			nc.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			nc.addEventListener(AsyncErrorEvent.ASYNC_ERROR, netSteameErrorHandler);
			nc.connect(null);
		}
		private function netStatusHandler(event: NetStatusEvent): void {
			//trace("this:", event.info.code);

			if (!timeCorrect) {
				if (NUM > -1) {
					netStatus(event.info.code, NUM);
				} else {
					netStatus(event.info.code);
				}
			} else {
				if (event.info.code != "NetStream.Play.Stop") {
					if (NUM > -1) {
						netStatus(event.info.code, NUM);
					} else {
						netStatus(event.info.code);
					}
				} else {
					//trace("=======",getTime() , duration - C.CONFIG["config"]["bufferTime"] * 0.001,duration,C.CONFIG["config"]["bufferTime"] * 0.001);
					if (getTime() >= duration - C.CONFIG["config"]["bufferTime"] * 0.01) {
						if (NUM > -1) {
							netStatus(event.info.code, NUM);
						} else {
							netStatus(event.info.code);
						}
						sendStop = true;
					} else {
						videoPlay();
						if (!stopTimer) {
							stopTimer = new timeInterval(C.CONFIG["config"]["bufferTime"] - 1, stopTimerHandler);
						}
						stopTimer.start();
						//trace("延迟秒数",(duration - getTime()));
						new timeOut((duration - getTime()) * 1000, function () {
							if (!sendStop) {
								//trace("确保发送")
								sendStop = true;
								if (stopTimer) {
									stopTimer.close();
									stopTimer = null;
								}
								if (NUM > -1) {
									netStatus("NetStream.Play.Stop", NUM);
								} else {
									netStatus("NetStream.Play.Stop");
								}
							}
						});
					}
				}
			}
			switch (event.info.code) {
				case "NetConnection.Connect.Success":
					connectStream();
					break;
				default:
					break;
			}
			//trace(event.info.code);

		}
		private function stopTimerHandler(): void {
			if (getTime() >= duration) {
				//trace("发送成功");
				if (NUM > -1) {
					netStatus("NetStream.Play.Stop", NUM);
				} else {
					netStatus("NetStream.Play.Stop");
				}
				sendStop = true;
				stopTimer.close();
				stopTimer = null;
			}
			//trace("检查发送");
		}
		private function securityErrorHandler(event: SecurityErrorEvent): void {}
		private function netSteameErrorHandler(event: AsyncErrorEvent): void {}
		private function connectStream(): void {
			if (isClear) { //如果已被清除，则不进行下面的动作
				return;
			}
			if (!playUrl) {
				playUrl = videoUrl;
			}
			var customClient = new Object();
			customClient.onMetaData = metaDataHandler;
			ns = new NetStream(nc);
			ns.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			ns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, netSteameErrorHandler);
			ns.useHardwareDecoder=usehardwareeecoder;
			ns.client = customClient;
			ns.play(playUrl);
		}
		private function metaDataHandler(info: Object): void {
			if (isClear) { //如果已被清除，则不进行下面的动作
				return;
			}
			var metaDataObj: Object = {};
			if (!info.hasOwnProperty("duration")) {
				info["duration"] = 0;
			}
			if (frist) {
				info = script.getHttpKey(info);
				info["bytesTotal"] = ns.bytesTotal;
				videoMeta = info;
				if (!info.hasOwnProperty("keytime")) {
					DRAG = "";
				}
				metaDataObj = {
					type: "[object NetStream]",
					metaData: info
				};

			}
			metaDataObj["netStream"] = ns;
			if (bytesTotal == 0 && ns.bytesTotal > 0) {
				bytesTotal = ns.bytesTotal;
			}
			if (duration == 0 && info["duration"] > 0) {
				duration = info["duration"];
			}
			frist = false;
			if (!info.hasOwnProperty("width")) {
				clear();
				error("There is no width for video metadata");
				return;
			}
			if (!info.hasOwnProperty("height")) {
				clear();
				error("There is no height for video metadata");
				return;
			}


			if (isClear) { //如果已被清除，则不进行下面的动作
				return;
			}
			if (NUM > -1) {
				//trace("运行了load",NUM,metaDataObj);
				streamSendOut(metaDataObj, NUM);
				//trace("运行了load==", NUM);
			} else {
				streamSendOut(metaDataObj);
			}

		}


		private function newPlayUrl(time: Number = 0): void {
			if (isClear) { //如果已被清除，则不进行下面的动作
				return;
			}
			//trace(videoMeta["keytime"]);
			var keytime: Array = videoMeta["keytime"];
			//trace(keytime.length);
			var keyframes: Array = videoMeta["keyframes"];
			var index: int = 0;
			var start: String = "";
			for (var i: int = 0; i < keytime.length; i++) {
				if (time < keytime[i]) {
					index = i > 0 ? i - 1 : i;
					break;
				}
			}
			if (time > keytime[keytime.length - 1]) {
				index = keytime.length - 1;
			}
			//trace("++++++++++++++++++++++++++++++++++",time);
			//trace(index);
			//trace(keytime[index]);
			//trace("++++++++++++++++++++++++++==========++++++++");
			//script.log(time);
			//script.log(keytime);
			//mp4文件按关键时间点
			var drag: String = script.replace(DRAG, ["time_", "frames_"], ["", ""]);
			if (script.getFileExt(videoUrl) == ".mp4") {
				start = drag + "=" + keytime[index];
			} else {
				start = drag + "=" + keyframes[index];
			}
			if (DRAG.indexOf("time_") > -1) {
				start = drag + "=" + keytime[index];
			}
			if (DRAG.indexOf("frames_") > -1) {
				start = drag + "=" + keyframes[index];
			}
			startTime = keytime[index];
			startBytes = keyframes[index];
			if (videoUrl.indexOf("?") > -1) {
				playUrl = videoUrl.replace("?", "?" + start + "&"); //videoUrl + "&" + start;
			} else {
				playUrl = videoUrl + "?" + start;
			}
			//trace(keytime[index]);
			//trace(playUrl);

			startTimeNum = 0; //重置计数
			startLoadNum=0;
			if (ns) {
				ns.close();
				ns.play(playUrl);
			}

		}
		private function getNewTime(time: Number): Number { //根据当前加载量计算跳转时间
			//var bytesLoaded: Number = ns.bytesLoaded;
			//var bytesTotal: Number = ns.bytesTotal;
			var limitTime: Number = ns.bytesLoaded * duration / bytesTotal;
			if (time > limitTime) {
				return limitTime;
			}
			return time;
		}
		//提供给外部调用使用
		public function getTime(): Number {
			if (ns) {
				var time: Number = ns.time;
				//trace("time:",time,startTime,startTimeNum);
				if (time < startTime && startTimeNum<300 && time>0) {
					startTimeNum++;
				}
				if (time < startTime || startTimeNum > 6) {
					time += startTime;
				}
				return time;
			}
			return 0;

		}
		public function getBytesLoaded(): Number {
			if (ns) {
				var bytesLoaded: Number = ns.bytesLoaded;
				//trace("startBytes",startBytes,bytesLoaded);
				if (bytesLoaded < startBytes && startLoadNum<300 && bytesLoaded>0) {
					startLoadNum ++;
				}
				if (bytesLoaded < startBytes || startLoadNum > 6) {
					bytesLoaded += startBytes;
				}
				return bytesLoaded;
			}
			return 0;
		}
		public function getDuration(): Number {
			return duration;
		}
		public function getBytesTotal(): Number {
			//trace(NUM,"总字节:",bytesTotal);
			return bytesTotal;
		}
		public function getBufferTime(): Number {
			if (ns && getTime() < getDuration() - C.CONFIG["config"]["bufferTime"] * 0.001) {
				return ns.bufferTime;
			}
			return (C.CONFIG["config"]["bufferTime"] * 0.001) * 2;
		}
		public function getBufferLength(): Number {
			if (ns) {
				return ns.bufferLength;
			}
			return 0.2;
		}
		public function videoPlay(): void {
			if (ns) {
				ns.resume();
			}
		}
		public function videoPause(): void {
			if (ns) {
				ns.pause();
			}
		}
		public function videoSeek(time: Number = 0): void {
			//trace("要跳转的时间：",time);
			if (ns) {
				if (DRAG == "") {
					ns.seek(getNewTime(time));
				} else {
					if (playUrl.indexOf(script.replace(DRAG, ["time_", "frames_"], ["", ""]) + "=") > -1) {
						newPlayUrl(time);
					} else {
						if (time <= getNewTime(time)) {
							ns.seek(time);
						} else {
							newPlayUrl(time);
						}
					}
				}
			}
		}
		public function videoVolume(val: Number = 0): void { //修改音量
			if (isClear) { //如果已被清除，则不进行下面的动作
				return;
			}
			var v: SoundTransform = ns.soundTransform;
			v.volume = val;
			if (ns) {
				ns.soundTransform = v;
			}
		}

		public function clear(): void {
			isClear = true; //设置清除
			if (nc != null) {
				nc.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
				nc.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
				nc = null;
			}
			if (ns != null) {
				ns.dispose();
				ns.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
				ns.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, netSteameErrorHandler);
				ns = null;
			}
		}
		//提供给外部调用结束
	}

}