package ckaction.process {
	import ckaction.act.script;
	import ckaction.act.loadXml;
	import ckaction.C.C;
	import ckaction.act.des;
	public class analysisVideoUrlNum {
		private var videoHandler: Function = null;
		private var videoArr: Array = [];
		private var N:int=0;
		public function analysisVideoUrlNum(fun: Function,n:int=0) {
			// constructor code
			videoHandler = fun;
			N=n;
			analysis(C.CONFIG["flashvars"]["video"][n]["video"]);
		}
		private function analysis(url:String=""): void {
			if(url.substr(0,8)=="website:"){
				loadUrl(des.getString(url.replace("website:", "")));
			}
		}
		private function loadUrl(url: String) {
			new loadXml(url, function (data: * ) {
				if (data) {
					//script.traceObject(data);
					//C.CONFIG["flashvars"]=script.mergeOldFlashvars(C.CONFIG["flashvars"], data);
					C.CONFIG["flashvars"]=script.mergeObject(C.CONFIG["flashvars"],data)
					videoHandler(true);
				} else {
					videoHandler(false);
				}
			});
		}
	}
	
}
