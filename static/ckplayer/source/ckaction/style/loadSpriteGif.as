package ckaction.style {
	import flash.display.Sprite;
	import ckaction.player.gifPlayer;
	import flash.display.MovieClip;

	public class loadSpriteGif {
		

		public static function loadGif(url: String, w: int = 0, h: int = 0,radius:int=0,num:int=12): Sprite {
			//trace(url,w,h,radius);
			var sprite: Sprite = new Sprite();
			var gif:gifPlayer=null;
			loadImg();
			function loadImg(): void {
				gif=new gifPlayer(url,completeHandler)
			}
			function completeHandler(m:MovieClip): void {
				sprite.addChild(m);
				var obj:Object={
					width:w,
					height:h,
					radius:radius,
					backgroundColor: 0xFFFFFF, //背景颜色
					backgroundAlpha: 1 //背景透明度
				};
				gif.changeWH(w,h);
				
				var maskSprit:Sprite=element.newSprite(obj);
				sprite.addChild(maskSprit);
				sprite.mask=maskSprit;
				
			}			
			return sprite;
		}

	}

}