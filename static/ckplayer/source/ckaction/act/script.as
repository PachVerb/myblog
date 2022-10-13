package ckaction.act {
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.ByteArray;
	import flash.events.ErrorEvent;
	//import ckaction.C.C;

	public class script {

		public static function formatTime(seconds: Number = 0, hourc: int = 0, hours: int = 0): Array { //格式化秒数为时分秒
			//seconds = 3800;
			var timeh: int = Math.floor(seconds / 3600),
				timei = Math.floor(Math.floor(seconds % 3600) / 60),
				timeI = Math.floor(seconds / 60),
				times = Math.floor(Math.floor(seconds % 60));
			if (hourc > 0) {
				timeh += (hours - hourc + 1);
				if (timeh < 0) {
					timeh = 24 + timeh;
				}
			}
			var array: Array = [
				timeh < 10 ? "0" + timeh : timeh.toString(),
				timei < 10 ? "0" + timei : timei.toString(),
				timeI < 10 ? "0" + timeI : timeI.toString(),
				times < 10 ? "0" + times : times.toString(),
				seconds < 10 ? "0" + seconds : seconds.toString()
			];
			return array;
		}
		public static function formatInsertTime(str: String = "", total: Number = 0): Array {
			//trace(str,total);
			if (!str) {
				return null;
			}
			var arr: Array = str.split(",");
			var newArr: Array = [];
			for (var i: int = 0; i < arr.length; i++) {
				var s: String = arr[i].toString();
				if (s.indexOf("%") > -1) {
					newArr.push(total * Number(s.replace("%", "")) * 0.01);
				} else {
					newArr.push(Number(s));
				}
			}
			//trace("jfuj",newArr);
			return newArr;
		}
		public static function formatM3u8Definition(url: String, n: int = 0, tags: Array = null, name: Array = null): String {
			var i: int = 0;
			if (!name) {
				return "";
			}
			if (tags.length > 0) {
				var ti: int = 0;
				for (i = 0; i < tags.length; i++) {
					if (url.indexOf(tags[i]) > -1) {
						ti = i;
						break;
					}
				}
				if (ti < name.length) {
					return name[ti];
				} else {
					return name[name.length - 1];
				}

			} else {
				if (n < name.length) {
					return name[n];
				} else {
					return name[name.length - 1];
				}
			}
		}
		public static function getNowDate(b: Boolean = true): String { //获取当前时间
			var nowDate: Date = new Date();
			var month: int = nowDate.month + 1;
			var date: int = nowDate.date;
			var hours: int = nowDate.hours;
			var minutes: int = nowDate.minutes;
			var seconds: int = nowDate.seconds;
			var tMonth: String = "",
				tDate: String = "",
				tHours: String = "",
				tMinutes: String = "",
				tSeconds: String = ""
			tSeconds = (seconds < 10) ? "0" + seconds : seconds + "";
			tMinutes = (minutes < 10) ? "0" + minutes : minutes + "";
			tHours = (hours < 10) ? "0" + hours : hours + "";
			tDate = (date < 10) ? "0" + date : date + "";
			tMonth = (month < 10) ? "0" + month : month + "";
			if (b) {
				return tMonth + "/" + tDate + " " + tHours + ":" + tMinutes + ":" + tSeconds;
			}
			return nowDate.fullYear + tMonth + tDate + tHours + tMinutes + tSeconds;
		}
		public static function getFileExt(filepath: String = null): String { //判断后缀，和rtmp协议
			if (filepath != "") {
				if (filepath.substr(0, 7) == "rtmp://") {
					return "rtmp";
				}
				if (filepath.indexOf("?") > -1) {
					filepath = filepath.split("?")[0];
				}
				var pos: String = "." + filepath.replace(/.+\./, "");
				return pos;
			}
			return "";
		}
		public static function arrSort(arr: Array): Array { //对二维数组进行冒泡排序
			var temp: Array = [];
			for (var i: int = 0; i < arr.length; i++) {
				for (var j: int = 0; j < arr.length - i; j++) {
					if (arr[j + 1] && arr[j][3] < arr[j + 1][3]) {
						temp = arr[j + 1];
						arr[j + 1] = arr[j];
						arr[j] = temp;
					}
				}
			}
			return arr;
		}
		public static function getCoor(obj: Object): Object {
			/*根据宽高计算元素的长宽和坐标
			obj={
				stageW=播放器的宽
				stageH=播放器的高
				eleW=元件的宽
				eleH=元件的高
				stretched=缩放形式：0=原始大小，1=自动缩放，2=只有当元件的宽或高大于播放器宽高时才进行缩放，3=参考播放器宽高，4=宽度参考播放器宽、高度自动，5=高度参考播放器高、宽度自动
				align=水平对齐方式 left,center,right
				vAlign=垂直对齐方式 top.middle,bottom
				spacingLeft=左方预留间距
				spacingTop=上方预留间距
				spacingRight=右方预留间距
				spacingBottom=下方预留间距
			}
			*/
			var nObj: Object = mergeObject({
				stageW: 0,
				stageH: 0,
				eleW: 0,
				eleH: 0,
				stretched: 0,
				align: "center",
				vAlign: "middle",
				spacingLeft: 0,
				spacingTop: 0,
				spacingRight: 0,
				spacingBottom: 0
			}, obj);
			//traceObject(nObj);
			var stageW: int = nObj["stageW"] - nObj["spacingLeft"] - nObj["spacingRight"];
			var stageH: int = nObj["stageH"] - nObj["spacingTop"] - nObj["spacingBottom"];
			var eleW: int = nObj["eleW"];
			var eleH: int = nObj["eleH"];
			var w: int = eleW,
				h: int = eleH,
				x: int = 0,
				y: int = 0;

			if (nObj["stretched"] == 2) {
				if (eleW > stageW) {
					nObj["stretched"] = 4;
				}
				if (eleH > stageH) {
					nObj["stretched"] = 5;
				}
				if (eleW > stageW && eleH > stageH) {
					nObj["stretched"] = 1;
				}
			}
			switch (nObj["stretched"]) {
				case 1:
					if (stageW / stageH < eleW / eleH) {
						w = stageW;
						h = w * eleH / eleW;
					} else {
						h = stageH;
						w = h * eleW / eleH;
					}
					break;
				case 3:
					w = stageW;
					h = stageH;
					break;
				case 4:
					w = stageW;
					h = w * eleH / eleW;
					break;
				case 5:
					h = stageH;
					w = h * eleW / eleH;
					break;
				default:
					break;

			}
			switch (nObj["align"]) {
				case "left":
					x = nObj["spacingLeft"];
					break;
				case "center":
					x = (stageW - w) * 0.5 + nObj["spacingLeft"];
					break;
				case "right":
					x = stageW - w + nObj["spacingLeft"];
					break;
				default:
					break;

			}
			switch (nObj["vAlign"]) {
				case "top":
					y = nObj["spacingTop"];
					break;
				case "middle":
					y = (stageH - h) * 0.5 + nObj["spacingTop"];
					break;
				case "bottom":
					y = stageH - h + nObj["spacingTop"];
					break;
				default:
					break;

			}
			//trace(w,h,x,y);
			return {
				width: w,
				height: h,
				x: x,
				y: y
			};
		}
		public static function mergeOldFlashvars(nObj: Object, oObj: Object): Object {
			for (var k: String in oObj) {
				switch (k) {
					case "p":
						if (Number(oObj[k]) == 1) {
							nObj["autoplay"] = true;
						} else {
							nObj["autoplay"] = false;
						}
						break;
					case "lv":
						if (Number(oObj[k]) == 1) {
							nObj["live"] = true;
						} else {
							nObj["live"] = false;
						}
						break
					case "i":
						nObj["poster"] = oObj[k];
						break;
					case "v":
						nObj["volume"] = Number(oObj[k]) * 0.01;
						break;
					case "h":
						var h: int = Number(oObj[k]);
						var q: String ="";
						if(oObj.hasOwnProperty("q")){
							q = oObj["q"];
						}
						switch (h) {
							case 1:
								q = q != "" ?"frames_"+ q : "frames_start";
								break;
							case 2:
								q = q != "" ? "time_"+q : "time_start";
								break;
							case 3:
							case 4:
								q = q != "" ? q : "start"
								break;
						}
						nObj["drag"] = h > 0 ? q : "";
						break;
					case "g":
						nObj["seek"] = Number(oObj[k]);
						break;
					case "er":
						nObj["error"] = oObj[k];
						break;
					case "k":
						if (oObj["n"] != "" && oObj["k"] != "") {
							var arrk: Array = oObj["k"].toString().split("|");
							var arrn: Array = oObj["n"].toString().split("|");
							if (arrk.length == arrn.length) {
								var arrx: Array = [];
								for (var i: int = 0; i < arrk.length; i++) {
									arrx.push({
										time: arrk[i],
										words: arrn[i]
									});

								}
								nObj["promptSpot"] = arrx;
							}
						}
						break;
					default:
						break;
				}
			}
			return nObj;
		}
		public static function simpleMergeObject(newObj: Object, oldObject: Object): Object { //简单形式直接替换对象
			//简单合并对象
			for (var k: String in oldObject) {
				newObj[k] = oldObject[k];
			}
			return newObj;
		}
		public static function supplementObject(newObj: Object, oldObject: Object): Object { //把旧对象合并到新对象里,主要用来补充参数，即如果原对象中包含了该参数就不需要再加入了

			for (var k: String in oldObject) {
				if (!newObj.hasOwnProperty(k)) {
					newObj[k] = oldObject[k];
				} else {
					if (!newObj[k] || k == "volume") {
						if(getType(newObj[k])=="number"){
							newObj[k] = Number(oldObject[k]);
						}
						else{
							newObj[k] = oldObject[k];
						}
						
					}
				}
			}
			return newObj;
		}
		public static function formatSsl(str:String):String{
			var arr:Array=str.split("");
			var newStr:String="";
			for(var i:int=0; i<str.length; i++){
				if(str.charAt(i)>='0' && str.charAt(i)<='9'){
					newStr+=arr[i];
				}else if((str.charAt(i)>='a' && str.charAt(i)<='z') || (str.charAt(i)>='A' && str.charAt(i) <= 'Z')){
					newStr+=arr[i];
				}
			}
			return newStr;
		}
		public static function mergeObject(obj: Object = null, old: Object = null): Object { //把旧对象合并到新对象里,主要用来格式化参数
			function sendObj(nObj: Object, oObj: Object): Object {
				for (var k: String in oObj) {
					if (oObj[k] != undefined) {
						//trace(k,nObj[k] , getType(nObj[k]));
						var type: String = "";
						if (nObj.hasOwnProperty(k)) {
							type = getType(nObj[k]);
							
							if (oObj[k]) {
								//trace(k,nObj[k],oObj[k],type,getType(nObj[k]),typeof(nObj[k]));
								switch (type) {
									case "object":
										nObj[k] = sendObj(nObj[k], oObj[k]);
										break;
									case "boolean":
										nObj[k] = (oObj[k] != "false" && oObj[k] != false) ? true : false;
										break;
									case "number":
										nObj[k] = Number(oObj[k]);
										//trace(k,nObj[k]);
										break;
									default:
										nObj[k] = oObj[k];
										if(nObj[k]=="true"){
											nObj[k]=true;
										}
										if(nObj[k]=="false"){
											nObj[k]=false;
										}
										break;
								}
							} else {
								if (type == "number" && (oObj[k] == 0 || oObj[k] == "0")) {
									nObj[k] = 0;
								}
								if(oObj[k]=="true"){
									nObj[k] =true;
								}
								if(oObj[k]=="false"){
									nObj[k] =false;
								}
							}
						} else {
							if (oObj[k]) {
								nObj[k] = oObj[k];
							}
						}

					}
				}
				return nObj;
			}
			return sendObj(obj, old);
		}

		public static function getStringLen(str): int { //计算字符长度，中文算2，字母数字算1
			var len: int = 0;
			for (var i: int = 0; i < str.length; i++) {
				if (str.charCodeAt(i) > 127 || str.charCodeAt(i) == 94) {
					len += 2;
				} else {
					len++;
				}
			}
			return len;
		}
		public static function copyObject(obj: Object): * { //复制对象
			var newObj: ByteArray = new ByteArray()
			newObj.writeObject(obj);
			newObj.position = 0;
			return newObj.readObject();
		}
		public static function getLen(str: String = ""): Number { //获取字符的长度
			if (!str) {
				return 0;
			}
			var digital: int = 0; //数字  
			var character: int = 0; //字母  
			var space: int = 0; //空格  
			var other: int = 0; //其它字符 
			for (var i: int = 0; i < str.length; i++) {
				if (str.charAt(i) >= '0' && str.charAt(i) <= '9') {
					digital++;
				} else if ((str.charAt(i) >= 'a' && str.charAt(i) <= 'z') || (str.charAt(i) >= 'A' && str.charAt(i) <= 'Z')) {
					character++;
				} else if (str.charAt(i) == ' ') {
					space++;
				} else {
					other++;
				}
			}
			return (digital + character + space + other * 2) * 0.5
		}

		public static function addListenerArr(listenerArr: Array, ele: String = "", fun: String = ""): Array { //添加监听函数数组
			if (ele != "" && fun != "") {
				var have: Boolean = false;
				for (var i: int = 0; i < listenerArr.length; i++) {
					var arr = listenerArr[i];
					if (arr[0] == ele && arr[1] == fun) {
						have = true;
						break;
					}
				}
				if (!have) {
					listenerArr.push([ele, fun]);
				}
			}
			return listenerArr;
		}

		public static function removeListenerArr(listenerArr: Array, ele: String = "", fun: String = ""): Array { //删除监听函数数组
			if (ele != "" && fun != "") {
				for (var i: int = 0; i < listenerArr.length; i++) {
					var arr = listenerArr[i];
					if (arr[0] == ele && arr[1] == fun) {
						listenerArr.splice(i, 1);
						break;
					}
				}
			}
			return listenerArr;
		}
		public static function callJs(js: String, val: *= null,val2:*=null): void {
			//trace(js);
			var arr: Array = js.split(".");
			if (arr[0] == "" || !ExternalInterface.available) {
				return;
			}
			if(val2 != null){
				if (val != null) {
					try {
						ExternalInterface.call(js, val,val2);
					} catch (event:Error) {
						new log(event)
					}
				} else {
					try {
						ExternalInterface.call(js,val2);
					} catch (event:Error) {
						new log(event)
					}
				}
			}
			else{
				if (val != null) {
					try {
						ExternalInterface.call(js, val);
					} catch (event:Error) {
						log(event)
					}
				} else {
					try {
						ExternalInterface.call(js);
					} catch (event:Error) {
						new log(event)
					}
				}
			}
		}
		public static function openLink(url: String, target: String = '_blank', features: String = ""): void {
			var myURL: URLRequest = new URLRequest(url);
			//trace(url,myURL);
			try {
				ExternalInterface.call("window.open", url, target, features);
			} catch (event:Error) {
				try {
					ExternalInterface.call("function setWMWindow() {window.open('" + url + "', '" + target + "', '" + features + "');}");
				} catch (event: Error) {
					navigateToURL(myURL, target);
				}
			}
		}
		public static function getHttpKey(info: Object): Object {
			var k: String = "";
			var vf: Array = [],
				vt: Array = [];
			//script.traceObject(info);
			if (info.hasOwnProperty("keyframes")) {
				var keyframes: Object = info["keyframes"];
				for (k in keyframes) {
					switch (k) {
						case "times":
							vt.push(keyframes[k]);
							break;
						case "filepositions":
							vf.push(keyframes[k]);
							break;
						default:
							break;
					}
				}
				if(keyframes.hasOwnProperty("filepositions") && keyframes["filepositions"]){
					vf=keyframes["filepositions"];
				}
				if(keyframes.hasOwnProperty("times") && keyframes["times"]){
					vt=keyframes["times"];
				}
			} else if (info.hasOwnProperty("seekpoints")) {
				var seekpoints: Object = info["seekpoints"];
				for (k in seekpoints) {
					var seekpoints2 = seekpoints[k];
					for (var k2: String in seekpoints2) {
						switch (k2) {
							case "time":
								vt.push(seekpoints2[k2]);
								break;
							case "offset":
								vf.push(seekpoints2[k2]);
								break;
							default:
								break;
						}
					} //end for k2
				} //end for k
			}
			if (vt.length > 0) {
				info["keytime"] = vt;
				info["keyframes"] = vf;
			}
			return info;
		}
		public static function randomString(len: int = 16): String { //获取一个随机值
			var chars: String = "abcdefghijklmnopqrstuvwxyz";
			var maxPos: int = chars.length;　　
			var val: String = "";
			for (var i: int = 0; i < len; i++) {
				val += chars.charAt(Math.floor(Math.random() * maxPos));
			}
			return 'ckv' + val;
		}
		public static function getPath(file: String): Object { //获取路径和对应ckplayer.swf的
			var p: String = file.split("?")[0];
			var a: Array = [];
			var g: String = "\/";
			var h: String = "";
			if (p.indexOf("\/") > -1) {
				a = p.split("\/");
			} else {
				a = p.split("/");
				g = "/";
			}
			for (var i: int = 0; i < a.length - 1; i++) {
				h += a[i] + g;
			}
			var fa: Array = a[a.length - 1].split("?");
			var xa: Array = fa[0].toString().split(".");
			return {
				path: h,
				file: fa[0],
				fileName: xa[0]
			};
		}
		public static function arrSum(arr: Array, sort: int = -1): Number { //将数组里的值相加,sort=指定截断
			var num: Number = 0;
			//trace(sort > 0 ? sort : arr.length);
			if (sort > arr.length || sort == -1) {
				sort = arr.length;
			}
			for (var i: int = 0; i < sort; i++) {
				num += Number(arr[i]);
			}
			return num;
		}
		public static function replace(val: String, oldArr: Array, newArr: Array): String {
			if (!val || oldArr.length != newArr.length) {
				return val;
			}
			for (var i: int = 0; i < oldArr.length; i++) {
				val = val.split(oldArr[i]).join(newArr[i]);
			}
			return val;
		}
		public static function getType(val: * ): String { //获取变量类型
			if (val == undefined) {
				return undefined
			}
			if (typeof (val) == "object") {
				if (val.length != undefined) {
					return "array";
				} else {
					return "object";
				}
			}
			return typeof (val);
		}
		public static function traceObject(cObj: Object): void { //输出对象和数组
			function tr(obj: Object, jg: String = "") {
				for (var k: String in obj) {
					//trace(jg, k, obj[k]);

					if (typeof (obj[k]) == "object") {
						trace(jg, k, "{");
						tr(obj[k], jg + " ");
						trace(jg, "},");
					} else {
						if (typeof (obj[k]) == "string") {
							trace(jg, k, ":\"", obj[k], "\",");
						} else {
							trace(jg, k, ":", obj[k], ",");
						}
					}


				}
			}
			tr(cObj);
		}
		public static function strReplace(str: String, find: Array, replace: Array): String {
			if (str != "" && find.length == replace.length) {
				for (var i: int = 0; i < find.length; i++) {
					str = str.split(find[i]).join(replace[i]);
				}
			}
			return str;
		}
		public static function trackToArray(str: String):Array {
			var arr:Array=str.split(",");
			var tempArr:Array=[];
			var newArr:Array=[];
			for(var i=0;i<arr.length;i++){
				tempArr.push(arr[i]);
				if(i % 3==2){
					newArr.push(tempArr);
					tempArr=[];
				}
			}
			return newArr;
		}
	}

}