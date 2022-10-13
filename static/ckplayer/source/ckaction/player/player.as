package ckaction.player {
	import flash.events.Event;
	import ckaction.act.script;
	import ckaction.C.C;
	import ckaction.player.httpstream;
	import ckaction.player.rtmpstream;
	import ckaction.player.httpm3u8;
	import ckaction.player.httpmerge;
	import flash.media.Video;
	import flash.display.Stage;
	import flash.display.Sprite;
	import flash.net.NetStream;
	import ckaction.act.timeInterval;
	import fl.motion.ColorMatrix;
	import flash.filters.ColorMatrixFilter;
	import ckaction.act.log;
	import ckaction.act.des;
	import ckaction.act.timeOut;
	import flash.net.FileReference;
	import com.adobe.images.JPGEncoder;
	import flash.display.BitmapData;
	import flash.utils.ByteArray;
	import com.dynamicflash.util.Base64;

	public class player {
		private var STAGE: Stage = null;
		private var THIS: Sprite = null;
		private var playNum: int = 0;
		private var video: Video = null;
		private var stageW: int = 0,
			stageH: int = 0;
		private var stream: Array = new Array();
		private var netStreamObj: Object = new Object();
		private var metaDataObj: Object = {}; //视频默认的元数据
		private var bg: Object = {};
		private var FLASHVARS: Object = {};
		public var NOPLAY: Boolean = false; //是否不自动播放
		public var firstSeek: Number = 0;
		public var volume: Number = 0;
		public var timeCorrect: Number = 0;
		//计时器
		private var timeInterVal: timeInterval = null,
			loadInterVal: timeInterval = null,
			bufferInterVal: timeInterval = null;
		private var timeFrequency: int = 100;
		private var isClear: Boolean = false;
		private var loadIndex: int = 0;
		private var paused: Boolean = false;
		private var ended: Boolean = false;
		private var nowRotation: int = 0;
		//计算加载速度
		private var oldByte: Number = 0;
		private var loadSpeed: Number = 0;
		//buffer
		private var bufferB: Number = 0
		public var vType: String = "";
		private var tempUrl: String = "";
		private var streamClosed: Boolean = false;
		private var brightness: int = 0,
			contrast: Number = 127.5,
			saturation: int = 1,
			hue: int = 0;
		private var zoom: Number = 1;
		private var proportion: Object = {
			width: 0,
			height: 0
		};
		private var loadTime:Number=0;//加载的时间
		private var errorNum: int = 0; //错误重试次数
		private var rtmpLink: Boolean = false; //是否需要暂停后重连接
		/*
		private var httpNetStream: httpstream = null;
		private var rtmpNetStream: rtmpstream = null;
		private var httpM3u8: httpm3u8 = null;
		private var httpMerge:httpmerge=null;//多段视频播放
		*/
		private var nowPlayUrl: String = "";
		public function player(stage: Stage, sprite: Sprite, noPlay: Boolean = false, index: int = 0, n: int = 0, seek: int = 0) {
			// constructor code
			//trace("新建了一个player", firstSeek);
			STAGE = stage;
			THIS = sprite;
			NOPLAY = noPlay;
			//trace("NOPLAY===",NOPLAY);
			loadIndex = index;
			stageW = STAGE.stageWidth;
			stageH = STAGE.stageHeight;
			playNum = n;
			firstSeek = seek;
			STAGE.addEventListener(Event.RESIZE, function (event: Event) {
				resizeHandler();
			});
			var config: Object = C.CONFIG;
			timeFrequency = config["config"]["timeFrequency"];
			bg = config["style"]["video"]["reserve"];
			FLASHVARS = config["flashvars"];
			volume = FLASHVARS["volume"];
			nowRotation = FLASHVARS["rotation"];
			errorNum = 0;
			loadHandler();
		}
		private function loadHandler(): void {
			//trace("调用了一次loadHandler", C.CONFIG["flashvars"]["live"]);
			stream = [];
			//netStreamObj=null;
			if (timeInterVal) {
				timeInterVal.stop();
			}
			var config: Object = C.CONFIG;
			if (!metaDataObj.hasOwnProperty("width") || !metaDataObj.hasOwnProperty("height")) {
				metaDataObj = {
					width: config["style"]["videoDefault"]["defaultWidth"],
					height: config["style"]["videoDefault"]["defaultHeight"]
				};
			}
			//格式化视频地址
			if (!config["flashvars"]["video"]) {
				error("No video url");
				return;
			}
			var videoArr: Array = config["flashvars"]["video"];
			if (videoArr.length == 0) {
				error("No video url");
				return;
			}
			var vObj: Object = videoArr[playNum];
			//script.traceObject(vObj);
			if (vObj.hasOwnProperty("video")) {
				var httpMerge: httpmerge = new httpmerge();
				httpMerge.videoUrl = vObj["video"];
				httpMerge.speedFun = speedFunction;
				stream.push(httpMerge);
			} else {
				//script.traceObject(vObj);
				if (vObj.hasOwnProperty("type")) {
					vType = vObj["type"];
				}
				if (!vType && vObj.hasOwnProperty("file")) {
					vType = script.getFileExt(vObj["file"]);
				}
				vType = vType.replace("video/", "").replace(".", "");
				switch (vType) {
					case "m3u8":
						var httpM3u8: httpm3u8 = new httpm3u8();
						httpM3u8.stage = STAGE;
						httpM3u8.definitionList = definitionList;
						httpM3u8.definitionNow = definitionNow;
						httpM3u8.speedFun=speedFun;
						stream.push(httpM3u8);
						break;
					case "rtmp":
						var rtmpNetStream: rtmpstream = new rtmpstream();
						rtmpNetStream.secureToken = C.CONFIG["flashvars"]["securetoken"];
						rtmpNetStream.fcsubscribe = C.CONFIG["flashvars"]["fcsubscribe"];
						rtmpNetStream.username = C.CONFIG["flashvars"]["username"];
						rtmpNetStream.password = C.CONFIG["flashvars"]["password"];
						rtmpNetStream.userid = C.CONFIG["flashvars"]["userid"];
						rtmpNetStream.videoWH = C.CONFIG["style"]["video"];
						rtmpNetStream.bufferTime= C.CONFIG["config"]["rtmpBufferTime"];
						stream.push(rtmpNetStream);
						break;
					default:
						var httpNetStream: httpstream = new httpstream();
						stream.push(httpNetStream);
						break;
				}
				//trace("==========",vObj);
				if (!tempUrl && vObj.hasOwnProperty("file")) {
					tempUrl = des.getString(vObj["file"]);
				}
				if (C.CONFIG["flashvars"]["unescape"]) {
					if(vObj.hasOwnProperty("file")){
						nowPlayUrl = unescape(des.getString(vObj["file"]));
					}
					else{
						nowPlayUrl=vObj.toString();
					}
					
				} else {
					if(vObj.hasOwnProperty("file")){
						nowPlayUrl = des.getString(vObj["file"]);
					}
					else{
						nowPlayUrl=vObj.toString();
					}
				}
				stream[0].videoUrl = nowPlayUrl;
				THIS["sendJS"]("playFile", nowPlayUrl);
			}
			stream[0].netStatus = netStatus;
			try{
				stream[0].usehardwareeecoder = C.CONFIG["config"]["usehardwareeecoder"];
			}
			catch(event: Error){
				
			}
			stream[0].streamSendOut = streamSendOut; //changeNetStream
			stream[0].error = error;
			stream[0].load();
		}
		private function speedFunction(sp: int = 0): void {
			//trace("sp:",sp);
			THIS["getPlayerData"]({
				name: "showBuffer",
				val: sp
			});
		}
		//当修改了C.CONFIG后
		public function changeConfig() {
			var config: Object = C.CONFIG;
			timeFrequency = config["config"]["timeFrequency"];
			bg = config["style"]["video"]["reserve"];
			FLASHVARS = config["flashvars"];
			nowRotation = FLASHVARS["rotation"];
		}
		//用于交互
		public function haveNetStream(): Boolean {
			return netStreamObj.hasOwnProperty("netStream");
		}
		public function videoPlay(): void {

			paused = false;
			if (streamClosed) {
				streamClosed = false;
				stream[0].clear();
				stream[0] = null;
				//trace("------------------------------------------------------------loadHandler");
				loadHandler();
				return;
			}
			//trace("firstSeek",firstSeek);
			if (firstSeek > 0) {
				THIS["videoPause"](false);
				var firstSeekTemp: Number = firstSeek;
				if (haveNetStream()) {
					firstSeek = 0;
				}
				new timeOut(200, function () {
					THIS["videoSeek"](firstSeekTemp);

				});


			} else {
				//trace(stream[0].getDuration(), stream[0].getTime(), ended );
				if (ended == true) {
					ended = false;
					//trace("结束");
					if (vType != "m3u8") {
						THIS["videoSeek"](0);
					} else {
						stream[0].clear();
						stream[0] = null;
						loadHandler();
					}

				} else {
					//trace("=========================================================================调用了stream[0].videoPlay()258");
					stream[0].videoPlay();
				}
			}


		}
		public function videoPause(): void {
			stream[0].videoPause();
			//trace("暂停");
			paused = true;
			if (rtmpLink) {
				streamClosed = true;
				rtmpLink = false;
				NOPLAY = false;
			}
		}
		public function changeVolume(v: Number = 1): void {
			//trace("要修改成的音量:", v);
			if (stream.length > 0) {
				volume = v;
				stream[0].videoVolume(v);
			}

		}
		public function videoSeek(t: Number = 0): void {
			//trace("要跳转：",t);
			if (stream.length > 0) {
				if(t > stream[0].getDuration()){
					if(C.CONFIG["flashvars"]["forceduration"]>0){
						t = 0;
						THIS["sendJS"]("ended");
					}
					else{
						t = stream[0].getDuration()-0.6;
					}
					
					//
				}
				if (stream[0].getDuration() > 0 && !C.CONFIG["config"]["liveAndVod"]["open"]) {
					if (ended && this.vType == "m3u8") {
						ended = false;
						//trace("firstSeek====", firstSeek);
						firstSeek = t;
						stream[0].clear();
						stream[0] = null;
						loadHandler();
						return;
					}
					if (t >= 0) {
						stream[0].videoSeek(t);
					}
				}
				if (C.CONFIG["config"]["liveAndVod"]["open"]) {
					var nowDate: Date = new Date();
					if (C.CONFIG["config"]["time"] > 0) {
						nowDate = new Date(C.CONFIG["config"]["time"]);
					}
					var minutes: int = nowDate.minutes;
					var seconds: int = nowDate.seconds;
					var val: Number = (C.CONFIG["config"]["liveAndVod"]["vodTime"] - 1) * 3600 + minutes * 60 + seconds - t;
					if (val < 0) {
						backLive();
						return;
					}
					var newUrl: String = tempUrl;
					var start: String = C.CONFIG["config"]["liveAndVod"]["start"];
					start += ("=" + val);
					if (newUrl.indexOf("?") > -1) {
						newUrl = newUrl + "&" + start;
					} else {
						newUrl = newUrl + "?" + start;
					}
					//trace(newUrl);
					timeCorrect = val; //记录要纠正的时间
					changeVideoUrl(newUrl);
				}

			}
			ended = false;
		}
		public function backLive(): void {
			if (tempUrl != "") {
				changeVideoUrl(tempUrl);
				timeCorrect = 0;
			}

		}
		private function changeVideoUrl(url: String): void {
			stream[0].clear();
			stream[0] = null;
			C.CONFIG["flashvars"]["video"][playNum]["file"] = url;
			loadHandler();

		}
		public function getPaused(): Boolean {
			return paused;
		}
		//用于交互结束
		private function netStatus(status: String) {
			trace(status);
			THIS["netStatus"](status);
			switch (status) {
				case "NetStream.Play.Stop": //播放完毕
					ended = true;
					break;
				case "NetConnection.Connect.Closed": //流被关闭了
					streamClosed = true;
					if (!C.CONFIG["flashvars"]["live"]) {
						firstSeek = stream[0].getTime();
					}
					if (!paused) {
						//trace("==================THIS[\"videoPlay\"]();==368");
						THIS["videoPlay"]();
					}
					break;
				default:
					break;
			}
		}
		private function formatMetaDataObj(obj):Object{//用来格式化视频的宽和高度
			var k:String="";
			if (!obj.hasOwnProperty("width")) {
				for(k in obj){
					if(k.toLowerCase().indexOf("width")>-1){
						if(int(obj[k])>0){
							obj["width"]=obj[k];
						}
					}
				}
			}
			if (!obj.hasOwnProperty("height")) {
				for(k in obj){
					if(k.toLowerCase().indexOf("height")>-1){
						if(int(obj[k])>0){
							obj["height"]=obj[k];
						}
					}
				}
			}
			return obj;
		}
		private function streamSendOut(obj: Object): void {
			if (isClear) {
				return;
			}
			trace("=============接受了一次streamSendOut");
			//script.traceObject(obj["metaData"]);
			//trace("没有",obj.hasOwnProperty("metaData"));
			if (!obj.hasOwnProperty("metaData")) {
				new log("There is no metadata for netStream");
				//return;
			}
			if (video != null) {
				changeNetStream(obj);
				return;
			}
			
			netStreamObj = obj;
			metaDataObj = script.mergeObject(metaDataObj, obj["metaData"]);
			//script.traceObject(netStreamObj);
			//trace("metaDataObj", metaDataObj["width"], metaDataObj["height"]);
			//metaDataObj=formatMetaDataObj(metaDataObj);
			if (!metaDataObj.hasOwnProperty("width")) {
				metaDataObj["width"] = C.CONFIG["style"]["video"]["defaultWidth"];
			}
			if (metaDataObj["width"] == 0) {
				metaDataObj["width"] = C.CONFIG["style"]["video"]["defaultWidth"];
			}
			if (!metaDataObj.hasOwnProperty("height")) {
				metaDataObj["height"] = C.CONFIG["style"]["video"]["defaultHeight"];
			}
			if (metaDataObj["height"] == 0) {
				metaDataObj["height"] = C.CONFIG["style"]["video"]["defaultHeight"];
			}
			//script.traceObject(metaDataObj);
			var cObj: Object = {
				stageW: stageW,
				stageH: stageH,
				eleW: proportion["width"] > 0 ? proportion["width"] : metaDataObj["width"],
				eleH: proportion["height"] > 0 ? proportion["height"] : metaDataObj["height"],
				stretched: bg["stretched"],
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
			if(vType!="rtmp"){
				netStreamObj["netStream"].bufferTime = C.CONFIG["config"]["bufferTime"] * 0.001;
			}
			else{
				netStreamObj["netStream"].bufferTime = C.CONFIG["config"]["rtmpBufferTime"] * 0.001;
			}
			
			if (C.CONFIG["config"]["bufferTimeMax"] > 0) {
				netStreamObj["netStream"].bufferTimeMax = C.CONFIG["config"]["bufferTimeMax"] * 0.001;
			}
			changeVolume(volume);
			video = new Video(coor["width"], coor["height"]);
			video.x = coor["x"];
			video.y = coor["y"];
			video.attachNetStream(netStreamObj["netStream"]);
			//trace("当前视频流的宽高", video.videoHeight, video.videoWidth);
			video.smoothing = true;
			THIS.addChildAt(video, loadIndex);
			trace(video.width,video.height,video.x,video.y,loadIndex);
			//netStreamObj["netStream"].resume();
			if (nowRotation != 0) {
				videoRotation(nowRotation, true);
			}
			//trace(stream[0].getDuration(), !C.CONFIG["flashvars"]["live"], !C.CONFIG["config"]["liveAndVod"]["open"]);
			if (stream[0].getDuration() > 0 && !C.CONFIG["flashvars"]["live"] && !C.CONFIG["config"]["liveAndVod"]["open"]) {
				//trace("总时间：",stream[0].getDuration());
				THIS["getPlayerData"]({
					name: "changeTimeTotal",
					val: stream[0].getDuration()
				});
				//trace("总时间：",stream[0].getDuration());
			} else if (C.CONFIG["config"]["liveAndVod"]["open"] && !C.CONFIG["flashvars"]["live"]) {
				THIS["getPlayerData"]({
					name: "changeTimeTotal",
					val: C.CONFIG["config"]["liveAndVod"]["vodTime"] * 3600
				});
			} else {
				//trace("修改了live");
				C.CONFIG["flashvars"]["live"] = true;
			}
			//trace("+++",C.CONFIG["flashvars"]["live"]);
			timeInterVal = new timeInterval(timeFrequency, timeInterValHandler);
			timeInterVal.start();
			//trace("vType:==========================",vType);
			if (stream[0].getBytesTotal() > 0) {
				if (stream[0].getBytesTotal() > 0) {
					THIS["getPlayerData"]({
						name: "changeLoadTotal",
						val: stream[0].getBytesTotal()
					});
				}
				//trace("添加了监听加载量的计算");
				loadInterVal = new timeInterval(timeFrequency, loadInterValHandler);
				loadInterVal.start();
			}
			bufferInterVal = new timeInterval(100, bufferInterValHandler);
			bufferInterVal.start();
			if (vType == "rtmp") {
				if (!C.CONFIG["config"]["playCorrect"] || NOPLAY) {
					//trace("video执行了暂停");
					THIS["videoPause"](false);
				}
			} else {
				//videoPause();
				THIS["videoPause"](false);
			}
			//script.traceObject(C.CONFIG["flashvars"]);
			//trace("NOPLAY", NOPLAY);
			if (!NOPLAY) {
				trace("==================THIS[\"videoPlay\"]();==519");
				THIS["videoPlay"]();
			}
			//trace("=收到一个流");
			THIS["changeVolume"](volume);
			if (vType == "rtmp" && C.CONFIG["flashvars"]["live"] && C.CONFIG["config"]["playCorrect"]) {
				rtmpLink = true;
			}
		}
		private function changeNetStream(obj: Object): void {
			netStreamObj = obj;
			//script.traceObject(metaDataObj);
			if (video) {
				video.clear();
				video.attachNetStream(netStreamObj["netStream"]);
				changeVolume(volume);
				if (!C.CONFIG["config"]["playCorrect"]) {
					THIS["videoPause"](false);
				}
				trace("==================THIS[\"videoPlay\"]();==537");
				THIS["videoPlay"]();
				if (timeInterVal) {
					timeInterVal.start();
				}
			}
		}
		private function timeInterValHandler(): void {
			var timeTemp: Number = stream[0].getTime();
			//trace(stream[0].getDuration() == 0 , C.CONFIG["flashvars"]["live"] , C.CONFIG["config"]["liveAndVod"]["open"]);
			if (!C.CONFIG["flashvars"]["live"] && C.CONFIG["config"]["liveAndVod"]["open"]) {
				timeTemp = -timeCorrect - 999;
			}
			//trace(stream[0].getDuration() , !C.CONFIG["flashvars"]["live"] , !C.CONFIG["config"]["liveAndVod"]["open"]);
			if (stream[0].getDuration() > 0 && !C.CONFIG["flashvars"]["live"] && !C.CONFIG["config"]["liveAndVod"]["open"]) {
				if (ended == true) {
					timeTemp = stream[0].getDuration();
				}
				THIS["getPlayerData"]({
					name: "timePlaySliderChange",
					val: timeTemp
				});
				THIS["getPlayerData"]({
					name: "changeVodTime",
					val: timeTemp
				});
				THIS["getPlayerData"]({
					name: "timePlaySimpleChange",
					val: timeTemp
				});
			} else {
				THIS["getPlayerData"]({
					name: "changeLiveTime",
					val: timeTemp
				});
				if (C.CONFIG["config"]["liveAndVod"]["open"]) {
					THIS["getPlayerData"]({
						name: "timePlaySliderChange",
						val: timeTemp
					});
					THIS["getPlayerData"]({
						name: "timePlaySimpleChange",
						val: timeTemp
					});
				}

			}
		}
		private function speedFun(b:Number):void{
			THIS["sendJS"]("speed", b);
		}
		private function loadInterValHandler(): void {
			var loadByte: Number = stream[0].getBytesLoaded();
			if (loadByte > oldByte) {
				loadSpeed = ((loadByte - oldByte) / C.CONFIG["config"]["timeFrequency"]) * (1000 / C.CONFIG["config"]["timeFrequency"]);
				THIS["sendJS"]("speed", loadSpeed);
				//计算当前已加载的时间
				var totalT=stream[0].getDuration();
				var totalL=stream[0].getBytesTotal();
				var nT=0;
				if(totalL>0){
					nT=totalT*loadByte/totalL;
				}
				loadTime=nT;
				THIS["sendJS"]("loadTime", nT);
				THIS["sendJS"]("loadByte", loadByte);
			}
			oldByte = loadByte;
			if (loadByte > 0) {
				if (loadByte < stream[0].getBytesTotal()) {
					THIS["getPlayerData"]({
						name: "timeLoadSliderChange",
						val: loadByte
					});
					THIS["getPlayerData"]({
						name: "timeLoadSimpleChange",
						val: loadByte
					});
				} else {
					if (loadInterVal) {
						loadInterVal.close();
						loadInterVal = null;
					}
					THIS["getPlayerData"]({
						name: "timeLoadSliderChange",
						val: stream[0].getBytesTotal()
					});
					THIS["getPlayerData"]({
						name: "timeLoadSimpleChange",
						val: stream[0].getBytesTotal()
					});
					THIS["sendJS"]("loadComplete");
				}
			}
		}
		private function bufferInterValHandler(): void {

			var bufferTime: Number = stream[0].getBufferTime();
			var bufferLength: Number = stream[0].getBufferLength();
			if (bufferLength >= bufferTime || (stream[0].getTime() > stream[0].getDuration() - bufferTime)) {
				THIS["getPlayerData"]({
					name: "showBuffer",
					val: 100
				});
			} else {
				bufferB = Math.round(bufferLength * 100 / bufferTime);
				THIS["getPlayerData"]({
					name: "showBuffer",
					val: bufferB
				});
			}
		}
		//调用亮度

		public function videoBrightness(n: int = 0): void {
			if (video) {
				var m: ColorMatrix = new ColorMatrix();
				var f: ColorMatrixFilter = new ColorMatrixFilter();
				m.SetBrightnessMatrix(n); //设置亮度值，值的大小是 -255--255   0为中间值，向右为亮向左为暗。
				f.matrix = m.GetFlatArray();
				video.filters = [f];
				brightness = n;
			}

		}
		//调整video的对比度
		public function videoContrast(n: Number = 127.5): void {
			if (video) {
				var m: ColorMatrix = new ColorMatrix();
				var f: ColorMatrixFilter = new ColorMatrixFilter();
				m.SetContrastMatrix(n); //设置对比度值，值的大小是 -255--255  127.5为中间值，向右对比鲜明向左对比偏暗。
				f.matrix = m.GetFlatArray();
				video.filters = [f];
				contrast = n;
			}
		}
		//调整video的饱和度
		public function videoSaturation(n: int = 1): void {
			if (video) {
				var m: ColorMatrix = new ColorMatrix();
				var f: ColorMatrixFilter = new ColorMatrixFilter();
				m.SetSaturationMatrix(n); //设置饱和度值，值的大小是 -255--255   1为中间值，0为灰度值（即黑白相片）。
				f.matrix = m.GetFlatArray();
				video.filters = [f];
				saturation = n;
			}

		}
		//调整video的色相
		public function videoHue(n: int = 0): void {
			if (video) {
				var m: ColorMatrix = new ColorMatrix();
				var f: ColorMatrixFilter = new ColorMatrixFilter();
				m.SetHueMatrix(n); //设置色相值，值的大小是 -255--255  0为中间值，向右向左一试便知。
				f.matrix = m.GetFlatArray();
				video.filters = [f];
				hue = n;
			}
		}
		//截图
		public function screenshot(obj: String, save: Boolean = false, name: String = ""): void {
			var fileReference: FileReference = new FileReference();
			var encoder: JPGEncoder = new JPGEncoder(100);
			var bitmapData: BitmapData = null;
			if (obj == "video" && video) {
				//trace("============",THIS.graphics.readGraphicsData()[loadIndex]);
				//trace(new GraphicsBitmapFill(.bitmapData));
				try {
					bitmapData = new BitmapData(video.width, video.height);
					bitmapData.draw(video);
				} catch (event: Error) {
					new log("screenshot " + obj + " Error:" + event);
				}
			} else {
				bitmapData = new BitmapData(this.stageW, this.stageH);
				bitmapData.draw(THIS);
			}
			var data: ByteArray = encoder.encode(bitmapData);
			if (save) {
				if (name == "") {
					if (haveNetStream()) {
						name = script.getNowDate(false) + "-" + stream[0].getTime() + ".jpg";
					} else {
						name = script.getNowDate(false) + ".jpg";
					}
					//trace(name);
				}
				try {
					fileReference.save(data, name);
					data.clear();
				} catch (event: Error) {
					new log(event);
				}
			}
			var bs: String = "data:image/jpg;base64," + Base64.encodeByteArray(data);
			THIS["screenshotJS"](obj, save, name, bs);
		}
		//旋转
		public function videoRotation(r: Number = 0, isR: Boolean = false): void {
			if (!video || (nowRotation == r && !isR)) {
				resizeHandler();
				return;
			}
			if (r != 1 && r != -1 && r != -90 && r != -180 && r != -270 && r != 90 && r != 270 && r != 180 && r != 0) {
				resizeHandler();
				return;
			}
			var temp: int = 0;
			if (r != -1 && r != 1) {
				nowRotation = r;
			} else {
				if (r == 1) {
					if (nowRotation < 270) {
						nowRotation += 90;
					} else {
						nowRotation = 0;
						resizeHandler();
						return;
					}
				} else {
					if (nowRotation > -270) {
						nowRotation -= 90;
					} else {
						nowRotation = 0;
						resizeHandler();
						return;
					}
				}

			}
			if (!isR) {
				resizeHandler();
				return;
			}
			var wh: Object = {};
			if (metaDataObj) {
				wh = {
					width: metaDataObj["width"],
					height: metaDataObj["height"]
				}
			} else {
				wh = {
					width: video.videoWidth,
					height: video.videoHeight
				}
			}
			var coor: Object = {};
			var obj: Object = {
				stageW: stageW,
				stageH: stageH,
				eleW: wh["width"],
				eleH: wh["height"],
				stretched: bg["stretched"],
				align: bg["align"],
				vAlign: bg["vAlign"],
				spacingLeft: bg["spacingLeft"],
				spacingTop: bg["spacingTop"],
				spacingRight: bg["spacingRight"],
				spacingBottom: bg["spacingBottom"]
			};
			switch (nowRotation) {
				case 90:
				case -270:
					temp = obj["eleW"];
					obj["eleW"] = obj["eleH"];
					obj["eleH"] = temp;
					coor = script.getCoor(obj);
					coor["x"] = coor["x"] + coor["width"];
					if (zoom == 1) {
						video.height = coor["width"];
						video.width = coor["height"];
					} else {
						video.height = coor["width"] * zoom;
						video.width = coor["height"] * zoom;
						coor["x"] += coor["width"] * (zoom - 1) * 0.5;
						coor["y"] -= coor["height"] * (zoom - 1) * 0.5;
					}
					break;
				case 180:
				case -180:
					coor = script.getCoor(obj);
					coor["x"] = coor["x"] + coor["width"];
					coor["y"] = coor["y"] + coor["height"];
					if (zoom == 1) {
						video.height = coor["height"];
						video.width = coor["width"];
					} else {
						video.height = coor["height"] * zoom;
						video.width = coor["width"] * zoom;
						coor["y"] += coor["height"] * (zoom - 1) * 0.5;
						coor["x"] += coor["width"] * (zoom - 1) * 0.5;
					}
					break;
				case 270:
				case -90:
					temp = obj["eleW"];
					obj["eleW"] = obj["eleH"];
					obj["eleH"] = temp;
					coor = script.getCoor(obj);
					coor["y"] = coor["y"] + coor["height"];
					if (zoom == 1) {
						video.height = coor["width"];
						video.width = coor["height"];
					} else {
						video.height = coor["width"] * zoom;
						video.width = coor["height"] * zoom;
						coor["y"] += (coor["height"] * (zoom - 1) * 0.5);
						coor["x"] -= coor["width"] * (zoom - 1) * 0.5;
					}
					break;
				default:
					resizeHandler();
					return;
					break;

			}
			video.rotation = nowRotation;
			video.x = coor["x"];
			video.y = coor["y"];
		}
		//长宽比例
		public function videoProportion(w: int = 0, h: int = 0): void {
			proportion = {
				width: w,
				height: h
			};
			resizeHandler();
		}
		//监听控制栏是否显示
		public function controlBarIsShow(b: Boolean): void {
			if (b) {
				bg = C.CONFIG["style"]["video"]["reserve"];
			} else {
				bg = C.CONFIG["style"]["video"]["controlBarHideReserve"];
			}
			resizeHandler();
		}
		//缩放比例
		public function videoZoom(n: Number = 1): void {
			if (n < 0) {
				return;
			}
			zoom = n;
			resizeHandler();
		}
		private function resizeHandler(): void {
			if (isClear) {
				return;
			}
			stageW = STAGE.stageWidth;
			stageH = STAGE.stageHeight;
			if (video) {
				video.rotation = 0;
			}
			var coor: Object = {};
			if (metaDataObj && video) {
				var obj: Object = {
					stageW: stageW,
					stageH: stageH,
					eleW: proportion["width"] > 0 ? proportion["width"] : metaDataObj["width"],
					eleH: proportion["height"] > 0 ? proportion["height"] : metaDataObj["height"],
					stretched: bg["stretched"],
					align: bg["align"],
					vAlign: bg["vAlign"],
					spacingLeft: bg["spacingLeft"],
					spacingTop: bg["spacingTop"],
					spacingRight: bg["spacingRight"],
					spacingBottom: bg["spacingBottom"]
				};
				coor = script.getCoor(obj);
				video.width = coor["width"];
				video.height = coor["height"];
				video.x = coor["x"];
				video.y = coor["y"];
				if (zoom != 1 && zoom >= 0) {
					video.x -= (video.width * (zoom - 1) * 0.5);
					video.y -= (video.height * (zoom - 1) * 0.5);
					video.width = video.width * zoom;
					video.height = video.height * zoom;
				}
				if (nowRotation != 0) {
					videoRotation(nowRotation, true);
				}
			} else {
				return;
			}
		}
		public function getStatus(): Object {
			if (!video) {
				return null;
			}
			var obj: Object = {
				videoWidth: video.width,
				videoHeight: video.height,
				streamWidth: metaDataObj["width"],
				streamHeight: metaDataObj["height"],
				videoX: video.x,
				videoY: video.y,
				width: stageW,
				height: stageH,
				videoRotation: nowRotation,
				time: netStreamObj["netStream"].time,
				totalTime: metaDataObj.hasOwnProperty("duration") ? metaDataObj["duration"] : 0,
				duration: metaDataObj.hasOwnProperty("duration") ? metaDataObj["duration"] : 0,
				bytesLoaded: netStreamObj["netStream"].bytesLoaded,
				bytesTotal: netStreamObj["netStream"].bytesTotal,
				speed: loadSpeed,
				volume: volume,
				buffer: bufferB,
				loadTime:loadTime,
				brightness: brightness,
				contrast: contrast,
				saturation: saturation,
				hue: hue,
				paused: getPaused(),
				metaData: metaDataObj
			}
			return obj;
		}
		public function posterHandler(): void {
			if (video) {
				THIS.setChildIndex(video, loadIndex);
			}
		}
		public function clear(): void {
			isClear = true;
			if (haveNetStream()) {
				stream[0].clear();
				stream[0] = null;
			}
			if (video) {
				THIS.removeChild(video);
				video = null;
			}
			if (timeInterVal) {
				timeInterVal.close();
				timeInterVal = null;
			}
			if (loadInterVal) {
				loadInterVal.close();
				loadInterVal = null;
			}
			if (bufferInterVal) {
				bufferInterVal.close();
				bufferInterVal = null;
			}
		}
		public function getCurrentSrc(): String {
			return nowPlayUrl;
		}
		private function definitionList(arr: Array, n: int = 0): void {
			//获得列表后将flashvars里的video变成标准格式
			var a: Array = [];
			var defTags: Array = C.CONFIG["config"]["m3u8Definition"]["tags"];
			var defName: Array = C.CONFIG["language"]["m3u8Definition"]["name"];
			for (var i: int = 0; i < arr.length; i++) {
				var obj: Object = {
					file: arr[i],
					type: "m3u8",
					weight: 0,
					definition: script.formatM3u8Definition(arr[i], i, defTags, defName)
				};
				if (i == n) {
					obj["weight"] = 1;
				}
				a.push(obj);
			}
			nowPlayUrl = arr[n];
			C.CONFIG["flashvars"]["video"] = a;
			THIS["faceDefinition"](n);
		}
		private function definitionNow(n: int): void {
			if (!C.CONFIG["config"].hasOwnProperty("m3u8Definition")) {
				return;
			}
			THIS["faceDefinition"](n);
		}
		private function error(error: String = ""): void {
			if (errorNum < C.CONFIG["config"]["errorNum"]) {
				streamClosed = false;
				if (stream[0] != null) {
					stream[0].clear();
					stream[0] = null;
				}
				errorNum++;
				//trace("------------------------------------------------------------loadHandler-error");
				loadHandler();

			} else {
				errorNum = 0;
				new log("error:" + error);
				THIS["videoError"](C.CONFIG["flashvars"]["streamNotFound"] != "" ? C.CONFIG["flashvars"]["streamNotFound"] : C.CONFIG["language"]["error"]["streamNotFound"]);
			}

		}
	}

}