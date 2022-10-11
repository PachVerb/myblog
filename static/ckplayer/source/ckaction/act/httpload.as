package ckaction.act {
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.display.LoaderInfo;
	public class httpload {
		private var load: Loader = null;
		private var file: String = "";
		private var successFun: Function = null;
		public function httpload(url: String, success: Function) {
			// constructor code
			successFun = success;
			file = url;
			loader();
		}
		private function loader(): void {
			load = new Loader();
			load.contentLoaderInfo.addEventListener(Event.COMPLETE, completeHandler);
			load.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, errorHandler); //监听加载失败
			load.load(new URLRequest(file));
		}
		private function completeHandler(event: Event): void {
			successFun(load);
			remove();
		}
		private function errorHandler(event: IOErrorEvent): void {
			remove();
			successFun(null);
		}
		private function remove(): void {
			load.removeEventListener(Event.COMPLETE, completeHandler);
			load.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			load = null;
		}
	}

}