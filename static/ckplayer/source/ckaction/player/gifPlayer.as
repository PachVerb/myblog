package ckaction.player {
	import flash.net.FileReference;
	import org.bytearray.gif.player.GIFPlayer;
	import org.bytearray.gif.events.GIFPlayerEvent;
	import org.bytearray.gif.events.FrameEvent;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.display.MovieClip;
	public class gifPlayer {
		private var g: GIFPlayer = null;
		private var file: String = "";
		private var successFun: Function = null;
		private var loadNumber:Boolean=true;
		var m: MovieClip =null;
		public function gifPlayer(url: String, success: Function) {
			// constructor code
			successFun = success;
			file = url;
			loader();
		}
		private function loader(): void {
			g = new GIFPlayer();
			g.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			g.addEventListener(GIFPlayerEvent.COMPLETE, completeHandler);
			g.addEventListener(FrameEvent.FRAME_RENDERED, frameHandler);
			g.load(new URLRequest(file));
		}
		private function ioErrorHandler(event: IOErrorEvent): void {
			successFun(null);
		}
		private function completeHandler(event: GIFPlayerEvent): void {}
		private function frameHandler(event: FrameEvent): void {
			var w: Number = event.frame.bitmapData.width;
			var h: Number = event.frame.bitmapData.height;
			if (loadNumber) {
				loadNumber = false;
				m = new MovieClip();
				m.addChild(g);
				m.width = w;
				m.height = h;
				successFun(m)
			}

		}
		public function changeWH(w:int,h:int):void{
			g.width=w;
			g.height=h;
		}
		public function underChild():void{
			m.removeChild(g);
		}
	}

}