package ckaction {
	import flash.display.Sprite;
	import flash.display.StageScaleMode;
	import flash.display.StageAlign;
	import flash.events.Event;
	import flash.system.Security;
	import flash.display.StageDisplayState;
	import flash.events.KeyboardEvent;
	import ckaction.process.config;
	import ckaction.act.script;
	import ckaction.style.face;
	import ckaction.process.analysisVideoUrl;
	import ckaction.act.timeOut;
	import ckaction.process.analysis;
	import ckaction.style.poster;
	import ckaction.ad.adPlayer;
	import ckaction.C.C;
	import ckaction.player.player;
	import ckaction.act.timeInterval;
	import ckaction.ad.adOtherPlayer;
	import ckaction.style.newElement;
	import flash.external.ExternalInterface;
	import ckaction.act.log;
	import ckaction.menu.rightMenu;
	import ckaction.act.script;
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import ckaction.process.analysisVideoUrlNum;
	import ckaction.act.loadXml;
	import ckaction.style.track;
	import flash.events.ErrorEvent;
	import flash.events.MouseEvent;


	public class main extends Sprite {
		Security.allowDomain("*");
		Security.allowInsecureDomain("*");
		private var FLASHVARS: Object = {}; //flashvars
		private var FACE: face = null;
		//
		private var tempVolume: Number = 0,
			nowVolume: Number = 0;
		//
		private var controlBarShow: Boolean = true;
		//
		private var videoUrl: Array = null; //视频地址
		private var adUrl: Object = null; //广告地址
		private var autoPlay: Boolean = false; //是否自动播放
		private var noPlay: Boolean = false; //加载完但不播放（因为前置广告在播放，或默认加载没有前置广告但默认暂停）
		private var autoLoad: Boolean = false; //默认加载
		private var firstPlay: Boolean = false; //是否第一次播放
		private var posterFun: poster = null; //用来加载封面图片的
		private var trackClass: track = null;
		private var mouseCoorObj:Object={x:0,y:0};//保存鼠标坐标
		//广告类
		private var adPlayClass: adPlayer = null;
		private var adName: String = "";
		private var adFrontPlayed: Boolean = false; //前置广告是否已播放
		private var adInsertPlayed: Boolean = false; //插入广告是否在播放
		private var adEndPlayed: Boolean = false; //结束广告是否已播放
		private var adFunObj: Object = {};
		private var insertTimeArr: Array = null; //插入广告的开始时间数组
		private var insertPlay: Array = []; //插入广告保存是否播放的数组
		private var otherTimeArr: Array = null; //其它广告的开始时间数组
		private var otherAdArr: Array = []; //其它广告数组
		private var otherPlay: Array = []; //其它广告保存是否播放的数组
		private var otherAd: Array = []; //其它广告数组
		//
		private var vPlayer: player = null;
		private var time: Number = 0; //当前播放时间
		private var timeTotal: Number = 0;
		private var newVideoTimeOut: timeOut = null;
		//
		private var loadIndex: int = 0; //视频显示的深度，因为界面加载完后在有背景的情况下深度不一定
		//状态
		private var videoState: Object = {};
		private var isKeyClock: Boolean = false; //是否锁定按键
		//其它广告
		private var otherInterVal: timeInterval = null;
		private var otherTime: int = 0;
		//
		private var timeMax: Number = 0,
			timeSeek: Number = -1;
		//构建弹幕文件
		private var element: newElement = null;
		//监听函数列表
		private var listenerArr: Array = [];
		private var playNum: int = 0;
		
		private var errorShow: Boolean = false;
		//是否可以加载官方广告
		private var changeNum: int = 0;
		public function main() {
			// constructor code
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			var flashvars: Object = stage.loaderInfo.parameters;
			if (flashvars.hasOwnProperty("log")) {
				if (flashvars["log"] == "true" || flashvars["log"] == "yes" || flashvars["log"] == 1 || flashvars["log"] == "1") {
					C.CONFIG["flashvars"]["log"] = true;
				}
			}
			stage.addEventListener(Event.RESIZE, resizeHandler);
			adFunObj = {
				advertisementShow: advertisementShow,
				changeAdCountDown: changeAdCountDown,
				changeAdSkipDelay: changeAdSkipDelay,
				adStop: videoPlay,
				changeFaceWh: changeFaceWh
			};
			config(); //加载配置文件
			new log("process:Loaded");
		}
		private function config(): void {
			//加载配置文件
			new log("process:Config load");
			new ckaction.process.config(stage, configHandler);
		}
		private function configHandler(): void {
			//配置文件加载完成
			new log("process:Config loaded");
			//new log(C.CONFIG);
			if (C.CONFIG["config"]["buttonMode"]["player"]) {
				this.buttonMode = true;
			}
			
			//adUrl=C.CONFIG["flashvars"]["adUrl"];
			new rightMenu(this);//构建右键
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler); //监听键盘事件
			stage.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, wheelHandler);
			addCallback();
			if (C.CONFIG["flashvars"]["loaded"] != "") {
				new log("process:Config loaded:"+C.CONFIG["flashvars"]["loaded"]);
				if (C.CONFIG["flashvars"]["variable"] != "") {
					script.callJs(script.formatSsl(C.CONFIG["flashvars"]["variable"]) + ".loadedHandler");
				} else {
					script.callJs(script.formatSsl(C.CONFIG["flashvars"]["loaded"]));
				}
			} else {
				if (C.CONFIG["flashvars"]["variable"] != "") {
					script.callJs(script.formatSsl(C.CONFIG["flashvars"]["variable"]) + ".loadedHandler");
				}
			}

			if (C.CONFIG["config"]["time"] > 0) {
				var tempTimer: timeInterval = new timeInterval(1000, function () {
					var tempNowTime: Number = C.CONFIG["config"]["time"];
					C.CONFIG["config"]["time"] = tempNowTime + 1000;
				});
				tempTimer.start();
			}
			//script.traceObject(C.CONFIG["config"]);

		}
		public function loadFace(): void { //加载风格
			if (C.CONFIG.hasOwnProperty("style") && C.CONFIG.hasOwnProperty("language")) {
				if (C.CONFIG["style"].hasOwnProperty("controlBar")) {
					new log("process:Face load");
					FACE = new face(stage, this, into);
				} else {
					into();
				}
			} else {
				into();
			}
			//script.traceObject(C.CONFIG["flashvars"]);
		}
		private function into(index: int = -1): void { //界面加载完成后开始的动作
			//trace("动作开始");
			//custom('controlBar','button','previousPage',false)
			//script.traceObject(getConfig("config"));
			new log("process:Player start");
			sendJS("playerStart");
			if (C.CONFIG["flashvars"]["crossdomain"] != "") {
				//如果在flashvars里指定了跨域策略，则加载
				flash.system.Security.loadPolicyFile(C.CONFIG["flashvars"]["crossdomain"]);
			} else {
				if (C.CONFIG["config"]["crossdomain"] != "") {
					//如果在配置文件里指定了跨域策略，则加载
					flash.system.Security.loadPolicyFile(C.CONFIG["config"]["crossdomain"]);
				}
			}

			videoError();
			if (loadIndex != index && index != -1) {
				loadIndex = index;
			}
			if (newVideoTimeOut != null) {
				newVideoTimeOut.stop();
				newVideoTimeOut = null;
			}

			if (FACE) { //如果界面对象存在，则初始化
				FACE.changeLoadTotal();
				FACE.timeLoadSliderChange();
				FACE.timeLoadSimpleChange();
				FACE.changeTimeTotal(C.CONFIG["flashvars"]["duration"]);
				FACE.timePlaySimpleChange();
				FACE.timePlaySliderChange();
				if (!C.CONFIG["flashvars"]["live"]) {
					FACE.changeVodTime();
				}
				FACE.showLoading();
				FACE.showCenterPlay(false);
			}
			if (trackClass) {
				trackClass.close();
				trackClass = null;
			}
			new log("process:Analysis video url");
			if (C.CONFIG["flashvars"].hasOwnProperty("video") && C.CONFIG["flashvars"]["video"]) {
				trace("分析视频");
				new analysisVideoUrl(newPlayerHandler); //分析视频地址
			} else {
				new log("error:There is no video in the flashvars");
				videoError(C.CONFIG["flashvars"]["cannotFindUrl"] != "" ? C.CONFIG["flashvars"]["cannotFindUrl"] : C.CONFIG["language"]["error"]["cannotFindUrl"]);
			}

		}
		private function newPlayerHandler(arr: Array = null, m: int = 0): void {
			//视频地址分析完成
			trace("===||");
			script.traceObject(arr);
			new log(arr);
			trace("===");
			if (!arr) {
				new log("error:flashvars[\"video\"] format error");
				videoError(C.CONFIG["flashvars"]["formatError"] != "" ? C.CONFIG["flashvars"]["formatError"] : C.CONFIG["language"]["error"]["formatError"]);
				//trace("已经出错");
				return;
			}
			if (FACE && C.CONFIG["flashvars"]["duration"] > 0) { //如果界面对象存在，则初始化
				FACE.changeTimeTotal(C.CONFIG["flashvars"]["duration"]);
				if (!C.CONFIG["flashvars"]["live"]) {
					FACE.changeVodTime();
				}
			}
			new log("process:Video url analysis completed");
			playNum = m; //要播放的数组索引
			if (C.CONFIG["config"]["definition"] && FACE) {
				FACE.loadDefinition(playNum);
				FACE.newDefinition(playNum);
			}
			//C.CONFIG["flashvars"]["video"] = arr;
			//C.CONFIG["flashvars"]["weight"] = weight;
			FLASHVARS = C.CONFIG["flashvars"];
			autoPlay = FLASHVARS["autoplay"]; //是否自动播放
			//script.traceObject(C.CONFIG["flashvars"]);
			//trace("autoPlay:",autoPlay,FLASHVARS["autoplay"]);
			autoLoad = C.CONFIG["config"]["autoLoad"];
			nowVolume = FLASHVARS["volume"];
			//trace("autoPlay",autoPlay,autoLoad,nowVolume);
			//script.traceObject(C.CONFIG);
			//return;


			if (otherInterVal) {
				otherInterVal.close();
				otherInterVal = null;
			}
			//script.traceObject(C.CONFIG["flashvars"]);
			if (!FLASHVARS.hasOwnProperty("advertisements") || !FLASHVARS["advertisements"]) {
				advsHandler(null);
			} else {
				//trace("进行分析");
				//script.traceObject(FLASHVARS["advertisements"]);
				new log("process:Analysis advertisements");
				new analysis(FLASHVARS["advertisements"], advsHandler); //分析广告内容
			}
		}
		private function advsHandler(obj: Object): void { //广告分析结束
			advertisementsHandler(obj);
		}
		private function advertisementsHandler(obj: Object): void { //广告分析结束
			//script.traceObject(obj);
			new log("process:Advertisements analysis completed");
			if (obj) {
				adUrl = obj;
				if (adUrl.hasOwnProperty("inserttime")) {
					FLASHVARS["inserttime"] = adUrl["inserttime"];
				}
			}
			//script.traceObject(adUrl);
			//分析其它广告
			if (adUrl && adUrl.hasOwnProperty("other") && adUrl["other"]) {
				otherPlay = [];
				otherTimeArr = [];
				otherAdArr = adUrl["other"];
				for (var i: int = 0; i < otherAdArr.length; i++) {
					otherPlay.push(0);
					otherAd.push(null);
					if (otherAdArr[i].hasOwnProperty("startTime") && otherAdArr[i]["startTime"] > 0) {
						otherTimeArr.push(otherAdArr[i]["startTime"]);
					} else {
						otherTimeArr.push(0);
					}
				}
			}
			//script.traceObject(otherTimeArr);
			//其它广告分析完成

			if (vPlayer) {
				vPlayer.clear();
				vPlayer = null;
			}
			//trace(C.CONFIG["flashvars"]["cktrack"]);
			loadSubbtitle();
			if (C.CONFIG["config"]["delay"] > 0) {
				new timeOut(C.CONFIG["config"]["delay"], addPlayer);
			} else {
				addPlayer();
			}
			//script.traceObject(C.CONFIG["flashvars"]);
		}
		private function loadSubbtitle():void{//加载字幕文件
			var trackS:String=C.CONFIG["flashvars"]["cktrack"];
			var trackDelay:Number=C.CONFIG["flashvars"]["cktrackdelay"];
			var trackArr=[];
			if(trackS && trackS.indexOf(",")>-1){
				trackArr=script.trackToArray(trackS);
				var index:int=0;
				for(var i:int=0;i<trackArr.length;i++){
					if(trackArr[i][2]>index){
						index=trackArr[i][2];
					}
				}
				trackS=trackArr[index][0];
			}
			if (trackS) {
				trackClass = new track(this, C.CONFIG["style"]["cktrack"],trackS,trackDelay);
			}
			if (C.CONFIG["config"]["subtitle"] && FACE && trackArr.length>0) {
				FACE.loadSubtitles(index);
				FACE.newSubtitles(index);
			}
		}
		private function addPlayer(): void {
			if (!FLASHVARS.hasOwnProperty("video") || !FLASHVARS["video"]) {
				videoError(C.CONFIG["language"]["error"]["cannotFindUrl"]);
				return;
			}
			noPlay = false;
			firstPlay = true;
			if (autoPlay) { //如果自动播放
				//trace("===========", adUrl.hasOwnProperty("front"), adUrl["front"]);
				//script.traceObject(adUrl);
				/*-----------------------------------------------------*/

				if (adUrl && adUrl.hasOwnProperty("front") && adUrl["front"]) { //如果有前置广告
					frontAdPlay();
					//trace("autoLoad", autoLoad);
					if (autoLoad) {
						noPlay = true;
						newPlayer();
					}
				} else {
					newPlayer();
				}
				/*-----------------------------------------------------*/
			} else { //如果不自动播放
				loadPoster();
				if (autoLoad) {
					noPlay = true;
					newPlayer();
				}
			}
		}
		//======================================================加载初始化图片==================================================================
		private function loadPoster(): void {
			if (FLASHVARS.hasOwnProperty("poster") && FLASHVARS["poster"]) {
				if (posterFun) {
					posterFun.hide();
					posterFun = null;
				}
				new log("process:Poster load");
				posterFun = new poster(stage, this, videoPlay, getControlBarShow, posterHandler);
				posterFun.loadPoster(FLASHVARS["poster"], C.CONFIG["style"]["video"], loadIndex);
			} else {
				//如果没有封面图，则隐藏loading
				if (FACE) { //如果界面对象存在
					FACE.showLoading(false);
					FACE.showCenterPlay();
				}
			}
		}
		private function posterHandler(loaded: Boolean = false): void {
			if (FACE) { //如果界面对象存在
				FACE.showLoading(false);
				FACE.showCenterPlay();
			}
			if (vPlayer) {
				vPlayer.posterHandler();
			}
		}
		//======================================================开始播放前置广告==================================================================
		private function frontAdPlay(): void { //加载前置广告
			if (FACE) { //如果界面对象存在
				FACE.showLoading(false);
				FACE.showCenterPlay(false);
			}
			if (adPlayClass) {
				adPlayClass.close();
				adPlayClass = null;
			}
			trace("播放前置广告");
			adName = "front";
			new log("process:front ad play");
			this.sendJS("frontAd", "play");
			adPlayClass = new adPlayer(stage, this, adFunObj, adUrl["front"], C.CONFIG["style"]["advertisement"], adName);
			adFrontPlayed = true; //说明前置广告已经播放了
		}
		//控制广告元件（背景，倒计时，跳过广告按钮等）显示
		private function advertisementShow(objName: String, b: Boolean = true): void {
			if (FACE) {
				FACE.advertisementShow(objName, b);
			}
		}
		//向face里发送广告的尺寸
		private function changeFaceWh(obj: Object): void {
			if (FACE) {
				FACE.changeFaceWh(obj);
			}
		}
		//改变文本框
		private function changeAdCountDown(t: int = 0): void {
			//trace(t);
			if (FACE) {
				FACE.changeAdCountDown(t);
			}
		}
		//改变跳过广告延时时间
		private function changeAdSkipDelay(t: int = 0): void {
			if (FACE) {
				FACE.changeAdSkipDelay(t);
			}
		}
		//======================================================开始播放暂停广告================================================================
		private function adPausePlay(): void {
			if (adInsertPlayed || firstPlay || adEndPlayed) { //如果正在播放插入广告
				return;
			}
			if (adUrl && adUrl.hasOwnProperty("pause") && adUrl["pause"]) {
				//script.traceObject(adUrl["pause"]);
				trace("开始播放暂停广告");
				new log("process:Pause ad play");
				this.sendJS("pauseAd", "play");
				adName = "pause";
				adPlayClass = new adPlayer(stage, this, adFunObj, adUrl["pause"], C.CONFIG["style"]["advertisement"], adName);
			}
		}
		public function closePauseAd(): void {
			//trace("关闭了暂停广告");
			if (adPlayClass != null) {
				adPlayClass.close();
				adPlayClass = null;
				new log("process:Pause ad close");
				this.sendJS("pauseAd", "close");
			}
		}
		//=======================================================开始播放结束广告==============================================================
		private function endAdPlay(): void {
			if (adPlayClass) {
				adPlayClass.close();
				adPlayClass = null;
			}
			//trace("播放结束广告");
			var adEndObj: Object = {
				advertisementShow: advertisementShow,
				changeAdCountDown: changeAdCountDown,
				changeAdSkipDelay: changeAdSkipDelay,
				adStop: ended,
				changeFaceWh: changeFaceWh
			};
			new log("process:End ad play");
			this.sendJS("endAd", "play");
			adName = "end";
			trace("播放广告");
			adPlayClass = new adPlayer(stage, this, adEndObj, adUrl["end"], C.CONFIG["style"]["advertisement"], adName);
			adEndPlayed = true; //说明结束广告已经播放了
		}
		//======================================================播放其它广告====================================================================
		private function otherInterValHandler(): void {
			otherTime++;
			for (var i: int = 0; i < otherAdArr.length; i++) {
				if (otherPlay[i] == 0) {
					if (otherTime >= otherTimeArr[i]) {
						otherPlay[i] = 1;
						otherAd[i] = new adOtherPlayer(stage, this, otherAdArr[i], i);
					}
				}
			}
		}
		public function closeOtherAd(num: int = 0): void {
			if (otherAd.length > num) {
				if (otherAd[num]) {
					otherAd[num].close();
					otherAd[num] = null;
				}
			}
		}
		//======================================================开始播放视频====================================================================
		private function newPlayer(): void {
			trace("NOPLAY+++", noPlay);
			vPlayer = new player(stage, this, noPlay, loadIndex, playNum, FLASHVARS["seek"]);
			vPlayer.volume = nowVolume;
		}
		public function changeDefinition(n: int = 0): void {
			trace("切换清晰度编号：" + n);
			playNum = n;
			if (vPlayer) {
				vPlayer.clear();
				vPlayer = null;
			}
			if (FACE) { //如果界面对象存在，则初始化
				FACE.changeLoadTotal();
				FACE.timeLoadSliderChange();
				FACE.timeLoadSimpleChange();
				FACE.changeTimeTotal();
				FACE.timePlaySimpleChange();
				FACE.timePlaySliderChange();
				if (!C.CONFIG["flashvars"]["live"]) {
					FACE.changeVodTime();
				}
				FACE.showLoading();
				FACE.showCenterPlay(false);
			}
			autoPlay = true;

			var videoArr: Array = C.CONFIG["flashvars"]["video"];
			var vObj: Object = videoArr[playNum];
			if (vObj.hasOwnProperty("video") && vObj["video"]) {
				if (vObj["video"].toString().substr(0, 8) == "website:") {
					new analysisVideoUrlNum(changeDefinitionHandler, playNum);
				} else {
					changeDefinitionHandler();
				}
			} else {
				changeDefinitionHandler();
			}

		}
		public function changeSubtitles(n:int=0):void{
			var trackS:String=C.CONFIG["flashvars"]["cktrack"];
			var trackArr=[];
			if(trackS.indexOf(",")>-1){
				trackArr=script.trackToArray(trackS);
				trackS=trackArr[n][0];
			}
			if (trackS != "") {
				if(trackClass){
					trackClass.close();
					trackClass=null;
				}
				trackClass = new track(this, C.CONFIG["style"]["cktrack"],trackS);
			}
			if (C.CONFIG["config"]["subtitle"] && FACE && trackArr.length>0) {
				trace("FACE.loadSubtitles");
				FACE.loadSubtitles(n);
				FACE.newSubtitles(n);
			}
		}
		public function changeSubtitlesSize(n:int=0,m:int=0):void{
			if(trackClass){
				C.CONFIG["style"]["cktrack"]["size"]=n;
				C.CONFIG["style"]["cktrack"]["leading"]=m;
				trackClass.changeSize(n,m);
			}
		}
		private function changeDefinitionHandler(b: Boolean = true): void {
			if (!b) {
				if (changeNum < C.CONFIG["config"]["errorNum"]) {
					changeNum++;
					changeDefinition(playNum);
				} else {
					videoError(C.CONFIG["flashvars"]["cannotFindUrl"] != "" ? C.CONFIG["flashvars"]["cannotFindUrl"] : C.CONFIG["language"]["error"]["cannotFindUrl"]);
				}
				return;
			}
			changeNum = 0;
			vPlayer = new player(stage, this, false, loadIndex, playNum);
			sendJS("definitionChange",playNum);
			vPlayer.firstSeek = time;
			vPlayer.volume = nowVolume;
			faceDefinition(playNum);
		}
		public function faceDefinition(n: int = 0): void {
			if (C.CONFIG["config"]["definition"] && FACE) {
				FACE.loadDefinition(n);
				FACE.newDefinition(n);
			}
		}
		public function getPlayerData(obj: Object): void {
			//script.traceObject(obj);
			var i: int = 0;
			switch (obj["name"]) {
				case "changeTimeTotal":
					timeTotal = obj["val"];
					sendJS("duration", timeTotal);
					new log("duration:" + timeTotal);
					//trace(FLASHVARS.hasOwnProperty("inserttime"), (FLASHVARS["inserttime"] + ""), timeTotal > 0, adUrl);
					if (FLASHVARS.hasOwnProperty("inserttime") && (FLASHVARS["inserttime"] + "") != "" && timeTotal > 0 && adUrl) {
						if (adUrl.hasOwnProperty("insert") && adUrl["insert"]) {
							insertTimeArr = script.formatInsertTime(FLASHVARS["inserttime"], obj["val"]);
							trace("insertTimeArr", insertTimeArr);
							insertPlay = [];
							if (insertTimeArr) {
								for (i = 0; i < insertTimeArr.length; i++) {
									insertPlay.push(false);
								}
							} else {
								insertPlay = null;
							}
						}
					}
					break;
				case "changeLoadTotal":
					sendJS("bytesTotal", obj["val"]);
					new log("bytesTotal:" + obj["val"]);
					break;
				case "changeVodTime":
					time = obj["val"];
					if (!vPlayer.getPaused()) {
						sendJS("time", time);
						if (trackClass!=null) {
							//trace(trackClass);
							trackClass.sendTime(time);
						}
					}

					//new log("time:"+time);
					if (timeMax < time) {
						timeMax = time;
					}
					if (insertPlay && !adInsertPlayed) { //播放中插广告
						for (i = 0; i < insertPlay.length; i++) {
							if (insertPlay[i] == false) {
								if (obj["val"] >= insertTimeArr[i]) {
									insertPlay[i] = true;

									if (adPlayClass) {
										adPlayClass.close();
										adPlayClass = null;
									}
									adInsertPlayed = true;
									videoPause(false);
									adName = "insert";
									new log("process:Insert ad play");
									this.sendJS("insertAd", "play");
									adPlayClass = new adPlayer(stage, this, adFunObj, adUrl["insert"], C.CONFIG["style"]["advertisement"], adName);
								}
								break;
							}
						}
					}
					break;
				case "timeLoadSliderChange":
					sendJS("bytes", obj["val"]);
					//new log("bytes:" + obj["val"]);
					break;
				case "showBuffer":
					if (obj["val"] < 100) {
						sendJS("buffer", obj["val"]);
						new log("buffer:" + obj["val"]);
					}

					break;
				default:
					break;

			}

			if (FACE) {
				//trace("===");
				//script.traceObject(obj);
				if (FACE.hasOwnProperty(obj["name"])) {
					FACE[obj["name"]](obj["val"]);
				}
			}
		}
		public function netStatus(status: String) {
			//trace("-----++------", status);
			new log("netStatus:" + status);
			this.sendJS("netStatus", status)
			switch (status) {
				case "NetConnection.Connect.Closed": //针对rtmp流暂停后被关闭的操作
					trace(C.CONFIG["flashvars"]["live"]);
					if(vPlayer && vPlayer.vType=="rtmp" && C.CONFIG["flashvars"]["live"]==true){
						break;
					}
				case "NetConnection.Connect.Failed":
				case "NetStream.Play.StreamNotFound": //加载出错
					videoError(C.CONFIG["flashvars"]["streamNotFound"] != "" ? C.CONFIG["flashvars"]["streamNotFound"] : C.CONFIG["language"]["error"]["streamNotFound"]);
					break;
				case "NetStream.Play.Start":
					if (FACE) { //如果界面对象存在
						FACE.showLoading(false);
						FACE.showCenterPlay(false);
					}
					//M.showLoading(false);
					//M.definition();
					sendJS("loadedmetadata");
					break;
				
				case "NetStream.SeekStart.Notify":
				case "NetStream.Seek.seeking":
					videoState["seeking"] = true;
					new log("netStream:seek start");
					this.sendJS("seek", "start");
					new log("netStream:seeking");
					//listenerJs("seeking");
					//M.showLoading();
					break;
				//case "NetStream.Seek.Notify":
				case "NetStream.Seek.seeked":
				case "NetStream.Seek.Complete":
					videoState["seeking"] = false;
					new log("netStream:seek ended");
					this.sendJS("seek", "ended");
					if (FACE) {
						FACE.changeTimePlaySlider();
					}
					if (!firstPlay) {
						videoPlay();
					}

					videoError();
					//listenerJs("seeked");
					//script.callJs(chplayer + ".resetTrack");
					//videoPlay();
					//M.showLoading(false);
					break;
				case "NetStream.Buffer.Empty": //开始缓冲
					break;
				case "NetStream.Pause.Notify": //暂停状态
					videoState["paused"] = true;
					//listenerJs("pause");
					sendJS("loadedmetadata");
					if (FACE) {
						FACE.changeTimePlaySlider();
					}
					//if(newElement){
					//	newElement.changePauseded(true);
					//}
					break;
				case "NetStream.Unpause.Notify":
					//return;
					videoState["paused"] = false;
					closePauseAd();
					//listenerJs("play");
					sendJS("loadedmetadata");
					videoError();
					break;
				case "NetStream.Buffer.Full": //缓冲完成，进行播放
					//videoState["seeking"] = false;
					//new log("netStream:seek ended");
					//this.sendJS("seek","ended");
					new log("netStream:buffer");
					sendJS("buffer", 100);
					new log("buffer:100");
					videoError();
					if (FACE) {
						FACE.changeTimePlaySlider();
					}
					//M.showLoading(false);
					break;
				case "NetStream.Play.Stop": //播放完毕
					ended();
					break;
				default:
					break;
			}
		}
		//-----------------------------------------------------------------------可交互动作---------------------------------------------

		public function videoSeek(time: Number = 0, face: Boolean = true): void {
			if (!firstPlay) {
				new log("seekTime:" + time);
				this.sendJS("seekTime", time);
				if (vPlayer && vPlayer.haveNetStream() && !errorShow) {
					//videoPlay();
					vPlayer.videoSeek(time);
					if (timeSeek == -1) {
						timeSeek = time;
					}
					if (face && FACE) {
						FACE.timePlaySliderChange(time);
					}

				}
			} else {
				if (vPlayer && vPlayer.haveNetStream() && !errorShow) {
					vPlayer.firstSeek = time;
				}
				if (face && FACE) {
					FACE.timePlaySliderChange(0);
				}
				videoPlay();
			}

		}
		public function backLive(): void {
			if (vPlayer && vPlayer.haveNetStream() && !errorShow) {
				vPlayer.backLive();
			}
		}
		public function videoPlay(): void {
			trace("执行了main:videoPlay");
			//隐藏封面图
			if (errorShow) {
				return;
			}
			trace("第一次播放", firstPlay);
			if (firstPlay) {
				if (posterFun) { //如果有封面图片，则隐藏
					posterFun.hide();
					posterFun = null;
				}
				//隐藏loading和centerPlay
				if (FACE) { //如果界面对象存在
					FACE.showLoading(false);
					FACE.showCenterPlay(false);
				}

			}
			//如果广告正在播放
			//trace("adPlayClass",adPlayClass);
			if (adPlayClass != null) {
				new log("process:" + adPlayClass.STYLE + " ad ended");
				this.sendJS(adPlayClass.STYLE + "Ad", "ended");
				adPlayClass.close();
				adPlayClass = null;
			} else {
				//trace(adUrl , adFrontPlayed && adUrl.hasOwnProperty("front") , adUrl["front"]);
				if (adUrl && !adFrontPlayed && adUrl.hasOwnProperty("front") && adUrl["front"]) { //如果前置广告没有播放而又有前置广告则播放前置广告
					trace("需要播放前置");
					closePauseAd();
					frontAdPlay()
					return;
				}
			}
			if (vPlayer) { //如果播放对象存在
				if (vPlayer.haveNetStream()) { //如果播放对象存在流，则播放
					vPlayer.videoPlay();
					new log("netStream:play");
					this.sendJS("play");
					this.sendJS("paused", false);
					if (!otherInterVal) {
						otherInterVal = new timeInterval(1000, otherInterValHandler);
						otherInterVal.start();
					}
				} else { //如果不存在，则设置成加载完自动播放
					vPlayer.NOPLAY = false;
				}

			} else {
				noPlay = false;
				newPlayer();
			}
			if (FACE) {
				FACE.showCenterPlay(false);
				FACE.showButton("pause");
				FACE.showButton("play", false);
			}
			firstPlay = false;
			adInsertPlayed = false;
			//trace("执行了：videoPlay==");
			if (element) {
				element.changePauseded(false);
			}
		}
		public function videoPause(b: Boolean = true): void {
			trace("执行了main：videoPause");
			if (vPlayer && vPlayer.haveNetStream() && !errorShow) {
				vPlayer.videoPause();
				new log("netStream:pause");
				this.sendJS("pause");
				this.sendJS("paused", true);
				if (FACE) {
					FACE.showCenterPlay();
					FACE.showButton("play");
					FACE.showButton("pause", false);
				}
			}
			if (element) {
				element.changePauseded(true);
			}
			if (!firstPlay) {
				closePauseAd();
			}
			if (b) {
				adPausePlay();
			}

		}
		public function playOrPause(): void {
			if (vPlayer && vPlayer.haveNetStream()) {
				if (vPlayer.getPaused()) {
					videoPlay();
				} else {
					videoPause();
				}
			} else {
				videoPlay();
			}
		}
		public function changeVolume(vol: Number, face: Boolean = true): void {
			//如果face=true，则调用face里的相关函数
			//trace("调节音量：", vol);
			nowVolume = vol;
			if (vPlayer && vPlayer.haveNetStream()) {
				vPlayer.changeVolume(vol);
				new log("volume:" + vol);
				this.sendJS("volume", vol);
				//sendVolume
				if (C.CONFIG["flashvars"]["variable"] != "") {
					script.callJs(C.CONFIG["flashvars"]["variable"] + ".sendVolume", vol);
				}
			}
			if (face && FACE) {
				FACE.volumeSliderChange(vol);
			}
		}
		public function videoMute(): void {
			//trace("执行了：videoMute");
			new log("mute:true");
			this.sendJS("mute", true);
			tempVolume = nowVolume;
			nowVolume = 0;
			changeVolume(0);
		}
		public function videoEscMute(): void {
			//trace("执行了：videoEscMute");
			new log("mute:false");
			sendJS("mute", false);

			if (tempVolume == 0) {
				tempVolume = FLASHVARS["volume"];
			}
			if (tempVolume == 0) {
				tempVolume = 0.8;
			}
			changeVolume(tempVolume);
		}
		public function adMute(): void {
			//trace("执行了adMute");
			new log("adMute:true");
			this.sendJS("adMute", true);
			if (adPlayClass) {
				adPlayClass.adMute();
			}
		}
		public function escAdMute(): void {
			//trace("执行了adEscMute");
			new log("adMute:false");
			this.sendJS("adMute", false);
			if (adPlayClass) {
				adPlayClass.adMute(false);
			}
		}
		public function videoBrightness(n: int = 0): void {
			if (vPlayer && vPlayer.haveNetStream() && !errorShow) {
				new log("videoBrightness:" + n);
				this.sendJS("videoBrightness", n);
				vPlayer.videoBrightness(n);
			}
		}
		public function videoContrast(n: Number = 127.5): void {
			if (vPlayer && vPlayer.haveNetStream() && !errorShow) {
				new log("videoContrast:" + n);
				this.sendJS("videoContrast", n);
				vPlayer.videoContrast(n);
			}
		}
		public function videoSaturation(n: int = 1): void {
			if (vPlayer && vPlayer.haveNetStream() && !errorShow) {
				new log("videoSaturation:" + n);
				this.sendJS("videoSaturation", n);
				vPlayer.videoSaturation(n);
			}
		}
		public function videoHue(n: int = 0): void {
			if (vPlayer && vPlayer.haveNetStream() && !errorShow) {
				new log("videoHue:" + n);
				this.sendJS("videoHue", n);
				vPlayer.videoHue(n);
			}
		}
		public function videoZoom(n: Number = 1): void {
			if (vPlayer && vPlayer.haveNetStream() && !errorShow) {
				new log("videoZoom:" + n);
				this.sendJS("videoZoom", n);
				vPlayer.videoZoom(n);
			}
		}
		public function videoProportion(w: int = 0, h: int = 0): void {
			if (vPlayer && vPlayer.haveNetStream() && !errorShow) {
				new log("videoProportion:width" + w + ",height:" + h);
				this.sendJS("videoProportion", {
					width: w,
					height: h
				});
				vPlayer.videoProportion(w, h);
			}
		}
		public function videoError(error: String = ""): void {
			if (error) {
				errorShow = true;
				if (vPlayer) {
					vPlayer.clear();
				}
			} else {
				errorShow = false;
			}
			if (FACE) {
				if (error) {
					new log("error:" + error);
					this.sendJS("error", error);
					//trace(vPlayer["ddd"]["=="]);
					//trace(error);
					FACE.errorShow(error);
					if (posterFun) {
						posterFun.hide();
					}

				} else {
					FACE.errorShow("");
				}
			}
		}
		public function volumeDown(): void {
			nowVolume -= C.CONFIG["config"]["volumeJump"];
			if (nowVolume < 0) {
				nowVolume = 0;
			}
			changeVolume(nowVolume);
		}
		public function volumeUp(): void {
			nowVolume += C.CONFIG["config"]["volumeJump"];
			changeVolume(nowVolume);
		}
		public function fastBack(): void { //快退
			if (timeTotal == 0) {
				return;
			}
			var value: Number = 0;
			if (time - C.CONFIG["config"]["timeJump"] >= 0) {
				value = time - C.CONFIG["config"]["timeJump"];
			} else {
				value = 0;
			}
			if (!isFast(value)) {
				return;
			}
			videoSeek(value);
			new log("fastBack:" + value);
			this.sendJS("fastBack", value);
		}

		public function fastNext(): void { //快进
			if (timeTotal == 0) {
				return;
			}
			var value: Number = 0;
			if (time + C.CONFIG["config"]["timeJump"] <= timeTotal) {
				value = (time + C.CONFIG["config"]["timeJump"]);
			} else if (timeTotal > 0) {
				value = timeTotal;
			}
			if (!isFast(value)) {
				return;
			}
			videoSeek(value);
			new log("fastNext:" + value);
			this.sendJS("fastNext", value);
		}
		private function isFast(value: Number = 0): Boolean {
			switch (C.CONFIG["config"]["timeScheduleAdjust"]) {
				case 0:
					return false;
					break;
				case 2:
					if (value < time) {
						return false;
					}
					break;
				case 3:
					if (value > time) {
						return false;
					}
					break;
				case 4:
					//trace(timeSeek);
					if (timeSeek > -1) {
						if (value < timeSeek) {
							return false;
						}
					} else {
						if (value < time) {
							return false;
						}
					}
					break;
				case 5:
					if (value > timeMax) {
						return false;
					}
					break;
			}
			return true;
		}
		public function videoRotation(r: Number = 0): Object { //旋转
			if (vPlayer && vPlayer.haveNetStream()) {
				vPlayer.videoRotation(r);
				new log("videoRotation:" + r);
				this.sendJS("videoRotation", r);
			}
			return null;
		}
		public function adPlay(): void {
			if (adPlayClass) {
				adPlayClass.play();
			}
		}
		public function adPause(): void {
			if (adPlayClass) {
				adPlayClass.pause();
			}
		}
		public function controlBarIsShow(b: Boolean = true): void {
			//监听控制栏是否隐藏
			controlBarShow = b;
			new log("controlBar:" + b.toString());
			this.sendJS("controlBar", b);
			if (vPlayer) {
				vPlayer.controlBarIsShow(b);
			}
		}
		public function getControlBarShow(): Boolean { //获取控制栏是否隐藏
			return controlBarShow;
		}
		public function keyDownClock(b: Boolean): void {
			isKeyClock = b;
		}
		//构建元件
		public function addElement(obj: Object): String {
			var n: int = 0;
			if (FACE) {
				n = FACE.getClickSpriteIndex();
			}
			if (!element) {
				element = new newElement(stage, this, n);
			}
			var sp: Sprite = element.addelement(obj);
			return sp.name;
		}
		public function getElement(name: String): Object {
			if (element) {
				return element.getElement(name);
			}
			return false;
		}
		public function deleteElement(name: String): void {
			if (element) {
				element.deleteElement(name);
			}
		}
		public function elementShow(name:String="",bn:Boolean=true):void {
			if (element) {
				element.elementShow(name,bn);
			}
		}
		public function animate(obj: Object): String {
			if (element) {
				return element.animate(obj);
			}
			return "";
		}
		public function animateResume(name: String = ""): void {
			if (element) {
				element.animateResume(name);
			}
		}
		public function animatePause(name: String = ""): void {
			if (element) {
				element.animatePause(name);
			}
		}
		public function deleteAnimate(name: String = ""): void {
			if (element) {
				element.deleteAnimate(name);
			}
		}
		public function copy(k: String = ""): void { //复制flashvars里的值
			if (!FLASHVARS.hasOwnProperty(k)) {
				new log(k + " is not present in the flashvars");
				return;
			}
			Clipboard.generalClipboard.clear();
			Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, FLASHVARS[k], false);
		}
		//共用的触发事件
		public function clickEvent(call: String = ""): void {
			sendJS("clickEvent",call);
			if (call == "none" || call == "" || call == null) {
				return;
			}
			var callArr: Array = call.split("->");
			if (callArr.length == 2) {
				var callM: String = callArr[0];
				var callE: String = callArr[1];
				//trace(callE,callM);
				if (!callE) {
					return;
				}
				var val: String = "";
				var eArr: Array = [];
				switch (callM) {
					case "actionScript":
						//trace(THIS.hasOwnProperty(callE));
						if (callE.indexOf("(") > -1) {
							eArr = callE.split("(");
							callE = eArr[0];
							val = script.strReplace(eArr[1], [")"], [""]);
						}
						if (this.hasOwnProperty(callE)) {
							if (val == "") {
								this[callE]();
							} else {
								eArr = val.split(",");
								switch (eArr.length) {
									case 1:
										this[callE](eArr[0]);
										break;
									case 2:
										this[callE](eArr[0], eArr[1]);
										break;
									case 3:
										this[callE](eArr[0], eArr[1], eArr[2]);
										break;
									case 4:
										this[callE](eArr[0], eArr[1], eArr[2], eArr[3]);
										break;
									case 5:
										this[callE](eArr[0], eArr[1], eArr[2], eArr[3], eArr[4]);
										break;
									case 6:
										this[callE](eArr[0], eArr[1], eArr[2], eArr[3], eArr[4], eArr[5]);
										break;
									default:
										this[callE]();
										break;
								}

							}
						}
						break;
					case "javaScript":
						if (callE.substr(0, 11) == "[flashvars]") {
							callE = script.strReplace(callE, ["[flashvars]"], [""]);
							if (FLASHVARS.hasOwnProperty(callE)) {
								callE = FLASHVARS[callE];
							} else {
								break;
							}
						}
						if (callE.indexOf("(") > -1) {
							eArr = callE.split("(");
							callE = eArr[0];
							val = script.strReplace(eArr[1], [")"], [""]);
						}
						new log("callJs:" + callE + "(" + val + ")");
						if (val == "") {
							
							script.callJs(callE);

						} else {
							script.callJs(callE, val);
						}
						break;
					case "link":
						var callLink: Array = (callE + ",").split(",");
						if (callLink[0].substr(0, 11) == "[flashvars]") {
							var fl: String = script.strReplace(callLink[0], ["[flashvars]"], [""]);
							if (FLASHVARS.hasOwnProperty(fl)) {
								callLink[0] = FLASHVARS[fl];
							} else {
								break;
							}
						}
						script.openLink(callLink[0], callLink[1]);
						break;
					default:
						break;
				}
			}
		}
		//==============================================修改config
		public function changeConfig(...arg): Boolean {
			var obj: Object = C.CONFIG;
			var i: int = 0;
			if (script.getType(arg[0]) == "object") {
				var bj: Object = arg[0];
				arg = [];
				for (var k: String in bj) {
					arg.push(bj[k]);
				}
			}
			for (i = 0; i < arg.length - 1; i++) {
				if (obj.hasOwnProperty(arg[i])) {
					obj = obj[arg[i]];
				} else {
					return false;
				}
			}
			obj = arg[arg.length - 1];
			switch (arg.length) {
				case 2:
					C.CONFIG[arg[0]] = obj;
					break;
				case 3:
					C.CONFIG[arg[0]][arg[1]] = obj;
					break;
				case 4:
					C.CONFIG[arg[0]][arg[1]][arg[2]] = obj;
					break;
				case 5:
					C.CONFIG[arg[0]][arg[1]][arg[2]][arg[3]] = obj;
					break;
				case 6:
					C.CONFIG[arg[0]][arg[1]][arg[2]][arg[3]][arg[4]] = obj;
					break;
				case 7:
					C.CONFIG[arg[0]][arg[1]][arg[2]][arg[3]][arg[4]][arg[5]] = obj;
					break;
				case 8:
					C.CONFIG[arg[0]][arg[1]][arg[2]][arg[3]][arg[4]][arg[5]][arg[6]] = obj;
					break;
				case 9:
					C.CONFIG[arg[0]][arg[1]][arg[2]][arg[3]][arg[4]][arg[5]][arg[6]][arg[7]] = obj;
					break;
				case 10:
					C.CONFIG[arg[0]][arg[1]][arg[2]][arg[3]][arg[4]][arg[5]][arg[6]][arg[7]][arg[8]] = obj;
					break;
				default:
					return false;
					break;
			}
			//script.traceObject(CONFIG["flashvars"]);
			if (vPlayer) {
				vPlayer.changeConfig();
			}
			if (FACE) {
				FACE.changeConfig();
			}
			if (element) {
				element.changeConfig();
			}
			if (otherAd) {
				for (i = 0; i < otherAd.length; i++) {
					if (otherAd[i] != null) {
						otherAd[i].changeConfig();
					}
				}
			}
			new log("configChange");
			new log(C.CONFIG);
			this.sendJS("configChange", C.CONFIG);
			return true;
		}
		//获取config
		public function getConfig(...arg): * {
			if (script.getType(arg[0]) == "object") {
				var bj: Object = arg[0];
				arg = [];
				for (var k: String in bj) {
					arg.push(bj[k]);
				}
			}
			var obj: Object = C.CONFIG;
			for (var i: int = 0; i < arg.length; i++) {
				if (obj.hasOwnProperty(arg[i])) {
					obj = obj[arg[i]];
				} else {
					return null;
					break;
				}
			}
			return obj;
		}
		//打开广告链接
		public function openAdLink(): void {
			if (adPlayClass) {
				adPlayClass.openAdLink();
			}
		}
		//结束
		public function ended(): void {
			//new log("enddd");
			//trace("结束播放",!adEndPlayed ,adUrl.hasOwnProperty("end") , adUrl["end"]);
			new log(adUrl);
			if (adUrl && !adEndPlayed && adUrl.hasOwnProperty("end")) { //如果结束广告没有播放而又有结束广告则播放结束广告
				if (adUrl["end"]) {
					videoPause();
					endAdPlay();
					return;
				}

			}
			adEndPlayed = false;
			if (adEndPlayed) {
				new log("process:End ad ended");
				this.sendJS("endAd", "ended");
			}
			trace("1429-videoPause");
			videoPause();
			this.sendJS("ended");
			new log("process:Ended");
			if (FLASHVARS["loop"]) {
				if (vPlayer && vPlayer.haveNetStream()) {
					adEndPlayed = false;
					videoSeek(0);
				}
			}
		}
		//清除视频
		public function videoClear(): void {
			var i: int = 0;
			if (vPlayer) {
				vPlayer.clear();
				vPlayer = null;
			}

			if (adPlayClass) {
				adPlayClass.close();
				adPlayClass = null;
			}
			if (otherPlay.length > 0) {
				for (i = 0; i < otherPlay.length; i++) {
					otherPlay[i].close();
					otherPlay[i] = null;
				}
			}
			if (posterFun) {
				posterFun.hide();
				posterFun = null;
			}
			if (FACE) {
				FACE.clear();
			}

			//重置初始化数据
			videoUrl = null; //视频地址
			adUrl = null; //广告地址
			autoPlay = false; //是否自动播放
			noPlay = false; //加载完但不播放（因为前置广告在播放，或默认加载没有前置广告但默认暂停）
			autoLoad = false; //默认加载
			firstPlay = false; //是否第一次播放
			adName = "";
			adFrontPlayed = false; //前置广告是否播放了
			adInsertPlayed = false; //插入广告是否在播放
			adEndPlayed = false; //结束广告是否播放了
			insertTimeArr = null; //插入广告的开始时间数组
			insertPlay = []; //插入广告保存是否播放的数组
			otherTimeArr = null; //其它广告的开始时间数组
			otherAdArr = []; //其它广告数组
			otherPlay = []; //其它广告保存是否播放的数组
			otherAd = []; //其它广告数组
			//
			time = 0; //当前播放时间
			timeTotal = 0;
			new log("videoClear");
			this.sendJS("videoClear");
		}
		//播放新视频
		public function newVideo(obj: * ): void {
			videoClear();
			new log("videoChange");
			this.sendJS("videoChange");
			var newObj: Object = {};
			var type: String = script.getType(obj);
			switch (type) {
				case "string":
				case "array":
					newObj = {
						video: obj
					};
					break;
				case "object":
					if (obj.hasOwnProperty("video")) {
						newObj = obj;
					} else {
						newObj = {
							video: obj
						};
					}
					break;
				default:
					new log("error:newVideo error");
					break;

			}
			C.CONFIG["flashvars"] = script.simpleMergeObject(C.CONFIG["flashvars"], newObj);
			C.CONFIG["flashvars"]["volume"] = nowVolume;
			newVideoTimeOut = new timeOut(200, into);

		}
		public function getStatus(): Object {
			return getMetaDate();
		}
		public function getMetaDate(): Object {
			//获取播放器状态
			var objTemp: Object = {};
			var obj: Object = {
				width: stage.stageWidth,
				height: stage.stageHeight,
				controlBarShow: controlBarShow
			};
			if (vPlayer && vPlayer.haveNetStream()) {
				objTemp = vPlayer.getStatus();
				obj = script.simpleMergeObject(obj, objTemp);
			}
			return obj;
		}
		public function getCurrentSrc():String{
			if (vPlayer) {
				return vPlayer.getCurrentSrc();
			}
			return "";
		}
		//自定义插件
		public function custom(...arg): void {
			if (script.getType(arg[0]) == "object") {
				var bj: Object = arg[0];
				arg = [];
				for (var k: String in bj) {
					arg.push(bj[k]);
				}
			}
			if (FACE) {
				FACE.custom(arg);
			}
		}
		//注册外部监听函数
		public function addListenerJS(...arg) {
			listenerArr = script.addListenerArr(listenerArr, arg[0], arg[1]);
			new log("javascript.addListener:" + arg[0] + "," + arg[1]);
			//new log(listenerArr);
		}
		//删除外部监听函数
		public function removeListenerJS(...arg) {
			listenerArr = script.removeListenerArr(listenerArr, arg[0], arg[1]);
			new log("javascript.removeListener" + arg[0] + "," + arg[1]);
			//new log(listenerArr);
		}

		public function addListener(...arg): void {
			if (arg.length == 2) {
				if (FACE) {
					FACE.addListener(arg[0], arg[1]);
				}
				new log("actionscript.addListener:" + arg[0] + "," + arg[1]);
			} else {
				if (FACE) {
					FACE.addListener(arg[1], arg[2]);
				}
				new log("actionscript.addListener:" + arg[0] + "," + arg[1] + "," + arg[2]);
			}
		}
		public function removeListener(...arg): void {
			if (arg.length == 2) {
				if (FACE) {
					FACE.removeListener(arg[0], arg[1]);
				}
				new log("actionscript.removeListener:" + arg[0] + "," + arg[1]);
			} else {
				if (FACE) {
					FACE.removeListener(arg[1], arg[2]);
				}
				new log("actionscript.removeListener:" + arg[0] + "," + arg[1] + "," + arg[2]);
			}
		}
		public function resizeHandler(event: Event): void {
			var obj: Object = {
				width: stage.stageWidth,
				height: stage.stageHeight
			}
			this.sendJS("resize", obj);
			new log("resize");
			new log(obj);
		}
		public function enterFrameHandler(event: Event): void {
			var coor:Object={
				x: mouseX,
				y: mouseY
			};
			if(mouseCoorObj["x"]!=mouseX && mouseCoorObj["y"]!=mouseY){
				sendJS("mouse", coor);
				mouseCoorObj=coor;
			}
			
		}
		private function wheelHandler(event: MouseEvent): void {
			var n: int = int(event.delta);
			sendJS("wheel", n);
		}
		public function sendJS(name: String, value: *= null): void {
			//trace(name,value);
			if (name) {
				//第一步向swf插件里发送
				if (FACE) {
					FACE.sendJS(name, value);
				}
				if (listenerArr.length == 0) {
					return;
				}
				for (var i: int = 0; i < listenerArr.length; i++) {
					var arr: Array = listenerArr[i];
					if (arr[0] == name) {
						if(C.CONFIG["flashvars"]["variable"]){
							script.callJs(arr[1], value,C.CONFIG["flashvars"]["variable"])
							
						}
						else{
							script.callJs(arr[1], value)
						}
					}
				}
			}
		}
		public function openUrl(url: String, target: String = '_blank', features: String = ""): void {
			script.openLink(url, target, features)
		}
		//============================================================================================================================
		//注册外部控制函数
		private function addCallback(): void {
			if (!ExternalInterface.available) {
				//new log("addCallback error");
				return;
			}
			new log("register addCallback");
			var i: int = 0;
			var ac: String = C.CONFIG["config"]["addCallback"];
			var crr: Array = ac.split(",");
			var arr: Array = [];
			for (i = 0; i < crr.length; i++) {
				switch (crr[i]) {
					case "getStatus":
						arr.push([crr[i], getMetaDate]);
						break;
					case "addListener":
						arr.push([crr[i], addListenerJS]);
						break;
					case "removeListener":
						arr.push([crr[i], removeListenerJS]);
						break;
					default:
						try{
							arr.push([crr[i], this[crr[i]]]);

						}
						catch(event:ErrorEvent){
							
						}
						break;
				}
			}
			arr.push(["getVersion", getVersion]);
			for (i = 0; i < arr.length; i++) {
				ExternalInterface.addCallback(arr[i][0], arr[i][1]);
			}
		}
		//控制控制栏隐藏
		public function changeControlBarShow(show: Boolean = true): void {
			if (FACE) {
				FACE.changeControlBarShow(show);
			}
		}
		//获取内部版本
		public function getVersion(): String {
			return C.VERSION;
		}
		//截图功能
		public function screenshot(obj: String, save: Boolean = false, name: String = ""): void {
			if (vPlayer) {
				vPlayer.screenshot(obj, save, name);
			}
		}
		//接受截图监听
		public function screenshotJS(obj: String, save: Boolean, name: String, base64: String) {
			new log(name + ":" + base64);
			this.sendJS("screenshot", {
				object: obj,
				save: save,
				name: name,
				base64: base64
			});
		}
		//============================================================================================================================
		public function switchFull(): void { //操作全屏/退出全屏
			switch (stage.displayState) {
				case "normal":
					if (C.CONFIG["fullInteractive"] == "true") {
						stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
					} else {
						stage.displayState = "fullScreen";
					}
					break;
				default:
					stage.displayState = "normal";
					break;
			}
			if (FACE) {
				FACE.checkFullScreen();
			}
		}
		public function fullScreen(): void {
			switch (stage.displayState) {
				case "normal":
					if (C.CONFIG["fullInteractive"] == "true") {
						stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
					} else {
						stage.displayState = "fullScreen";
					}
					break;
			}
			if (FACE) {
				FACE.checkFullScreen();
			}
		}
		public function quitFullScreen(): void {
			switch (stage.displayState) {
				case "fullScreen":
					stage.displayState = "normal";
					break;
			}
			if (FACE) {
				FACE.checkFullScreen();
			}
		}
		//===================================================按下键盘事件
		private function keyDownHandler(event: KeyboardEvent): void {
			if (isKeyClock) {
				return;
			}
			var now: Number = 0;
			var keyDown: Object = C.CONFIG["config"]["keyDown"];
			//trace("按键", event.keyCode);
			this.sendJS("keyDown", event.keyCode);
			new log("keyDown:" + event.keyCode);
			switch (event.keyCode) {
				case 32:
					if (adInsertPlayed || (firstPlay && adFrontPlayed) || adEndPlayed) { //如果正在播放插入广告
						break;
					}
					if (keyDown["space"]) {
						playOrPause();
					}
					break;
				case 37: //左
					if (adInsertPlayed || (firstPlay && adFrontPlayed) || adEndPlayed) { //如果正在播放插入广告
						break;
					}
					if (keyDown["left"]) {
						fastBack();
					}
					break;
				case 39: //右
					if (adInsertPlayed || (firstPlay && adFrontPlayed) || adEndPlayed) { //如果正在播放插入广告
						break;
					}
					if (keyDown["right"]) {
						fastNext();
					}
					break;
				case 38: //上
					if (keyDown["up"]) {
						volumeUp();
					}
					break;
				case 40: //下
					if (keyDown["down"]) {
						volumeDown();
					}
					break;
			}
		}
		
	}

}