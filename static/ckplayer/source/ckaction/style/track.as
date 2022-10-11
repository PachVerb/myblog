package ckaction.style {
	import flash.display.Sprite;
	import ckaction.act.loadXml;
	import ckaction.act.script;

	public class track {
		private var THIS: Sprite = null;
		private var CFIG: Object = {};
		private var trackList: Array = [];
		private var trackIndex: int = 0;
		private var trackDelay:Number=0;
		private var nowTrackShow: Object = {
			sn: ""
		};
		private var trackElement: Array = [];
		private var time: Number = 0;
		private var isClose: Boolean = false;
		public function track(sp: Sprite, config: Object, file: String = "",trackD:Number=0) {
			if (!file) {
				return;
			}
			THIS = sp;
			CFIG = config;
			trackDelay=trackD;
			new loadXml(file, function (data: String) {
				if (isClose) {
					return;
				} else {
					if (data) {
						//trace(data);
						trackList = parseSrtSubtitles(data);
						//script.traceObject(trackList);
					}
				}

			});
			// constructor code
		}
		public function changeSize(n:int=0,m:int=0):void{
			CFIG["size"]=n;
			CFIG["leading"]=m;
			trackHide();
			trackShow(nowTrackShow);
		}
		public function sendTime(t: Number): void {
			if (isClose) {
				return;
			}
			time = t;
			if (trackIndex >= trackList.length) {
				trackIndex = 0;
			}

			
			var nowTrack: Object = trackList[trackIndex]; //当前编号对应的字幕内容
			if(nowTrack==null){
				return;
			}
			/*
				this.nowTrackShow=当前显示在界面上的内容
				如果当前时间正好在nowTrack时间内，则需要判断
			*/
			//trace(t,trackIndex,nowTrack["startTime"],nowTrack["endTime"]);
			if (t >= nowTrack["startTime"] && t <= nowTrack["endTime"]) {
				/*
				 	如果当前显示的内容不等于当前需要显示的内容时，则需要显示正确的内容
				*/
				var nowShow = nowTrackShow;
				if (nowShow["sn"] != nowTrack["sn"]) {
					trackHide();
					trackShow(nowTrack);
				}
			} else {
				/*
				 * 如果当前播放时间不在当前编号字幕内，则需要先清空当前的字幕内容，再显示新的字幕内容
				 */
				//trace("重新计算编号");
				trackHide();
				checkTrack();
			}
		}
		//==========================================
		private function trackShow(track: Object) {
			if (isClose) {
				return;
			}
			nowTrackShow = track;
			var arr: Array = track["content"];
			for (var i: int = 0; i < arr.length; i++) {
				var tObj:Object=CFIG;
				tObj["type"]="text";
				tObj["text"]=arr[i];
				
				/*var tObj:Object={
						type: "text",
						text: arr[i],
						color: CFIG["color"],
						size: CFIG["size"],
						font: CFIG["font"],
						leading: CFIG["leading"],
						bold: CFIG["bold"],
						alpha: 1
					};*/
				//if(CFIG.hasOwnProperty("backgroundColor")){
				//	tObj["backgroundColor"]=CFIG["backgroundColor"];
				//}
				
				var obj: Object = {
					list: [tObj],
					position: [1, 2, null, -(arr.length - i) * CFIG["leading"] - CFIG["marginBottom"]]
				};
				var ele: String = THIS["addElement"](obj);
				trackElement.push(ele);
			}
		}
		/*
			内部函数
			隐藏字字幕内容
		*/
		private function trackHide() {
			for (var i: int = 0; i < trackElement.length; i++) {
				THIS["deleteElement"](trackElement[i]);
			}
			trackElement = [];
		}
		/*
			内部函数
			重新计算字幕的编号
		*/
		private function checkTrack() {
			if (isClose) {
					return;
				}
			var num: int = trackIndex;
			var arr: Array = trackList;
			var i = 0;
			var have = false;
			for (i = num; i < arr.length; i++) {
				if (time >= arr[i]["startTime"] && time <= arr[i]["endTime"]) {
					trackIndex = i;
					//trace("新的编号：",time,trackIndex);
					have = true;
					break;
				}
			}
			if (!have) {
				trackIndex = 0;
			}
		}
		//=================================
		private function delHtmlTag(str: String) {
			return str.replace(/<[^>]+>/g, ""); //去掉所有的html标记
		}
		private function trim(str: String) {
			return str.replace(/(^\s*)|(\s*$)/g, "");
		}
		private function toSeconds(t: String) { //将时分秒转换成秒
			var s: int = 0.0;
			if (t) {
				var p: Array = t.split(":");
				for (var i: int = 0; i < p.length; i++) {
					s = s * 60 + parseFloat(p[i].replace(",", "."));
				}
			}
			return s;
		}
		private function parseSrtSubtitles(srt: String) {
			var subtitles: Array = [];
			var textSubtitles: Array = [];
			var i: int = 0;
			var arrs: Array = srt.split("\n");
			var arr: Array = [];

			for (i = 0; i < arrs.length; i++) {
				if (arrs[i].replace(/\s/g, "").length > 0) {
					arr.push(arrs[i]);
				} else {
					if (arr.length > 0) {
						textSubtitles.push(arr);
					}
					arr = [];
				}
			}
			for (i = 0; i < textSubtitles.length; ++i) {
				var textSubtitle: Array = textSubtitles[i];
				if (textSubtitle.length >= 2) {
					var sn: int = textSubtitle[0]; // 字幕的序号
					var startTime: Number = toSeconds(trim(textSubtitle[1].split(" --> ")[0])); // 字幕的开始时间
					var endTime: Number = toSeconds(trim(textSubtitle[1].split(" --> ")[1])); // 字幕的结束时间
					var content: Array = [delHtmlTag(textSubtitle[2])]; // 字幕的内容
					if(trackDelay!=0){
						startTime+=trackDelay;
						endTime+=trackDelay;
					}
					// 字幕可能有多行
					if (textSubtitle.length > 2) {
						for (var j = 3; j < textSubtitle.length; j++) {
							content.push(delHtmlTag(textSubtitle[j]));
						}
					}
					// 字幕对象
					var subtitle: Object = {
						sn: sn,
						startTime: startTime,
						endTime: endTime,
						content: content
					};
					subtitles.push(subtitle);
				}
			}
			return subtitles;
		}
		public function close(): void {
			trackHide();
			isClose=true;
		}

	}

}