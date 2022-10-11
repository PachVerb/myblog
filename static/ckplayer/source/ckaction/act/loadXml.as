package ckaction.act {
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import ckaction.act.XML2JSON;
	import flash.events.ErrorEvent;
	import ckaction.C.C;
	import flash.net.URLVariables;

	public class loadXml {
		private var f: Function; //加载成功或失败都返回该函数
		private var l: URLLoader = null;
		public function loadXml(m: String, c: Function, met: String = "get"): void {
			if(!m){
				trace("没有文件路径");
				c(null);
				return;
			}
			f = c;
			var r: URLRequest = new URLRequest(m);
			//var params: URLVariables = new URLVariables();
			//params["path"]=C.PATH["path"]+C.PATH["file"];
			//r.data=params;
			//r.method = met;
			l = new URLLoader();
			l.addEventListener(Event.COMPLETE, com);
			l.addEventListener(IOErrorEvent.IO_ERROR, err);
			l.load(r);
		}
		private function remove(): void {
			l.removeEventListener(Event.COMPLETE, com);
			l.removeEventListener(IOErrorEvent.IO_ERROR, err);
		}
		private function com(event: Event): void {
			var str: String = event.currentTarget.data.toString();
			if (str.indexOf("<?xml version=") > -1 || str.indexOf("</") > -1) {
				var xml: XML = new XML(event.currentTarget.data);
				if (xml) {
					try {
						analysis(xml);
					} catch (event: Error) {
						f(null);
					}
				} else {
					f(null);
				}
			} else if (str.indexOf("{") == 0 || str.indexOf("[") == 0) {
				try {
					var json: Object = JSON.parse(event.currentTarget.data);
					if (json != null) {
						
						f(json);
					} else {
						f(null);
					}
				} catch (event: Error) {
					new log(event);
					trace(event);
					f(null);
				}
			} else {
				f(str);
			}
			remove();
		}
		private function analysis(xml: XML): void {
			var obj: Object = XML2JSON.parse(xml);
			try {
				f(obj);
			} catch (event: Error) {
				f(null);
			}
		}
		private function err(event: IOErrorEvent) {
			f(null);
			remove();
		}

	}

}