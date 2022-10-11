package ckaction.process {
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.AsyncErrorEvent;

	public class getVideoMeta {
		private var videoArr: Array = [];
		private var isClear: Boolean = false;
		private var loadI: int = 0;
		private var nc: NetConnection = null;
		private var ns: NetStream = null;
		private var complete:Function=null;
		private var speedFun:Function=null;
		public function getVideoMeta(arr,fun,speed) {
			// constructor code
			videoArr = arr;
			complete=fun;
			speedFun=speed;
			nc = new NetConnection();
			nc.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			nc.addEventListener(AsyncErrorEvent.ASYNC_ERROR, netSteameErrorHandler);
			nc.connect(null);
		}
		private function netStatusHandler(event: NetStatusEvent): void {
			switch (event.info.code) {
				case "NetConnection.Connect.Success":
					connectStream();
					break;
				default:
					break;
			}
			//trace(event.info.code);

		}
		private function securityErrorHandler(event: SecurityErrorEvent): void {}
		private function netSteameErrorHandler(event: AsyncErrorEvent): void {}
		private function connectStream(): void {
			if (isClear) { //如果已被清除，则不进行下面的动作
				return;
			}
			var customClient = new Object();
			customClient.onMetaData = metaDataHandler;
			ns = new NetStream(nc);
			ns.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			ns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, netSteameErrorHandler);
			ns.client = customClient;
			ns.play(videoArr[loadI]["file"]);
		}
		private function metaDataHandler(info: Object): void {
			videoArr[loadI]["duration"] = info["duration"];
			videoArr[loadI]["bytesTotal"] = ns.bytesTotal;
			ns.dispose();
			ns.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			ns.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, netSteameErrorHandler);
			ns = null;
			speedFun(loadI);
			if (loadI < videoArr.length - 1) {
				loadI++;
				connectStream();
			} else {
				complete(videoArr);
			}
		}
		public function clear(): void {
			isClear = true;
		}

	}

}