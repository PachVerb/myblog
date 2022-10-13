package ckaction.style {
	import flash.display.Loader;
	import flash.display.Stage;
	import flash.display.Sprite;
	import flash.events.Event;
	import ckaction.act.script;
	import flash.events.MouseEvent;
	import ckaction.act.log;

	public class poster {
		private var STAGE: Stage = null;
		private var THIS: Sprite = null,
			VPLAY:Function = null,
			GETCONTROLBARSHOW:Function=null;
		private var loadIndex:int=0;
		private var loadHandler: Function = null; //调用主控制台的into
		private var VIDEO: Object = null;
		private var picUrl: String = "";
		private var image: Loader = null;
		private var imageW: int = 0,imageH: int = 0;
		private var isLoad:Boolean=true;
		
		public function poster(stage: Stage, sprite: Sprite, vplay:Function,getControlBarShow:Function, loadFun: Function) {
			// constructor code
			STAGE = stage;
			THIS = sprite;
			VPLAY = vplay;
			GETCONTROLBARSHOW=getControlBarShow
			loadHandler = loadFun;
			stage.addEventListener(Event.RESIZE, resizeHandler);
		}
		public function loadPoster(pic: String, video: Object,index:int=0): void {
			VIDEO = video;
			picUrl = pic;
			loadIndex=index;
			if (image) {
				THIS.removeChild(image);
				image = null;
			} else {
				if(isLoad){
					new loadImg(pic, loaderHandler);
				}
				
			}
		}
		private function loaderHandler(load: Loader = null): void {
			if(!isLoad){
				return;
			}
			if (load) {
				image = load;
				imageW = image.width;
				imageH = image.height;
				THIS.addChildAt(image, loadIndex);
				image.addEventListener(MouseEvent.CLICK,function(event:MouseEvent){
						VPLAY();
					});
				imageResize();
				loadHandler(true);
			} else {
				loadHandler(false);
			}
		}
		private function imageResize(): void {
			if (image) {
				var obj: Object ={};
				if(GETCONTROLBARSHOW()){
					obj=VIDEO["reserve"];
				}
				else{
					obj=VIDEO["controlBarHideReserve"];
				}
				obj["stageW"]=STAGE.stageWidth;
				obj["stageH"]=STAGE.stageHeight;
				obj["eleW"]=imageW;
				obj["eleH"]=imageH;
				var coor:Object=script.getCoor(obj);
				image.x=coor["x"];
				image.y=coor["y"];
				image.width=coor["width"];
				image.height=coor["height"];
			}
		}
		private function resizeHandler(event: Event): void {
			if (image) {
				imageResize();
			}
		}
		public function hide():void{
			//接收外部通知,隐藏卸载掉封面图
			new log("process:Poster hide")
			isLoad=false;
			if (image) {
				THIS.removeChild(image);
				image = null;
			}
			
		}

	}

}