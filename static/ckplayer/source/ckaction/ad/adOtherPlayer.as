package ckaction.ad {
	import flash.display.Sprite;
	import flash.display.Loader;
	import ckaction.player.gifPlayer;
	import ckaction.act.httpload;
	import flash.display.MovieClip;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import ckaction.act.script;
	import ckaction.act.requestController;
	import ckaction.style.element;
	import ckaction.C.C;
	import ckaction.act.timeOut;

	public class adOtherPlayer {
		private var STAGE: Stage = null;
		private var THIS: Sprite = null;
		private var adObj: Object = null;
		private var adNum: int = 0;
		private var isClose: Boolean = false;
		private var stageW: int = 0,
			stageH: int = 0;
		private var load: Loader = null;
		private var gif: gifPlayer = null;
		private var httpLoad: httpload = null;
		private var loadGif: MovieClip = null;
		private var adMask: Sprite = null;
		private var adMetaData: Object = {
			width: 0,
			height: 0
		};
		private var CONFIG: Object = C.CONFIG;
		private var STYLE: Object = {};
		private var closeOtherButtonShow: Boolean = true;
		private var closeButton: Sprite = null;
		private var timeOutVal: timeOut = null;
		public function adOtherPlayer(stage: Stage, sprite: Sprite, obj: Object, num: int = 0) {
			// constructor code
			STYLE = CONFIG["style"]
			adObj = obj;
			adNum = num;
			STAGE = stage;
			THIS = sprite;
			closeOtherButtonShow = STYLE["advertisement"]["closeOtherButtonShow"];
			stageW = STAGE.stageWidth,
			stageH = STAGE.stageHeight;
			STAGE.addEventListener(Event.RESIZE, function (event: Event) {
				resizeHandler();
			});
			adPlay();
			if (adObj.hasOwnProperty("time") && Number(adObj["time"]) > 0) {
				timeOutVal = new timeOut(Number(adObj["time"]) * 1000, closeAd);
			}
		}
		//当修改了C.CONFIG后
		public function changeConfig() {
			var config: Object = C.CONFIG;
			STYLE = config["style"];
		}
		private function adPlay(): void {
			if (isClose) {
				return;
			}
			if (!adObj["type"]) {
				adObj["type"] = script.getFileExt(adObj["file"]);
			}
			adObj["type"] = adObj["type"].replace(".", "");
			switch (adObj["type"]) {
				case "png":
				case "jpg":
				case "jpeg":
				case "swf":
					httpLoad = new httpload(adObj["file"], loaderHandler);
					break;
				case "gif":
					gif = new gifPlayer(adObj["file"], gifHandler);
					break;
				default:
					break;
			}
		}
		//图片，swf加载成功
		private function loaderHandler(ld: Loader = null): void {
			if (isClose) {
				return;
			}
			if (ld) {
				load = ld;
				adMetaData = {
					width: load.width,
					height: load.height
				};
				THIS.addChild(load);
				resizeHandler();
				if (adObj.hasOwnProperty("exhibitionMonitor")) {
					new requestController(STYLE["advertisement"]["method"], adObj["exhibitionMonitor"], adObj);
				}
				if (adObj["link"]) {
					addAdMask();
				}
				if (closeOtherButtonShow) {
					addCloseOtherButton();
				}
			}
		}
		//gif加载成功
		private function gifHandler(mc: MovieClip = null): void {
			if (isClose) {
				return;
			}
			//trace("===");
			if (mc != null) {
				loadGif = mc;
				adMetaData = {
					width: loadGif.width,
					height: loadGif.height
				};
				//trace(loadGif.width);
				THIS.addChild(loadGif);
				resizeHandler();
				if (adObj.hasOwnProperty("exhibitionMonitor") && adObj["exhibitionMonitor"]!="") {
					new requestController(STYLE["advertisement"]["method"], adObj["exhibitionMonitor"], adObj);
				}
				if (adObj.hasOwnProperty("link") && adObj["link"]) {
					addAdMask();
				}
				if (closeOtherButtonShow) {
					addCloseOtherButton();
				}
			}
		}
		private function addCloseOtherButton(): void {
			if (isClose) {
				return;
			}
			if (STYLE.hasOwnProperty("advertisement") && STYLE["advertisement"].hasOwnProperty("closeOtherButton")) {
				closeButton = element.imgButton(STYLE["advertisement"]["closeOtherButton"], "closeOtherAd", function () {});
				THIS.addChild(closeButton);
				closeButton.addEventListener(MouseEvent.CLICK, mouseClickHandler);
				resizeHandler();
			}
		}
		private function mouseClickHandler(event: MouseEvent): void {
			closeAd();
		}
		private function closeAd(): void {
			THIS["closeOtherAd"](adNum);
		}
		public function close(): void {
			isClose = true;
			if (load) {
				THIS.removeChild(load);
				load = null;
			}
			if (loadGif) {
				THIS.removeChild(loadGif);
				loadGif = null;
			}
			if (adMask) {
				THIS.removeChild(adMask);
				adMask = null;
			}
			if (closeButton) {
				THIS.removeChild(closeButton);
				closeButton = null;
			}
			if (timeOutVal) {
				timeOutVal.stop();
				timeOutVal = null;
			}
		}
		private function addAdMask(): void {
			if (!adMask) {
				var spObj: Object = {
					backgroundColor: 0xFF0000,
					border: 0,
					backgroundAlpha: 0, //背景透明度
					width: adMetaData["width"],
					height: adMetaData["height"]
				};
				adMask = element.newSprite(spObj);
				adMask.addEventListener(MouseEvent.CLICK, adMaskClickHandler);
				adMask.buttonMode = true;
			}
			THIS.addChild(adMask);
			resizeHandler();
		}
		private function adMaskClickHandler(event: MouseEvent): void {
			openAdLink();
		}
		//打开广告链接
		public function openAdLink(): void {
			if (adObj.hasOwnProperty("clickMonitor")) {
				new requestController(STYLE["advertisement"]["method"], adObj["clickMonitor"], adObj);
			}
			script.openLink(adObj["link"], adObj["target"]);
		}
		private function resizeHandler(): void {
			if (isClose) {
				return;
			}
			stageW = STAGE.stageWidth;
			stageH = STAGE.stageHeight;
			var coor: Object = coorDinate(adObj);
			//trace(coor["width"],coor["height"]);
			if (load) {
				load.x = coor["x"];
				load.y = coor["y"];
			}
			if (loadGif) {
				loadGif.x = coor["x"];
				loadGif.y = coor["y"];
				gif.changeWH(adMetaData["width"], adMetaData["height"]);
			}
			if (adMask) {
				adMask.x = coor["x"];
				adMask.y = coor["y"];
			}
			if (closeButton) {
				coor = coorDinate(STYLE["advertisement"]["closeOtherButton"], adMask || load || loadGif);
				closeButton.x = coor["x"] + (adMask || load || loadGif).x;
				closeButton.y = coor["y"] + (adMask || load || loadGif).y;
			}
		}
		private function coorDinate(obj: Object, refer: * = null): Object {
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
	}

}