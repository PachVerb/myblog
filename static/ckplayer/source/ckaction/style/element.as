package ckaction.style {
	import flash.display.Sprite;
	import flash.text.TextField;
	import ckaction.act.script;
	import flash.text.TextFormat;
	import flash.display.SimpleButton;
	import flash.display.MovieClip;
	import flash.utils.ByteArray;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.display.Bitmap;
	import flash.events.MouseEvent;
	import flash.display.JointStyle;
	import flash.display.CapsStyle;
	import ckaction.act.des;

	public class element {

		public static function newSprite(obj: Object = null): Sprite { //建立一个圆角矩形
			var con: Object = {
				backgroundColor: null, //背景颜色
				backgroundAlpha: 0, //背景透明度
				border: 0,
				borderColor: null, //边框颜色
				radius: 0, //圆角弧度
				width: 0,
				height: 0
			};
			con = script.mergeObject(con, obj);
			//trace(con["width"], con["height"], con["radius"], con["radius"]);
			var sprite: Sprite = new Sprite();
			if (con["backgroundColor"] != null) {
				sprite.graphics.beginFill(con["backgroundColor"], con["backgroundAlpha"]); //背景色，透明度CapsStyle.NONE
			}
			if (con["borderColor"] != null && con["border"] > 0) {
				sprite.graphics.lineStyle(con["border"], con["borderColor"], con["borderAlpha"], true, "normal", CapsStyle.NONE, JointStyle.MITER, 1.414);
			}
			sprite.graphics.drawRoundRect(0, 0, con["width"], con["height"], con["radius"], con["radius"]);
			return sprite;
		}
		public static function newLine(obj: Object = null): Sprite { //建立直线
			var o: Object = {
				color: 0x000000, //背景颜色
				alpha: 1, //透明度
				width: 1,
				height: 1
			};
			o = script.mergeObject(o, obj);
			var s: Sprite = new Sprite();
			s.graphics.lineStyle(o["height"], o["color"]);
			s.graphics.moveTo(0, 0);
			s.graphics.lineTo(o["width"], 0);
			s.alpha = o["alpha"];
			return s;
		}
		public static function newTriangle(obj: Object = null): Sprite { //画三角
			var o: Object = {
				width: 0,
				height: 0,
				backgroundColor: null,
				border: 0,
				borderColor: null,
				alpha: 0
			}
			o = script.mergeObject(o, obj);
			var sprite: Sprite = new Sprite();
			if (o["backgroundColor"] != null && o["alpha"]) {
				sprite.graphics.beginFill(o["backgroundColor"], o["alpha"]);
			}
			if (o["borderColor"] != null && o["border"] && o["alpha"]) {
				sprite.graphics.lineStyle(o["border"], o["borderColor"], o["alpha"]);
			}

			sprite.graphics.moveTo(0, 0);
			sprite.graphics.lineTo(o["width"], 0);
			sprite.graphics.lineTo(o["width"] * 0.5, o["height"]);
			sprite.graphics.lineTo(0, 0);
			sprite.graphics.endFill();
			return sprite;
		}
		public static function newText(obj: Object = null): TextField { //建立一个简单的文本框
			var o: Object = {
				text: "",
				color: 0xFFFFFF,
				size: 14,
				font: "Microsoft YaHei,\5FAE\8F6F\96C5\9ED1,微软雅黑",
				width: 0,
				height: 0,
				leading: 0,
				alpha: 1,
				bold: false,
				rightMargin: 0,
				leftMargin: 0,
				textAlign: "left"

			}
			o = script.mergeObject(o, obj);
			var format: TextFormat = new TextFormat();
			format.leading = o["leading"];
			format.size = o["size"];
			format.font = o["font"];
			format.color = o["color"];
			format.align = o["textAlign"];
			if(o["bold"]==true){
				format.bold=o["bold"];
			}
			
			var text: TextField = new TextField();
			text.defaultTextFormat = format;
			text.mouseEnabled = false;
			text.text = o["text"];
			text.wordWrap = o["width"] > 0 ? true : false;
			text.width = o["width"] > 0 ? o["width"] : text.textWidth + 5;
			text.height = o["height"] > 0 ? o["height"] : text.textHeight + 5;
			text.alpha = o["alpha"];
			return text;
		}
		public static function newButton(obj: Object = null): SimpleButton { //建立一个按钮
			var o: Object = {
				backgroundAlpha:0.8,
				height: 30 ,
				alpha: 1 ,
				font: "Microsoft YaHei,\5FAE\8F6F\96C5\9ED1,微软雅黑",
				padding: 0,
				align: "right",
				overTextColor: 0xFFFFFF,
				textColor: 0xEFEFEF,
				border: 0,
				bold: false,
				overBackgroundColor: 0x444444,
				size: 14,
				borderColor: 0x333333,
				width: 60,
				backgroundColor: 0x1A1A1A,
				radius: 0,
				text:""
			}
			//script.traceObject(obj);
			o = script.mergeObject(o, obj);
			//建立背景
			var bg: Object = {
				backgroundColor: o["backgroundColor"], //背景颜色
				backgroundAlpha: o["backgroundAlpha"], //背景透明度
				border: o["border"],
				borderColor: o["borderColor"], //边框颜色
				radius: o["radius"], //圆角弧度
				width: o["width"],
				height: o["height"]
			};
			var bgSprite:Sprite=newSprite(bg);
			bg["backgroundColor"]=o["overBackgroundColor"]; //背景颜色
			var overSprite:Sprite=newSprite(bg);
			//文字
			var textObj:Object={
				text: o["text"],
				color: o["textColor"],
				size: o["size"],
				font: o["font"],
				alpha: o["alpha"],
				bold: o["bold"]
			}
			var text:TextField=newText(textObj);
			textObj["color"]=o["overTextColor"];
			var overText:TextField=newText(textObj);
			var tx:int=0;
			switch(o["align"]){
				case "left":
					tx=o["padding"]
					break;
				case "center":
					tx=(bgSprite.width-text.width)*0.5;
					break;
				case "right":
					tx=bgSprite.width-text.width-o["padding"];
					break;
			}
			text.x=tx;
			overText.x=tx;
			text.y=(bgSprite.height-text.height)*0.5;
			overText.y=(bgSprite.height-overText.height)*0.5;
			bgSprite.addChild(text);
			overSprite.addChild(overText);
			var button: SimpleButton = new SimpleButton();
			if (o["over"]) {
				button.upState = overSprite;
			}
			else {
				button.upState = bgSprite;
			}
		
			button.overState = overSprite;
			button.hitTestState = overSprite;
			button.downState = overSprite;
			return button;
		}
		public static function imgButton(obj: Object = null, name: String = "", imgLoadedFun: Function = null): Sprite { //建立一个以图片为元件的按钮
			var o: Object = {
				mouseOver: "",
				mouseOut: ""
			}
			o = script.mergeObject(o, obj);
			if (!o["mouseOver"] || !o["mouseOut"]) {
				return null;
			}
			var mObj: Object = {
				bgAlpha: 0, //背景透明度
				width: 1,
				height: 1
			};
			var sp: Sprite = newSprite(mObj);
			var over: ByteArray = des.getByteArray(o["mouseOver"]);
			var out: ByteArray =des.getByteArray(o["mouseOut"]);
			var outBitMap: Bitmap = null,
				overBitMap: Bitmap = null;

			var loadOut: Loader = new Loader(),
				loadOver: Loader = new Loader();

			function loadOutImg(): void {
				loadOut.loadBytes(out); //读取ByteArray 
				loadOut.contentLoaderInfo.addEventListener(Event.COMPLETE, function (event: Event) {
					outBitMap = event.target.content as Bitmap; //读取Bitmap    
					sp.addChild(outBitMap);
					loadOverImg();
				});
			}
			function loadOverImg(): void {
				loadOver.loadBytes(over); //读取ByteArray
				loadOver.contentLoaderInfo.addEventListener(Event.COMPLETE, function (event: Event) {
					overBitMap = event.target.content as Bitmap; //读取Bitmap    
					sp.addChild(overBitMap);
					overBitMap.visible = false;
					addListener();
				});
			}
			function addListener(): void {
				sp.addEventListener(MouseEvent.MOUSE_OVER, function (event: MouseEvent) {
					overBitMap.visible = true;
				});
				sp.addEventListener(MouseEvent.MOUSE_OUT, function (event: MouseEvent) {
					overBitMap.visible = false;
				});
				if (imgLoadedFun != null) {
					imgLoadedFun();
				}
			}
			loadOutImg();
			sp.buttonMode = true;
			if (name != "") {
				sp.name = name;
			}
			return sp;
		}
		public static function imgSprite(img: String = ""): Sprite {
			var mObj: Object = {
				bgAlpha: 0, //背景透明度
				width: 1,
				height: 1
			};
			var sp: Sprite = newSprite(mObj);
			var byte: ByteArray = des.getByteArray(img);
			var ld: Loader = new Loader();
			ld.loadBytes(byte); //读取ByteArray
			ld.contentLoaderInfo.addEventListener(Event.COMPLETE, function (event: Event) {
				var BitMap: Bitmap = event.target.content as Bitmap; //读取Bitmap    
				sp.addChild(BitMap);
			});
			return sp;
		}

	}

}