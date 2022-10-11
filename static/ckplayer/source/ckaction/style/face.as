package ckaction.style {
	import flash.display.Stage;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.display.Loader;
	import ckaction.act.script;
	import flash.text.TextField;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.events.ErrorEvent;
	import fl.transitions.Tween;
	import fl.transitions.easing.None;
	import fl.transitions.TweenEvent;
	import flash.display.StageDisplayState;
	import ckaction.act.timeInterval;
	import ckaction.C.C;
	import flash.events.DataEvent;
	import ckaction.act.timeOut;
	import flash.ui.Mouse;
	import ckaction.act.log;
	import flash.display.SimpleButton;

	public class face {
		private var STAGE: Stage = null;
		private var THIS: Sprite = null;
		private var CONFIG: Object = {}, STYLE: Object = {}, LANGUAGE: Object = {}, FLASHVARS: Object = {};
		private var intoFun: Function = null; //调用主控制台的into
		private var stageW: int = 0,
			stageH: int = 0;
		private var M: Sprite = null; //控制栏元件
		public var MOBJ: Object = {}; //存放控制栏里各元素的
		private var imgButtonI: int = 0;
		private var mouseDownName: String = ""; //鼠标在音量和进度上按下时附值
		private var point: Point = null; //进度按钮音量调节按钮坐标
		private var volumeTemp: Number = 0; //保存临时音量
		private var timeTotal: Number = 0; //总时间
		private var timeNow: Number = 0; //播放时间
		private var timeMax: Number = -1; //当前播放的最大时间
		private var timeSeek: Number = -1; //拖动前的时间
		private var loadTotal: int = 0; //总字节
		private var loadNow: int = 0; //当前加载量
		private var timeFollow: Boolean = true; //时间进度条是否走动
		private var seekTime: Number = 0; //要跳转的时间
		private var mUpSeek: Boolean = true; //是否支持在鼠标拖动进度按钮后的动作
		private var loaderNum: int = 0; //要加载的图片总量
		private var showTween: Tween = null,
			hideTween: Tween = null;
		private var timeSliderShow: Boolean = true,
			timeOutSliderShow: Boolean = false,
			mShow: Boolean = true;
		private var cbHideTimer: timeInterval = null,
			cbShowTimer: timeInterval = null;
		private var cbTween: Tween = null;
		private var oldStageXY: Object = {};
		private var mMinXY: Object = {};
		private var errorText: TextField = null;
		private var setTimeClick: timeOut = null;
		private var isClick: Boolean = false;
		private var pause: Sprite = null;
		//提示点
		private var promptSpotArr: Array = [];
		private var promptSpotObjArr: Array = [];
		//定义元件开始
		//存放播放器背景
		private var background: Object = {
			background: null
		};
		private var clickSprite: Sprite = null;
		private var loading: Loader = null,
			logo: Loader = null;
		private var prompt: Sprite = null;
		private var force: Boolean = false;
		//定义元件结束
		//获取状态
		public var full: Boolean = false; //是否全屏状态
		//预览图片
		private var previewElement: newPreview = null;
		private var preview: Sprite = null;
		private var previewLoad: Boolean = false,
			previewLoadIng: Boolean = false;
		private var previewTop: Sprite = null;
		private var pTween: Tween = null; //预览图片缓动
		private var previewPrompt: Sprite = null;
		private var listenerArr: Array = [];
		private var definitionTimer: timeInterval = null,subtitleTimer:timeInterval=null;
		private var buttonDown: Boolean = false;
		private var videoSpriteXY:Object={x:0,y:0};
		public function face(stage: Stage, sprite: Sprite, into: Function) {
			// constructor code
			STAGE = stage;
			THIS = sprite;
			CONFIG = C.CONFIG;
			STYLE = CONFIG["style"];
			LANGUAGE = CONFIG["language"];
			FLASHVARS = CONFIG["flashvars"];
			script.traceObject(STYLE);
			intoFun = into;
			stageW = STAGE.stageWidth;
			stageH = STAGE.stageHeight;
			stage.addEventListener(Event.RESIZE, resizeHandler);
			loadBackGround();
		}

		private function resizeHandler(event: Event): void {
			resize();
			//resize();
		}
		private function resize(): void {
			stageW = STAGE.stageWidth;
			stageH = STAGE.stageHeight;
			//修改背景位置和尺寸
			backgroundResize();
			//控制栏
			controlBarResize();
			//loading
			loadingResize();
			//logo
			logoResize();
			//buffer
			bufferResize();
			//音量
			volumeSliderResize();
			//时间进度
			timeSliderResize();
			//简易时间进度
			simpleScheduleResize();
			//点播时间显示框
			vodTimeTextResize();
			//直播显示框
			liveTimeTextResize();
			//调节全局自定义元件的坐标
			loadCustomResize();
			//如果控制栏是隐藏状态
			if (!mShow) {
				mShowHandler();
				if (cbHideTimer) {
					cbHideTimer.start();
				}
				if (cbShowTimer) {
					cbShowTimer.stop();
				}
			}
			//调整错误文本框
			errorShowResize();
			//调整中间播放按钮
			centerPlayResize();
			//调用前置后置广告
			advertisementResize();

			checkFullScreen();
			definitionResize();
			subtitlesResize();
			promptSpotResize();
		}
		//加载字幕切换组件
		public function loadSubtitles(n:int=-1):void{
			if (!C.CONFIG["config"]["subtitle"]) {
				return;
			}
			var trackS:String=C.CONFIG["flashvars"]["cktrack"];
			var trackArr=[];
			var index:int=0;
			if(trackS && trackS.indexOf(",")>-1){
				trackArr=script.trackToArray(trackS);
				for(var i:int=0;i<trackArr.length;i++){
					if(trackArr[i][2]>index){
						index=trackArr[i][2];
					}
				}
				if(n==-1){
					n=index;
				}
			}
			var eventS: String = STYLE["controlBar"]["subtitle"]["event"];
			if (MOBJ.hasOwnProperty("subtitleDefault") && MOBJ["subtitleDefault"] != null) {
				if (eventS == "over") {
					MOBJ["subtitleDefault"].removeEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler);
				} else {
					MOBJ["subtitleDefault"].removeEventListener(MouseEvent.CLICK, mouseClickHandler);
					MOBJ["subtitleDefault"].removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
					MOBJ["subtitleDefault"].removeEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
				}
				M.removeChild(MOBJ["subtitleDefault"]);
				MOBJ["subtitleDefault"] = null;
			}
			
			var text: String = "";
			if (n > -1) {
				text=trackArr[n][1];
			}

			if (text == "") {
				text = LANGUAGE["subtitle"];
			}
			var buttonObj: Object = script.copyObject(STYLE["controlBar"]["subtitle"]["defaultButton"]);
			if (n == -1) {
				buttonObj["overBackgroundColor"] = buttonObj["backgroundColor"];
			}
			buttonObj["text"] = text;
			var button: SimpleButton = element.newButton(buttonObj);

			if (MOBJ.hasOwnProperty("timeSlider")) {
				var tc: int = M.getChildIndex(MOBJ["timeSlider"]["backDefaultSprite"]);
				M.addChildAt(button, tc);
			} else {
				M.addChild(button);
			}
			if (n > -1) {
				if (eventS == "over") {
					button.addEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler);
				} else {
					button.addEventListener(MouseEvent.CLICK, mouseClickHandler);
					button.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
					button.addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
				}
			}
			MOBJ["subtitleDefault"] = button;
			//加载按钮列表

			subtitlesResize();
		}
		public function newSubtitles(high: int = 0): void { //high是高亮编号
			if (!C.CONFIG["config"]["subtitle"]) {
				loadSubtitles(-1);
				return;
			}
			var trackS:String=C.CONFIG["flashvars"]["cktrack"];
			var trackArr=[];
			if(trackS.indexOf(",")>-1){
				trackArr=script.trackToArray(trackS);
			}
			else{
				return;
			}
			//建立按钮
			if (MOBJ.hasOwnProperty("subtitleBack") && MOBJ["subtitleBack"] != null) {
				M.removeChild(MOBJ["subtitleBack"]);
				MOBJ["subtitleBack"] = null;
			}
			var buttonObj: Object = {};
			var text = "";
			var buttonArr: Array = [];
			var lineArr: Array = [];
			for (var i: int = 0; i < trackArr.length; i++) {
				if (i != high) {
					buttonObj = STYLE["controlBar"]["subtitle"]["button"];
				} else {
					buttonObj = STYLE["controlBar"]["subtitle"]["buttonHighlight"];
				}
				if (trackArr[i][1] != "") {
					text = trackArr[i][1];
				}
				buttonObj["text"] = text;
				var button: SimpleButton = element.newButton(buttonObj);
				button.name = "subtitle_" + i;
				button.addEventListener(MouseEvent.CLICK, function (event: MouseEvent) {
					THIS["changeSubtitles"](event.target.name.toString().replace("subtitle_", ""));
				});
				buttonArr.push(button);
			}
			//创建背景
			//计算宽高
			var background: Object = STYLE["controlBar"]["subtitle"]["background"];
			var separate: Object = STYLE["controlBar"]["subtitle"]["separate"];
			var bWidth: int = Number(background["paddingLeft"]) + Number(background["paddingRight"]) + buttonArr[0].width;
			var bHeight: int = Number(background["paddingTop"]) + Number(background["paddingBottom"]) + buttonArr[0].height * buttonArr.length;
			bHeight += (Number(separate["height"]) + Number(separate["marginTop"]) + Number(separate["marginBottom"])) * (buttonArr.length - 1);
			//script.traceObject();
			var bgObj: Object = {
				backgroundColor: background["backgroundColor"], //背景颜色
				backgroundAlpha: background["backgroundAlpha"], //背景透明度
				border: background["border"],
				borderColor: background["borderColor"], //边框颜色
				radius: background["radius"], //圆角弧度
				width: bWidth,
				height: bHeight
			}
			var bgSprite: Sprite = element.newSprite(bgObj);
			//画倒三角
			var triangleObj: Object = {
				width: background["triangleWidth"],
				height: background["triangleHeight"],
				backgroundColor: background["triangleBackgroundColor"],
				border: background["triangleBorder"],
				borderColor: background["triangleBorderColor"],
				alpha: background["triangleAlpha"]
			};
			var triangle: Sprite = element.newTriangle(triangleObj);
			triangle.y = bgSprite.height + Number(background["triangleDeviationY"]);
			triangle.x = (bgSprite.width - triangle.width) * 0.5 + Number(background["triangleDeviationX"]);
			bgSprite.addChild(triangle);
			//倒三角结束
			//将按钮填充进去并且画个间隔线
			var lineObj: Object = {
				color: separate["color"], //背景颜色
				alpha: Number(separate["alpha"]), //透明度
				width: bWidth - Number(separate["marginLeft"]) - Number(separate["marginRight"]),
				height: Number(separate["height"])
			};
			var nY: int = Number(background["paddingTop"]);
			for (i = 0; i < buttonArr.length; i++) {
				buttonArr[i].y = nY;
				buttonArr[i].x = Number(background["paddingLeft"]);
				bgSprite.addChild(buttonArr[i]);
				nY += buttonArr[i].height;
				//画间隔线
				if (i < buttonArr.length - 1) {
					var line: Sprite = element.newLine(lineObj);
					nY += Number(separate["marginTop"]);
					line.x = Number(separate["marginLeft"]);
					line.y = nY;
					nY += line.height;
					nY += Number(separate["marginBottom"]);
					bgSprite.addChild(line);
				}
				//画间隔线结束
			}
			bgSprite.visible = false;
			//填充结束
			M.addChild(bgSprite);
			MOBJ["subtitleBack"] = bgSprite;
			subtitlesResize();
			//trace(201, "行", bWidth, bHeight);
		}
		//加载清晰度组件
		public function loadDefinition(n: int = -1): void {
			if (!C.CONFIG["config"]["definition"]) {
				return;
			}

			var eventS: String = STYLE["controlBar"]["definition"]["event"];
			if (MOBJ.hasOwnProperty("definitionDefault") && MOBJ["definitionDefault"] != null) {
				if (eventS == "over") {
					MOBJ["definitionDefault"].removeEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler);
				} else {
					MOBJ["definitionDefault"].removeEventListener(MouseEvent.CLICK, mouseClickHandler);
					MOBJ["definitionDefault"].removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
					MOBJ["definitionDefault"].removeEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
				}
				M.removeChild(MOBJ["definitionDefault"]);
				MOBJ["definitionDefault"] = null;
			}
			var text: String = "";
			if (n > -1) {
				var video: Array = C.CONFIG["flashvars"]["video"];
				if (video[n].hasOwnProperty("definition")) {
					if (video[n]["definition"] != "") {
						text = video[n]["definition"];
					}

				}
			}

			if (text == "") {
				text = LANGUAGE["definition"];
			}
			var buttonObj: Object = script.copyObject(STYLE["controlBar"]["definition"]["defaultButton"]);
			if (n == -1) {
				buttonObj["overBackgroundColor"] = buttonObj["backgroundColor"];
			}
			buttonObj["text"] = text;
			var button: SimpleButton = element.newButton(buttonObj);

			if (MOBJ.hasOwnProperty("timeSlider")) {
				var tc: int = M.getChildIndex(MOBJ["timeSlider"]["backDefaultSprite"]);
				M.addChildAt(button, tc);
			} else {
				M.addChild(button);
			}
			if (n > -1) {
				if (eventS == "over") {
					button.addEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler);
				} else {
					button.addEventListener(MouseEvent.CLICK, mouseClickHandler);
					button.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
					button.addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
				}
			}
			MOBJ["definitionDefault"] = button;
			//加载按钮列表

			definitionResize();
		}
		public function newDefinition(high: int = 0): void { //high是高亮编号
			if (!C.CONFIG["config"]["definition"]) {
				loadDefinition(-1);
				return;
			}
			var video: Array = C.CONFIG["flashvars"]["video"];
			if (video[0].hasOwnProperty("definition")) {
				if (video[0]["definition"] == "") {
					loadDefinition(-1);
					return;
				}
			} else {
				loadDefinition(-1);
				return;
			}
			//建立按钮
			if (MOBJ.hasOwnProperty("definitionBack") && MOBJ["definitionBack"] != null) {
				M.removeChild(MOBJ["definitionBack"]);
				MOBJ["definitionBack"] = null;
			}
			var buttonObj: Object = {};
			var text = "";
			var buttonArr: Array = [];
			var lineArr: Array = [];
			for (var i: int = 0; i < video.length; i++) {
				if (i != high) {
					buttonObj = STYLE["controlBar"]["definition"]["button"];
				} else {
					buttonObj = STYLE["controlBar"]["definition"]["buttonHighlight"];
				}
				if (video[i]["definition"] != "") {
					text = video[i]["definition"];
				}
				buttonObj["text"] = text;
				var button: SimpleButton = element.newButton(buttonObj);
				button.name = "definition_" + i;
				button.addEventListener(MouseEvent.CLICK, function (event: MouseEvent) {
					THIS["changeDefinition"](event.target.name.toString().replace("definition_", ""));
				});
				buttonArr.push(button);
			}
			//创建背景
			//计算宽高
			var background: Object = STYLE["controlBar"]["definition"]["background"];
			var separate: Object = STYLE["controlBar"]["definition"]["separate"];
			var bWidth: int = Number(background["paddingLeft"]) + Number(background["paddingRight"]) + buttonArr[0].width;
			var bHeight: int = Number(background["paddingTop"]) + Number(background["paddingBottom"]) + buttonArr[0].height * buttonArr.length;
			bHeight += (Number(separate["height"]) + Number(separate["marginTop"]) + Number(separate["marginBottom"])) * (buttonArr.length - 1);
			//script.traceObject();
			var bgObj: Object = {
				backgroundColor: background["backgroundColor"], //背景颜色
				backgroundAlpha: background["backgroundAlpha"], //背景透明度
				border: background["border"],
				borderColor: background["borderColor"], //边框颜色
				radius: background["radius"], //圆角弧度
				width: bWidth,
				height: bHeight
			}
			var bgSprite: Sprite = element.newSprite(bgObj);
			//画倒三角
			var triangleObj: Object = {
				width: background["triangleWidth"],
				height: background["triangleHeight"],
				backgroundColor: background["triangleBackgroundColor"],
				border: background["triangleBorder"],
				borderColor: background["triangleBorderColor"],
				alpha: background["triangleAlpha"]
			};
			var triangle: Sprite = element.newTriangle(triangleObj);
			triangle.y = bgSprite.height + Number(background["triangleDeviationY"]);
			triangle.x = (bgSprite.width - triangle.width) * 0.5 + Number(background["triangleDeviationX"]);
			bgSprite.addChild(triangle);
			//倒三角结束
			//将按钮填充进去并且画个间隔线
			var lineObj: Object = {
				color: separate["color"], //背景颜色
				alpha: Number(separate["alpha"]), //透明度
				width: bWidth - Number(separate["marginLeft"]) - Number(separate["marginRight"]),
				height: Number(separate["height"])
			};
			var nY: int = Number(background["paddingTop"]);
			for (i = 0; i < buttonArr.length; i++) {
				buttonArr[i].y = nY;
				buttonArr[i].x = Number(background["paddingLeft"]);
				bgSprite.addChild(buttonArr[i]);
				nY += buttonArr[i].height;
				//画间隔线
				if (i < buttonArr.length - 1) {
					var line: Sprite = element.newLine(lineObj);
					nY += Number(separate["marginTop"]);
					line.x = Number(separate["marginLeft"]);
					line.y = nY;
					nY += line.height;
					nY += Number(separate["marginBottom"]);
					bgSprite.addChild(line);
				}
				//画间隔线结束
			}
			bgSprite.visible = false;
			//填充结束
			M.addChild(bgSprite);
			MOBJ["definitionBack"] = bgSprite;
			definitionResize();
			//trace(201, "行", bWidth, bHeight);
		}
		private function definitionResize(): void {
			if (!C.CONFIG["config"]["definition"]) {
				return;
			}
			//backgroundCoor
			var newCoor: Object
			if (MOBJ.hasOwnProperty("definitionDefault") && MOBJ["definitionDefault"] != null) {
				newCoor = coorDinate(STYLE["controlBar"]["definition"]["defaultButtonCoor"], MOBJ["controlBarBgColor"]);
				//script.traceObject(newCoor)
				MOBJ["definitionDefault"].x = newCoor["x"];
				MOBJ["definitionDefault"].y = newCoor["y"];
			}
			if (MOBJ.hasOwnProperty("definitionBack") && MOBJ["definitionBack"] != null) {
				var height: String = STYLE["controlBar"]["definition"]["backgroundCoor"]["height"].toString();
				newCoor = coorDinate(STYLE["controlBar"]["definition"]["backgroundCoor"], MOBJ["controlBarBgColor"]);
				MOBJ["definitionBack"].x = newCoor["x"];
				MOBJ["definitionBack"].y = newCoor["y"] - (height == "true" ? MOBJ["definitionBack"].height : 0);
			}
		}
		private function subtitlesResize(): void {
			if (!C.CONFIG["config"]["subtitle"]) {
				return;
			}
			//backgroundCoor
			var newCoor: Object
			if (MOBJ.hasOwnProperty("subtitleDefault") && MOBJ["subtitleDefault"] != null) {
				newCoor = coorDinate(STYLE["controlBar"]["subtitle"]["defaultButtonCoor"], MOBJ["controlBarBgColor"]);
				//script.traceObject(newCoor)
				MOBJ["subtitleDefault"].x = newCoor["x"];
				MOBJ["subtitleDefault"].y = newCoor["y"];
			}
			if (MOBJ.hasOwnProperty("subtitleBack") && MOBJ["subtitleBack"] != null) {
				var height: String = STYLE["controlBar"]["subtitle"]["backgroundCoor"]["height"].toString();
				newCoor = coorDinate(STYLE["controlBar"]["subtitle"]["backgroundCoor"], MOBJ["controlBarBgColor"]);
				MOBJ["subtitleBack"].x = newCoor["x"];
				MOBJ["subtitleBack"].y = newCoor["y"] - (height == "true" ? MOBJ["subtitleBack"].height : 0);
			}
		}
		//-------------------------------------------------------------------------------------------logo
		private function logoResize(): void {
			if (logo) {
				var coor: Object = coorDinate(STYLE["logo"]);
				logo.x = coor["x"];
				logo.y = coor["y"];
			}
		}
		private function loadLogo(): void {
			//加载loading元件
			if (STYLE.hasOwnProperty("logo") && STYLE["logo"]["file"]!="" && STYLE["logo"]["file"]!="null") {
				loaderNum++;
				var newLoader: loadByteImg = new loadByteImg(STYLE["logo"]["file"], function (byte: Loader = null) {
					if (byte) {
						logo = byte;
						THIS.addChild(logo);
						imgLoaded();
						logoResize();
					}
				});
			}

		}
		//-------------------------------------------------------------------------------------------logo 结束
		//-------------------------------------------------------------------------------------------buffer
		private function bufferResize(): void {
			var coor: Object = {};
			if (MOBJ.hasOwnProperty("buffer")) {
				coor = coorDinate(STYLE["buffer"]);
				MOBJ["buffer"].x = coor["x"];
				MOBJ["buffer"].y = coor["y"];
			}
			if (MOBJ.hasOwnProperty("bufferText")) {
				coor = coorDinate(STYLE["buffer"]["text"]);
				MOBJ["bufferText"].x = coor["x"];
				MOBJ["bufferText"].y = coor["y"];
			}
		}
		private function loadBuffer(): void {
			//加载loading元件
			if (STYLE.hasOwnProperty("buffer")) {
				loaderNum++;
				var newLoader: loadByteImg = new loadByteImg(STYLE["buffer"]["file"], function (byte: Loader = null) {
					if (byte) {
						MOBJ["buffer"] = byte;
						THIS.addChild(MOBJ["buffer"]);
						MOBJ["buffer"].visible = false;
						imgLoaded();
						bufferResize();
					}
				});
				if (STYLE["buffer"].hasOwnProperty("text")) {
					var obj: Object = STYLE["buffer"]["text"];
					obj["text"] = script.replace(LANGUAGE["buffer"], ["[$percentage]"], [0]);
					var newText: TextField = element.newText(obj);
					THIS.addChild(newText);
					MOBJ["bufferText"] = newText;
					MOBJ["bufferText"].visible = false;
				}
			}

		}

		//-------------------------------------------------------------------------------------------buffer 结束
		//-------------------------------------------------------------------------------------------loading
		private function loadingResize(): void {
			if (loading) {
				var coor: Object = coorDinate(STYLE["loading"]);
				loading.x = coor["x"];
				loading.y = coor["y"];
			}
		}
		private function loadLoading(): void {
			//加载loading元件
			if (STYLE.hasOwnProperty("loading") && STYLE["loading"]["file"]!="" && STYLE["loading"]["file"]!="null") {
				loaderNum++;
				var newLoader: loadByteImg = new loadByteImg(STYLE["loading"]["file"], function (byte: Loader = null) {
					if (byte) {
						loading = byte;
						THIS.addChild(loading);
						imgLoaded();
						loadingResize();
					}
				});
			}

		}
		//-------------------------------------------------------------------------------------------loading 结束

		private function promptSpotResize(): void { //根据时间点计算坐标
			if (promptSpotArr.length > 0) {
				var w = MOBJ["timeSlider"]["backgroundDefaultLoader"].width;
				trace("宽度:", w);
				//timeTotal
				for (var i: int = 0; i < promptSpotArr.length; i++) {
					var p: Object = promptSpotObjArr[i];
					var x: int = (p["time"] * w / timeTotal) - promptSpotArr[i].width * 0.5;
					if (x < 0) {
						x = 0;
					}
					if (x > w - promptSpotArr[i].width) {
						x = w - promptSpotArr[i].width
					}
					var y: int = (MOBJ["timeSlider"]["backDefaultSprite"].height - promptSpotArr[i].height) * 0.5;
					promptSpotArr[i].x = x;
					promptSpotArr[i].y = y;
				}
			}
		}
		//-------------------------------------------------------------------------------------------提示点结束
		//-------------------------------------------------------------------------------------------提示图片
		private function previewShow(t: int = 0): void {
			if (!preview && !previewLoad) {
				if (!previewLoadIng) {
					previewLoadIng = true;
					loadPreview(t);
				}
				return;
			}
			if (preview != null) {
				var scale: int = FLASHVARS["preview"]["scale"];
				var x: int = M.mouseX;
				var nowNum: int = t / scale;
				var numTotal: int = timeTotal / scale;
				var imgW: int = preview.width * 0.01 / FLASHVARS["preview"]["file"].length;
				var imgH: int = preview.height;
				var left: int = (imgW * nowNum) - x + imgW * 0.5,
					top: int = stageH - STYLE["preview"]["bottom"] - imgH;
				//top: int = M.y - imgH - (M.height - STYLE["controlBar"]["height"]);
				var topLeft: int = x - imgW * 0.5;
				var timepieces: int = 0;
				var isTween: Boolean = true;
				if (previewTop == null) {
					var obj: Object = {
						width: imgW - Number(STYLE["preview"]["border"]),
						height: imgH - Number(STYLE["preview"]["border"]),
						borderAlpha: Number(STYLE["preview"]["alpha"]),
						border: STYLE["preview"]["border"],
						borderColor: STYLE["preview"]["borderColor"]
					}
					previewTop = element.newSprite(obj);
					THIS.addChildAt(previewTop, THIS.getChildIndex(M));
					previewTop.visible = false;
				}
				//topLeft-=STYLE["preview"]["border"];
				//trace(THIS.getChildIndex(preview),THIS.getChildIndex(previewTop));
				if (THIS.getChildIndex(preview) > THIS.getChildIndex(previewTop)) {
					var temp: int = THIS.getChildIndex(preview);

					//THIS.addChildAt(previewTop, THIS.getChildIndex(preview));
					THIS.addChildAt(preview, THIS.getChildIndex(previewTop));
				}
				if (topLeft < 0) {
					topLeft = 0;
					timepieces = x - topLeft - imgW * 0.5;
				}
				if (topLeft > stageW - imgW) {
					topLeft = stageW - imgW;
					timepieces = x - topLeft - imgW * 0.5;
				}
				if (left < 0) {
					left = 0;
				}
				if (left > numTotal * imgW - stageW) {
					left = numTotal * imgW - stageH;
				}
				if (preview.visible == false) {
					isTween = false;
				}
				previewTop.x = topLeft + STYLE["preview"]["border"] * 0.5;
				previewTop.y = top + STYLE["preview"]["border"] * 0.5;
				previewTop.visible = true;
				preview.visible = true;
				preview.y = top;
				if (previewPrompt) {
					previewPrompt.y = top - previewPrompt.height - Number(C.CONFIG["style"]["previewPrompt"]["marginBottom"]);
					THIS.addChildAt(previewPrompt, THIS.getChildIndex(preview) + 1);
				}
				if (pTween != null) {
					pTween.stop();
					pTween = null;
				}
				if (isTween) {
					pTween = new Tween(preview, "x", None.easeOut, preview.x, -(left + timepieces), 0.3, true);
				} else {
					preview.x = -(left + timepieces);
				}
			}
		}
		private function previewHide(): void {
			if (previewTop) {
				previewTop.visible = false;
			}
			if (preview) {
				preview.visible = false;
			}
		}
		private function loadPreview(t: int = 0): void {
			if (timeTotal <= 0) {
				return;
			}
			if (FLASHVARS.hasOwnProperty("preview") && FLASHVARS["preview"] && !previewLoad) {
				if (FLASHVARS["preview"].hasOwnProperty("file") && FLASHVARS["preview"].hasOwnProperty("scale")) {
					previewElement = new newPreview(FLASHVARS["preview"]["file"], function (sp: Sprite = null) {
						if (sp) {
							if (preview) {
								THIS.removeChild(preview);
								preview = null;
							}
							//TRACE(preview.width)
							preview = sp;
							THIS.addChildAt(preview, THIS.getChildIndex(M));
							preview.visible = false;
							if (t > 0 && prompt) {
								previewShow(t);
							}
						}
						previewElement = null;
						previewLoad = true;
					});
				}

			}
		}
		//-------------------------------------------------------------------------------------------提示图片
		//-------------------------------------------------------------------------------------------控制栏
		private function controlBarResize(): void {
			var newSize: Object = {}, newCoor: Object = {};
			var i: int = 0;
			var customArr: Array = [];
			var k: String = "";
			if (M) {
				var coor: Object = coorDinate({
					align: STYLE["controlBar"]["align"],
					vAlign: STYLE["controlBar"]["vAlign"],
					offsetX: STYLE["controlBar"]["offsetX"],
					offsetY: STYLE["controlBar"]["offsetY"]
				});
				M.x = coor["x"];
				M.y = coor["y"];
			}
			if (MOBJ.hasOwnProperty("controlBarBgColor")) {
				newSize = calculatedSize(STYLE["controlBar"]["width"].toString(), STYLE["controlBar"]["height"].toString());
				MOBJ["controlBarBgColor"].width = newSize["width"];
				MOBJ["controlBarBgColor"].height = newSize["height"];
			}
			if (MOBJ.hasOwnProperty("backgroundImg")) {
				newSize = calculatedSize(STYLE["controlBar"]["width"].toString(), STYLE["controlBar"]["height"].toString());
				MOBJ["backgroundImg"].width = newSize["width"];
				MOBJ["backgroundImg"].height = newSize["height"];
			}
			//MOBJ["button"]
			if (MOBJ.hasOwnProperty("button")) {
				for (k in MOBJ["button"]) {
					newCoor = coorDinate(STYLE["controlBar"]["button"][k], MOBJ["controlBarBgColor"]);
					MOBJ["button"][k].x = newCoor["x"];
					MOBJ["button"][k].y = newCoor["y"];
				}
			}
			//定义自定义按钮的坐标
			if (MOBJ.hasOwnProperty("customButton")) {
				for (k in MOBJ["customButton"]) {
					newCoor = coorDinate(STYLE["controlBar"]["custom"]["button"][k], MOBJ["controlBarBgColor"]);
					//script.traceObject(newCoor);
					MOBJ["customButton"][k].x = newCoor["x"];
					MOBJ["customButton"][k].y = newCoor["y"];
				}
			}
			//自定义图片的坐标

			if (MOBJ.hasOwnProperty("customImages")) {
				for (k in MOBJ["customImages"]) {
					newCoor = coorDinate(STYLE["controlBar"]["custom"]["images"][k], MOBJ["controlBarBgColor"]);
					MOBJ["customImages"][k].x = newCoor["x"];
					MOBJ["customImages"][k].y = newCoor["y"];
				}
			}
			//自定义文本框的坐标
			if (MOBJ.hasOwnProperty("customText")) {
				for (k in MOBJ["customText"]) {
					newCoor = coorDinate(STYLE["controlBar"]["custom"]["text"][k], MOBJ["controlBarBgColor"]);
					MOBJ["customText"][k].x = newCoor["x"];
					MOBJ["customText"][k].y = newCoor["y"];
				}
			}
			//自定swf的坐标
			if (MOBJ.hasOwnProperty("customSwf")) {
				for (k in MOBJ["customSwf"]) {
					newCoor = coorDinate(STYLE["controlBar"]["custom"]["swf"][k], MOBJ["controlBarBgColor"]);
					MOBJ["customSwf"][k].x = newCoor["x"];
					MOBJ["customSwf"][k].y = newCoor["y"];
				}
			}
		}
		private function loadCustomResize(): void {
			//定义自定义按钮的坐标
			var k: String = "";
			var newCoor: Object = {};
			if (MOBJ.hasOwnProperty("vcustomButton")) {
				for (k in MOBJ["vcustomButton"]) {
					newCoor = coorDinate(STYLE["custom"]["button"][k]);
					//script.traceObject(newCoor);
					MOBJ["vcustomButton"][k].x = newCoor["x"];
					MOBJ["vcustomButton"][k].y = newCoor["y"];
				}
			}
			//自定义图片的坐标
			//trace("自定义图片",MOBJ.hasOwnProperty("vcustomImages"));
			if (MOBJ.hasOwnProperty("vcustomImages")) {
				for (k in MOBJ["vcustomImages"]) {
					newCoor = coorDinate(STYLE["custom"]["images"][k]);
					MOBJ["vcustomImages"][k].x = newCoor["x"];
					MOBJ["vcustomImages"][k].y = newCoor["y"];
				}
			}
			//自定义文本框的坐标
			if (MOBJ.hasOwnProperty("vcustomText")) {
				for (k in MOBJ["vcustomText"]) {
					newCoor = coorDinate(STYLE["custom"]["text"][k]);
					MOBJ["vcustomText"][k].x = newCoor["x"];
					MOBJ["vcustomText"][k].y = newCoor["y"];
				}
			}
			//自定swf的坐标
			for( k in MOBJ){
				trace(k,MOBJ[k]);
			}
			if (MOBJ.hasOwnProperty("vcustomSwf")) {
				for (k in MOBJ["vcustomSwf"]) {
					newCoor = coorDinate(STYLE["custom"]["swf"][k]);
					MOBJ["vcustomSwf"][k].x = newCoor["x"];
					MOBJ["vcustomSwf"][k].y = newCoor["y"];
				}
			}
		}
		private function loadControlBar(): void {
			//建立一个基于界面底部的元件
			var mObj: Object = {
				backgroundColor: 0xFF0000,
				backgroundAlpha: 0, //背景透明度
				width: 1,
				height: 1
			};
			M = element.newSprite(mObj);
			THIS.addChild(M);
			if (CONFIG["config"]["buttonMode"]["controlBar"]) {
				M.buttonMode = true;
			}
			if (STYLE.hasOwnProperty("controlBar")) {
				if (STYLE["controlBar"].hasOwnProperty("hideControlBar")) {
					if (STYLE["controlBar"]["hideControlBar"].hasOwnProperty("hideDelayTime")) {
						if (STYLE["controlBar"]["hideControlBar"]["hideDelayTime"] > 0) {
							cbHideTimer = new timeInterval(STYLE["controlBar"]["hideControlBar"]["hideDelayTime"], cbHideTimerHandler);
							cbHideTimer.start();
							cbShowTimer = new timeInterval(100, cbShowTimerHandler);
						}
					}
				}
			}

			//加载纯色层
			//加载背景
			var background: Object = STYLE["controlBar"]["background"];
			var newSize: Object = calculatedSize(STYLE["controlBar"]["width"].toString(), STYLE["controlBar"]["height"].toString());
			//无论有没有图片都加载一个纯色层
			if (background.hasOwnProperty("backgroundColor") && background["backgroundColor"]) {
				mObj = {
					backgroundColor: background["backgroundColor"],
					backgroundAlpha: (background.hasOwnProperty("backgroundImg") && background["backgroundImg"]) ? 0 : background["alpha"], //背景透明度
					width: newSize["width"],
					height: newSize["height"],
					radius: background["radius"]
				};
				var backgroundColorSprite: Sprite = element.newSprite(mObj);
				M.addChild(backgroundColorSprite);
				MOBJ["controlBarBgColor"] = backgroundColorSprite;
			}
			if (background.hasOwnProperty("backgroundImg") && background["backgroundImg"]) {
				loaderNum++;
				var backgroundImgLoader: loadByteImg = new loadByteImg(background["backgroundImg"], function (byte: Loader = null) {
					if (byte) {
						var loader: Loader = byte;
						loader.alpha = background["alpha"];
						M.addChild(loader);
						MOBJ["backgroundImg"] = loader;

					} else {
						new log("error:Failed to load STYLE[\"controlBar\"][\"background\"][\"backgroundImg\"]");

					}
					imgLoaded();
					controlBarResize();
					controlLoaderHandler();
					backgroundImgLoader = null;
				});

			} else {
				controlBarResize();
				controlLoaderHandler();
				//loadLogo();
			}

		}
		//统一的在控制栏加载完成后的动作
		private function controlLoaderHandler(): void {
			loadControlBarButton();
			loadDefinition();
			loadSubtitles();//加载字幕切换按钮
			loadVolumeSlider(); //构建音量调节滑动条
			loadTimeSlider(); //构建时间进度滑动条
			loadSimpleSchedule(); //简单进度条
			loadTimeText();
			loadLoading();
			loadLogo();
			loadBuffer();
			loadCustom();
			loadAdvertisement();
			if (CONFIG["config"]["previewDefaultLoad"]) {
				loadPreview();
			}
		}

		//加载音量调节和进度条
		private function volumeSliderResize(): void {
			if (MOBJ.hasOwnProperty("volumeSlider")) {
				var newCoor: Object = coorDinate(STYLE["controlBar"]["volumeSchedule"], MOBJ["controlBarBgColor"]);
				MOBJ["volumeSlider"]["backSprite"].x = newCoor["x"];
				MOBJ["volumeSlider"]["backSprite"].y = newCoor["y"];
			}
		}

		//静音切换
		private function muteOrEscMute(volume: Number = 0): void {
			if (volume == 0) {
				MOBJ["button"]["mute"].visible = false;
				MOBJ["button"]["escMute"].visible = true;
			} else {
				MOBJ["button"]["mute"].visible = true;
				MOBJ["button"]["escMute"].visible = false;
			}
		}
		private function mouseMoveHandler(event: MouseEvent): void {
			/*MOBJ["volume"] = {
					backSprite: backSprite,
					backgroundLoader:backgroundLoader,
					maskLoader: maskLoader,
					maskSprite: maskSprite,
					buttonLoader: buttonLoader
				};*/
			var pointTemp: Point = new Point(event.localX, event.localY);
			var value: Number = 0;
			var stageX: int = 0;
			//trace(event);
			//trace(event.currentTarget.name);
			switch (event.currentTarget) {
				case MOBJ["timeSlider"]["backgroundDefaultLoader"]:
				case MOBJ["timeSlider"]["loadDefaultLoader"]:
				case MOBJ["timeSlider"]["playDefaultLoader"]:
					//trace(timeTotal,new Date);
					if (timeTotal == 0 || FLASHVARS["live"]) {
						break;
					}
					//trace(MOBJ["timeSlider"]["backDefaultSprite"].mouseX,MOBJ["timeSlider"]["backgroundDefaultLoader"].width);
					var mx: int = MOBJ["timeSlider"]["backDefaultSprite"].mouseX;
					var bw: int = MOBJ["timeSlider"]["backgroundDefaultLoader"].width;
					if (mx > bw - 2) {
						mx = bw;
					}
					value = int(mx * timeTotal / bw);
					if (value > timeTotal) {
						value = timeTotal;
					}
					if (value < 0) {
						value = 0;
					}
					//trace(MOBJ["timeSlider"]["backDefaultSprite"].mouseX,MOBJ["timeSlider"]["backgroundDefaultLoader"].width,value,"v");
					//trace(event.stageX, event.stageY , pointTemp.y);
					stageX = STAGE.mouseX - M.x - MOBJ["timeSlider"]["backDefaultSprite"].x;
					//trace(value,LANGUAGE["timeSliderOver"]);
					showPrompt(getFormatTime(LANGUAGE["timeSliderOver"], value), stageX, event.stageY - pointTemp.y);
					previewShow(value);
					break;
				case MOBJ["timeSlider"]["buttonDefaultLoader"]:
					if (timeTotal == 0 || FLASHVARS["live"]) {
						break;
					}
					value = Number((MOBJ["timeSlider"]["buttonDefaultLoader"].x - MOBJ["timeSlider"]["backDefaultSprite"].x) * timeTotal / (MOBJ["timeSlider"]["backgroundDefaultLoader"].width - MOBJ["timeSlider"]["buttonDefaultLoader"].width));
					//trace("value:",value);
					if (value > timeTotal) {
						value = timeTotal;
					}
					if (value < 0) {
						value = 0;
					}
					seekTime = value;
					//trace("要跳转的秒数，来之face",seekTime);
					showPrompt(getFormatTime(LANGUAGE["timeSliderOver"], value), event.stageX, event.stageY - pointTemp.y);
					break;
				case MOBJ["definitionDefault"]:
					if (STYLE["controlBar"]["definition"]["event"] != "over") {
						showPrompt(LANGUAGE["buttonOver"]["definition"], M.x + MOBJ["definitionDefault"].x + MOBJ["definitionDefault"].width * 0.5, event.stageY - pointTemp.y);
					}
					break;
				case MOBJ["subtitleDefault"]:
					if (STYLE["controlBar"]["subtitle"]["event"] != "over") {
						showPrompt(LANGUAGE["buttonOver"]["subtitles"], M.x + MOBJ["subtitleDefault"].x + MOBJ["subtitleDefault"].width * 0.5, event.stageY - pointTemp.y);
					}
					break;
				case MOBJ["volumeSlider"]["backgroundLoader"]:
				case MOBJ["volumeSlider"]["maskLoader"]:
					value = MOBJ["volumeSlider"]["backgroundLoader"].mouseX / MOBJ["volumeSlider"]["backSprite"].width;
					//changeVolume(vol * 0.01, true, true, false);
					if (value > 1) {
						value = 1;
					}
					if (value < 0) {
						value = 0;
					}
					showPrompt(script.strReplace(LANGUAGE["volumeSliderOver"], ["[$volume]"], [Math.ceil(value * 100).toString()]), event.stageX, event.stageY - pointTemp.y);
					break;
				case MOBJ["volumeSlider"]["buttonLoader"]:
					value = getVolumeTemp();
					showPrompt(script.strReplace(LANGUAGE["volumeSliderOver"], ["[$volume]"], [Math.ceil(value * 100).toString()]), event.stageX, event.stageY - pointTemp.y);
					break;
				case STAGE:
					if (M && MOBJ.hasOwnProperty("timeSlider") && MOBJ.hasOwnProperty("timeOutSlider")) {
						if (STAGE.mouseX > M.x + mMinXY["x"] && STAGE.mouseX < M.x + mMinXY["x"] + M.width && STAGE.mouseY > M.y + mMinXY["y"] && STAGE.mouseY < M.y + mMinXY["y"] + M.height) {
							if (!timeSliderShow) {
								timeDefaultShow();
							}
						} else {
							if (!timeOutSliderShow) {
								timeOutShow();
							}
						}
					}
					break;
				default:
					if (event.target.name.toString().indexOf("spirte_") > -1) {
						var ni: int = Number(event.target.name.toString().replace("spirte_", ""));
						var timeString: String = "";
						if (CONFIG["config"]["promptSpotTime"]) {
							timeString = getFormatTime(LANGUAGE["timeSliderOver"], promptSpotObjArr[ni]["time"]) + " ";
						}
						stageX = STAGE.mouseX - M.x - MOBJ["timeSlider"]["backDefaultSprite"].x;
						showPrompt(getFormatTime(LANGUAGE["timeSliderOver"], promptSpotObjArr[ni]["time"]), stageX, event.stageY - pointTemp.y);
						showPreviewPrompt(timeString + promptSpotObjArr[ni]["words"], stageX, event.stageY - pointTemp.y);
						previewShow(promptSpotObjArr[ni]["time"]);
					}
					break;
			}
		}
		private function timeDefaultShow(): void {
			if (showTween) {
				showTween.stop();
				showTween = null;
			}
			if (hideTween) {
				hideTween.stop();
				hideTween = null;
			}
			showTween = new Tween(MOBJ["timeSlider"]["backDefaultSprite"], "alpha", None.easeOut, MOBJ["timeSlider"]["backDefaultSprite"].alpha, 1, STYLE["controlBar"]["timeSchedule"]["defaultShowTime"], true);
			showTween.start();
			hideTween = new Tween(MOBJ["timeOutSlider"]["backOutSprite"], "alpha", None.easeOut, MOBJ["timeOutSlider"]["backOutSprite"].alpha, 0, STYLE["controlBar"]["timeSchedule"]["mouseOutHideTime"], true);
			hideTween.start();
			timeSliderShow = true;
			timeOutSliderShow = false;
		}
		private function timeOutShow(): void {
			if (showTween) {
				showTween.stop();
				showTween = null;
			}
			if (hideTween) {
				hideTween.stop();
				hideTween = null;
			}
			showTween = new Tween(MOBJ["timeSlider"]["backDefaultSprite"], "alpha", None.easeOut, MOBJ["timeSlider"]["backDefaultSprite"].alpha, 0, STYLE["controlBar"]["timeSchedule"]["defaultHideTime"], true);
			showTween.start();
			hideTween = new Tween(MOBJ["timeOutSlider"]["backOutSprite"], "alpha", None.easeOut, MOBJ["timeOutSlider"]["backOutSprite"].alpha, 1, STYLE["controlBar"]["timeSchedule"]["mouseOutShowTime"], true);
			hideTween.start();
			timeOutSliderShow = true;
			timeSliderShow = false;
		}
		private function cbHideTimerHandler(): void {
			var nowStageXY: Object = {
				x: STAGE.mouseX,
				y: STAGE.mouseY
			};
			if (MOBJ["button"]["pause"].visible && (nowStageXY["x"] == oldStageXY["x"] || nowStageXY["y"] == oldStageXY["y"]) && (STAGE.mouseX < M.x + mMinXY["x"] || STAGE.mouseX > M.x + mMinXY["x"] + M.width || STAGE.mouseY < M.y + mMinXY["y"] || STAGE.mouseY > M.y + mMinXY["y"] + M.height)) {
				var hideEnvironment: String = STYLE["controlBar"]["hideControlBar"]["hideEnvironment"];
				if (mShow && (hideEnvironment == "all" || (hideEnvironment == "full" && full) || (hideEnvironment == "nofull" && !full))) {
					mHideHandler();
					if (cbShowTimer) {
						cbHideTimer.stop();
						cbShowTimer.start();
					}
				}
			}
			oldStageXY = nowStageXY;
		}
		private function cbShowTimerHandler(): void {
			var nowStageXY: Object = {
				x: STAGE.mouseX,
				y: STAGE.mouseY
			};
			if (nowStageXY["x"] != oldStageXY["x"] || nowStageXY["y"] != oldStageXY["y"]) {
				oldStageXY = nowStageXY;
				if (!mShow) {
					mShowHandler();
					if (cbHideTimer) {
						cbHideTimer.start();
						cbShowTimer.stop();
					}
				}

			}
		}
		private function mShowHandler(): void {
			if (force) {
				return;
			}
			if (cbTween) {
				cbTween.removeEventListener(TweenEvent.MOTION_FINISH, simpleScheduleHandler);
				cbTween = null;
			}
			mShow = true;
			var coor: Object = coorDinate({
				align: STYLE["controlBar"]["align"],
				vAlign: STYLE["controlBar"]["vAlign"],
				offsetX: STYLE["controlBar"]["offsetX"],
				offsetY: STYLE["controlBar"]["offsetY"]
			});
			if (MOBJ.hasOwnProperty("simpleSchedule")) {
				MOBJ["simpleSchedule"]["backDefaultSprite"].visible = false;
			}
			if(M.visible==false){
				M.visible=true;
			}
			if (STYLE["controlBar"]["hideControlBar"]["hideMode"] == "alpha") {
				cbTween = new Tween(M, "alpha", None.easeOut, M.alpha, 1, STYLE["controlBar"]["hideControlBar"]["hideTweenTime"], true);
			} else {
				cbTween = new Tween(M, "y", None.easeOut, M.y, coor["y"], STYLE["controlBar"]["hideControlBar"]["hideTweenTime"], true);
			}
			THIS["controlBarIsShow"]();
			Mouse.show();
		}
		private function mHideHandler(): void {
			trace("控制栏隐藏");
			if (cbTween) {
				cbTween.removeEventListener(TweenEvent.MOTION_FINISH, simpleScheduleHandler);
				cbTween = null;
			}
			mShow = false;
			THIS["controlBarIsShow"](false);
			if (force) {
				M.visible=false;
			} else {
				if (STYLE["controlBar"]["hideControlBar"]["hideMode"] == "alpha") {
					cbTween = new Tween(M, "alpha", None.easeOut, M.alpha, 0, STYLE["controlBar"]["hideControlBar"]["hideTweenTime"], true);
				} else {
					cbTween = new Tween(M, "y", None.easeOut, M.y, stageH + M.height, STYLE["controlBar"]["hideControlBar"]["hideTweenTime"], true);
				}
				if (cbTween) {
					cbTween.addEventListener(TweenEvent.MOTION_FINISH, simpleScheduleHandler);
				}
			}

			if (!force) {
				Mouse.hide();
			}
		}
		private function simpleScheduleHandler(event: TweenEvent) {
			if (MOBJ.hasOwnProperty("simpleSchedule")) {
				var showSimpleSchedule: String = STYLE["controlBar"]["hideControlBar"]["showSimpleSchedule"];
				if (showSimpleSchedule == "all" || (showSimpleSchedule == "nofull" && !full) || (showSimpleSchedule == "full" && full)) {
					MOBJ["simpleSchedule"]["backDefaultSprite"].visible = true;
				}

			}
		}
		private function getVolumeTemp(): Number {
			var vol: Number = volumeTemp;
			if (vol > 1) {
				vol = 1;
			}
			if (vol < 0) {
				vol = 0;
			}
			return vol;
		}
		private function timeSliderResize() {
			//timeSliderResize
			/*
				MOBJ["timeSlider"] = {
					backDefaultSprite: backDefaultSprite,
					backgroundDefaultLoader: backgroundDefaultLoader,
					loadDefaultLoader: loadDefaultLoader,
					loadDefaultSprite: loadDefaultSprite,
					playDefaultLoader: playDefaultLoader,
					playDefaultSprite: playDefaultSprite,
					buttonDefaultLoader: buttonDefaultLoader
				};
			*/
			var newCoor: Object = {};
			var newSize: Object = {};
			if (MOBJ.hasOwnProperty("timeSlider")) {
				newCoor = coorDinate(STYLE["controlBar"]["timeSchedule"]["default"], MOBJ["timeSlider"]["backDefaultSprite"]);
				script.traceObject(newCoor);
				newSize = calculatedSize(STYLE["controlBar"]["timeSchedule"]["default"]["width"].toString(), MOBJ["timeSlider"]["backDefaultSprite"].height.toString(), MOBJ["controlBarBgColor"]);
				MOBJ["timeSlider"]["backDefaultSprite"].x = newCoor["x"];
				MOBJ["timeSlider"]["backDefaultSprite"].y = newCoor["y"];
				MOBJ["timeSlider"]["backgroundDefaultLoader"].width = newSize["width"];
				MOBJ["timeSlider"]["loadDefaultLoader"].width = newSize["width"];
				MOBJ["timeSlider"]["playDefaultLoader"].width = newSize["width"];
				trace(MOBJ["timeSlider"]["backDefaultSprite"].height);
				timePlaySliderChange(timeNow);
				timeLoadSliderChange(loadNow);
			}
			if (MOBJ.hasOwnProperty("timeOutSlider")) {
				//trace(MOBJ["timeOutSlider"]["backOutSprite"].width, "==");
				newCoor = coorDinate(STYLE["controlBar"]["timeSchedule"]["mouseOut"], MOBJ["timeOutSlider"]["backOutSprite"]);
				newSize = calculatedSize(STYLE["controlBar"]["timeSchedule"]["mouseOut"]["width"].toString(), MOBJ["timeOutSlider"]["backOutSprite"].height.toString(), MOBJ["controlBarBgColor"]);
				MOBJ["timeOutSlider"]["backOutSprite"].x = newCoor["x"];
				MOBJ["timeOutSlider"]["backOutSprite"].y = newCoor["y"];
				MOBJ["timeOutSlider"]["backgroundOutLoader"].width = newSize["width"];
				MOBJ["timeOutSlider"]["loadOutLoader"].width = newSize["width"];
				MOBJ["timeOutSlider"]["playOutLoader"].width = newSize["width"];

				timePlaySliderChange(timeNow);
				timeLoadSliderChange(loadNow);
			}
		}
		private function simpleScheduleResize() {
			//timeSliderResize
			/*
				MOBJ["timeSlider"] = {
					backDefaultSprite: backDefaultSprite,
					backgroundDefaultLoader: backgroundDefaultLoader,
					loadDefaultLoader: loadDefaultLoader,
					loadDefaultSprite: loadDefaultSprite,
					playDefaultLoader: playDefaultLoader,
					playDefaultSprite: playDefaultSprite,
					buttonDefaultLoader: buttonDefaultLoader
				};
			*/
			var newCoor: Object = {};
			var newSize: Object = {};
			if (MOBJ.hasOwnProperty("simpleSchedule")) {
				newCoor = coorDinate(STYLE["controlBar"]["hideControlBar"]["simpleSchedule"]);
				newSize = calculatedSize(STYLE["controlBar"]["hideControlBar"]["simpleSchedule"]["width"].toString(), MOBJ["simpleSchedule"]["backDefaultSprite"].height.toString());
				MOBJ["simpleSchedule"]["backDefaultSprite"].x = newCoor["x"];
				MOBJ["simpleSchedule"]["backDefaultSprite"].y = newCoor["y"];
				MOBJ["simpleSchedule"]["backgroundDefaultLoader"].width = newSize["width"];
				MOBJ["simpleSchedule"]["loadDefaultLoader"].width = newSize["width"];
				MOBJ["simpleSchedule"]["playDefaultLoader"].width = newSize["width"];
				timePlaySimpleChange(timeNow);
				timeLoadSimpleChange(loadNow);
			}
		}

		private function mouseDownHandler(event: MouseEvent): void {
			STAGE.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			point = new Point(event.localX, event.localY);
			switch (event.currentTarget) {
				case MOBJ["timeSlider"]["buttonDefaultLoader"]:
					if (timeTotal == 0 || FLASHVARS["live"] || CONFIG["config"]["timeScheduleAdjust"] == 0) {
						break;
					}
					mouseDownName = "time";
					timeFollow = false;
					buttonDown = true;
					trace("是否跟着走timeFollow02", timeFollow);
					mUpSeek = true;
					//trace("a");
					MOBJ["timeSlider"]["buttonDefaultLoader"].addEventListener(Event.ENTER_FRAME, enterFrameHandler);
					break;
				case MOBJ["volumeSlider"]["buttonLoader"]:
					mouseDownName = "volume";
					MOBJ["volumeSlider"]["buttonLoader"].addEventListener(Event.ENTER_FRAME, enterFrameHandler);
					break;
				default:
					break;
			}

		}
		private function enterFrameHandler(event: Event): void {
			if (point != null) {
				var newX: int = 0;
				switch (mouseDownName) {
					case "time":
						var btW: Number = MOBJ["timeSlider"]["buttonDefaultLoader"].width;
						var bkW: Number = MOBJ["timeSlider"]["backgroundDefaultLoader"].width;
						if (timeTotal == 0 || FLASHVARS["live"] || CONFIG["config"]["timeScheduleAdjust"] == 0) {
							return;
						}
						newX = MOBJ["timeSlider"]["backDefaultSprite"].mouseX - point.x;
						if (point.x > btW * 0.5) {
							newX += (point.x - btW * 0.5);
						} else {
							newX -= (btW * 0.5 - point.x);
						}
						if (newX < 0) {
							newX = 0;
						}
						//trace(newX);
						var seekTimeTemp = (newX - MOBJ["timeSlider"]["backDefaultSprite"].x) * timeTotal / (bkW - btW);
						//trace("seekTimeTemp",seekTimeTemp,MOBJ["timeSlider"]["backDefaultSprite"].x,MOBJ["timeSlider"]["backDefaultSprite"].width);
						var isSeek: Boolean = true;
						switch (CONFIG["config"]["timeScheduleAdjust"]) {
							case 0:
								isSeek = false;
								break;
							case 2:
								if (seekTimeTemp < timeNow) {
									isSeek = false;
								}
								break;
							case 3:
								if (seekTimeTemp > timeNow) {
									isSeek = false;
								}
								break;
							case 4:
								//trace(timeSeek);
								if (timeSeek > -1) {
									if (seekTimeTemp < timeSeek) {
										isSeek = false;
									}
								} else {
									if (seekTimeTemp < timeNow) {
										isSeek = false;
									}
								}
								break;
							case 5:
								if (seekTimeTemp > timeMax) {
									isSeek = false;
								}
								break;
						}
						//trace("-------------------",isSeek);
						if (!isSeek) {
							mUpSeek = false;
							break;
						} else {
							mUpSeek = true;
						}
						if (newX >= bkW - btW) {
							newX = bkW - btW;
						}
						MOBJ["timeSlider"]["buttonDefaultLoader"].x = newX;
						MOBJ["timeSlider"]["playDefaultSprite"].width = newX + btW * 0.5;
						//seekTime = (newX*timeTotal)/(bkW-btW);
						if (seekTime < 0) {
							seekTime = 0;
						}
						if (seekTime > timeTotal - 1) {
							seekTime = 0;
						}
						//trace("要跳转的时间",seekTime);
						break;
					case "volume":
						newX = MOBJ["volumeSlider"]["backSprite"].mouseX - point.x;
						if (point.x > MOBJ["volumeSlider"]["buttonLoader"].width * 0.5) {
							newX += (point.x - MOBJ["volumeSlider"]["buttonLoader"].width * 0.5);
						} else {
							newX -= (MOBJ["volumeSlider"]["buttonLoader"].width * 0.5 - point.x);
						}
						if (newX < 0) {
							newX = 0;
						}
						if (newX >= MOBJ["volumeSlider"]["backSprite"].width - MOBJ["volumeSlider"]["buttonLoader"].width) {
							newX = MOBJ["volumeSlider"]["backSprite"].width - MOBJ["volumeSlider"]["buttonLoader"].width;
							MOBJ["volumeSlider"]["maskSprite"].width = MOBJ["volumeSlider"]["backSprite"].width;
						} else {
							MOBJ["volumeSlider"]["maskSprite"].width = newX + MOBJ["volumeSlider"]["buttonLoader"].width * 0.5
						}
						MOBJ["volumeSlider"]["buttonLoader"].x = newX;
						var vol: Number = Math.round(MOBJ["volumeSlider"]["buttonLoader"].x * 100 / (MOBJ["volumeSlider"]["backSprite"].width - MOBJ["volumeSlider"]["buttonLoader"].width)) * 0.01;
						if (vol > 1) {
							vol = 1;
						}
						if (vol < 0) {
							vol = 0;
						}
						volumeTemp = vol;
						THIS["changeVolume"](vol, false); //调用主程序里的调节音量并且不改变调用滑块
						muteOrEscMute(vol);
						break;
					default:
						break;
				}
			}
		}
		private function mouseUpHandler(event: MouseEvent): void {
			point = null;
			switch (mouseDownName) {
				case "time":
					//trace(timeTotal);
					buttonDown = false;
					if (timeTotal == 0 || FLASHVARS["live"] || CONFIG["config"]["timeScheduleAdjust"] == 0) {
						return;
					}
					MOBJ["timeSlider"]["buttonDefaultLoader"].removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
					//trace("+++++++++++++++++",mUpSeek);
					if (mUpSeek) {
						//trace("要跳转的秒数来之Up", seekTime);
						THIS["videoSeek"](seekTime, false); //调用主程序里的Seek并且不改变调用滑块
					} else {
						timeFollow = true;
					}
					break;
				case "volume":
					MOBJ["volumeSlider"]["buttonLoader"].removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
					break;
				default:
					break;
			}
			//showTips(null, "");
			STAGE.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
		}

		private function loadVolumeSlider(): void {
			//音量调节滑块
			var volume: Object = STYLE["controlBar"]["volumeSchedule"];
			var backgroundLoader: Loader = null,
				maskLoader: Loader = null,
				buttonLoader: Sprite = null,
				backSprite: Sprite = null,
				maskSprite: Sprite = null;
			function loadBackgroundImg(): void {
				loaderNum++;
				var backgroundImgLoader: loadByteImg = new loadByteImg(volume["backgroundImg"], function (byte: Loader = null) {
					if (byte) {
						backgroundLoader = byte;
						loadMaskImg();
					} else {
						new log("error:Failed to load STYLE[\"controlBar\"][\"volume\"][\"background\"][\"backgroundImg\"]");

					}
					imgLoaded();
					backgroundImgLoader = null;
				});
			}
			function loadMaskImg(): void {
				loaderNum++;
				var maskImgLoader: loadByteImg = new loadByteImg(volume["maskImg"], function (byte: Loader = null) {
					if (byte) {
						maskLoader = byte;
						loadButtonImg()
					} else {
						new log("error:Failed to load STYLE[\"controlBar\"][\"volume\"][\"maskImg\"][\"backgroundImg\"]");

					}
					loadButtonImg();
					imgLoaded();
					maskImgLoader = null;
				});
			}
			function loadButtonImg(): void {
				loaderNum++;
				buttonLoader = element.imgButton(volume["button"], "volumeSchedule", function () {
					loadButtonHandler();
					imgLoaded();

				});
			}
			function loadButtonHandler(): void {
				var sObj: Object = {
					backgroundColor: 0xFF0000, //背景颜色
					backgroundAlpha: 0, //背景透明度
					width: backgroundLoader.width,
					height: backgroundLoader.height > buttonLoader.height ? backgroundLoader.height : buttonLoader.height
				};
				backSprite = element.newSprite(sObj);
				if (CONFIG["config"]["buttonMode"]["volumeSchedule"]) {
					backSprite.buttonMode = true;
				}
				maskSprite = element.newSprite(sObj);
				backgroundLoader.y = (backSprite.height - backgroundLoader.height) * 0.5;
				backSprite.addChild(backgroundLoader);
				maskLoader.y = (backSprite.height - maskLoader.height) * 0.5;
				backSprite.addChild(maskLoader);
				backSprite.addChild(maskSprite);
				maskLoader.mask = maskSprite;
				buttonLoader.y = (backSprite.height - buttonLoader.height) * 0.5;
				backSprite.addChild(buttonLoader);
				M.addChild(backSprite);
				MOBJ["volumeSlider"] = {
					backSprite: backSprite,
					backgroundLoader: backgroundLoader,
					maskLoader: maskLoader,
					maskSprite: maskSprite,
					buttonLoader: buttonLoader
				};
				volumeSliderResize();
				volumeSliderChange(FLASHVARS["volume"]);
				buttonLoader.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
				backgroundLoader.addEventListener(MouseEvent.CLICK, mouseClickHandler);
				maskLoader.addEventListener(MouseEvent.CLICK, mouseClickHandler);
				backgroundLoader.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
				maskLoader.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
				buttonLoader.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
				backSprite.addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);

			}
			if (volume.hasOwnProperty("backgroundImg") && volume["backgroundImg"]) {
				loadBackgroundImg();
			}
		}
		//时间进度调节滑动条
		private function loadTimeSlider(): void {
			var timeSchedule: Object = STYLE["controlBar"]["timeSchedule"];
			var defaultSchedule: Object = {}, outSchedule: Object = {};
			var backgroundDefaultLoader: Loader = null,
				loadDefaultLoader: Loader = null,
				playDefaultLoader: Loader = null,
				buttonDefaultLoader: Sprite = null,
				backDefaultSprite: Sprite = null,
				loadDefaultSprite: Sprite = null,
				playDefaultSprite: Sprite = null;
			var backgroundOutLoader: Loader = null,
				loadOutLoader: Loader = null,
				playOutLoader: Loader = null,
				buttonOutLoader: Sprite = null,
				backOutSprite: Sprite = null,
				loadOutSprite: Sprite = null,
				playOutSprite: Sprite = null;
			function loadDefaultBackgroundImg(): void {
				loaderNum++;
				var backgroundImgDefaultLoader: loadByteImg = new loadByteImg(defaultSchedule["backgroundImg"], function (byte: Loader = null) {
					if (byte) {
						backgroundDefaultLoader = byte;
						loadDefaultLoadImg();
					} else {
						new log("error:Failed to load STYLE[\"controlBar\"][\"timeSchedule\"][\"default\"][\"background\"][\"backgroundImg\"]");

					}
					imgLoaded();
					backgroundImgDefaultLoader = null;
				});
			}
			function loadDefaultLoadImg(): void {
				loaderNum++;
				var loadImgDefaultLoader: loadByteImg = new loadByteImg(defaultSchedule["loadProgressImg"], function (byte: Loader = null) {
					if (byte) {
						loadDefaultLoader = byte;
						loadDefaultPlayImg();
					} else {
						new log("error:Failed to load STYLE[\"controlBar\"][\"timeSchedule\"][\"default\"][\"background\"][\"loadProgressImg\"]");

					}
					imgLoaded();
					loadImgDefaultLoader = null;
				});
			}
			function loadDefaultPlayImg(): void {
				loaderNum++;
				var playImgDefaultLoader: loadByteImg = new loadByteImg(defaultSchedule["playProgressImg"], function (byte: Loader = null) {
					if (byte) {
						playDefaultLoader = byte;
						loadDefaultButtonImg();
					} else {
						new log("error:Failed to load STYLE[\"controlBar\"][\"timeSchedule\"][\"default\"][\"background\"][\"playProgressImg\"]");

					}
					imgLoaded();
					playImgDefaultLoader = null;
				});
			}
			function loadDefaultButtonImg(): void {
				loaderNum++;
				buttonDefaultLoader = element.imgButton(timeSchedule["button"], "timeSchedule", function () {
					if (timeSchedule.hasOwnProperty("mouseOut") && timeSchedule["mouseOut"]) {
						outSchedule = timeSchedule["mouseOut"];
						loadOutBackgroundImg();
					} else {
						loadButtonHandler();
					}
					imgLoaded();

				});
			}
			//----------------------------加载鼠标离开进度条

			function loadOutBackgroundImg(): void {
				loaderNum++;
				var backgroundImgOutLoader: loadByteImg = new loadByteImg(outSchedule["backgroundImg"], function (byte: Loader = null) {
					if (byte) {
						backgroundOutLoader = byte;
						loadOutLoadImg();
					} else {
						new log("error:Failed to load STYLE[\"controlBar\"][\"timeSchedule\"][\"out\"][\"background\"][\"backgroundImg\"]");

					}
					imgLoaded();
					backgroundImgOutLoader = null;
				});
			}
			function loadOutLoadImg(): void {
				loaderNum++;
				var loadImgOutLoader: loadByteImg = new loadByteImg(outSchedule["loadProgressImg"], function (byte: Loader = null) {
					if (byte) {
						loadOutLoader = byte;
						loadOutPlayImg();
					} else {
						new log("error:Failed to load STYLE[\"controlBar\"][\"timeSchedule\"][\"out\"][\"background\"][\"loadProgressImg\"]");

					}
					imgLoaded();
					loadImgOutLoader = null;
				});
			}
			function loadOutPlayImg(): void {
				loaderNum++;
				var playImgOutLoader: loadByteImg = new loadByteImg(outSchedule["playProgressImg"], function (byte: Loader = null) {
					if (byte) {
						playOutLoader = byte;
					} else {
						new log("error:Failed to load STYLE[\"controlBar\"][\"timeSchedule\"][\"out\"][\"background\"][\"playProgressImg\"]");

					}
					loadButtonHandler();
					imgLoaded();
					playImgOutLoader = null;
				});
			}

			//----------------------------加载鼠标离开进度条结束
			function loadButtonHandler(): void {

				var sObj: Object = {};
				//----------------------
				if (timeSchedule.hasOwnProperty("mouseOut") && timeSchedule["mouseOut"]) {
					sObj = {
						backgroundColor: 0xFF0000, //背景颜色
						backgroundAlpha: 0, //背景透明度
						width: 11,
						height: backgroundOutLoader.height
					};
					backOutSprite = element.newSprite(sObj);
					loadOutSprite = element.newSprite(sObj);
					playOutSprite = element.newSprite(sObj);

					backOutSprite.addChild(backgroundOutLoader);
					backgroundOutLoader.y = (backOutSprite.height - backgroundOutLoader.height) * 0.5;
					backOutSprite.addChild(loadOutLoader);
					loadOutLoader.y = (backOutSprite.height - loadOutLoader.height) * 0.5;
					backOutSprite.addChild(loadOutSprite);
					loadOutLoader.mask = loadOutSprite;
					backOutSprite.addChild(playOutLoader);

					playOutLoader.y = (backOutSprite.height - playOutLoader.height) * 0.5;

					backOutSprite.addChild(playOutSprite);
					playOutLoader.mask = playOutSprite;

					M.addChild(backOutSprite);
					MOBJ["timeOutSlider"] = {
						backOutSprite: backOutSprite,
						backgroundOutLoader: backgroundOutLoader,
						loadOutLoader: loadOutLoader,
						loadOutSprite: loadOutSprite,
						playOutLoader: playOutLoader,
						playOutSprite: playOutSprite
					};
					MOBJ["timeOutSlider"]["backOutSprite"].alpha = 0;
					backgroundOutLoader.addEventListener(MouseEvent.CLICK, mouseClickHandler);
					loadOutLoader.addEventListener(MouseEvent.CLICK, mouseClickHandler);
					playOutLoader.addEventListener(MouseEvent.CLICK, mouseClickHandler);
					backgroundOutLoader.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
					loadOutLoader.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
					playOutLoader.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
				}
				//---------------------
				sObj = {
					backgroundColor: 0xFF0000, //背景颜色
					backgroundAlpha: 0, //背景透明度
					width: 11,
					height: backgroundDefaultLoader.height > buttonDefaultLoader.height ? backgroundDefaultLoader.height : buttonDefaultLoader.height
				};
				backDefaultSprite = element.newSprite(sObj);
				if (CONFIG["config"]["buttonMode"]["timeSchedule"]) {
					backDefaultSprite.buttonMode = true;
				}
				loadDefaultSprite = element.newSprite(sObj);
				playDefaultSprite = element.newSprite(sObj);
				backDefaultSprite.addChild(backgroundDefaultLoader);
				backgroundDefaultLoader.y = (backDefaultSprite.height - backgroundDefaultLoader.height) * 0.5;
				backDefaultSprite.addChild(loadDefaultLoader);
				loadDefaultLoader.y = (backDefaultSprite.height - loadDefaultLoader.height) * 0.5;
				backDefaultSprite.addChild(loadDefaultSprite);
				loadDefaultLoader.mask = loadDefaultSprite;
				backDefaultSprite.addChild(playDefaultLoader);
				playDefaultLoader.y = (backDefaultSprite.height - playDefaultLoader.height) * 0.5;
				backDefaultSprite.addChild(playDefaultSprite);
				playDefaultLoader.mask = playDefaultSprite;
				backDefaultSprite.addChild(buttonDefaultLoader);
				buttonDefaultLoader.y = (backDefaultSprite.height - buttonDefaultLoader.height) * 0.5;
				M.addChild(backDefaultSprite);
				MOBJ["timeSlider"] = {
					backDefaultSprite: backDefaultSprite,
					backgroundDefaultLoader: backgroundDefaultLoader,
					loadDefaultLoader: loadDefaultLoader,
					loadDefaultSprite: loadDefaultSprite,
					playDefaultLoader: playDefaultLoader,
					playDefaultSprite: playDefaultSprite,
					buttonDefaultLoader: buttonDefaultLoader
				};
				//M.addEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler);
				//M.addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
				buttonDefaultLoader.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
				backgroundDefaultLoader.addEventListener(MouseEvent.CLICK, mouseClickHandler);
				loadDefaultLoader.addEventListener(MouseEvent.CLICK, mouseClickHandler);
				playDefaultLoader.addEventListener(MouseEvent.CLICK, mouseClickHandler);

				backgroundDefaultLoader.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
				loadDefaultLoader.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
				playDefaultLoader.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
				buttonDefaultLoader.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
				backDefaultSprite.addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
				STAGE.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler); //注册鼠标经过屏幕时的动作
				timeSliderResize();
			}
			if (timeSchedule.hasOwnProperty("default") && timeSchedule["default"]) {
				defaultSchedule = timeSchedule["default"];
				loadDefaultBackgroundImg();
			}
		}
		//时间进度调节滑动条
		private function loadSimpleSchedule(): void {
			var defaultSchedule: Object = {};
			if (STYLE["controlBar"].hasOwnProperty("hideControlBar")) {
				if (STYLE["controlBar"]["hideControlBar"]["showSimpleSchedule"] != "none") {
					defaultSchedule = STYLE["controlBar"]["hideControlBar"]["simpleSchedule"];
				} else {
					return;
				}
			} else {
				return;
			}
			var backgroundDefaultLoader: Loader = null,
				loadDefaultLoader: Loader = null,
				playDefaultLoader: Loader = null,
				buttonDefaultLoader: Sprite = null,
				backDefaultSprite: Sprite = null,
				loadDefaultSprite: Sprite = null,
				playDefaultSprite: Sprite = null;

			function loadDefaultBackgroundImg(): void {
				loaderNum++;
				var backgroundImgDefaultLoader: loadByteImg = new loadByteImg(defaultSchedule["backgroundImg"], function (byte: Loader = null) {
					if (byte) {
						backgroundDefaultLoader = byte;
						loadDefaultLoadImg();
					} else {
						new log("error:Failed to load STYLE[\"controlBar\"][\"simpleSchedule\"][\"background\"][\"backgroundImg\"]");

					}
					imgLoaded();
					backgroundImgDefaultLoader = null;

				});
			}
			function loadDefaultLoadImg(): void {
				loaderNum++;
				var loadImgDefaultLoader: loadByteImg = new loadByteImg(defaultSchedule["loadProgressImg"], function (byte: Loader = null) {
					if (byte) {
						loadDefaultLoader = byte;
						loadDefaultPlayImg();
					} else {
						new log("error:Failed to load STYLE[\"controlBar\"][\"simpleSchedule\"][\"background\"][\"loadProgressImg\"]");

					}
					imgLoaded();
					loadImgDefaultLoader = null;
				});
			}
			function loadDefaultPlayImg(): void {
				loaderNum++;
				var playImgDefaultLoader: loadByteImg = new loadByteImg(defaultSchedule["playProgressImg"], function (byte: Loader = null) {
					if (byte) {
						playDefaultLoader = byte;
						loadDefaultHandler();
					} else {
						new log("error:Failed to load STYLE[\"controlBar\"][\"simpleSchedule\"][\"background\"][\"playProgressImg\"]");

					}
					imgLoaded();
					playImgDefaultLoader = null;
				});
			}

			function loadDefaultHandler(): void {

				var sObj: Object = {
					backgroundColor: 0xFF0000, //背景颜色
					backgroundAlpha: 0, //背景透明度
					width: 11,
					height: backgroundDefaultLoader.height
				};

				backDefaultSprite = element.newSprite(sObj);
				loadDefaultSprite = element.newSprite(sObj);
				playDefaultSprite = element.newSprite(sObj);
				backDefaultSprite.addChild(backgroundDefaultLoader);
				backgroundDefaultLoader.y = (backDefaultSprite.height - backgroundDefaultLoader.height) * 0.5;
				backDefaultSprite.addChild(loadDefaultLoader);
				loadDefaultLoader.y = (backDefaultSprite.height - loadDefaultLoader.height) * 0.5;
				backDefaultSprite.addChild(loadDefaultSprite);
				loadDefaultLoader.mask = loadDefaultSprite;
				backDefaultSprite.addChild(playDefaultLoader);
				playDefaultLoader.y = (backDefaultSprite.height - playDefaultLoader.height) * 0.5;
				backDefaultSprite.addChild(playDefaultSprite);
				playDefaultLoader.mask = playDefaultSprite;
				THIS.addChild(backDefaultSprite);
				backDefaultSprite.visible = false;
				MOBJ["simpleSchedule"] = {
					backDefaultSprite: backDefaultSprite,
					backgroundDefaultLoader: backgroundDefaultLoader,
					loadDefaultLoader: loadDefaultLoader,
					loadDefaultSprite: loadDefaultSprite,
					playDefaultLoader: playDefaultLoader,
					playDefaultSprite: playDefaultSprite
				};
				//script.traceObject(MOBJ);
				simpleScheduleResize();
			}
			loadDefaultBackgroundImg();
		}
		//获取当前播放时间
		private function getFormatTime(timeStr: String, nowTime: Number = -1): String {
			var nowDate: Date = new Date();
			if (C.CONFIG["config"]["time"] > 0) {
				//trace(C.CONFIG["config"]["time"]);
				nowDate = new Date(C.CONFIG["config"]["time"]);
			}
			//trace(nowDate);
			var yearY: int = nowDate.fullYear;
			var month: int = nowDate.month + 1;
			var date: int = nowDate.date;
			var hours: int = nowDate.hours;
			var minutes: int = nowDate.minutes;
			var seconds: int = nowDate.seconds;

			var yeary: String = yearY.toString().substr(2, 2);
			var monthh: String = month < 10 ? "0" + month : month.toString();
			var datee: String = date < 10 ? "0" + date : date.toString();
			var hourss: String = hours < 10 ? "0" + hours : hours.toString();
			var minutess: String = minutes < 10 ? "0" + minutes : minutes.toString();
			var secondss: String = seconds < 10 ? "0" + seconds : seconds.toString();
			/*liveTimey:yeary,//liveTimey
				liveTimeY:yearY,
				liveTimem:monthh,
				liveTimed:hourss,
				liveTimeh:hourss,
				liveTimei:minutess,
				liveTimes:secondss,*/
			//trace(nowTime , timeNow);
			var timeArr: Array = script.formatTime(nowTime > -1 ? nowTime : timeNow, C.CONFIG["config"]["liveAndVod"]["open"] ? C.CONFIG["config"]["liveAndVod"]["vodTime"] : 0, C.CONFIG["config"]["liveAndVod"]["open"] ? hours : 0);
			//trace(timeArr);
			var totalArr: Array = script.formatTime(timeTotal);
			for (var i: int = 0; i < totalArr.length; i++) {
				timeArr.push(totalArr[i]);
			}
			timeArr.push(yeary, yearY, monthh, datee, hourss, minutess, secondss);
			timeArr.push(LANGUAGE["live"]);
			timeArr.push(LANGUAGE["vod"]);
			//timeArr.push(LANGUAGE["vod"]);
			//timeArr.push(LANGUAGE["liveAndVod"]);
			var timeStrArr: Array = ["[$timeh]", "[$timei]", "[$timeI]", "[$times]", "[$timeS]", "[$durationh]", "[$durationi]", "[$durationI]", "[$durations]", "[$durationS]",
				"[$liveTimey]", "[$liveTimeY]", "[$liveTimem]", "[$liveTimed]", "[$liveTimeh]", "[$liveTimei]", "[$liveTimes]", "[$liveLanguage]", "[$vodLanguage]"
			];
			//trace(timeStrArr);
			if (FLASHVARS["live"]) {
				return script.strReplace(script.strReplace(LANGUAGE["live"], timeStrArr, timeArr), timeStrArr, timeArr);
			} else if (C.CONFIG["config"]["liveAndVod"]["open"]) {
				return script.strReplace(script.strReplace(LANGUAGE["liveAndVod"], timeStrArr, timeArr), timeStrArr, timeArr);
			} else {
				return script.strReplace(script.strReplace(timeStr, timeStrArr, timeArr), timeStrArr, timeArr);
				
			}

		}
		//获取当前播放时间
		private function getFormatLiveTime(): Object {
			var nowDate: Date = new Date();
			if (C.CONFIG["config"]["time"] > 0) {
				nowDate = new Date(C.CONFIG["config"]["time"]);
			}
			var hours: int = nowDate.hours;
			var minutes: int = nowDate.minutes;
			var seconds: int = nowDate.seconds;
			return {
				hours: hours,
				minutes: minutes,
				seconds: seconds
			};
		}
		//调整点播时间文本框
		private function vodTimeTextResize(): void {
			if (MOBJ.hasOwnProperty("timeVodText") && MOBJ["timeVodText"] != null) {
				var timeTextArr: Array = MOBJ["timeVodText"];
				var timeText: Object = STYLE["controlBar"]["timeText"]["vod"];
				var vodArr: Array = [];
				if (script.getType(timeText) != "array") {
					vodArr.push(timeText);
				} else {
					vodArr = STYLE["controlBar"]["timeText"]["vod"];
				}
				for (var i: int = 0; i < timeTextArr.length; i++) {
					var coor: Object = coorDinate(vodArr[i]);
					timeTextArr[i].x = coor["x"];
					timeTextArr[i].y = coor["y"];
					M.addChild(timeTextArr[i]);
				}
			}
		}
		//调整直播时间文本框
		private function liveTimeTextResize(): void {
			if (MOBJ.hasOwnProperty("timeLiveText") && MOBJ["timeLiveText"] != null) {
				var timeTextArr: Array = MOBJ["timeLiveText"];
				var timeText: Object = STYLE["controlBar"]["timeText"]["live"];
				var liveArr: Array = [];
				if (script.getType(timeText) != "array") {
					liveArr.push(timeText);
				} else {
					liveArr = STYLE["controlBar"]["timeText"]["live"];
				}
				for (var i: int = 0; i < timeTextArr.length; i++) {
					var coor: Object = coorDinate(liveArr[i]);
					timeTextArr[i].x = coor["x"];
					timeTextArr[i].y = coor["y"];
					M.addChild(timeTextArr[i]);
				}
			}
		}
		//加载点播时间文本框
		private function loadVodTimeText(): void {
			if (!STYLE["controlBar"]["timeText"].hasOwnProperty("vod")) {
				return;
			}
			var vodArr: Array = [];
			var textArr: Array = [];
			var timeTextArr: Array = [];
			if (script.getType(STYLE["controlBar"]["timeText"]["vod"]) != "array") {
				vodArr.push(STYLE["controlBar"]["timeText"]["vod"]);
			} else {
				vodArr = STYLE["controlBar"]["timeText"]["vod"];
			}
			for (var i: int = 0; i < vodArr.length; i++) {
				var obj: Object = {
					text: getFormatTime(vodArr[i]["text"]),
					color: vodArr[i]["color"],
					size: vodArr[i]["size"],
					font: vodArr[i]["font"],
					alpha: vodArr[i]["alpha"],
					bold: vodArr[i]["bold"]
				};
				var newText: TextField = element.newText(obj);
				M.addChild(newText);
				timeTextArr.push(newText);
			}
			MOBJ["timeVodText"] = timeTextArr;
			vodTimeTextResize();

		}

		//加载直播时间文本框
		private function loadLiveTimeText(): void {
			if (!STYLE["controlBar"]["timeText"].hasOwnProperty("live")) {
				return;
			}
			var timeText: Object = STYLE["controlBar"]["timeText"]["live"];
			var liveArr: Array = [];
			var textArr: Array = [];
			var timeTextArr: Array = [];
			if (script.getType(timeText) != "array") {
				liveArr.push(timeText);
			} else {
				liveArr = STYLE["controlBar"]["timeText"]["live"];
			}
			for (var i: int = 0; i < liveArr.length; i++) {
				var obj: Object = {
					text: getFormatTime(liveArr[i]["text"]),
					color: liveArr[i]["color"],
					size: liveArr[i]["size"],
					font: liveArr[i]["font"],
					alpha: liveArr[i]["alpha"],
					bold: liveArr[i]["bold"]
				};
				var newText: TextField = element.newText(obj);
				M.addChild(newText);
				timeTextArr.push(newText);
			}
			MOBJ["timeLiveText"] = timeTextArr;
			liveTimeTextResize();
		}
		//调用错误提示文本框
		private function errorShowResize(): void {
			if (errorText) {
				var coor: Object = coorDinate(STYLE["error"]);
				errorText.x = coor["x"];
				errorText.y = coor["y"];
			}
		}

		//加载全局自定义
		private function loadCustom(): void {
			var buttonObj: Object = {};
			var k: String = "";
			var obj: Object = {};
			var button: Sprite = null;
			if (STYLE.hasOwnProperty("custom")) {
				if (STYLE["custom"].hasOwnProperty("button")) {
					buttonObj = STYLE["custom"]["button"];
					for (k in buttonObj) {
						obj = buttonObj[k];
						if (obj.hasOwnProperty("mouseOut") && obj["mouseOver"]) {
							loaderNum++;
							button = element.imgButton(obj, k, imgLoaded);
							if (!MOBJ.hasOwnProperty("vcustomButton")) {
								MOBJ["vcustomButton"] = {};
							}
							MOBJ["vcustomButton"][k] = button
							if (STYLE["custom"]["button"][k].hasOwnProperty("show") && STYLE["custom"]["button"][k]["show"] == "false") {
								button.visible = false;
							}
							THIS.addChild(button);
							button.addEventListener(MouseEvent.MOUSE_OVER, function (event: MouseEvent) {
								//trace("event.target.name:",event.target.name);
								showVButtonCustomPrompt(event.target.name);
							});
							button.addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
							button.addEventListener(MouseEvent.CLICK, mouseClickHandler);
						}
					}
				}
				//加载自定义的文本
				if (STYLE["custom"].hasOwnProperty("text")) {
					buttonObj = STYLE["custom"]["text"];
					for (k in buttonObj) {
						obj = buttonObj[k];
						if (obj.hasOwnProperty("text")) {
							var textTemp: String = getFormatText(obj["text"]);
							if (textTemp) {
								var newText: TextField = element.newText({
									text: textTemp,
									color: obj["color"],
									size: obj["size"],
									font: obj["font"],
									alpha: obj["alpha"],
									bold: obj["bold"]
								});
								THIS.addChild(newText);
								if (!MOBJ.hasOwnProperty("vcustomText")) {
									MOBJ["vcustomText"] = {};
								}
								MOBJ["vcustomText"][k] = newText;
								if (STYLE["custom"]["text"][k].hasOwnProperty("show") && STYLE["custom"]["text"][k]["show"] == "false") {
									newText.visible = false;
								}
								loadCustomResize();
							}
							
						}
					}
				}
				//加载自定义的图片
				//trace("是否有自定义的图片",STYLE["custom"].hasOwnProperty("images"));
				if (STYLE["custom"].hasOwnProperty("images")) {
					buttonObj = STYLE["custom"]["images"];
					//trace(buttonObj);
					script.traceObject(buttonObj);
					for (k in buttonObj) {
						obj = buttonObj[k];
						
						if (obj.hasOwnProperty("img")) {
							loaderNum++;
							var imgLoader: loadByteImg = new loadByteImg(obj["img"], function (byte: Loader = null, myName: String = "") {
								//trace("===加载了吗");
								if (byte) {
									if (!MOBJ.hasOwnProperty("vcustomImages")) {
										MOBJ["vcustomImages"] = {};
									}
									MOBJ["vcustomImages"][byte.name] = byte;
									THIS.addChild(MOBJ["vcustomImages"][byte.name]);
									if (STYLE["custom"]["images"][byte.name].hasOwnProperty("show") && STYLE["custom"]["images"][byte.name]["show"] == "false") {
										MOBJ["vcustomImages"][byte.name].visible = false;
									}
									loadCustomResize();
								} else {
									new log("error:Failed to load STYLE[\"custom\"][\"images\"][\"" + myName + "\"]");

								}
								imgLoaded();
								imgLoader = null;
							}, k);
						}
					}
				}
				//加载自定义的swf插件
				if (STYLE["custom"].hasOwnProperty("swf")) {
					buttonObj = STYLE["custom"]["swf"];
					for (k in buttonObj) {
						obj = buttonObj[k];
						if (obj.hasOwnProperty("swf")) {
							loaderNum++;
							var swfLoader: loadByteImg = new loadByteImg(obj["swf"], function (byte: Loader = null, myName: String = "") {
								if (byte) {
									if (!MOBJ.hasOwnProperty("vcustomSwf")) {
										MOBJ["vcustomSwf"] = {};
									}
									MOBJ["vcustomSwf"][byte.name] = byte;
									THIS.addChild(MOBJ["vcustomSwf"][byte.name]);
									if (STYLE["custom"]["swf"][byte.name].hasOwnProperty("show") && STYLE["custom"]["swf"][byte.name]["show"] == "false") {
										MOBJ["vcustomSwf"][byte.name].visible = false;
									}
									//传递播放器对象
									var nObj: Object = STYLE["custom"]["swf"][byte.name];
									if (nObj.hasOwnProperty("callActionScript") && nObj["callActionScript"]) {
										var swfObj: Object = byte.content;
										if (swfObj.hasOwnProperty("setAppObj")) {
											if (swfObj.setAppObj.length == 2) {
												swfObj.setAppObj(THIS, byte.name);
											} else {
												swfObj.setAppObj(THIS);
											}
										} else {
											if (swfObj.hasOwnProperty("main")) {
												if (swfObj.main.setAppObj.length == 2) {
													swfObj.main.setAppObj(THIS, byte.name);
												} else {
													swfObj.main.setAppObj(THIS);
												}
											} else {
												new log("error:Cannot call function STYLE[\"custom\"][\"swf\"][\"" + myName + "\"][\"callActionScript\"]/" + nObj["callActionScript"] + "()");
											}
										}
										
										//
									}
									loadCustomResize();
									imgLoaded();
									//传递播放器对象结束
									controlBarResize();
								} else {
									new log("error:Failed to load STYLE[\"custom\"][\"swf\"][\"" + myName + "\"]");

								}
								swfLoader = null;
							}, k);
						}
					}
				}
			}
			loadCustomResize();
		}
		//加载前置后置广告
		private function loadAdvertisement(): void {
			var adObj: Object = STYLE["advertisement"];
			var button: Sprite = null;
			MOBJ["advertisement"] = {};
			var obj: Object = {};
			function loadAdBackground() {
				//加载纯色层
				//加载背景
				if (adObj.hasOwnProperty("background")) {
					var bgSprite: Sprite = null;
					var bg: Object = adObj["background"];
					var elementObj: Object = {
						backgroundColor: bg["backgroundColor"],
						backgroundAlpha: bg["alpha"],
						width: stageW,
						height: stageH
					};
					bgSprite = element.newSprite(elementObj);
					MOBJ["advertisement"]["background"] = bgSprite;
				}
				loadAdCountDown();
			}
			function loadAdCountDown() {
				//广告倒计时背景

				if (adObj.hasOwnProperty("countDown")) {

					var countDown: Object = adObj["countDown"];
					if (countDown.hasOwnProperty("backgroundImg")) {
						loaderNum++;
						var backgroundImgLoader: loadByteImg = new loadByteImg(countDown["backgroundImg"], function (byte: Loader = null) {
							if (byte) {
								byte.alpha = countDown["alpha"];
								byte.width = countDown["width"];
								byte.height = countDown["height"];
								THIS.addChild(byte);
								byte.visible = false;
								MOBJ["advertisement"]["countDown"] = byte;
							} else {
								new log("error:Failed to load STYLE[\"advertisement\"][\"countDown\"][\"backgroundImg\"]");
							}
							imgLoaded();
							skipAdButtonLoad();
							advertisementResize();
							backgroundImgLoader = null;
						});
					} else {
						var mObj: Object = {
							backgroundColor: countDown["backgroundColor"],
							backgroundAlpha: (countDown.hasOwnProperty("backgroundImg") && countDown["backgroundImg"]) ? 0 : countDown["alpha"], //背景透明度
							width: countDown["width"],
							height: countDown["height"],
							radius: countDown["radius"]
						};
						var background: Sprite = element.newSprite(mObj);
						MOBJ["advertisement"]["countDown"] = background;
						advertisementResize();
						skipAdButtonLoad();
					}
				} else {
					skipAdButtonLoad();
				}
				advertisementResize();
			}
			function skipAdButtonLoad() {
				if (adObj.hasOwnProperty("skipAdButton")) {
					obj = adObj["skipAdButton"];
					if (obj.hasOwnProperty("mouseOut") && obj["mouseOver"]) {
						loaderNum++;
						button = element.imgButton(obj, "skipAdButton", imgLoaded);
						MOBJ["advertisement"]["skipAdButton"] = button
						button.addEventListener(MouseEvent.CLICK, mouseClickHandler);
						advertisementResize();
					}
				}
				loadAdSkipDelay();

			}
			function loadAdSkipDelay() {
				//延时显示跳过广告按钮倒计时背景
				if (adObj.hasOwnProperty("skipDelay")) {
					var skipDelay: Object = adObj["skipDelay"];
					if (skipDelay.hasOwnProperty("backgroundImg")) {
						loaderNum++;
						var backgroundImgLoader: loadByteImg = new loadByteImg(skipDelay["backgroundImg"], function (byte: Loader = null) {
							if (byte) {
								byte.alpha = skipDelay["alpha"];
								byte.width = skipDelay["width"];
								byte.height = skipDelay["height"];
								MOBJ["advertisement"]["skipDelay"] = byte;
							} else {
								new log("error:Failed to load STYLE[\"advertisement\"][\"skipDelay\"][\"backgroundImg\"]");
							}
							imgLoaded();
							nuteButtonLoad();
							advertisementResize();
							backgroundImgLoader = null;
						});
					} else {
						var mObj: Object = {
							backgroundColor: skipDelay["backgroundColor"],
							backgroundAlpha: (skipDelay.hasOwnProperty("backgroundImg") && skipDelay["backgroundImg"]) ? 0 : skipDelay["alpha"], //背景透明度
							width: skipDelay["width"],
							height: skipDelay["height"],
							radius: skipDelay["radius"]
						};
						var background: Sprite = element.newSprite(mObj);
						MOBJ["advertisement"]["skipDelay"] = background;
						advertisementResize();
						nuteButtonLoad();
					}
				} else {
					nuteButtonLoad();
				}
				advertisementResize();
			}
			function nuteButtonLoad() {
				if (adObj.hasOwnProperty("muteButton") && adObj.hasOwnProperty("escMuteButton")) {
					obj = adObj["muteButton"];
					if (obj.hasOwnProperty("mouseOut") && obj["mouseOver"]) {
						loaderNum++;
						button = element.imgButton(obj, "muteButton", imgLoaded);
						MOBJ["advertisement"]["muteButton"] = button
						button.addEventListener(MouseEvent.CLICK, mouseClickHandler);
						advertisementResize();
					}
					obj = adObj["escMuteButton"];
					if (obj.hasOwnProperty("mouseOut") && obj["mouseOver"]) {
						loaderNum++;
						button = element.imgButton(obj, "escMuteButton", imgLoaded);
						MOBJ["advertisement"]["escMuteButton"] = button;
						button.addEventListener(MouseEvent.CLICK, mouseClickHandler);
						advertisementResize();
					}
				}
				closeButtonLoad();
			}
			function closeButtonLoad() {
				if (adObj.hasOwnProperty("closeButton")) {
					obj = adObj["closeButton"];
					if (obj.hasOwnProperty("mouseOut") && obj["mouseOver"]) {
						loaderNum++;
						button = element.imgButton(obj, "closeButton", imgLoaded);
						MOBJ["advertisement"]["closeButton"] = button;
						button.addEventListener(MouseEvent.CLICK, mouseClickHandler);
						advertisementResize();
					}
				}
				adLinkButtonLoad();
			}
			function adLinkButtonLoad() {
				if (adObj.hasOwnProperty("adLinkButton")) {
					obj = adObj["adLinkButton"];
					if (obj.hasOwnProperty("mouseOut") && obj["mouseOver"]) {
						loaderNum++;
						button = element.imgButton(obj, "adLinkButton", imgLoaded);
						MOBJ["advertisement"]["adLinkButton"] = button;
						button.visible = false;
						THIS.addChild(button);
						button.addEventListener(MouseEvent.CLICK, mouseClickHandler);

					}
					advertisementResize();
				} else {
					advertisementResize();
				}
			}
			loadAdBackground();
		}

		//广告相关的变化
		private function advertisementResize(): void {
			if (MOBJ.hasOwnProperty("advertisement")) {
				var adObj: Object = STYLE["advertisement"];
				var advertisement: Object = MOBJ["advertisement"];
				var newCoor: Object = {};
				if (advertisement.hasOwnProperty("background")) {
					advertisement["background"].width = stageW;
					advertisement["background"].height = stageH;
				}
				for (var k: String in advertisement) {
					if (k != "background") {
						if (k != "closeButton") {
							newCoor = coorDinate(adObj[k]);
						} else {
							newCoor = coorDinate(adObj[k], pause);
							newCoor["x"] += pause.x;
							newCoor["y"] += pause.y;
							if (newCoor["x"] < 0) {
								newCoor["x"] = 0;
							}
							if (newCoor["x"] > stageW - MOBJ["advertisement"]["closeButton"].width) {
								newCoor["x"] = stageW - MOBJ["advertisement"]["closeButton"].width;
							}
							if (newCoor["y"] < 0) {
								newCoor["y"] = 0;
							}
							if (newCoor["y"] > stageH - MOBJ["advertisement"]["closeButton"].height) {
								newCoor["y"] = stageH - MOBJ["advertisement"]["closeButton"].height;
							}
						}
						MOBJ["advertisement"][k].x = newCoor["x"];
						MOBJ["advertisement"][k].y = newCoor["y"];
					}
				}

			}
		}

		//加载中间播放按钮
		private function centerPlayResize(): void {
			if (MOBJ.hasOwnProperty("centerPlay")) {
				var newCoor: Object = coorDinate(STYLE["centerPlay"]);
				MOBJ["centerPlay"].x = newCoor["x"];
				MOBJ["centerPlay"].y = newCoor["y"];
			}
		}

		//加载控制栏按钮
		private function loadControlBarButton(): void {
			var obj: Object = {};
			var buttonObj: Object = STYLE["controlBar"]["button"];
			var button: Sprite = null;
			var k: String = "";
			for (k in buttonObj) {
				obj = buttonObj[k];
				if (obj.hasOwnProperty("mouseOut") && obj["mouseOver"]) {
					loaderNum++;
					button = element.imgButton(obj, k, imgLoaded);
					if (!MOBJ.hasOwnProperty("button")) {
						MOBJ["button"] = {};
					}
					MOBJ["button"][k] = button
					M.addChild(button);
					button.addEventListener(MouseEvent.MOUSE_OVER, function (event: MouseEvent) {
						showButtonPrompt(event.target.name);
					});
					button.addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
					button.addEventListener(MouseEvent.CLICK, mouseClickHandler);
				}
			}
			if (FLASHVARS["autoplay"]) {
				MOBJ["button"]["play"].visible = false;
				MOBJ["button"]["pause"].visible = true;
			} else {
				MOBJ["button"]["play"].visible = true;
				MOBJ["button"]["pause"].visible = false;
			}
			if (FLASHVARS["volume"] > 0) {
				MOBJ["button"]["mute"].visible = true;
				MOBJ["button"]["escMute"].visible = false;
			} else {
				MOBJ["button"]["mute"].visible = false;
				MOBJ["button"]["escMute"].visible = true;
			}
			MOBJ["button"]["escFull"].visible = false;
			MOBJ["button"]["backLive"].visible = false;
			//加载中间播放按钮
			if (STYLE.hasOwnProperty("centerPlay")) {
				obj = STYLE["centerPlay"];
				if (obj.hasOwnProperty("mouseOut") && obj["mouseOver"]) {
					loaderNum++;
					button = element.imgButton(obj, "centerPlay", imgLoaded);
					MOBJ["centerPlay"] = button
					THIS.addChild(button);
					button.addEventListener(MouseEvent.CLICK, mouseClickHandler);
					centerPlayResize();
					showCenterPlay(false);
				}
			}
			//加载自定义的按钮
			if (STYLE["controlBar"].hasOwnProperty("custom")) {
				if (STYLE["controlBar"]["custom"].hasOwnProperty("button")) {
					buttonObj = STYLE["controlBar"]["custom"]["button"];
					for (k in buttonObj) {
						obj = buttonObj[k];
						if (obj.hasOwnProperty("mouseOut") && obj["mouseOut"]!="") {
							loaderNum++;
							button = element.imgButton(obj, k, imgLoaded);
							if (!MOBJ.hasOwnProperty("customButton")) {
								MOBJ["customButton"] = {};
							}
							MOBJ["customButton"][k] = button;
							if (STYLE["controlBar"]["custom"]["button"][k].hasOwnProperty("show") && STYLE["controlBar"]["custom"]["button"][k]["show"] == "false") {
								button.visible = false;
							}
							M.addChild(button);
							button.addEventListener(MouseEvent.MOUSE_OVER, function (event: MouseEvent) {
								showButtonCustomPrompt(event.target.name);
							});
							button.addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
							button.addEventListener(MouseEvent.CLICK, mouseClickHandler);
						}
					}
				}

				//加载自定义的文本
				if (STYLE["controlBar"]["custom"].hasOwnProperty("text")) {
					buttonObj = STYLE["controlBar"]["custom"]["text"];
					for (k in buttonObj) {
						obj = buttonObj[k];
						if (obj.hasOwnProperty("text")) {
							var textTemp: String = getFormatText(obj["text"]);
							if (textTemp) {
								var newText: TextField = element.newText({
									text: textTemp,
									color: obj["color"],
									size: obj["size"],
									font: obj["font"],
									alpha: obj["alpha"],
									bold: obj["bold"]
								});
								M.addChild(newText);

								if (!MOBJ.hasOwnProperty("customText")) {
									MOBJ["customText"] = {};
								}
								if (STYLE["controlBar"]["custom"]["text"][k].hasOwnProperty("show") && STYLE["controlBar"]["custom"]["text"][k]["show"] == "false") {
									newText.visible = false;
								}
								MOBJ["customText"][k] = newText
							}

						}
					}
				}
				//加载自定义的图片
				if (STYLE["controlBar"]["custom"].hasOwnProperty("images")) {
					buttonObj = STYLE["controlBar"]["custom"]["images"];
					for (k in buttonObj) {
						obj = buttonObj[k];
						if (obj.hasOwnProperty("img")) {
							loaderNum++;
							var imgLoader: loadByteImg = new loadByteImg(obj["img"], function (byte: Loader = null, myName: String = "") {
								if (byte) {
									if (!MOBJ.hasOwnProperty("customImages")) {
										MOBJ["customImages"] = {};
									}
									MOBJ["customImages"][byte.name] = byte;
									if (STYLE["controlBar"]["custom"]["images"][byte.name].hasOwnProperty("show") && STYLE["controlBar"]["custom"]["images"][byte.name]["show"] == "false") {
										MOBJ["customImages"][byte.name].visible = false;
									}
									M.addChild(MOBJ["customImages"][byte.name]);
									controlBarResize();
								} else {
									new log("error:Failed to load STYLE[\"controlBar\"][\"custom\"][\"images\"][\"" + myName + "\"]");

								}
								imgLoaded();
								imgLoader = null;
							}, k);
						}
					}
				}
				//加载自定义的swf插件
				if (STYLE["controlBar"]["custom"].hasOwnProperty("swf")) {
					buttonObj = STYLE["controlBar"]["custom"]["swf"];
					for (k in buttonObj) {
						obj = buttonObj[k];
						if (obj.hasOwnProperty("swf")) {
							loaderNum++;
							var swfLoader: loadByteImg = new loadByteImg(obj["swf"], function (byte: Loader = null, myName: String = "") {
								if (byte) {
									if (!MOBJ.hasOwnProperty("customSwf")) {
										MOBJ["customSwf"] = {};
									}
									MOBJ["customSwf"][byte.name] = byte;
									if (STYLE["controlBar"]["custom"]["swf"][byte.name].hasOwnProperty("show") && STYLE["controlBar"]["custom"]["swf"][byte.name]["show"] == "false") {
										MOBJ["customSwf"][byte.name].visible = false;
									}
									M.addChild(MOBJ["customSwf"][byte.name]);
									//传递播放器对象
									var nObj: Object = STYLE["controlBar"]["custom"]["swf"][byte.name];
									if (nObj.hasOwnProperty("callActionScript") && nObj["callActionScript"]) {
										var swfObj: Object = byte.content;
										if (swfObj.hasOwnProperty("setAppObj")) {
											if (swfObj.setAppObj.length == 2) {
												swfObj.setAppObj(THIS, byte.name);
											} else {
												swfObj.setAppObj(THIS);
											}

										} else {
											if (swfObj.hasOwnProperty("main")) {
												if (swfObj.main.setAppObj.length == 2) {
													swfObj.main.setAppObj(THIS, byte.name);
												} else {
													swfObj.main.setAppObj(THIS);
												}
											} else {
												new log("error:Cannot call function STYLE[\"controlBar\"][\"custom\"][\"swf\"][\"" + myName + "\"][\"callActionScript\"]/" + nObj["callActionScript"] + "()");
											}
										}
										//
									}
									imgLoaded();
									//传递播放器对象结束
									controlBarResize();
								} else {
									new log("error:Failed to load STYLE[\"controlBar\"][\"custom\"][\"swf\"][\"" + myName + "\"]");

								}
								swfLoader = null;
							}, k);
						}
					}
				}
			}
			controlBarResize();

		}
		//格式化文本框里的内容
		private function getFormatText(str: String = ""): String {
			var newStr: String = "";
			if (str.substr(0, 11) == "[flashvars]") {
				newStr = script.strReplace(str, ["[flashvars]"], [""]);
				if (FLASHVARS.hasOwnProperty(newStr)) {
					newStr = FLASHVARS[newStr];
				} else {
					newStr = "";
				}
			} else {
				newStr = str;
			}
			return newStr;
		}
		private function imgLoaded(): void {
			imgButtonI++;
			if (imgButtonI > loaderNum - 1 && loaderNum > 1) {
				imgButtonI = -1000;
				mMinXY = getMMinXY();
				var index: int = 0;
				if (background["background"]) {
					index = 1;
				}
				intoFun(index);
			}
		}
		//-------------------------------------------------------------------------------------------提示框结束
		private function showButtonPrompt(k: String = ""): void {
			if (k && LANGUAGE["buttonOver"].hasOwnProperty(k)) {
				if (MOBJ["button"].hasOwnProperty(k)) {
					var x: int = MOBJ["button"][k].x + M.x + MOBJ["button"][k].width * 0.5;
					var y: int = MOBJ["button"][k].y + M.y;
					showPrompt(LANGUAGE["buttonOver"][k], x, y)
				}
			}
		}
		private function showButtonCustomPrompt(k: String = ""): void {
			if (k && LANGUAGE["buttonOver"].hasOwnProperty(k)) {
				//script.traceObject(MOBJ["customButton"]);
				if (MOBJ["customButton"].hasOwnProperty(k)) {
					var x: int = MOBJ["customButton"][k].x + M.x + MOBJ["customButton"][k].width * 0.5;
					var y: int = MOBJ["customButton"][k].y + M.y;
					showPrompt(LANGUAGE["buttonOver"][k], x, y)
				}
			}
		}
		private function showVButtonCustomPrompt(k: String = ""): void {
			if (k && LANGUAGE["buttonOver"].hasOwnProperty(k)) {
				//script.traceObject(MOBJ);
				
				if(MOBJ.hasOwnProperty("vcustomButton")){
					//trace("==========",MOBJ["vcustomButton"][k].x);
					if (MOBJ["vcustomButton"].hasOwnProperty(k)) {
						//trace("==========d",MOBJ["vcustomButton"][k].x);
						try{
							var x: int = MOBJ["vcustomButton"][k].x + MOBJ["vcustomButton"][k].width * 0.5;
							var y: int = MOBJ["vcustomButton"][k].y;
							showPrompt(LANGUAGE["buttonOver"][k], x, y);
						}
						catch(event:ErrorEvent){}
					}
				}
				
			}
		}
		private function showPrompt(str: String = "", x: int = 0, y: int = 0): void {
			if (prompt != null) {
				THIS.removeChild(prompt);
				prompt = null;
			}
			if (!str || !mShow) {
				return;
			}
			var promptObj: Object = STYLE["prompt"];
			var textObj: Object = {
				text: str,
				color: promptObj["color"],
				size: promptObj["size"],
				font: promptObj["font"],
				bold: promptObj["bold"],
				alpha: promptObj["alpha"]
			};
			var text: TextField = element.newText(textObj);
			var bgObj: Object = {
				backgroundColor: promptObj["backgroundColor"], //背景颜色
				backgroundAlpha: promptObj["backgroundAlpha"], //背景透明度
				border: promptObj["border"],
				borderColor: promptObj["borderColor"], //边框颜色
				radius: promptObj["radius"], //圆角弧度
				width: text.width + Number(promptObj["paddingLeft"]) + Number(promptObj["paddingRight"]),
				height: text.height + Number(promptObj["paddingTop"]) + Number(promptObj["paddingBottom"])
			}
			prompt = element.newSprite(bgObj);
			prompt.addChild(text);
			text.x = Number(promptObj["paddingLeft"]);
			text.y = Number(promptObj["paddingTop"]);
			//画倒三角
			var triangleObj: Object = {
				width: promptObj["triangleWidth"],
				height: promptObj["triangleHeight"],
				backgroundColor: promptObj["triangleBackgroundColor"],
				border: promptObj["triangleBorder"],
				borderColor: promptObj["triangleBorderColor"],
				alpha: promptObj["triangleAlpha"]
			};
			var triangle: Sprite = element.newTriangle(triangleObj);
			triangle.y = prompt.height + Number(promptObj["triangleDeviationY"]);
			triangle.x = (prompt.width - triangle.width) * 0.5 + Number(promptObj["triangleDeviationX"]);
			prompt.addChild(triangle);
			//倒三角结束
			prompt.x = x - prompt.width * 0.5;
			prompt.y = y - prompt.height - Number(promptObj["marginBottom"]);
			if (prompt.x < 0) {
				prompt.x = 0;
			}
			if (prompt.x > stageW - prompt.width) {
				prompt.x = stageW - prompt.width;
			}
			if (prompt.y < 0) {
				prompt.y = 0;
			}
			if (prompt.y > stageH - prompt.height) {
				prompt.y = stageH - prompt.height;
			}
			THIS.addChild(prompt);
		}
		//-------------------------------------------------------------------------------------------提示框结束
		//===========================================================================================预览图提示文字
		private function showPreviewPrompt(str: String = "", x: int = 0, y: int = 0): void {
			if (previewPrompt != null) {
				THIS.removeChild(previewPrompt);
				previewPrompt = null;
			}
			if (!str) {
				return;
			}
			var promptObj: Object = STYLE["previewPrompt"];
			var textObj: Object = {
				text: str,
				color: promptObj["color"],
				size: promptObj["size"],
				font: promptObj["font"],
				bold: promptObj["bold"],
				alpha: promptObj["alpha"]
				//height:160
			};
			if (Number(promptObj["textWidth"]) > 0) {
				textObj["width"] = Number(promptObj["textWidth"]);

			}
			if (Number(promptObj["textHeight"]) > 0) {
				textObj["height"] = Number(promptObj["textHeight"]);

			}
			var text: TextField = element.newText(textObj);

			var bgObj: Object = {
				backgroundColor: promptObj["backgroundColor"], //背景颜色
				backgroundAlpha: promptObj["backgroundAlpha"], //背景透明度
				border: promptObj["border"],
				borderColor: promptObj["borderColor"], //边框颜色
				radius: promptObj["radius"], //圆角弧度
				width: text.width + Number(promptObj["paddingLeft"]) + Number(promptObj["paddingRight"]),
				height: text.height + Number(promptObj["paddingTop"]) + Number(promptObj["paddingBottom"])
			}

			previewPrompt = element.newSprite(bgObj);
			previewPrompt.addChild(text);
			text.x = Number(promptObj["paddingLeft"]);
			text.y = Number(promptObj["paddingTop"]);
			var py: int = y - previewPrompt.height - Number(promptObj["marginBottom"]);
			if (preview) {
				py -= preview.height;
			} else {
				if (prompt) {
					py -= prompt.height + 10;
				}
			}
			previewPrompt.x = x - previewPrompt.width * 0.5;
			previewPrompt.y = py;

			if (previewPrompt.x < 0) {
				previewPrompt.x = 0;
			}
			if (previewPrompt.x > stageW - previewPrompt.width) {
				previewPrompt.x = stageW - previewPrompt.width;
			}
			if (previewPrompt.y < 0) {
				previewPrompt.y = 0;
			}
			if (previewPrompt.y > stageH - previewPrompt.height) {
				previewPrompt.y = stageH - previewPrompt.height;
			}
			//THIS.addChild(previewPrompt);
			if (preview) {
				THIS.addChildAt(previewPrompt, THIS.getChildIndex(preview) + 1);
			} else {
				THIS.addChild(previewPrompt);
			}

		}
		//-------------------------------------------------------------------------------------------控制栏结束
		//-------------------------------------------------------------------------------------------播放器背景
		private function backgroundResize(): void {
			//trace("import flash.display.StageDisplayState;",stageH);
			if (background["background"]) {
				var bg: Object = STYLE["background"];
				var obj: Object = {
					stageW: stageW,
					stageH: stageH,
					eleW: background["width"],
					eleH: background["height"],
					stretched: bg["stretched"],
					align: bg["align"],
					vAlign: bg["vAlign"],
					spacingLeft: bg["spacingLeft"],
					spacingTop: bg["spacingTop"],
					spacingRight: bg["spacingRight"],
					spacingBottom: bg["spacingBottom"]
				};
				var coor: Object = script.getCoor(obj);
				background["background"].x = coor["x"];
				background["background"].y = coor["y"];
				background["background"].width = coor["width"];
				background["background"].height = coor["height"];
			}
			if (clickSprite) {
				clickSprite.width = stageW;
				clickSprite.height = stageH;
			}
		}
		private function loadBackGround(): void { //加载窗体背景
			if (STYLE.hasOwnProperty("background")) {
				var bg: Object = STYLE["background"];
				var bgSprite: Sprite = null;
				var elementObj: Object = {};
				if (bg.hasOwnProperty("backgroundColor")) {
					elementObj = {
						backgroundColor: bg["backgroundColor"],
						backgroundAlpha: bg["alpha"],
						width: stageW,
						height: stageH
					};
					bgSprite = element.newSprite(elementObj);
					THIS.addChild(bgSprite);
					background = {
						background: bgSprite,
						width: bgSprite.width,
						height: bgSprite.height
					};
				}
				elementObj = {
					backgroundColor: 0xFFFFFF,
					backgroundAlpha: 0,
					width: stageW,
					height: stageH
				};
				clickSprite = element.newSprite(elementObj);
				clickSprite.addEventListener(MouseEvent.CLICK, mouseClickHandler);
				if (bg.hasOwnProperty("backgroundImg") && bg["backgroundImg"]) {
					if (bgSprite) {
						THIS.removeChild(bgSprite);
					}
					var bgLoader: Loader = null;
					loaderNum++;
					var newLoader: loadByteImg = new loadByteImg(bg["backgroundImg"], function (byte: Loader = null) {
						if (byte) {
							bgLoader = byte;
							bgLoader.alpha = bg["alpha"];
							THIS.addChild(bgLoader);
							background = {
								background: bgLoader,
								width: bgLoader.width,
								height: bgLoader.height
							};
						} else {
							new log("error:Failed to load STYLE[\"background\"][\"backgroundImg\"]");
						}
						THIS.addChild(clickSprite);
						backgroundResize();
						loadControlBar(); //加载控制栏
						imgLoaded();
						newLoader = null;
					});

				} else {
					THIS.addChild(clickSprite);
					backgroundResize();
					loadControlBar(); //加载控制栏
				}
				//clickSprite
			}
			pause = element.newSprite({
				backgroundColor: 0xFFFFFF,
				backgroundAlpha: 0,
				width: stageW,
				height: stageH
			});
		}
		//--------------------------------------------------------------------------------------------共用的调用事件
		private function callEvent(buttonStyle: String = "", callName: String = ""): void {
			var obj: Object = {};
			//trace(buttonStyle, callName);
			switch (buttonStyle) {
				case "button":
					if (mShow) {
						obj = STYLE["controlBar"]["button"][callName];
					}
					break;
				case "customButton":
					if (mShow) {
						obj = STYLE["controlBar"]["custom"]["button"][callName];
					}
					break;
				case "vcustomButton":
					obj = STYLE["custom"]["button"][callName];
					break;
				case "centerPlay":
					obj = STYLE["centerPlay"];
					break;
				case "advertisement":
					obj = STYLE["advertisement"][callName];
					break;
			}
			if (!obj) {
				return;
			}
			//script.traceObject(obj);
			if (obj.hasOwnProperty("clickEvent") && obj["clickEvent"]) {
				THIS["clickEvent"](obj["clickEvent"]);
			}

		}

		//--------------------------------------------------------------------------------------------鼠标单击事件
		private function mouseClickHandler(event: MouseEvent): void {
			//trace(event.currentTarget.name);
			/*MOBJ["volume"] = {
					backSprite: backSprite,
					maskSprite: maskSprite,
					buttonLoader: buttonLoader
				};*/
			if (MOBJ.hasOwnProperty("button")) {
				if (MOBJ["button"].hasOwnProperty(event.target.name)) {
					//trace("button",event.target.name);
					callEvent("button", event.target.name);
					return;

				}
			}
			if (MOBJ.hasOwnProperty("vcustomButton")) {
				if (MOBJ["vcustomButton"].hasOwnProperty(event.target.name)) {
					callEvent("vcustomButton", event.target.name);
					return;

				}
			}
			if (MOBJ.hasOwnProperty("customButton")) {
				if (MOBJ["customButton"].hasOwnProperty(event.target.name)) {
					callEvent("customButton", event.target.name);
					return;

				}
			}
			if (MOBJ.hasOwnProperty("advertisement")) {
				if (MOBJ["advertisement"].hasOwnProperty(event.target.name)) {
					callEvent("advertisement", event.target.name);
					return;

				}
			}
			if (MOBJ.hasOwnProperty("centerPlay")) {
				if (event.target.name == "centerPlay") {
					callEvent("centerPlay", event.target.name);
					return;
				}

			}
			switch (event.currentTarget) {
				case clickSprite:
					//THIS["videoPlay"]();
					//callEvent("videoClick", {x:event.stageX,y:event.stageY});
					videoSpriteXY={x:event.stageX,y:event.stageY}
					clickMoveClickHanler();
					break;
				case MOBJ["timeSlider"]["backgroundDefaultLoader"]:
				case MOBJ["timeSlider"]["loadDefaultLoader"]:
				case MOBJ["timeSlider"]["playDefaultLoader"]:

					if (timeTotal == 0 || FLASHVARS["live"]) {
						break;
					}
					//trace(MOBJ["timeSlider"]["backDefaultSprite"].mouseX,MOBJ["timeSlider"]["backgroundDefaultLoader"].width);
					var mx: int = MOBJ["timeSlider"]["backDefaultSprite"].mouseX;

					var bw: int = MOBJ["timeSlider"]["backgroundDefaultLoader"].width;
					if (mx > bw - 2) {
						mx = bw;
					}
					var value: int = int(mx * timeTotal / bw);
					if (value > timeTotal) {
						value = timeTotal;
					}
					if (value < 0) {
						value = 0;
					}
					if (!isFast(value)) {
						break;
					}
					//根据配置进行判断
					//trace("+++++", value, timeNow);

					timeFollow = true;
					timePlaySliderChange(value);
					timeFollow = false;
					//trace("是否跟着走timeFollow03",timeFollow);
					THIS["videoSeek"](value, false); //调用主程序里的调节时间并且改变调用滑块
					//trace(MOBJ["timeSlider"]["backDefaultSprite"].mouseX,MOBJ["timeSlider"]["backgroundDefaultLoader"].width,value,"v");
					//showPrompt(getFormatTime(LANGUAGE["timeSliderOver"], value), event.stageX, event.stageY - pointTemp.y);
					break;
				case MOBJ["volumeSlider"]["backgroundLoader"]:
				case MOBJ["volumeSlider"]["maskLoader"]:
					var vol: Number = Math.round(MOBJ["volumeSlider"]["backSprite"].mouseX * 100 / MOBJ["volumeSlider"]["backSprite"].width) * 0.01;
					THIS["changeVolume"](vol); //调用主程序里的调节音量并且改变调用滑块
					break;
				case MOBJ["definitionDefault"]:
					if (MOBJ.hasOwnProperty("definitionBack") && MOBJ["definitionBack"] != null) {
						MOBJ["definitionBack"].visible = true;
						definitionTimerStart();
					}
					break;
				case MOBJ["subtitleDefault"]:
					//trace("===========================",MOBJ.hasOwnProperty("subtitleBack"),MOBJ["subtitleBack"]);
					if (MOBJ.hasOwnProperty("subtitleBack") && MOBJ["subtitleBack"] != null) {
						//trace("显示");
						MOBJ["subtitleBack"].visible = true;
						subtitleTimerStart();
					}
					break;
				default:
					if (event.target.name.toString().indexOf("spirte_") > -1) {
						var ni: int = Number(event.target.name.toString().replace("spirte_", ""));
						var time: int = promptSpotObjArr[ni]["time"];
						if (!isFast(time)) {
							break;
						}
						timeFollow = true;
						timePlaySliderChange(time);
						timeFollow = false;
						//trace("是否跟着走timeFollow04",timeFollow);
						THIS["videoSeek"](time, false); //调用主程序里的调节时间并且改变调用滑块
					}
					break;
			}
		}
		private function definitionTimerStart(): void {
			//definitionTimer
			if (!definitionTimer) {
				definitionTimer = new timeInterval(100, definitionTimerHandler);
			}
			definitionTimer.start();
		}
		private function definitionTimerHandler(): void {
			var mx: int = M.mouseX,
				my: int = M.mouseY;
			var minX: int = MOBJ["definitionDefault"].x < MOBJ["definitionBack"].x ? MOBJ["definitionDefault"].x : MOBJ["definitionBack"].x;
			var minY: int = MOBJ["definitionDefault"].y < MOBJ["definitionBack"].y ? MOBJ["definitionDefault"].y : MOBJ["definitionBack"].y;
			var maxX: int = MOBJ["definitionDefault"].x + MOBJ["definitionDefault"].width > MOBJ["definitionBack"].x + MOBJ["definitionBack"].width ? MOBJ["definitionDefault"].x + MOBJ["definitionDefault"].width : MOBJ["definitionBack"].x + MOBJ["definitionBack"].width;
			var maxY: int = MOBJ["definitionDefault"].y + MOBJ["definitionDefault"].height > MOBJ["definitionBack"].y + MOBJ["definitionBack"].height ? MOBJ["definitionDefault"].y + MOBJ["definitionDefault"].height : MOBJ["definitionBack"].y + MOBJ["definitionBack"].height;
			if (mx < minX || mx > maxX || my < minY || my > maxY) {
				MOBJ["definitionBack"].visible = false;
				definitionTimer.stop();
			}
		}
		private function subtitleTimerStart(): void {
			//definitionTimer
			if (!subtitleTimer) {
				subtitleTimer = new timeInterval(100, subtitleTimerHandler);
			}
			subtitleTimer.start();
		}
		private function subtitleTimerHandler(): void {
			var mx: int = M.mouseX,
				my: int = M.mouseY;
			var minX: int = MOBJ["subtitleDefault"].x < MOBJ["subtitleBack"].x ? MOBJ["subtitleDefault"].x : MOBJ["subtitleBack"].x;
			var minY: int = MOBJ["subtitleDefault"].y < MOBJ["subtitleBack"].y ? MOBJ["subtitleDefault"].y : MOBJ["subtitleBack"].y;
			var maxX: int = MOBJ["subtitleDefault"].x + MOBJ["subtitleDefault"].width > MOBJ["subtitleBack"].x + MOBJ["subtitleBack"].width ? MOBJ["subtitleDefault"].x + MOBJ["subtitleDefault"].width : MOBJ["subtitleBack"].x + MOBJ["subtitleBack"].width;
			var maxY: int = MOBJ["subtitleDefault"].y + MOBJ["subtitleDefault"].height > MOBJ["subtitleBack"].y + MOBJ["subtitleBack"].height ? MOBJ["subtitleDefault"].y + MOBJ["subtitleDefault"].height : MOBJ["subtitleBack"].y + MOBJ["subtitleBack"].height;
			if (mx < minX || mx > maxX || my < minY || my > maxY) {
				MOBJ["subtitleBack"].visible = false;
				subtitleTimer.stop();
			}
		}
		private function isFast(value: Number = 0): Boolean {
			switch (CONFIG["config"]["timeScheduleAdjust"]) {
				case 0:
					return false;
					break;
				case 2:
					if (value < timeNow) {
						return false;
					}
					break;
				case 3:
					if (value > timeNow) {
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
						if (value < timeNow) {
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
		private function mouseOverHandler(event: MouseEvent): void {
			switch (event.currentTarget) {
				case MOBJ["definitionDefault"]:
					if (MOBJ.hasOwnProperty("definitionBack") && MOBJ["definitionBack"] != null) {
						MOBJ["definitionBack"].visible = true;
						definitionTimerStart();
					}
					break;
				case MOBJ["subtitleDefault"]:
					if (MOBJ.hasOwnProperty("subtitleBack") && MOBJ["subtitleBack"] != null) {
						MOBJ["subtitleBack"].visible = true;
						definitionTimerStart();
					}
					break;
			}

		}
		private function mouseOutHandler(event: MouseEvent): void {
			showPrompt();
			showPreviewPrompt();
			previewHide();
		}
		private function clickMoveClickHanler(): void { //单击视频事件
			if (setTimeClick) {
				setTimeClick.stop();
				setTimeClick = null;
			}
			if (isClick) {
				//说明是双击
				isClick = false;
				THIS["sendJS"]("videoDoubleClick",videoSpriteXY);
				if (CONFIG["config"]["doubleClick"]) {
					THIS["switchFull"]();
				}

			} else {
				setTimeClick = new timeOut(CONFIG["config"]["doubleClickInterval"], setTimeClickHandler);
				isClick = true;
			}
		}
		private function setTimeClickHandler(): void {
			setTimeClick.stop();
			setTimeClick = null;
			isClick = false;
			THIS["sendJS"]("videoClick",videoSpriteXY);
			if (CONFIG["config"]["click"]) {
				//THIS["playOrPause"]();
				THIS["playOrPause"]();
				//MovieClip(parent.parent).playOrPause();
			}

		}

		//--------------------------------------------------------------------------------------------播放器背景结束
		private function coorDinate(obj: Object, refer: Sprite = null): Object {
			//script.traceObject(obj);
			//根据坐标及参考对象参数计算位置
			var nObj: Object = {
				align: "left",
				vAlign: "top",
				offsetX: "0",
				offsetY: "0"
			};
			nObj = script.mergeObject(nObj, obj);
			var x: int = 0,
				y: int = 0,
				w: int = refer != null ? refer.width : stageW,
				h: int = refer != null ? refer.height : stageH;
			switch (nObj["align"]) {
				case "left":
					x = 0;
					break;
				case "center":
					x = w * 0.5;
					break;
				default:
					x = w;
					break;
			}
			switch (nObj["vAlign"]) {
				case "top":
					y = 0;
					break;
				case "middle":
					y = h * 0.5;
					break;
				default:
					y = h;
					break;
			}
			//trace(x,y);
			x += nObj["offsetX"].toString().indexOf("%") > -1 ? w * Number(nObj["offsetX"].toString().replace("%", "")) * 0.01 : Number(nObj["offsetX"]);
			y += nObj["offsetY"].toString().indexOf("%") > -1 ? h * Number(nObj["offsetY"].toString().replace("%", "")) * 0.01 : Number(nObj["offsetY"]);
			//trace(x,y);
			return {
				x: x,
				y: y
			};
		}
		//根据宽高返回实际的宽高
		private function calculatedSize(w: String, h: String, refer: Sprite = null): Object {
			var nw: int = Number(w),
				nh: int = Number(h),
				ow: int = refer != null ? refer.width : stageW,
				oh: int = refer != null ? refer.height : stageH;
			if (w.indexOf("%") > -1) {
				nw = ow * Number(w.toString().replace("%", "")) * 0.01;
			}
			if (h.indexOf("%") > -1) {
				nh = oh * Number(h.toString().replace("%", "")) * 0.01;
			}
			return {
				width: nw,
				height: nh
			};
		}
		//返回控制栏的位置，主要用于在判断鼠标是否在控制栏里
		private function getMMinXY(): Object {
			var w: int = M.width,
				h: int = M.height,
				x: int = M.x,
				y: int = M.y;
			var minX: int = 0,
				minY: int = 0;
			for (var i: int = 0; i <= (M.numChildren - 1); i++) {
				//trace(M.getChildAt(j).y);
				//trace(M.getChildAt(j).y,(M.getChildAt(j).height+M.getChildAt(j).y),M.height);
				if (M.getChildAt(i).x < minX) {
					minX = M.getChildAt(i).x;
				}
				if (M.getChildAt(i).y < minY) {
					minY = M.getChildAt(i).y;
				}
			}
			return {
				x: minX,
				y: minY
			};
		}
		//============================================================交互函数统一放置
		//当修改了C.CONFIG后
		public function changeConfig() {
			CONFIG = C.CONFIG;
			STYLE = CONFIG["style"];
			LANGUAGE = CONFIG["language"];
			FLASHVARS = CONFIG["flashvars"];
			resize();
		}
		public function addListener(eve: String, fun: Function): void {
			var isAdd: Boolean = true; //可以加
			for (var i: int = 0; i < listenerArr.length; i++) {
				var arr: Array = listenerArr[i];
				if (arr[0] == eve && arr[1] == fun) {
					isAdd = false;
					break;
				}
			}
			if (isAdd) {
				listenerArr.push([eve, fun]);
			}

		}
		public function sendJS(name: String, value: *= null): void {
			var k: String = "";
			var obj: Object = {};
			var swfObj: Object = {};
			for (var i: int = 0; i < listenerArr.length; i++) {
				var arr: Array = listenerArr[i];
				if (arr[0] == name) {
					try {
						if (value) {
							arr[1](value);
						} else {
							arr[1]();
						}
					} catch (event: Error) {
						new log(event);
					}
				}
			}
		}
		public function removeListener(eve: String, fun: Function): void {
			for (var i: int = 0; i < listenerArr.length; i++) {
				var arr: Array = listenerArr[i];
				if (arr[0] == eve && arr[1] == fun) {
					listenerArr.splice(i, 1);
					break;
				}
			}
		}
		public function showBuffer(n: int = 0): void {
			var show: Boolean = true;
			if (n < 0 || n >= 100 || (loading && loading.visible) || (MOBJ.hasOwnProperty("centerPlay") && MOBJ["centerPlay"].visible)) {
				show = false;
			}
			if (MOBJ.hasOwnProperty("buffer")) {
				MOBJ["buffer"].visible = show;
			}
			if (MOBJ.hasOwnProperty("bufferText")) {
				MOBJ["bufferText"].visible = show;
				if (MOBJ["bufferText"].visible) {
					MOBJ["bufferText"].text = script.replace(LANGUAGE["buffer"], ["[$percentage]"], [n]);
				}

			}
		}
		//-------------------------------------------------------------------------------------------loading
		public function showLoading(show: Boolean = true): void {
			if (loading) {
				loading.visible = show;
			}
		}
		//-------------------------------------------------------------------------------------------提示点
		public function changePromptSpot(): void {
			STYLE = C.CONFIG["style"];
			FLASHVARS = C.CONFIG["flashvars"];
			var i: int = 0;
			var promptSpot: Object = STYLE["promptSpot"];
			if (promptSpotArr) {
				for (i = 0; i < promptSpotArr.length; i++) {
					//THIS.removeChild(
					MOBJ["timeSlider"]["backDefaultSprite"].removeChild(promptSpotArr[i]);
				}
			}
			if (!FLASHVARS.hasOwnProperty("promptSpot")) {
				return;
			}
			if (!FLASHVARS["promptSpot"]) {
				return;
			}
			if (script.getType(FLASHVARS["promptSpot"]) != "array") {
				return;
			}
			promptSpotArr = [];
			promptSpotObjArr = FLASHVARS["promptSpot"];
			for (i = 0; i < promptSpotObjArr.length; i++) {
				var mObj: Object = {
					backgroundColor: promptSpot["color"],
					backgroundAlpha: promptSpot["alpha"], //背景透明度
					radius: promptSpot["radius"],
					width: promptSpot["width"],
					height: promptSpot["height"]
				};
				var sprite: Sprite = element.newSprite(mObj);
				sprite.name = "spirte_" + i;
				sprite.buttonMode = true;
				sprite.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
				sprite.addEventListener(MouseEvent.CLICK, mouseClickHandler);
				promptSpotArr.push(sprite);
				MOBJ["timeSlider"]["backDefaultSprite"].addChildAt(sprite, MOBJ["timeSlider"]["backDefaultSprite"].getChildIndex(MOBJ["timeSlider"]["playDefaultSprite"]) + 1);
			}
			promptSpotResize();
		}

		//根据音量的大小来调整滑块的位置，提供给外部使用
		public function volumeSliderChange(volume: Number = 0): void {
			if (volume < 0) {
				volume = 0;
			}
			if (volume > 1) {
				volume = 1;
			}
			var bkW: int = MOBJ["volumeSlider"]["backSprite"].width;
			var mkW: int = MOBJ["volumeSlider"]["maskSprite"].width;
			var btW: int = MOBJ["volumeSlider"]["buttonLoader"].width;
			var newMkW: int = bkW * volume;
			var newBtW: int = 0;
			volumeTemp = volume;
			newBtW = newMkW - (btW * 0.5);
			if (newBtW < 0) {
				newBtW = 0;
			}
			if (newBtW > bkW - btW) {
				newBtW = bkW - btW;
			}
			MOBJ["volumeSlider"]["maskSprite"].width = newMkW;
			MOBJ["volumeSlider"]["buttonLoader"].x = newBtW;
			muteOrEscMute(volume);
		}
		//控制时间进度块是否跟着时间走
		public function changeTimePlaySlider(b: Boolean = true): void {
			if (buttonDown && b) {
				return;
			}
			timeFollow = b;
			//trace("================================================是否跟着走timeFollow01",timeFollow);
		}
		//根据播放时间调整滑块的位置，提供给外部使用
		public function changeTimeTotal(n: Number = 0): void {
			timeTotal = n;
			if(C.CONFIG["flashvars"]["forceduration"]>0){
				timeTotal=C.CONFIG["flashvars"]["forceduration"];
			}
			if (timeTotal > 0) {
				changePromptSpot();
			}
		}
		public function timePlaySliderChange(time: Number = 0): void {
			if (!timeFollow) {
				return;
			}
			if (time <= -999) {
				var nowObj: Object = getFormatLiveTime();
				if (time < -999) {
					MOBJ["button"]["backLive"].visible = true;
				} else {
					MOBJ["button"]["backLive"].visible = false;
				}
				//计算时间
				time = (CONFIG["config"]["liveAndVod"]["vodTime"] - 1) * 3600 + nowObj["minutes"] * 60 + nowObj["seconds"] + time + 999;
			}
			//trace("跳转",timeSeek,timeNow,time);
			if (timeSeek == -1 && (timeNow - time > 2 || timeNow - time < -2)) {
				timeSeek = timeNow;
			}
			timeNow = time;
			if (timeMax < time) {
				timeMax = time;
			}
			//trace("timeFollow====",time,timeTotal);
			var bw: Number = MOBJ["timeSlider"]["buttonDefaultLoader"].width; //按钮的宽
			var bgw: Number = MOBJ["timeSlider"]["backgroundDefaultLoader"].width //参数背景的宽
			var pw: Number = (time * (bgw - bw)) / timeTotal + bw * 0.5; //进度条的宽度
			MOBJ["timeSlider"]["playDefaultSprite"].width = pw; //进度条的宽
			var bx: Number = pw - bw * 0.5; //按钮的x
			if (bx < 0) {
				bx = 0;
			}
			if (bx > bgw - bw) {
				bx = bgw - bw
			}
			//trace("进度按钮的",bx,pw);
			if (MOBJ.hasOwnProperty("timeSlider")) {

				MOBJ["timeSlider"]["buttonDefaultLoader"].x = bx;
			}
			if (MOBJ.hasOwnProperty("timeOutSlider")) {
				//简单播放进度
				MOBJ["timeOutSlider"]["playOutSprite"].width = (time * MOBJ["timeOutSlider"]["backgroundOutLoader"].width) / timeTotal;
			}

		}
		public function timePlaySimpleChange(time: Number = 0): void {
			if (MOBJ.hasOwnProperty("simpleSchedule")) {
				//简单播放进度
				if (time == -999) {
					var nowObj: Object = getFormatLiveTime();
					//计算时间
					time = (CONFIG["config"]["liveAndVod"]["vodTime"] - 1) * 3600 + nowObj["minutes"] * 60 + nowObj["seconds"];
				}
				var n: int = (time * MOBJ["simpleSchedule"]["backgroundDefaultLoader"].width) / timeTotal;
				MOBJ["simpleSchedule"]["playDefaultSprite"].width = n;
			}

		}
		//根据加载量调整整滑块的位置，提供给外部使用
		public function changeLoadTotal(n: int = 0): void {
			loadTotal = n;
		}
		public function timeLoadSliderChange(load: int = 0): void {
			loadNow = load;
			if (MOBJ.hasOwnProperty("timeSlider")) {
				var n: int = (load * MOBJ["timeSlider"]["backgroundDefaultLoader"].width) / loadTotal;
				MOBJ["timeSlider"]["loadDefaultSprite"].width = n;
			}
			if (MOBJ.hasOwnProperty("timeOutSlider")) {
				var n2: int = (load * MOBJ["timeOutSlider"]["backgroundOutLoader"].width) / loadTotal;
				MOBJ["timeOutSlider"]["loadOutSprite"].width = n2;
			}
		}
		public function timeLoadSimpleChange(load: int = 0): void {
			loadNow = load;
			if (MOBJ.hasOwnProperty("simpleSchedule")) {
				var n2: int = (load * MOBJ["simpleSchedule"]["backgroundDefaultLoader"].width) / loadTotal;
				MOBJ["simpleSchedule"]["loadDefaultSprite"].width = n2;
			}
		}
		//判断是加载直播时间框还是加载点播文本框
		public function loadTimeText(): void {
			var i: int = 0;
			if (MOBJ.hasOwnProperty("timeVodText") && MOBJ["timeVodText"] != null) {
				for (i = 0; i < MOBJ["timeVodText"].length; i++) {
					M.removeChild(MOBJ["timeVodText"][i]);

				}
				MOBJ["timeVodText"] = null;
			}
			if (MOBJ.hasOwnProperty("timeLiveText") && MOBJ["timeLiveText"] != null) {
				for (i = 0; i < MOBJ["timeLiveText"].length; i++) {
					M.removeChild(MOBJ["timeLiveText"][i]);
				}
				MOBJ["timeLiveText"] = null;
			}
			if (!FLASHVARS["live"] && !C.CONFIG["config"]["liveAndVod"]["open"]) {
				//trace("vod");
				loadVodTimeText();
			} else {
				//trace("live");
				loadLiveTimeText(); //加载时间文本框
			}
		}
		public function changeVodTime(t: Number = 0): void { //改变点播视频时间
			var val: int = Math.round(t);
			if (MOBJ.hasOwnProperty("timeVodText") && MOBJ["timeVodText"] != null) {
				var timeText: Object = STYLE["controlBar"]["timeText"]["vod"];
				var textFiledArr: Array = MOBJ["timeVodText"];
				var vodArr: Array = [];
				var textArr: Array = [];
				var timeTextArr: Array = [];
				if (script.getType(STYLE["controlBar"]["timeText"]["vod"]) != "array") {
					vodArr.push(STYLE["controlBar"]["timeText"]["vod"]);
				} else {
					vodArr = STYLE["controlBar"]["timeText"]["vod"];
				}
				for (var i: int = 0; i < textFiledArr.length; i++) {
					//trace(getFormatTime(vodArr[i]["text"],t));
					MOBJ["timeVodText"][i].text = getFormatTime(vodArr[i]["text"], t);
				}
			} else {
				FLASHVARS["live"] = false;
				loadTimeText();
			}
		}
		public function changeLiveTime(t: int = 0): void { //直播时间的调用
			//trace(t,"===");
			if (MOBJ.hasOwnProperty("timeLiveText") && MOBJ["timeLiveText"] != null) {
				var timeText: Object = STYLE["controlBar"]["timeText"]["live"];
				var textFiledArr: Array = MOBJ["timeLiveText"];
				var vodArr: Array = [];
				var textArr: Array = [];
				var timeTextArr: Array = [];
				if (script.getType(STYLE["controlBar"]["timeText"]["live"]) != "array") {
					vodArr.push(STYLE["controlBar"]["timeText"]["live"]);
				} else {
					vodArr = STYLE["controlBar"]["timeText"]["live"];
				}
				for (var i: int = 0; i < textFiledArr.length; i++) {
					//trace(getFormatTime(vodArr[i]["text"],t));
					//trace(vodArr[i]["text"]);
					MOBJ["timeLiveText"][i].text = getFormatTime(vodArr[i]["text"], t);
				}
			} else {
				FLASHVARS["live"] = true;
				loadTimeText();
			}
		}
		//加载或移除错误提示文本框
		public function errorShow(error: String = ""): void {
			if (error) {
				var textObj: Object = STYLE["error"];
				textObj["text"] = error;
				if (errorText) {
					THIS.removeChild(errorText);
					errorText = null;
				}
				//script.traceObject(textObj);
				errorText = element.newText(textObj);
				THIS.addChild(errorText);
				errorShowResize();
				showCenterPlay(false);
				showLoading(true);
				showBuffer(100);
			} else {
				showLoading(false);
				if (errorText) {
					THIS.removeChild(errorText);
					errorText = null;
				}
			}
		}
		//改变参考宽高
		public function changeFaceWh(obj: Object): void {
			//trace("改变宽高");
			pause.width = obj["w"];
			pause.height = obj["h"];
			pause.x = obj["x"];
			pause.y = obj["y"];
			advertisementResize();
			THIS.addChild(MOBJ["advertisement"]["closeButton"]);
		}
		//显示广告相关元件
		public function advertisementShow(objName: String, b: Boolean = true): void {
			if (MOBJ.hasOwnProperty("advertisement")) {
				var advertisement: Object = MOBJ["advertisement"];
				var newCoor: Object = {};
				if (advertisement.hasOwnProperty(objName)) {
					MOBJ["advertisement"][objName].visible = b;
					if (b) {
						THIS.addChild(MOBJ["advertisement"][objName]);
					}
				}
			}
		}
		//显示倒计时
		public function changeAdCountDown(t: int = 0): void {

			if (MOBJ.hasOwnProperty("advertisement")) {
				if (MOBJ["advertisement"].hasOwnProperty("countDown")) {
					if (t < 0) {
						t = 0;
					}
					var textTemp: String = script.replace(LANGUAGE["adCountdown"], ["[$second]","[$Second]"], [t,t<10?"0"+t:t]);
					if (!MOBJ["advertisement"].hasOwnProperty("countDownText")) {
						var obj: Object = STYLE["advertisement"]["countDownText"];
						var newText: TextField = element.newText({
							text: "0",
							color: obj["color"],
							size: obj["size"],
							font: obj["font"],
							alpha: obj["alpha"],
							bold: obj["bold"],
							textAlign: obj["textAlign"],
							width: obj["width"]
						});
						MOBJ["advertisement"]["countDownText"] = newText;
					}
					MOBJ["advertisement"]["countDownText"].text = textTemp;
					THIS.addChild(MOBJ["advertisement"]["countDownText"]);
					advertisementResize();
					//trace("倒计时时间：",textTemp,MOBJ["advertisement"]["countDownText"].visible,THIS.getChildIndex(MOBJ["advertisement"]["countDown"]));
					//trace("countDownText",MOBJ["advertisement"]["countDownText"].x,MOBJ["advertisement"]["countDownText"].y,MOBJ["advertisement"]["countDownText"].width,MOBJ["advertisement"]["countDownText"].height);
				}
			}
		}
		//显示跳过广告按钮延时显示的文本
		public function changeAdSkipDelay(t: int): void {
			//trace("++");
			if (MOBJ.hasOwnProperty("advertisement")) {
				if (MOBJ["advertisement"].hasOwnProperty("skipDelay")) {
					if (t < 0) {
						t = 0;
					}
					var textTemp: String = script.replace(LANGUAGE["skipDelay"], ["[$second]","[$Second]"], [t,t<10?"0"+t:t]);
					if (!MOBJ["advertisement"].hasOwnProperty("skipDelayText")) {
						var obj: Object = STYLE["advertisement"]["skipDelayText"];
						var newText: TextField = element.newText({
							text: textTemp,
							color: obj["color"],
							size: obj["size"],
							font: obj["font"],
							alpha: obj["alpha"],
							bold: obj["bold"],
							textAlign: obj["textAlign"],
							width: obj["width"]
						});
						MOBJ["advertisement"]["skipDelayText"] = newText;
					}
					MOBJ["advertisement"]["skipDelayText"].text = textTemp;
					THIS.addChild(MOBJ["advertisement"]["skipDelayText"]);
					advertisementResize();
					//trace("倒计时时间：",textTemp);
					//trace("countDownText",MOBJ["advertisement"]["countDownText"].x,MOBJ["advertisement"]["countDownText"].y,MOBJ["advertisement"]["countDownText"].width,MOBJ["advertisement"]["countDownText"].height);
				}
			}
		}
		public function showCenterPlay(b: Boolean = true): void { //显示中间点击播放按钮
			if (MOBJ.hasOwnProperty("centerPlay")) {
				MOBJ["centerPlay"].visible = b;
			}
		}
		public function showButton(name: String, b: Boolean = true): void { //显示/隐藏控制栏按钮
			if (MOBJ["button"].hasOwnProperty(name)) {
				MOBJ["button"][name].visible = b;
			}
		}
		public function checkFullScreen(): void { //检查是否全屏
			if (STAGE.displayState == "normal") {
				MOBJ["button"]["full"].visible = true;
				MOBJ["button"]["escFull"].visible = false;
				if (full) {
					full = false;
					THIS["sendJS"]("full", full);
					new log("full:" + full);
				}
			} else {
				MOBJ["button"]["full"].visible = false;
				MOBJ["button"]["escFull"].visible = true;
				if (!full) {
					full = true;
					THIS["sendJS"]("full", full);
					new log("full:" + full);
				}
			}

		}
		public function getClickSpriteIndex(): int { //获取播放器上方用来单击双击层的深度
			return THIS.getChildIndex(clickSprite);
		}
		public function custom(arr: Array = null): void {
			if (!arr) {
				return;
			}
			//trace(arr);
			//trace("custom==============");
			var customeName: String = "";
			if (arr.length != 3 && arr.length != 4) {
				return
			}
			var style: String = "";
			var ks: String = "";
			if (arr.length == 3) {
				ks = arr[1]
				switch (arr[0]) {
					case "button":
						style = "vcustomButton";
						break;
					case "swf":
						style = "vcustomSwf";
						break;
					case "images":
						style = "vcustomImages";
						break;
					case "text":
						style = "vcustomText";
						break;
				}
				customeName = arr[0] + "." + arr[1];
			} else {
				ks = arr[2];
				switch (arr[1]) {

					case "button":
						style = "customButton";
						break;
					case "swf":
						style = "customSwf";
						break;
					case "images":
						style = "customImages";
						break;
					case "text":
						style = "customText";
						break;
				}
				customeName = arr[0] + "." + arr[1] + "." + arr[2];
			}
			//trace("stylename",style,ks);
			if (style) {
				if (!MOBJ.hasOwnProperty(style) || !MOBJ[style]) {
					return;
				}
				if (!MOBJ[style].hasOwnProperty(ks) || !MOBJ[style][ks]) {
					return;
				}
				MOBJ[style][ks].visible = arr[arr.length - 1];
				new log(customeName + ":" + arr[arr.length - 1]);
				THIS["sendJS"](customeName, arr[arr.length - 1]);
			}

		}
		public function clear(): void {
			var i: int = 0;
			changeLoadTotal(0);
			timeLoadSliderChange(0);
			changeTimeTotal(0);
			timePlaySliderChange(0);
			changeVodTime(0);
			showLoading();
			if (previewTop) {
				THIS.removeChild(previewTop);
				previewTop = null;
			}
			if (preview) {
				THIS.removeChild(preview);
				preview = null;
			}
			previewLoad = false;
			previewLoadIng = false;
			if (promptSpotArr) {
				for (i = 0; i < promptSpotArr.length; i++) {
					//THIS.removeChild(
					MOBJ["timeSlider"]["backDefaultSprite"].removeChild(promptSpotArr[i]);
				}
			}
			promptSpotArr = [];
		}
		public function changeControlBarShow(show: Boolean = true): void {
			if (show) {
				force = false;
				mShowHandler();
			} else {
				force = true;
				mHideHandler();
			}
		}

	}

}