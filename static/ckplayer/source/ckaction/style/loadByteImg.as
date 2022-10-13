package ckaction.style {
	import flash.utils.ByteArray;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.display.Bitmap;
	import flash.events.ErrorEvent;
	import ckaction.act.des;

	public class loadByteImg {

		public function loadByteImg(file: String, success: Function,myName:String="") {
			// constructor code
			//检查file是否需要解密
			//
			var ld: Loader = new Loader();
			try {
				var bt: ByteArray = des.getByteArray(file);
				ld.loadBytes(bt);
				ld.contentLoaderInfo.addEventListener(Event.COMPLETE, function (event: Event) {
					if(myName){
						ld.name=myName;
					}
					success(ld);
				});
			} catch (event:ErrorEvent) {
				if(myName){
					success(null,myName);
				}
				else{
					success(null);
				}
			}

		}


	}

}