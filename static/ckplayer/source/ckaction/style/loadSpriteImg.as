package ckaction.style {
	/*
		软件名称：chplayer
		软件作者：http://www.chplayer.com
		开源软件协议：Mozilla Public License, version 2.0(MPL 2.0)
		MPL 2.0协议英文（原文，正本）查看地址：https://www.mozilla.org/en-US/MPL/2.0/
		MPL 2.0协议中文（翻译）查看地址：http://www.chplayer.com/res/Mozilla_Public_License_2.0_Simplified_Chinese_Reference.txt
		文件最后更新日期：2017-03-17
	*/
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;

	public class loadSpriteImg {
		

		public static function loadImg(url: String, w: int = 0, h: int = 0,radius:int=0,num:int=12,lname:String=""): Sprite {
			//trace(url,w,h,radius);
			var load: Loader = null;
			var sprite: Sprite = new Sprite();
			loadImg();
			function loadImg(): void {
				load = new Loader();
				load.contentLoaderInfo.addEventListener(Event.COMPLETE, completeHandler);
				load.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, errorHandler); //监听加载失败
				load.load(new URLRequest(url));
			}
			function completeHandler(event: Event): void {
				load.width = w;
				load.height = h;
				sprite.addChild(load);
				if(radius>0){
					var spObj:Object={
						backgroundColor:"#FFFFFF",
						width:w,
						height:h,
						radius:radius
					};
					var mSprite:Sprite=element.newSprite(spObj);
					sprite.addChild(mSprite);
					load.mask=mSprite;
				}
				load.name=lname!=""?lname:"ele_"+num;
			}
			function errorHandler(event: IOErrorEvent): void {
				//trace("加载失败");
				remove();
			}
			function remove(): void {
				load.removeEventListener(Event.COMPLETE, completeHandler);
				load.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
				load = null;
			}
			
			return sprite;
		}

	}

}