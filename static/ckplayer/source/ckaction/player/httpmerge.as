package ckaction.player {
	import ckaction.act.script;
	import ckaction.act.timeInterval;
	import ckaction.C.C;
	import ckaction.act.des;
	import ckaction.act.timeOut;
	import ckaction.process.getVideoMeta;

	public class httpmerge {
		public var videoUrl: Array = [];
		public var netStatus: Function = null,
			streamSendOut: Function = null,
			error: Function = null; //发送流状态的函数，发送流的函数，统一用来报错的函数
		public var speedFun:Function=null;
		private var timeTotal: Number = 0,
			bytesTotal: Number = 0; //总时间，总字节
		private var timeArr: Array = [],
			bytesArr: Array = []; //时间数组，字节数组
		//private var DRAG:String="";
		private var isClear: Boolean = false; //默认不清除
		private var nowVolume: Number = 0;
		private var playNum: int = 0; //当前播放的视频编号
		private var loadNum: int = 0; //加载编号
		private var bytesMax:int=0;//已加载的编号最大编号
		private var nsArr: Array = [],
			streamArr: Array = [];
		private var loadedArr: Array = []; //是否已加载0=没有加载，1=正在加载，2=已加载
		private var interBytes: timeInterval = null;
		private var loadFrist:Boolean=true;
		private var loadNext: int = 0;
		private var playSeek: Number = -1; //默认要跳转的秒数，只有在跳转到新时间而相应的视频段没有加载的情况下才需要用到
		private var getMeta:getVideoMeta=null;
		public function httpmerge() {
			// constructor code
			//DRAG=C.CONFIG["flashvars"]["drag"];
		}
		public function load(): void {
			if (isClear) { //如果已被清除，则不进行下面的动作
				return;
			}
			trace("新建了一个视频");
			//script.traceObject(videoUrl);
			loadNext = C.CONFIG["config"]["loadNext"];
			var tempUrl:Object=videoUrl[0];
			if(!tempUrl.hasOwnProperty("duration") || !tempUrl.hasOwnProperty("bytesTotal")){
				getMeta=new getVideoMeta(videoUrl,loadUrl,speed);
			}
			else{
				loadUrl()
			}
		}
		private function speed(t:int=0):void{
			speedFun(Math.ceil(t*100/videoUrl.length));
		}
		private function loadUrl(ele:Array=null):void{
			if (isClear) { //如果已被清除，则不进行下面的动作
				return;
			}
			if(ele!=null){
				videoUrl=ele;
			}
			for (var i: int = 0; i < videoUrl.length; i++) {
				var stream: httpstream = new httpstream();
				if(C.CONFIG["flashvars"]["unescape"]){
					stream.videoUrl = unescape(des.getString(videoUrl[i]["file"]));
				}
				else{
					stream.videoUrl = des.getString(videoUrl[i]["file"]);
				}
				
				stream.netStatus = NetStatus;
				stream.streamSendOut = StreamSendOut;
				stream.error = errorNow;
				stream.NUM = i;
				loadedArr.push(0);
				nsArr.push(stream);
				streamArr.push(null);
				//计算总时间
				timeArr.push(Number(videoUrl[i]["duration"]));
				bytesArr.push(Number(videoUrl[i]["bytesTotal"]));
			}
			nsArr[0].load();
			loadedArr[0]=1;
			timeTotal = script.arrSum(timeArr);
			bytesTotal = script.arrSum(bytesArr);
			if (loadNext == 0) {
				loadNext = nsArr.length;
			}
		}
		private function NetStatus(status: String, n: int = 0) {
			//trace(status);
			//trace("接爱到状态",n,status,new Date().getMilliseconds());
			
			//trace("httpmerge",status);
			switch (status) {
				case "NetStream.Play.Stop": //播放完毕
					trace(playNum,n);
					if (playNum == n && playNum < nsArr.length - 1) { //说明是播放结束
						nsArr[playNum].videoPause();
						trace("开始请求下一段",new Date().getMilliseconds());
						newPlay(playNum+1, 0); //播
					}
					break;
				default:
					break;
			}
			if (playNum == n) {
				if (n == 0) {
					if (status != "NetStream.Play.Stop") {
						netStatus(status);
					}
				}
				else if (n < nsArr.length - 1) {
					if (status != "NetStream.Play.Stop" && status != "NetStream.Play.Start") {
						netStatus(status);
					}
				}
				else {
					if (status != "NetStream.Play.Start") {
						netStatus(status);
					}
				}
			}
		}
		private function StreamSendOut(obj: Object, n: int = 0): void {
			if (isClear) {
				return;
			}
			if (streamArr[n] == null) {
				streamArr[n] = obj;
			}
			bytesArr[n] = obj["metaData"]["bytesTotal"]; //更新当前段的字节
			if (loadFrist) {
				//trace("playSeek",playSeek);
				loadFrist=false;
				obj["metaData"]["duration"] = timeTotal;
				obj["metaData"]["bytesTotal"] = bytesTotal;
				streamSendOut(obj);
			}
			else {
				if (playNum == n) {
					streamSendOut(obj);
					//trace("playSeek",playSeek);
					if(playSeek>-1){
						nsArr[playNum].videoSeek(playSeek);
						
						playSeek=-1;
					}
					videoVolume(nowVolume);
				}
				else {
					nsArr[n].videoPause();
				}
			}
			if (!interBytes) {
				interBytes = new timeInterval(200, interBytesHandler);
			}
			interBytes.start();
		}
		private function interBytesHandler(): void {

			//判断是否需要加载下一项
			var loaded: Number = nsArr[loadNum].getBytesLoaded();
			var loadTotal: Number = nsArr[loadNum].getBytesTotal();
			if (loaded >= loadTotal) {
				loadedArr[loadNum] = 2; //说明该段已加载
				if ((loadNum - playNum) < loadNext && loadNum < (nsArr.length - 1)) {
					loadNum++;
					if (loadedArr[loadNum] == 0) {
						nsArr[loadNum].load();
						loadedArr[loadNum] = 1; //说明该段正在加载
					}
				}
				else {
					interBytes.stop();
				}
			}
		}
		//提供给外部调用使用
		public function getTime(): Number {
			//trace(nsArr[playNum].getTime());
			//trace(nsArr[playNum].getTime(),script.arrSum(timeArr, playNum));
			//trace("当前播放：",playNum);
			var temp:Number=nsArr[playNum].getTime() + script.arrSum(timeArr, playNum);
			//trace(temp,"==");
			if(temp<timeTotal){
				return temp;
			}
			else{
				return timeTotal;
			}
		}
		public function getBytesLoaded(): Number {
			var temp:Number=nsArr[loadNum].getBytesLoaded() + script.arrSum(bytesArr, loadNum);
			if(temp>bytesMax){
				bytesMax=temp;
			}
			return bytesMax;
		}
		public function getDuration(): Number {
			return timeTotal;
		}
		public function getBytesTotal(): Number {
			return bytesTotal;
		}
		public function getBufferTime(): Number {
			return nsArr[playNum].getBufferTime();
		}
		public function getBufferLength(): Number {
			return nsArr[playNum].getBufferLength();
		}
		public function videoPlay(): void {
			nsArr[playNum].videoPlay();
		}
		public function videoPause(): void {
			nsArr[playNum].videoPause();
		}
		public function videoSeek(time: Number = 0): void {
			//nsArr[playNum].videoSeek();
			//计算该时间属于第几段
			
			var position: int = 0; //属于第几段
			var t: int = 0;
			for (var i: int = 0; i < timeArr.length; i++) {
				t += timeArr[i];
				if (t > time) {
					position = i;
					break;
				}
			}
			
			var tempTime: int = time - script.arrSum(timeArr, position);
			//trace("客户",time,script.arrSum(timeArr, position-1),script.arrSum(timeArr, position),tempTime);
			if (position == playNum) { //在目前已播放的段落里播放
				nsArr[playNum].videoSeek(tempTime);
			}
			else { //不在目前已播放的段落里播放
				//trace("要跳转的===============",timeArr, position);
				nsArr[playNum].videoPause();
				newPlay(position, tempTime);
			}
			//trace("要跳转的",position,tempTime);
		}
		private function newPlay(position: int = 0, tempTime: int = 0): void { //播放指定段，指定时间
			//trace("跳转测试",streamArr[position] != null,playNum,position);
			playNum = position;
			if (streamArr[position] != null) { //如果要跳转的段落已加载
				//trace("执行监测时间01",new Date().getMilliseconds());
				streamSendOut(streamArr[position]);
				//trace("执行监测时间02",new Date().getMilliseconds());
				nsArr[position].videoSeek(tempTime);
				//trace("执行监测时间03",new Date().getMilliseconds());
				videoPlay();
				videoVolume(nowVolume);
				interBytes.start();
				
			}
			else {
				deleteLoad();
				playSeek = tempTime;
				loadNum = position;
				interBytes.stop();
				nsArr[loadNum].load();
				loadedArr[loadNum] = 1; //说明该段正在加载
			}
		}
		private function deleteLoad(): void {
			//清除所有在加载又没有加载完的段数
			for (var i: int = 0; i < loadedArr.length; i++) {
				if (loadedArr[i] == 1 || (i<playNum && C.CONFIG["config"]["smartRemove"])) {
					nsArr[i].clear();
					nsArr[i]=null;
					var stream: httpstream = new httpstream();
					stream.videoUrl = des.getString(videoUrl[i]["file"]);
					stream.netStatus = NetStatus;
					stream.streamSendOut = StreamSendOut;
					stream.error = error;
					stream.NUM = i;
					nsArr[i]=stream;
					streamArr[i]=null;
					loadedArr[i]=0;
				}
			}
		}
		public function videoVolume(val: Number = 0): void { //修改音量
			nowVolume = val;
			nsArr[playNum].videoVolume(val);
		}
		public function clear(): void {
			isClear = true; //设置清除
			for (var i = 0; i < nsArr.length; i++) {
				nsArr[i].clear();
			}
			if(getMeta){
				getMeta.clear();
				getMeta=null;
			}
		}
		public function errorNow(string:String=""):void{
			clear();
			error(string);
		}
	}

}