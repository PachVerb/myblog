package ckaction.act {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLStream;
	import flash.net.URLVariables;
	public class requestController {
		private var stream: URLLoader;
		private var req: URLRequest;
		public function requestController(method: String, url: String,paramsObj:Object=null ) {
			stream = new URLLoader();
			req = new URLRequest(url);
			if(paramsObj){
				var params: URLVariables=new URLVariables();
				for(var k:String in paramsObj){
					params[k]=paramsObj[k];
				}
				req.data = params;
			}
			req.method = method;
			//setHeaders(request);
			stream.addEventListener(Event.COMPLETE, completeHandler);
			stream.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			stream.load(req);
		}
		private function ioErrorHandler(event: Event): void {
			//将异常事件发出，由调用者处理
			trace("error",event);
		}
		private function completeHandler(event: Event): void {
			//trace(event.currentTarget.data);
		}
		public function dispose(): void {
			stream.removeEventListener(Event.COMPLETE, completeHandler);
			stream.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			stream = null;
			req = null;
		}
	}

}