package ckaction.style {
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.display.Stage;
	import fl.transitions.Tween;
	import fl.transitions.easing.None;
	import fl.motion.easing.Quadratic;
	import fl.motion.easing.Cubic;
	import fl.motion.easing.Quartic;
	import fl.motion.easing.Quintic;
	import fl.motion.easing.Sine;
	import fl.motion.easing.Exponential;
	import fl.motion.easing.Circular;
	import fl.motion.easing.Elastic;
	import fl.motion.easing.Back;
	import fl.motion.easing.Bounce;
	import fl.transitions.TweenEvent;
	import flash.events.MouseEvent;
	import flash.display.MovieClip;
	import flash.events.Event;
	import ckaction.act.script;
	import ckaction.style.loadSpriteImg;
	import ckaction.C.C;
	import com.dynamicflash.util.Base64;
	//import ckaction.act.log;


	public class newElement {
		private var pauseded: Boolean = false;
		private var STAGE: Stage = null;
		private var THIS: Sprite = null;
		private var FLASHVARS: Object = null;
		private var list: Array = [];
		//private var C:MovieClip=null
		private var alt: int = 0;
		private var eleArr: Array = [],
			eleNameArr: Array = []; //保存所有在改变舞台尺寸时需要调整位置的元件的数组
		private var eleTempArr: Array = [],
			eleNameTempArr: Array = []; //保存所有在改变舞台尺寸时需要调整位置的元件的数组
		private var animateArray: Array = [],
			animateElementArray: Array = [],
			animatePauseArray: Array = []; //缓动tween数组，缓动的元件ID数组，暂停时需要停止的元件ID数组
		public function newElement(stage: Stage, sprite: Sprite, an: int = 0) {
			STAGE = stage;
			THIS = sprite;
			var config: Object = C.CONFIG;
			FLASHVARS = config["flashvars"];
			alt = an;
			//C=cm;
			stage.addEventListener(Event.RESIZE, resizeHandler);
		}
		//当修改了C.CONFIG后
		public function changeConfig() {
			var config: Object = C.CONFIG;
			FLASHVARS = config["flashvars"];
		}
		public function addelement(newObj): Sprite {
			var obj = {
				list: [],
				x: "100%",
				y: "50%",
				position: [],
				alpha: 1,
				backgroundColor: null,
				backAlpha: 1,
				backRadius: 0,
				border: 0,
				borderColor: 0x000000,
				clickEvent: ""
			}
			obj = script.mergeObject(obj, newObj);
			//new log(obj);
			list = obj["list"];
			if (list.length == 0) {
				return null;
			}
			var bObj: Object = {};
			var elementArr: Array = [];
			var i: int = 0;
			var ele: Object = {};
			var cx: int = 0,
				maxH: int = 0;
			for (i = 0; i < list.length; i++) {
				ele = list[i];
				var mH: int = 0;
				var eleSprite: Sprite = null;
				switch (ele["type"]) {
					case "image":
					case "png":
					case "jpg":
					case "jpeg":
					case "bmp":	
					case "swf":
						bObj = {
							type: "image",
							file: "",
							radius: 0, //圆角弧度
							width: 30, //定义宽，必需要定义
							height: 30, //定义高，必需要定义
							alpha: 1, //透明度
							marginLeft: 0,
							marginRight: 0,
							marginTop: 0,
							marginBottom: 0,
							clickEvent: ""
						};
						list[i] = ele = script.mergeObject(bObj, ele);
						eleSprite = loadSpriteImg.loadImg(bObj["file"], bObj["width"], bObj["height"], bObj["radius"], i,bObj["clickEvent"]!=""?Base64.encode(bObj["clickEvent"]):"");

						cx += ele["marginLeft"];
						eleSprite.x = cx;
						cx += (eleSprite.width || ele["width"]) + ele["marginRight"];
						mH = ele["marginTop"];
						eleSprite.y = mH;
						mH += (eleSprite.height || ele["height"]) + ele["marginBottom"];
						if (maxH < mH) {
							maxH = mH;
						}
						
						if (bObj["clickEvent"] != "") {
							eleSprite.name=Base64.encode(bObj["clickEvent"]);
							eleSprite.buttonMode = true;
							eleSprite.addEventListener(MouseEvent.CLICK, mouseClickHandler);
						}
						elementArr.push(eleSprite);
						//eleNameArr.push();
						break;
					case "gif":
						bObj = {
							type: "gif",
							file: "",
							radius: 0, //圆角弧度
							width: 30, //定义宽，必需要定义
							height: 30, //定义高，必需要定义
							alpha: 1, //透明度
							marginLeft: 0,
							marginRight: 0,
							marginTop: 0,
							marginBottom: 0,
							clickEvent: ""
						};
						list[i] = ele = script.mergeObject(bObj, ele);
						var spObj: Object = {
							width: bObj["width"],
							height: bObj["height"]
						};
						eleSprite = loadSpriteGif.loadGif(bObj["file"], bObj["width"], bObj["height"], bObj["radius"], i);
						trace("加载");
						cx += ele["marginLeft"];
						eleSprite.x = cx;
						cx += (eleSprite.width || ele["width"]) + ele["marginRight"];
						mH = ele["marginTop"];
						eleSprite.y = mH;
						mH += (eleSprite.height || ele["height"]) + ele["marginBottom"];
						if (maxH < mH) {
							maxH = mH;
						}
						
						if (bObj["clickEvent"] != "") {
							eleSprite.name=Base64.encode(bObj["clickEvent"]);
							eleSprite.buttonMode = true;
							eleSprite.addEventListener(MouseEvent.CLICK, mouseClickHandler);
						}
						elementArr.push(eleSprite);
						//eleNameArr.push();
						break;
					case "text":
						bObj = {
							type: "text", //说明是文本
							text: "", //文本内容
							color: 0xFFFFFF,
							size: 14,
							font: "Microsoft YaHei,\5FAE\8F6F\96C5\9ED1,微软雅黑",
							leading: 0,
							alpha: 1, //透明度
							bold: false,
							paddingLeft: 0, //左边距离
							paddingRight: 0, //右边距离
							paddingTop: 0,
							paddingBottom: 0,
							marginLeft: 0,
							marginRight: 0,
							marginTop: 0,
							marginBottom: 0,
							backgroundColor: null,
							backAlpha: 1,
							backRadius: 0,
							border: 0,
							borderColor: 0x000000
						};
						list[i] = ele = script.mergeObject(bObj, ele);
						var textObj: Object = {
							text: bObj["text"],
							color: bObj["color"],
							size: bObj["size"],
							font: bObj["font"],
							bold: bObj["bold"],
							width: 0,
							height: 0,
							alpha: bObj["alpha"]
						};
						var text: TextField = element.newText(textObj);
						var textBgWidth: int = text.width + bObj["paddingLeft"] + bObj["paddingRight"];
						var textBgHeight: int = bObj["leading"] > 0 ? bObj["leading"] : 0;
						text.y = textBgHeight > 0 ? (textBgHeight - text.height) * 0.5 + bObj["paddingTop"] : bObj["paddingTop"];
						textBgHeight += (bObj["paddingTop"] + bObj["paddingBottom"]);
						text.x = bObj["paddingLeft"];
						var textBgObj: Object = {
							backgroundColor: bObj["backgroundColor"], //背景颜色
							radius: bObj["backRadius"], //圆角弧度
							backgroundAlpha: bObj["backAlpha"], //背景透明度
							border: bObj["border"],
							borderColor: bObj["borderColor"],
							width: textBgWidth,
							height: textBgHeight
						};
						eleSprite = element.newSprite(textBgObj);
						eleSprite.addChild(text);
						//eleSprite.name = "ele_" + i;
						cx += ele["marginLeft"];
						eleSprite.x = cx;
						cx += eleSprite.width + ele["marginRight"];
						mH = ele["marginTop"];
						eleSprite.y = mH;
						mH += eleSprite.height + ele["marginBottom"];
						if (maxH < mH) {
							maxH = mH;
						}
						elementArr.push(eleSprite);
						
						if (bObj["clickEvent"] != "" && (obj["clickEvent"] == "" || obj["clickEvent"] == null) && bObj["clickEvent"] != null) {
							eleSprite.name=Base64.encode(bObj["clickEvent"]);
							eleSprite.buttonMode = true;
							eleSprite.addEventListener(MouseEvent.CLICK, mouseClickHandler);
						}
						break;
					default:
						break;
				}
			}
			
			var spBgObj: Object = {
				backgroundColor: obj["backgroundColor"] != null ? obj["backgroundColor"] : null, //背景颜色
				radius: obj["backRadius"], //圆角弧度
				backgroundAlpha: obj["backAlpha"], //背景透明度
				border: obj["border"],
				borderColor: obj["borderColor"],
				width: cx,
				height: maxH
			};
			var sprite: Sprite = element.newSprite(spBgObj);
			for (i = 0; i < elementArr.length; i++) {
				sprite.addChild(elementArr[i]);
			}
			sprite.name = obj["x"] + "$" + obj["y"] + "$" + obj["position"].join(",") + "$" + script.randomString();
			var eleCoor: Object = calculationCoor(sprite);
			sprite.x = eleCoor["x"];
			sprite.y = eleCoor["y"];
			sprite.alpha = obj["alpha"];
			THIS.addChildAt(sprite, alt + 1);
			eleArr.push(sprite);
			eleNameArr.push(sprite.name);
			if (obj["clickEvent"] != "") {
				sprite.buttonMode = true;
				sprite.addEventListener(MouseEvent.CLICK, function (event: MouseEvent): void {
					THIS["clickEvent"](obj["clickEvent"]);
				});
			}
			return sprite;
		}
		private function mouseClickHandler(event: MouseEvent): void {
			//new log(event.target.name);
			var ce: String = Base64.decode(event.target.name);
			//new log(ce);
			THIS["clickEvent"](ce);

		}

		private function calculationCoor(ele: Sprite): Object {
			var arr = ele.name.split("$");
			var obj = {
				x: arr[0],
				y: arr[1],
				position: arr[2] != "" ? arr[2].split(",") : []
			}
			var x: int = Number(obj["x"].toString().split("%").join("")),
				y: int = Number(obj["y"].toString().split("%").join("")),
				position: Array = obj["position"];
			var w: int = STAGE.stageWidth,
				h: int = STAGE.stageHeight;
			var ew: int = ele.width,
				eh: int = ele.height;
			if (position.length > 0) {
				position.push(null, null, null, null);
				var i = 0;
				for (i = 0; i < position.length; i++) {
					if (position[i] == "null" || position[i] == "") {
						position[i] = null;
					}
					if (position[i] != null) {
						position[i] = Number(position[i]);
					}


				}
				if (position[2] == null) {
					switch (position[0]) {
						case 0:
							x = 0;
							break;
						case 1:
							x = (w - ew) * 0.5;
							break;
						default:
							x = w - ew;
							break;
					}
				} else {
					switch (position[0]) {
						case 0:
							x = position[2];
							break;
						case 1:
							x = w * 0.5 + position[2];
							break;
						default:
							x = w + position[2];
							break;
					}
				}
				if (position[3] == null) {
					switch (position[1]) {
						case 0:
							y = 0;
							break;
						case 1:
							y = (h - eh) * 0.5;
							break;
						default:
							y = h - eh;
							break;
					}
				} else {
					switch (position[1]) {
						case 0:
							y = position[3];
							break;
						case 1:
							y = h * 0.5 + position[3];
							break;
						default:
							y = h + position[3];
							break;
					}
				}
			} else {
				if (obj["x"].toString().search("%") > -1) {
					x = Math.floor(Number(obj["x"].toString().split("%").join("")) * w * 0.01);
				}
				if (obj["y"].toString().search("%") > -1) {
					y = Math.floor(Number(obj["y"].toString().split("%").join("")) * h * 0.01);
				}
			}

			return {
				x: x,
				y: y
			}
		}
		public function getElement(name: String): Object {
			var num: int = eleNameArr.indexOf(name);
			var sprite: Sprite =null
			if (num > -1) {
				sprite = eleArr[num];
				return {
					x: sprite.x,
					y: sprite.y,
					width: sprite.width,
					height: sprite.height,
					alpha: sprite.alpha
				}
			}
			num = eleNameTempArr.indexOf(name);
			if (num > -1) {
				sprite = eleTempArr[num];
				return {
					x: sprite.x,
					y: sprite.y,
					width: sprite.width,
					height: sprite.height,
					alpha: sprite.alpha,
					show:sprite.visible
				}
			}
			return null;
		}
		public function elementShow(name: String="",bn:Boolean=true):void{
			if(name==""){
				var i:int=0;
				for(i=0;i<eleNameTempArr.length;i++){
					eleTempArr[i].visible=bn;
				}
				return;
			}
			var num: int = eleNameArr.indexOf(name);
			if (num > -1) {
				eleArr[num].visible=bn;
			}
			num = eleNameTempArr.indexOf(name);
			if (num > -1) {
				eleTempArr[num].visible=bn;
			}
		}
		public function animate(ob: Object): String {
			var obj: Object = {
				element: null,
				parameter: "x",
				static: false,
				effect: "None.easeIn",
				start: null,
				end: null,
				speed: 0,
				overStop: false,
				pauseStop: false,
				callBack: null
			};
			obj = script.mergeObject(obj, ob);
			if (obj["element"] == null || obj["speed"] == 0) {
				return "";
			}
			var w: int = STAGE.stageWidth,
				h: int = STAGE.stageHeight;
			var eleCoor = {
				x: 0,
				y: 0
			};

			var run: Boolean = true;
			var pm = getElement(obj["element"]); //包含x,y,width,height,alpha属性
			//将该元件从元件数组里删除，让其不再跟随播放器的尺寸改变而改变位置
			var num = eleNameArr.indexOf(obj["element"]);
			var sprite: Sprite = null;
			if (num > -1) {
				sprite = eleArr[num];
				eleNameArr.splice(num, 1);
				eleArr.splice(num, 1);
				eleTempArr.push(sprite);
				eleNameTempArr.push(obj["element"]);
			}
			if (sprite == null) {
				return "";
			}
			var b: Number = 0; //初始值
			var c: Number = 0; //变化后的值
			var d = obj["speed"]; //持续时间
			//var setTimeOut = null;
			//var tweenObj = null;
			var start: String = obj["start"] == null ? "" : obj["start"].toString();
			var end: String = obj["end"] == null ? "" : obj["end"].toString();
			switch (obj["parameter"]) {
				case "x":
					if (obj["start"] == null) {
						b = pm["x"];
					} else {
						if (start.substr(start.length - 1, start.length) == "%") {
							b = Number(start.substr(0, start.length - 1)) * w * 0.01;
						} else {
							b = Number(start);
						}

					}
					if (obj["end"] == null) {
						c = pm["x"];
					} else {
						if (end.substr(end.length - 1, end.length) == "%") {
							c = Number(end.substr(0, end.length - 1)) * w * 0.01;
						} else if (end.substr(0, 1) == "-" || end.substring(0, 1) == "+") {
							if (typeof (obj["end"]) == "number") {
								c = obj["end"];
							} else {
								c = b + Number(end);
							}
						} else {
							c = Number(end);
						}
					}
					b = Math.floor(b);
					c = Math.floor(c);
					break;
				case "y":
					if (obj["start"] == null) {
						b = pm["y"];
					} else {
						if (start.substr(start.length - 1, start.length) == "%") {
							b = Number(start.substr(0, start.length - 1)) * h * 0.01;
						} else {
							b = Number(start);
						}

					}
					if (obj["end"] == null) {
						c = pm["y"];
					} else {
						if (end.substr(end.length - 1, end.length) == "%") {
							c = Number(end.substr(0, end.length - 1)) * h * 0.01;
						} else if (end.substr(0, 1) == "-" || end.substring(0, 1) == "+") {
							if (typeof (obj["end"]) == "number") {
								c = obj["end"];
							} else {
								c = b + Number(end);
							}
						} else {
							c = Number(end);
						}
					}
					b = Math.floor(b);
					c = Math.floor(c);

					break;
				case "alpha":
					if (obj["start"] == null) {
						b = pm["alpha"];
					} else {
						if (start.substr(start.length - 1, start.length) == "%") {
							b = Number(start.substr(0, start.length - 1));
						} else {
							b = Number(obj["start"]);
						}

					}
					if (obj["end"] == null) {
						c = pm["alpha"];
					} else {
						if (end.substr(end.length - 1, end.length) == "%") {
							c = Number(end.substr(0, end.length - 1));
						} else if (end.substr(0, 1) == "-" || end.substring(0, 1) == "+") {
							if (typeof (obj["end"]) == "number") {
								c = obj["end"];
							} else {
								c = b + Number(end);
							}
						} else {
							c = Number(end);
						}
					}
					break;

			}
			var effArr: Array = [None, Quadratic, Cubic, Quartic, Quintic, Sine, Exponential, Circular, Elastic, Back, Bounce];
			var effNameArr: Array = ["None", "Quadratic", "Cubic", "Quartic", "Quintic", "Sine", "Exponential", "Circular", "Elastic", "Back", "Bounce"];
			var arr: Array = obj["effect"].split(".");
			num = effNameArr.indexOf(arr[0]);
			var effectFun = effArr[num][arr[1]];
			var tween: Tween = new Tween(sprite, obj["parameter"], effectFun, b, c, d, true);

			if (obj["static"]) {
				function changeHandler(event: TweenEvent) {
					var coor = calculationCoor(sprite);
					switch (obj["parameter"]) {
						case "x":
							sprite.y = coor["y"];
							break;
						case "y":
							sprite.x = coor["x"];
							break;
						case "alpha":
							sprite.x = coor["x"];
							sprite.y = coor["y"];
							break;
					}
				};
				tween.addEventListener(TweenEvent.MOTION_CHANGE, changeHandler);
			}
			function backCall(): void {
				//trace("=====================================backcall");
				var numT:int = eleNameTempArr.indexOf(sprite.name);
				if (numT > -1) {
					eleNameTempArr.splice(numT, 1);
					eleTempArr.splice(numT, 1);
				}
				eleNameArr.push(sprite.name);
				eleArr.push(sprite);
				
				tween.removeEventListener(TweenEvent.MOTION_FINISH, finishHandler);
				tween = null;
				if (obj["callBack"] != null && typeof (obj["callBack"]) == "string") {
					script.callJs(obj["callBack"], sprite.name);
				}
			}
			function finishHandler(event: TweenEvent): void {
				switch (obj["parameter"]) {
					case "x":
						if (sprite.x != c) {
							tween.resume();
						} else {
							backCall();
						}
						break;
					case "y":
						if (sprite.y != c) {
							tween.resume();
						} else {
							backCall();
						}
						break;
					case "alpha":
						if (sprite.alpha != c) {
							tween.resume();
						} else {
							backCall();
						}
						break;
				}
			}
			tween.addEventListener(TweenEvent.MOTION_FINISH, finishHandler);

			if (obj["overStop"]) {
				function overHandler(event: MouseEvent) {
					tween.stop();
					sprite.removeEventListener(MouseEvent.MOUSE_OVER, overHandler);
					sprite.addEventListener(MouseEvent.MOUSE_OUT, outHandler);
				};
				function outHandler(event: MouseEvent) {
					var start = true;
					if (obj["pauseStop"] && pauseded) {
						start = false;
					}
					if (start) {
						tween.resume();
					}
					sprite.removeEventListener(MouseEvent.MOUSE_OUT, outHandler);
					sprite.addEventListener(MouseEvent.MOUSE_OVER, overHandler);
				};
				sprite.addEventListener(MouseEvent.MOUSE_OVER, overHandler);
			}
			tween.start();
			var animateId = "animate" + script.randomString();
			animateArray.push(tween);
			animateElementArray.push(animateId);
			if (obj["pauseStop"]) {
				animatePauseArray.push(animateId);
			}
			return animateId;
		}
		/*
			接口函数
			继续运行animate
		*/
		public function animateResume(id: String = "") {
			var arr: Array = [];
			if (id != "" && id != "undefined" && id != "pause") {
				arr.push(id);
			} else {
				if (id === "pause") {
					arr = animatePauseArray;
				} else {
					arr = animateElementArray;
				}
			}
			for (var i: int = 0; i < arr.length; i++) {
				var index: int = animateElementArray.indexOf(arr[i]);

				if (index > -1) {
					animateArray[index].resume();
				}
			}

		}
		/*
			接口函数
			暂停运行animate
		*/
		public function animatePause(id: String = "") {

			var arr: Array = [];
			if (id != "" && id != "undefined" && id != "pause") {
				arr.push(id);
			} else {
				if (id === "pause") {
					arr = animatePauseArray;
				} else {
					arr = animateElementArray;
				}
			}
			for (var i: int = 0; i < arr.length; i++) {
				var index: int = animateElementArray.indexOf(arr[i]);
				if (index > -1) {
					animateArray[index].stop();
				}
			}
		}
		/*
			内置函数
			根据元件删除数组里对应的内容
		*/
		public function deleteAnimate(id:String) {
			var index = animateElementArray.indexOf(id);
			if (index > -1) {
				//animatePause(id);
				animateArray[index].fforward();
				//animateArray.splice(index, 1);
				//animateElementArray.splice(index, 1);
			}
		}
		/*
			内置函数
			删除外部新建的元件
		*/
		public function deleteElement(name: String): void {
			trace(name);
			trace(eleNameArr);
			var num: int = eleNameArr.indexOf(name);
			if (num > -1) {
				THIS.removeChild(eleArr[num]);
				eleNameArr.splice(num, 1);
				eleArr.splice(num, 1);
			}
			deleteAnimate(name);
		}
		public function changePauseded(b: Boolean): void {
			pauseded = b;
			if (animatePauseArray.length == 0) {
				return;
			}
			if (b) {
				animatePause("pause");
			} else {
				animateResume("pause");
			}
		}
		public function resizeHandler(event: Event): void {
			if (eleArr.length > 0) {
				for (var i: int = 0; i < eleArr.length; i++) {
					var coor: Object = calculationCoor(eleArr[i]);
					eleArr[i].x = coor["x"];
					eleArr[i].y = coor["y"];
				}
			}
		}

	}

}