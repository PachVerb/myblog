package ckaction.ad {
	import ckaction.act.script;
	import flash.display.Sprite;
	import ckaction.act.timeInterval;
	import flash.display.Stage;
	import flash.events.Event;
	import ckaction.act.httpload;
	import flash.display.Loader;
	import ckaction.player.httpstream;
	import ckaction.player.rtmpstream;
	import ckaction.player.httpm3u8;
	import ckaction.player.gifPlayer;
	import flash.display.MovieClip;
	import ckaction.act.requestController;
	import flash.events.MouseEvent;
	import ckaction.style.element;
	import flash.net.NetStream;
	import flash.media.Video;
	import ckaction.act.log;

	public class adPlayer {

		//播放广告所要用到的变量
		private var FUN: Object = null; //调用主局函数
		private var ADV: Object = null; //有关于广告的配置函数
		private var STAGE: Stage = null;
		private var THIS: Sprite = null;
		public var STYLE: String = "";
		private var isClose: Boolean = false;
		private var stageW: int = 0,
			stageH: int = 0;
		private var adIndex: int = -1; //广告的深度用来做了第二次加载广告时用
		//
		private var adList: Array = []; //广告数组
		private var timeArr: Array = []; //时间数组
		private var timeTotal: int = 0; //总时间
		private var timeNow: int = 0; //总时间，用于计算当前倒计时的
		private var adNum: int = 0; //当前需要播放的编号
		private var timerInter: timeInterval = null;
		private var bg: Object = {};
		//播放函数列表
		private var load: Loader = null;
		private var gif: gifPlayer = null;
		private var video: Video = null;
		private var httpLoad: httpload = null;
		private var httpNetStream: httpstream = null;
		private var rtmpNetStream: rtmpstream = null;
		private var httpM3u8: httpm3u8 = null;

		private var loadGif: MovieClip = null;
		private var adMetaData: Object = null;
		private var adMask: Sprite = null;
		private var mute: Boolean = false; //是否静音状态
		private var showButton: Boolean = false; //是否需要显示功能按钮
		private var showSkipDelay: int = 0;
		private var streamObj:Object=null;

		public function adPlayer(stage: Stage, sprite: Sprite, fun: Object, obj: Array, advertisement: Object, style: String = "") {
			trace("新建了一个adPlayer");
			FUN = fun;
			ADV = advertisement;
			//script.traceObject(ADV);
			bg = ADV["reserve"];
			STAGE = stage;
			THIS = sprite;
			STYLE = style;
			adList = obj;
			stageW = STAGE.stageWidth,
			stageH = STAGE.stageHeight;

			STAGE.addEventListener(Event.RESIZE, function (event: Event) {
				resizeHandler();
			});
			//计算总时间
			for (var i: int = 0; i < adList.length; i++) {
				var adv: Object = adList[i];
				if (adv.hasOwnProperty("time")) {
					timeArr.push(adv["time"]);
				} else {
					timeArr.push(ADV["time"]);
				}
				if (!adv.hasOwnProperty("method")) {
					adList[i]["method"] = ADV["method"];
				}
			}

			timeTotal = script.arrSum(timeArr);
			timeNow = timeTotal;

			trace("timeNow:", timeNow);
			if (style == "front" || style == "insert" || style == "end") {
				showButton = true;
				FUN["advertisementShow"]("background");
				showSkipDelay = ADV[style + "SkipButtonDelay"];
			}
			adPlay();

		}
		private function adPlay(): void {
			if (isClose) {
				return;
			}
			if (adNum >= adList.length) {
				if (showButton) {
					adNum = -1;
					closeNowAd(false);
					closeAdAll();
					FUN["adStop"]();
					return;
				} else {
					adNum = -1;
					timeNow = timeTotal
					closeNowAd();
					return;
				}
			}
			//trace("播放广告",adNum);
			var ad: Object = adList[adNum];
			//script.traceObject(ad);
			if (!ad["type"]) {
				ad["type"] = script.getFileExt(ad["file"]);
			}
			ad["type"] = ad["type"].replace(".", "");
			switch (ad["type"]) {
				case "png":
				case "jpg":
				case "jpeg":
				case "swf":
					httpLoad = new httpload(ad["file"], loaderHandler);
					break;
				case "mp4":
				case "flv":
				case "f4v":
					httpNetStream = new httpstream();
					httpNetStream.videoUrl = ad["file"];
					httpNetStream.netStatus = netStatusHandler;
					httpNetStream.streamSendOut = streamSendOutHandler;
					httpNetStream.error = streamErrorHandler;
					httpNetStream.load();
					break;
				case "rtmp":
					rtmpNetStream = new rtmpstream();
					rtmpNetStream.videoUrl = ad["file"];
					rtmpNetStream.netStatus = netStatusHandler;
					rtmpNetStream.streamSendOut = streamSendOutHandler;
					rtmpNetStream.error = streamErrorHandler;
					rtmpNetStream.load();
					break;
				case "m3u8":
					httpM3u8 = new httpm3u8();
					httpM3u8.videoUrl = ad["file"];
					httpM3u8.netStatus = netStatusHandler;
					httpM3u8.streamSendOut = streamSendOutHandler;
					httpM3u8.error = streamErrorHandler;
					httpM3u8.stage = STAGE;
					httpM3u8.load();
					break;
				case "gif":
					gif = new gifPlayer(ad["file"], gifHandler);
					break;
				default:
					timeNow -= timeArr[adNum];
					adNum++;
					adPlay();
					break;
			}

		}
		//图片，swf加载成功
		private function loaderHandler(ld: Loader = null): void {
			if (isClose) {
				return;
			}
			if (ld) {
				trace("加载成功");
				load = ld;
				adMetaData = {
					width: load.width,
					height: load.height
				};
				if (adIndex > -1) {
					THIS.addChildAt(load, adIndex);
				} else {
					THIS.addChild(load);
					adIndex = THIS.getChildIndex(load)
				}
				if (mute) {
					load.unloadAndStop();
				}
				
				if (adList[adNum].hasOwnProperty("exhibitionMonitor")) {
					new requestController(adList[adNum]["method"], adList[adNum]["exhibitionMonitor"], adList[adNum]);
				}
				if (adList[adNum]["link"]) {
					addAdMask();
					if (ADV["linkButtonShow"] && showButton) {
						FUN["advertisementShow"]("adLinkButton");
					} else {
						FUN["advertisementShow"]("adLinkButton", false);
					}
				}

				addTimerInter(); //使用计时器
				if (showButton) {
					muteButtonShow();
				}
				resizeHandler();

			} else {
				timeNow -= timeArr[adNum];
				adNum++;
				adPlay();
			}
			closeButtonShow();
		}
		//视频状态
		private function netStatusHandler(status: String): void {
			//trace("status", status);
			switch (status) {
				case "NetStream.Play.Stop":
				case "NetConnection.Connect.Closed": //针对rtmp流暂停后被关闭的操作
					timerInter.stop();
					timerInter = null;
					closeNowAd();
					break;
			}
		}
		//视频加载成功
		private function streamSendOutHandler(obj: Object): void {
			//script.traceObject(obj);
			if (isClose || !obj) {
				return;
			}
			streamObj=obj;
			var videoTime: int = Math.floor(obj["metaData"]["duration"]);
			var timeTotalTemp: int = 0;
			var correctionTime: Boolean = false;
			if (ADV["videoForce"] == "true" || ADV["videoForce"] == true) {
				correctionTime = true;
			} else {
				if (timeArr[adNum] > videoTime && videoTime > 0) {
					correctionTime = true;
				}
			}
			if (correctionTime) {
				timeArr[adNum] = videoTime
				timeTotalTemp = script.arrSum(timeArr, -1);
				var cTemp: int = timeTotalTemp - timeTotal;
				timeTotal = timeTotalTemp;
				timeNow += cTemp;
			}
			adMetaData = {
				width: obj["metaData"]["width"],
				height: obj["metaData"]["height"]
			};
			script.traceObject(bg);
			var cObj: Object = {
				stageW: stageW,
				stageH: stageH,
				eleW: adMetaData["width"],
				eleH: adMetaData["height"],
				stretched: ADV[STYLE + "Stretched"],
				align: bg["align"],
				vAlign: bg["vAlign"],
				spacingLeft: bg["spacingLeft"],
				spacingTop: bg["spacingTop"],
				spacingRight: bg["spacingRight"],
				spacingBottom: bg["spacingBottom"]
			};
			var coor: Object = script.getCoor(cObj);
			if (video) {
				video.clear();
				video = null;
			}
			video = new Video(coor["width"], coor["height"]);
			video.x = coor["x"];
			video.y = coor["y"];
			if (adIndex > -1) {
				THIS.addChildAt(video, adIndex);
			} else {
				THIS.addChild(video);
				adIndex = THIS.getChildIndex(video)
			}
			video.attachNetStream(obj["netStream"]);
			video.smoothing = true;

			if (mute) {
				if (httpNetStream) {
					httpNetStream.videoVolume(0);
				}
				if (rtmpNetStream) {
					rtmpNetStream.videoVolume(0);
				}
				if (httpM3u8) {
					httpM3u8.videoVolume(0);
				}

			} else {
				if (httpNetStream) {
					httpNetStream.videoVolume(ADV["videoVolume"]);
				}
				if (rtmpNetStream) {
					rtmpNetStream.videoVolume(ADV["videoVolume"]);
				}
				if (httpM3u8) {
					httpM3u8.videoVolume(ADV["videoVolume"]);
				}
			}
			if (adList[adNum].hasOwnProperty("exhibitionMonitor")) {
				new requestController(adList[adNum]["method"], adList[adNum]["exhibitionMonitor"], adList[adNum]);
			}
			if (adList[adNum]["link"]) {
				addAdMask();
				if (ADV["linkButtonShow"] && showButton) {
					FUN["advertisementShow"]("adLinkButton");
				} else {
					FUN["advertisementShow"]("adLinkButton", false);
				}
			}

			if (ADV["videoForce"] == "false" || !ADV["videoForce"]) {
				addTimerInter(); //使用计时器
			} else {
				changeTimer();
			}
			if (showButton) {
				muteButtonShow();
			}
			closeButtonShow();
		}
		//视频接收到错误
		private function streamErrorHandler(error: String): void {
			if (isClose) {
				return;
			}
			timeNow -= timeArr[adNum];
			adNum++;
			adPlay();
		}
		//gif加载成功
		private function gifHandler(mc: MovieClip = null): void {
			if (isClose) {
				return;
			}
			if (mc != null) {
				loadGif = mc;
				adMetaData = {
					width: loadGif.width,
					height: loadGif.height
				};

				THIS.addChild(loadGif);
				resizeHandler();
				if (adList[adNum].hasOwnProperty("exhibitionMonitor")) {
					new requestController(adList[adNum]["method"], adList[adNum]["exhibitionMonitor"], adList[adNum]);
				}
				if (adList[adNum]["link"]) {
					addAdMask();
					if (ADV["linkButtonShow"] && showButton) {
						FUN["advertisementShow"]("adLinkButton");
					} else {
						FUN["advertisementShow"]("adLinkButton", false);
					}
				}

				addTimerInter(); //使用计时器
				if (showButton) {
					muteButtonShow();
				}
				closeButtonShow();
			} else {
				//加载错误
				timeNow -= timeArr[adNum];
				adNum++;
				adPlay();
			}

		}
		private function closeButtonShow(): void {
			if (isClose) {
				return;
			}
			if (STYLE == "pause" && ADV["closeButtonShow"]) {
				var w: int = 0,
					h: int = 0,
					x: int = 0,
					y: int = 0;
				if (loadGif) {
					w = loadGif.width;
					h = loadGif.height;
					x = loadGif.x;
					y = loadGif.y;
				}
				if (load) {
					w = load.width;
					h = load.height;
					x = load.x;
					y = load.y;
				}
				if (video) {
					w = video.width;
					h = video.height;
					x = video.x;
					y = video.y;
				}
				FUN["changeFaceWh"]({
					x: x,
					y: y,
					w: w,
					h: h
				});
				FUN["advertisementShow"]("closeButton");
			}
		}
		private function muteButtonShow(): void {
			if (ADV["muteButtonShow"]) {
				if (mute) {
					FUN["advertisementShow"]("muteButton", false);
					FUN["advertisementShow"]("escMuteButton");
				} else {
					FUN["advertisementShow"]("muteButton");
					FUN["advertisementShow"]("escMuteButton", false);
				}

			}
		}
		public function adMute(b: Boolean = true): void {
			if (b) {
				if (load) {

				}
				if (streamObj) {
					httpNetStream.videoVolume(0);
				}
			} else {
				if (load) {

				}
				if (httpNetStream) {
					httpNetStream.videoVolume(ADV["videoVolume"]);
				}
			}
			mute = b;
			muteButtonShow();
		}

		private function addAdMask(): void {
			if (isClose) {
				return;
			}
			if (!adMask) {
				var spObj: Object = {
					backgroundColor: 0xFF0000,
					border: 0,
					backgroundAlpha: 0.1, //背景透明度
					width: STAGE.stageWidth,
					height: STAGE.stageHeight
				};
				adMask = element.newSprite(spObj);
				adMask.addEventListener(MouseEvent.CLICK, adMaskClickHandler);
				adMask.buttonMode = true;
			}
			THIS.addChild(adMask);
			resizeHandler();
		}
		private function hideAdMask(): void {
			if (adMask && THIS.contains(adMask)) {
				THIS.removeChild(adMask);
			}
		}
		//计时
		private function addTimerInter(): void {
			var nowTimeNum: int = timeArr[adNum];
			if (showButton) {
				FUN["advertisementShow"]("countDown");
				FUN["advertisementShow"]("countDownText");
				FUN["changeAdCountDown"](timeNow);
			}
			if (timerInter) {
				timerInter.stop();
				timerInter = null;
			}
			trace("timeNow", timeNow, nowTimeNum);
			timerInter = new timeInterval(1000, function () {
				nowTimeNum--;
				timeNow--;
				if (showButton) {
					FUN["changeAdCountDown"](timeNow);
				}
				if (nowTimeNum <= 0) {
					if (STYLE != "pause" || adList.length > 1) {
						timerInter.close();
						timerInter = null;
						closeNowAd();
					}

				} else {
					if (showButton) {
						skipButtonShow();
					}
				}

			});
			timerInter.start();
			if (showButton) {
				skipButtonShow();
			}
		}
		//手动计时
		private function changeTimer(): void {
			if (showButton) {
				FUN["advertisementShow"]("countDown");
				FUN["advertisementShow"]("countDownText");
				FUN["changeAdCountDown"](timeNow);
			}
			if (timerInter) {
				timerInter.close();
				timerInter = null;
			}
			timeNow = timeTotal;
			if (adNum > 0) {
				timeNow -= script.arrSum(timeArr, adNum);
			}
			//trace("timeNow:", timeNow);
			var timeNowTemp: int = timeNow;
			function timerInterFun(): void {
				var vTime: Number = 0;
				if (httpNetStream) {
					vTime = httpNetStream.getTime();
				}
				timeNow = int(timeNowTemp - Math.floor(vTime));
				//trace("vTime", timeNow, vTime);
				if (showButton) {
					FUN["changeAdCountDown"](timeNow);
					skipButtonShow();
				}

			}
			timerInter = new timeInterval(200, timerInterFun);
			timerInter.start();
			if (showButton) {
				timerInterFun();
				skipButtonShow();
			}
		}
		//显示跳过广告按钮
		private function skipButtonShow(): void {
			//showSkipDelay
			//trace("运行了一次skipButtonShow()");
			if (showButton && ADV["skipButtonShow"]) {
				if (timeTotal - timeNow >= showSkipDelay) {
					FUN["advertisementShow"]("skipAdButton");
					FUN["advertisementShow"]("skipDelay", false);
					FUN["advertisementShow"]("skipDelayText", false);
				} else {
					FUN["advertisementShow"]("skipAdButton", false);
					FUN["advertisementShow"]("skipDelay");
					FUN["changeAdSkipDelay"](showSkipDelay - (timeTotal - timeNow));
				}
			}
		}

		private function adMaskClickHandler(event: MouseEvent): void {
			openAdLink();
		}
		//打开广告链接
		public function openAdLink(): void {
			if (adList[adNum].hasOwnProperty("clickMonitor")) {
				new requestController(adList[adNum]["method"], adList[adNum]["clickMonitor"], adList[adNum]);
			}
			script.openLink(adList[adNum]["link"], adList[adNum]["target"]);
		}
		private function resizeHandler(): void {
			if (isClose) {
				return;
			}
			var coor: Object = null;
			stageW = STAGE.stageWidth;
			stageH = STAGE.stageHeight;
			if (adMetaData) {
				var obj: Object = {
					stageW: stageW,
					stageH: stageH,
					eleW: adMetaData["width"],
					eleH: adMetaData["height"],
					stretched: ADV[STYLE + "Stretched"],
					align: bg["align"],
					vAlign: bg["vAlign"],
					spacingLeft: bg["spacingLeft"],
					spacingTop: bg["spacingTop"],
					spacingRight: bg["spacingRight"],
					spacingBottom: bg["spacingBottom"]
				};
				//script.traceObject(obj);
				coor = script.getCoor(obj);
			} else {
				return;
			}
			//script.traceObject(adMetaData);
			//trace("=================");
			//script.traceObject(coor);
			if (load) {
				load.width = coor["width"];
				load.height = coor["height"];
				load.x = coor["x"];
				load.y = coor["y"];
			}
			if (video) {
				video.width = coor["width"];
				video.height = coor["height"];
				video.x = coor["x"];
				video.y = coor["y"];
			}
			if (loadGif) {
				loadGif.width = coor["width"];
				loadGif.height = coor["height"];
				loadGif.x = coor["x"];
				loadGif.y = coor["y"];
				gif.changeWH(coor["width"], coor["height"]);
			}
			if (adMask) {
				adMask.width = coor["width"];
				adMask.height = coor["height"];
				adMask.x = coor["x"];
				adMask.y = coor["y"];
			}
			closeButtonShow();
		}
		//关闭当前的广告
		private function closeNowAd(next: Boolean = true): void { //next是否要播放下一集
			//trace("播放下一庥",adNum);
			hideAdMask();
			if (timerInter) {
				timerInter.stop();
				timerInter = null;
			}
			if (httpLoad) {
				httpLoad = null;
			}
			if (load) {
				load.unloadAndStop();
				THIS.removeChild(load);
				load = null;
			}
			if (httpNetStream) {
				httpNetStream.clear();
				httpNetStream = null;
			}
			if (rtmpNetStream) {
				rtmpNetStream.clear();
				rtmpNetStream = null;
			}
			if (video) {
				THIS.removeChild(video);
				video = null;
			}
			if (gif) {
				gif.underChild();
				gif = null;
			}
			if (loadGif) {
				THIS.removeChild(loadGif);
				loadGif = null
			}
			if (httpM3u8) {
				httpM3u8.clear();
				httpM3u8 = null;
			}
			if (next) {
				timeNow = timeTotal - script.arrSum(timeArr, adNum + 1);
				adNum++;
				adPlay();
			}

		}
		private function closeAdAll(): void {
			if (timerInter) {
				timerInter.stop();
				timerInter = null;
			}
			FUN["advertisementShow"]("background", false);
			FUN["advertisementShow"]("skipAdButton", false);
			FUN["advertisementShow"]("adLinkButton", false);
			FUN["advertisementShow"]("muteButton", false);
			FUN["advertisementShow"]("countDown", false);
			FUN["advertisementShow"]("countDownText", false);
			FUN["advertisementShow"]("skipDelay", false);
			FUN["advertisementShow"]("skipDelayText", false);
			FUN["advertisementShow"]("closeButton", false);
		}
		public function play():void{
			if(isClose){
				return;
			}
			if(timerInter){
				timerInter.start();
			}
			if(streamObj){
				streamObj["netStream"].resume();
			}
			if(loadGif){
				loadGif.play();
			}
			new log(STYLE+"Ad:play");
			THIS["sendJS"](STYLE+"Ad","play");
		}
		public function pause():void{
			if(isClose){
				return;
			}
			if(timerInter){
				timerInter.stop();
			}
			if(streamObj){
				streamObj["netStream"].pause();
			}
			if(loadGif){
				loadGif.stop();
			}
			new log(STYLE+"Ad:pause");
			THIS["sendJS"](STYLE+"Ad","pause");
		}
		public function close(): void {
			trace("关闭");
			isClose = true;
			closeNowAd(false);
			closeAdAll();
		}

	}

}