package ckaction.player {
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.AsyncErrorEvent;
	import flash.media.SoundTransform;
	import ckaction.act.TEA;
	import ckaction.act.timeOut;
	import flash.net.ObjectEncoding;
	import flash.events.ErrorEvent;

	public class rtmpstream {
		public var videoUrl: String = "";

		public var netStatus: Function = null,
			streamSendOut: Function = null,
			error: Function = null; //发送流状态的函数，发送流的函数，统一用来报错的函数
		public var secureToken: String = ""; //secureToken验证串
		public var fcsubscribe: Boolean = false; //是否采用FC
		public var username: String = "",
			password: String = "";
		public var userid:int=0;
		public var videoWH:Object={
			defaultWidth:4,
			defaultHeight:3
		};
		public var usehardwareeecoder:Boolean=false;
		public var bufferTime:int=0;
		private var nc: NetConnection = null;
		private var ns: NetStream = null;
		private var rtmp: String = "",
			live: String = "";
		private var isClear: Boolean = false; //默认不清除
		private var ncClose: Boolean = false;
		private var first: Boolean = true;
		private var duration: Number = 0;
		private var isInfo:Boolean=false;
		
		public function rtmpstream() {
			// constructor code
		}

		public function load(): void {
			trace("新建了一个rtmp_load");
			if (isClear) { //如果已被清除，则不进行下面的动作
				return;
			}
			//分析地址
			var arr: Array = videoUrl.split("|");
			if (arr.length == 2) {
				rtmp = arr[0];
				live = arr[1];
			} else {
				videoUrl.replace("mp4:mp4","mp4");
				arr = videoUrl.split("mp4:");
				if (arr.length >= 2) {
					rtmp = arr[0];
					if(rtmp.lastIndexOf("/")==rtmp.length-1){
						rtmp=rtmp.substr(0,rtmp.lastIndexOf("/"));
					}
					for(var i:int=1;i<arr.length;i++){
						if(i==1){
							live+="mp4:";
						}
						live += arr[i];
					}
				} else {
					var x:int = videoUrl.lastIndexOf("/");
					arr = [];
					if (x > 0) {
						arr.push(videoUrl.substr(0, x), videoUrl.substr(x + 1));
					}
					if (arr.length == 2) {
						rtmp = arr[0];
						live = arr[1];
					}
				}
			}
			trace("rtmp:"+rtmp);
			trace("live:"+live);
			//return;
			nc = new NetConnection();
			nc.client=this;
			nc.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			nc.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
			nc.objectEncoding=ObjectEncoding.AMF0;
			//nc.connect(rtmp);
			if (userid > 0) {
				nc.connect(rtmp, userid);
			}
			else if (username != "" && password == "") {
				nc.connect(rtmp + '?' + username.replace("|", "&"));
			}
			else if (username != "" && password != "") {
				nc.connect(rtmp, username, password);
			}
			else {
				nc.connect(rtmp);
			}
			trace(rtmp);
		}
		private function netStatusHandler(event: NetStatusEvent): void {
			trace(event.info.code);
			//return;
			netStatus(event.info.code);
			switch (event.info.code) {
				case "NetConnection.Connect.Success":
					if (secureToken && event.info.secureToken != undefined) {
						nc.call("secureTokenResponse", null, TEA.decrypt(event.info.secureToken, secureToken));
					}
					if (fcsubscribe) {
						nc.call("FCSubscribe", null, live);
					} 
					connectStream();
					break;
				case "NetStream.Play.Start":
					new timeOut(500,function(){
						trace("发送没有");
						if(!isInfo){
							metaDataHandler({
								width:videoWH["defaultWidth"],
								height:videoWH["defaultHeight"],
								duration:0
							});
						}
					});
					break;
				case "NetConnection.Connect.Closed": //针对rtmp流暂停后被关闭的操作
					ncClose = true;
					break;
				default:
					break;
			}
		}
		private function securityErrorHandler(event: SecurityErrorEvent): void {}
		private function netSteameErrorHandler(event: AsyncErrorEvent): void {}
		private function asyncErrorHandler(event: AsyncErrorEvent): void {}
		private function connectStream(): void {
			if (isClear) { //如果已被清除，则不进行下面的动作
				return;
			}
			var customClient = new Object();
			ns = new NetStream(nc);
			ns.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			ns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, netSteameErrorHandler);
			customClient.onMetaData = metaDataHandler;
			ns.client = customClient;
			//useHardwareDecoder
			ns.useHardwareDecoder=usehardwareeecoder;
			trace("缓冲",bufferTime*0.001);
			//ns.bufferTime=bufferTime*0.001;
			ns.play(live);
			trace("live",live);
			//ns.pause();
		}
		private function metaDataHandler(info: Object): void {
			if(isInfo){
				return;
			}
			isInfo=true;
			//ns.pause();
			if (first) {
				first = false;
				info["bytesTotal"] = 0;
				var metaDataObj: Object = {};
				//info["bytesTotal"] = ns.bytesTotal;
				metaDataObj = {
					type: "[object NetStream]",
					metaData: info
				};
				metaDataObj["netStream"] = ns;
				if(info.hasOwnProperty("duration")){
					duration = info["duration"];
				}
				else{
					duration = 0;
				}
				
				if (isClear) { //如果已被清除，则不进行下面的动作
					return;
				}
				trace("发送了一次");
				streamSendOut(metaDataObj);

			}
		}
		//供外部播放时调用
		public function getNs():NetStream{
			return ns;
		}
		//提供给外部调用使用
		public function getTime(): Number {
			if (ns) {
				return ns.time;
			}
			return 0;
		}
		public function getDuration(): Number {
			return duration;
		}
		public function getBytesLoaded(): Number {
			return 0;
		}
		public function getBytesTotal(): Number {
			return 0;
		}
		public function getBufferTime(): Number {
			if (ns) {
				return ns.bufferTime;
			}
			return 0;
		}
		public function getBufferLength(): Number {
			if (ns) {
				return ns.bufferLength;
			}
			return 0;
		}
		public function videoPlay(): void {
			trace("================================================================调用了videoPlay()");
			if (ns) {
				trace("================================================================调用了ns.resume()");
				ns.resume();
			}
		}
		public function videoPause(): void {
			if (ns) {
				ns.pause();
			}
		}
		//提供给外部调用结束
		public function clear(): void {
			isClear = true; //设置清除
			if (ns) {
				if (!ncClose) {
					ns.dispose();
				}
				ns.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
				ns.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, netSteameErrorHandler);
				ns = null;
			}
			if (nc) {
				nc.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
				nc.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
				nc.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
				nc = null;
			}
		}
		public function videoSeek(time: Number = 0): void {
			if (ns) {
				ns.seek(time);
			}
		}
		public function videoVolume(val: Number = 0): void { //修改音量
			var v: SoundTransform = ns.soundTransform;
			v.volume = val;
			if (ns) {
				ns.soundTransform = v;
			}

		}
	}

}