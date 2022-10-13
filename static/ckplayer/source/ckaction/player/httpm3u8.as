package ckaction.player {
	import org.mangui.hls.HLS;
	import org.mangui.hls.event.HLSEvent;
	import org.mangui.hls.utils.Params2Settings;
	import org.mangui.hls.constant.HLSPlayStates;
	import org.mangui.hls.model.Level;
	import flash.display.Stage;
	import flash.events.NetStatusEvent;
	import org.mangui.hls.HLSSettings;
	import flash.media.SoundTransform;
	import ckaction.C.C;
	import flash.events.Event;

	public class httpm3u8 {
		public var videoUrl: String = "";

		public var netStatus: Function = null,
			streamSendOut: Function = null,
			error: Function = null; //发送流状态的函数，发送流的函数，统一用来报错的函数
		public var definitionList: Function = null,
			definitionNow: Function = null;
		public var speedFun:Function=null;
		public var stage: Stage = null;
		public var usehardwareeecoder:Boolean=false;
		private var hls: HLS = null;
		private var isClear: Boolean = false; //默认不清除
		private var vWidth: int = 0,
			vHeight: int = 0,
			time: Number = 0,
			duration: Number = 0,
			bytesTotal: int = 0,
			bytesLoaded: int = 0;
		private var urlArr: Array = [];
		public function httpm3u8() {
			// constructor code
		}
		public function load(eve: Boolean = true): void {
			if (C.CONFIG["flashvars"]["debug"]) {
				org.mangui.hls.HLSSettings.logInfo = true;
				org.mangui.hls.HLSSettings.logDebug2 = true;
				org.mangui.hls.HLSSettings.logWarn = true;
				org.mangui.hls.HLSSettings.logError = true;
			}
			org.mangui.hls.HLSSettings.maxBufferLength = C.CONFIG["config"]["m3u8MaxBufferLength"];
			if (isClear) { //如果已被清除，则不进行下面的动作
				return;
			}
			hls = new HLS();
			hls.stage = stage;
			hls.addEventListener(HLSEvent.PLAYBACK_COMPLETE, completeHandler);
			hls.addEventListener(HLSEvent.ERROR, errorHandler);
			hls.addEventListener(HLSEvent.MANIFEST_LOADED, manifestHandler);
			hls.addEventListener(HLSEvent.MEDIA_TIME, mediaTimeHandler);
			hls.addEventListener(HLSEvent.PLAYBACK_STATE, stateHandler);
			hls.addEventListener(HLSEvent.FRAGMENT_LOADING, fragmentHandler);
			hls.addEventListener(HLSEvent.FRAGMENT_PLAYING, fragmentPlayingHandler);
			hls.addEventListener(HLSEvent.ID3_UPDATED, ID3Handler);
			hls.addEventListener(HLSEvent.FRAGMENT_LOADED, fragmentLoadedHandler);
			hls.addEventListener(HLSEvent.LOADED_BYTES,loadedBytesHandler);
			hls.stream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			try{
				hls.stream.useHardwareDecoder=usehardwareeecoder;
			}
			catch(error:Event){
				
			}
			hls.load(videoUrl);
		}
		private function fragmentLoadedHandler(event: HLSEvent): void {
			if (bytesLoaded < bytesTotal) {
				bytesLoaded++;
			}
		}
		private function loadedBytesHandler(event: HLSEvent): void {
			trace("加载量：",event.loadedBytes);
			speedFun(event.loadedBytes);
		}
		private function completeHandler(event: HLSEvent): void {
			//trace("hls:completeHandler", event);
		}
		private function errorHandler(event: HLSEvent): void {
			//trace("hls:errorHandler", event);
			error(C.CONFIG["language"]["error"]["streamNotFound"]);
			clear();
		}
		private function manifestHandler(event: HLSEvent): void { //可以播放了
			trace("可以进行播放====");
			var i: int = 0;
			var len: int = event.levels.length;
			while (i < len) {
				//trace("==",event.levels[i].url);
				urlArr.push(event.levels[i].url);
				i++;
			}
			trace(event.levels[hls.startLevel].url);
			if (urlArr.length > 1) {
				definitionList(urlArr, hls.startLevel);
			}
			bytesTotal = event.levels[hls.startLevel].fragments.length;
			if (isClear) {
				return;
			}
			hls.stream.play();
			duration = event.levels[hls.startLevel].duration;
			netStatus("NetConnection.Connect.Success");
		}
		private function mediaTimeHandler(event: HLSEvent): void {
			//监听时间改变
			time = Math.max(0, event.mediatime.position);

		}
		private function stateHandler(event: HLSEvent) {
			if (event.level < urlArr.length - 1) {
				definitionNow(event.level);
			}
			switch (event.state) {
				case HLSPlayStates.PLAYING_BUFFERING:
					break;
				case HLSPlayStates.PAUSED_BUFFERING:
					break;
				case HLSPlayStates.PLAYING:
					break;
				case HLSPlayStates.PAUSED:
					break;
				case HLSPlayStates.IDLE: //播放结束
					netStatus("NetStream.Play.Stop");
					break;
				default:
					break;
			}
		}
		private function fragmentHandler(event: HLSEvent): void {
			//trace("hls:fragmentHandler", event.playMetrics)
		}
		private function ID3Handler(event: HLSEvent) {
			//trace("hls:ID3Handler", event);
		}
		private function netStatusHandler(event: NetStatusEvent): void {
			//trace("========",event.info.code);
			netStatus(event.info.code);
		}
		private function fragmentPlayingHandler(event: HLSEvent): void {
			if (vWidth == 0 && vHeight == 0) {
				vWidth = event.playMetrics.video_width;
				vHeight = event.playMetrics.video_height;
				hls.stream.pause();
				var metaDataObj: Object = {
					netStream: hls.stream,
					type: "[object HLSNetStream]",
					metaData: {
						width: vWidth,
						height: vHeight,
						duration: duration,
						bytesTotal: bytesTotal

					}
				};
				//模拟发送监听状态
				netStatus("NetStream.Play.Start");
				streamSendOut(metaDataObj);
			}
			trace("hls:fragmentPlayingHandler", event);

		}
		public function videoVolume(val: Number = 0): void { //修改音量
			var v: SoundTransform = hls.stream.soundTransform;
			v.volume = val;
			if (hls.stream) {
				hls.stream.soundTransform = v;
			}

		}
		public function videoSeek(time: Number = 0): void {
			if (hls.stream) {
				var n: int = time/(duration / bytesTotal);
				if (bytesLoaded < n) {
					bytesLoaded = n;
				}
				hls.stream.seek(time);
			}
		}
		//提供给外部调用使用
		public function getTime(): Number {
			return time;
		}
		public function getDuration(): Number {
			return duration;
		}
		public function getBytesLoaded(): Number {
			return bytesLoaded;
		}
		public function getBytesTotal(): Number {
			return bytesTotal;
		}
		public function getBufferTime(): Number {
			if (hls.stream != null) {
				return hls.stream.bufferTime;
			}
			return 0;
		}
		public function getBufferLength(): Number {
			if (hls.stream != null) {
				return hls.stream.bufferLength;
			}
			return 0;
		}
		public function videoPlay(): void {
			trace("==执行了m3u8-videoPlay");
			if (hls.stream != null) {
				hls.stream.resume();
			}
		}
		public function videoPause(): void {
			if (hls.stream != null) {
				hls.stream.pause();
			}
		}
		//提供给外部调用结束
		public function clear(): void {
			isClear = true;
			if (hls) {
				hls.removeEventListener(HLSEvent.PLAYBACK_COMPLETE, completeHandler);
				hls.removeEventListener(HLSEvent.ERROR, errorHandler);
				hls.removeEventListener(HLSEvent.MANIFEST_LOADED, manifestHandler);
				hls.removeEventListener(HLSEvent.MEDIA_TIME, mediaTimeHandler);
				hls.removeEventListener(HLSEvent.PLAYBACK_STATE, stateHandler);
				hls.removeEventListener(HLSEvent.FRAGMENT_LOADING, fragmentHandler);
				hls.removeEventListener(HLSEvent.FRAGMENT_PLAYING, fragmentPlayingHandler);
				hls.removeEventListener(HLSEvent.ID3_UPDATED, ID3Handler);
				hls.removeEventListener(HLSEvent.FRAGMENT_LOADED, fragmentLoadedHandler);
				hls.removeEventListener(HLSEvent.LOADED_BYTES,loadedBytesHandler);
				hls.stream.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
				hls.stream.close();
				hls = null;
			}

		}
	}

}