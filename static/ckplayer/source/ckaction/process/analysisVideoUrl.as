package ckaction.process {
	import ckaction.act.script;
	import ckaction.act.loadXml;
	import ckaction.C.C;
	import ckaction.act.des;
	import ckaction.act.log;
	import flash.events.ErrorEvent;

	public class analysisVideoUrl {
		private var videoHandler: Function = null;
		private var videoArr: Array = [];
		public function analysisVideoUrl(fun: Function) {
			// constructor code
			videoHandler = fun;
			//script.traceObject(C.CONFIG["flashvars"]);
			analysis(C.CONFIG["flashvars"]["video"]);
		}
		private function analysis(video: * ): void {
			trace("开始分析视频",script.getType(video));
			try {
				var obj: Object = {};
				var i: int = 0;
				var split:String=C.CONFIG["config"]["split"];
				//trace("开始=================");
				//trace(video);
				//script.traceObject(video);
				//trace("=============", script.getType(video));
				//trace("结束");
				switch (script.getType(video)) {
					case "object":
						obj = video;
						if (obj.hasOwnProperty("video")) {
							if (script.getType(obj["video"]) == "array") {
								if (obj["video"].length > 0) {
									if (obj["video"][0].hasOwnProperty("video")) {
										//新数据形式
										trace("新");
										videoArr = obj["video"];
										C.CONFIG["flashvars"] = script.mergeObject(C.CONFIG["flashvars"], obj);
										trace("执行analysisArr,39");
										analysisArr();
									} else if (obj["video"][0].hasOwnProperty("seconds")) {
										//旧数据形式
										trace("旧");
										analysisOld(obj);
									} else {
										trace("不知道什么格式");
										C.CONFIG["flashvars"] = script.mergeObject(C.CONFIG["flashvars"], obj);
										try {
											var aarr: Array = obj["video"];
											videoArr = [];
											for (i = 0; i < aarr.length; i++) {
												videoArr.push({
													file: aarr[i][0],
													type: aarr[i][1].replace("video/", "") != "" ? aarr[i][1].replace("video/", "") : script.getFileExt(aarr[i][0]),
													definition: aarr[i][2],
													weight: Number(aarr[i][3])

												});
											}
											analysis(videoArr);
										} catch (event: Error) {
											videoArr = null;
											trace("执行analysisArr,63");
											analysisArr();
										}
									}
								} else {
									trace("格式错误");
									C.CONFIG["flashvars"] = script.mergeObject(C.CONFIG["flashvars"], obj);
									videoArr = null;
									trace("执行analysisArr,71");
									analysisArr();
								}
							} else {
								if (obj["video"].hasOwnProperty("file") && script.getType(obj["video"]["file"]) == "array") {
									analysisOld2(obj);
								} else {
									//video是个对象需要再加载
									C.CONFIG["flashvars"] = script.mergeObject(C.CONFIG["flashvars"], obj);
									analysis(obj["video"]);
								}

							}
						} else {
							if (obj.hasOwnProperty("file")) {
								C.CONFIG["flashvars"] = script.mergeObject(C.CONFIG["flashvars"], obj);
								videoArr = [obj];
								trace("执行analysisArr,88");
								analysisArr();
							} else if (obj.hasOwnProperty("url")) {
								C.CONFIG["flashvars"] = script.mergeObject(C.CONFIG["flashvars"], obj);
								if (script.getType(obj["url"]) == "string" && obj["url"].toString().substr(0, 8) == "website:") {
									analysis("website:" + obj["url"].replace("website:", ""));
								} else {
									videoArr = null;
									trace("执行analysisArr,96");
									analysisArr();
								}
							} else {
								C.CONFIG["flashvars"] = script.mergeObject(C.CONFIG["flashvars"], obj);
								videoArr = null;
								trace("执行analysisArr,101");
								analysisArr();
							}

						}

						break;
					case "array": //普通数组调用
						trace("普通数组形式的");
						trace(video);
						videoArr = video;
						trace("执行analysisArr,114");
						analysisArr();
						break;
					default: //普通调用，字符串类型
						var str: String = video;
						if (str.substr(0, 8) == "website:") {
							str = des.getString(str.replace("website:", ""));
							loadUrl(str);
						} else {
							//trace("只有地址", video);
							video=decodeURIComponent(video);
							new log("video-split："+split);
							if (video.indexOf(split) == -1) {
								video = des.getString(video);
								videoArr = [{
									file: video,
									type: C.CONFIG["flashvars"]["type"] ? C.CONFIG["flashvars"]["type"] : script.getFileExt(video).replace(".", ""),
									weight: 0,
									definition: ""
								}];
							} else {
								new log("video："+video);
								trace("=========================================");
								trace(video);
								var vArr: Array = video.split(split);
								//new log(vArr);
								//script.traceObject(vArr);
								var dArr: Array = [],
									wArr: Array = [],
									tArr:Array=[];
								if (C.CONFIG["flashvars"].hasOwnProperty("definition")) {
									dArr = C.CONFIG["flashvars"]["definition"].split(",");
								}
								if (C.CONFIG["flashvars"].hasOwnProperty("weight")) {
									wArr = C.CONFIG["flashvars"]["weight"].split(",");
								}
								
								if (C.CONFIG["flashvars"].hasOwnProperty("type")) {
									var typeTemp:String=C.CONFIG["flashvars"]["type"];
									if(typeTemp.indexOf(",")>-1){
										tArr = C.CONFIG["flashvars"]["type"].split(",");
									}
									else{
										tArr = C.CONFIG["flashvars"]["type"].split(split);
									}
								}
								for (var n: int = 0; n < vArr.length; n++) {
									var tObj: Object = {
										file: vArr[n]
										//type: C.CONFIG["flashvars"]["type"] ? C.CONFIG["flashvars"]["type"] : script.getFileExt(vArr[n])
									};
									if (dArr.length > n) {
										tObj["definition"] = dArr[n];
									}
									if (wArr.length > n) {
										tObj["weight"] = wArr[n];
									}
									if (tArr.length > n) {
										tObj["type"] = tArr[n];
									}
									if(!tObj.hasOwnProperty("type")){
										tObj["type"]= script.getFileExt(tObj["file"]);
									}
									videoArr.push(tObj);
								}
							}
							trace("执行analysisArr,166");
							analysisArr();
						}
						break;
				}
			} catch (event: Error) {
				trace("出错");
				videoArr = null;
				trace("执行analysisArr,173");
				analysisArr();
			}
		}
		private function analysisOld(obj: Object): void {
			//分析旧版形式
			//script.traceObject(obj);
			try {
				var vArr: Array = obj["video"];
				var nArr: Array = [];
				var type: String = "";
				var i: int = 0;
				for (i = 0; i < vArr.length; i++) {
					var tArr: Object = {
						file: vArr[i]["file"],
						bytesTotal: vArr[i]["size"],
						duration: vArr[i]["seconds"]
					};
					type = script.getFileExt(vArr[i]["file"]).replace(".", "");
					nArr.push(tArr);
				}
				var nObj: Object = {
					video: nArr,
					type: type,
					weight: 0,
					definition: ""
				};
				if (obj.hasOwnProperty("flashvars") && obj["flashvars"]) {
					var temp: String = script.replace(obj["flashvars"], ["{"], [""]);
					var arr: Array = temp.split("}");
					var fObj: Object = {};
					for (i = 0; i < arr.length; i++) {
						var temp2: String = arr[i];
						if (temp2 != "") {
							var arr2: Array = temp2.split("->");
							if (arr2[0] != "" && arr2[1] != "") {
								fObj[arr2[0]] = arr2[1];
							}
						}
					}
					C.CONFIG["flashvars"] = script.mergeOldFlashvars(C.CONFIG["flashvars"], fObj);
				}
				videoArr = [nObj];
				trace("执行analysisArr,216");
				analysisArr();
			} catch (event: Error) {
				videoArr = null;
				trace("执行analysisArr,220");
				analysisArr();
			}
		}
		private function analysisOld2(obj: Object): void {
			//分析旧版形式
			//script.traceObject(obj);
			try {
				var vArr: Array = obj["video"]["file"];
				var sArr: Array = obj["video"]["size"];
				var eArr: Array = obj["video"]["seconds"];
				var nArr: Array = [];
				var type: String = "";
				var i: int = 0;
				for (i = 0; i < vArr.length; i++) {
					var tArr: Object = {
						file: vArr[i],
						bytesTotal: sArr[i],
						duration: eArr[i]
					};
					type = script.getFileExt(vArr[i]).replace(".", "");
					nArr.push(tArr);
				}
				var nObj: Object = {
					video: nArr,
					type: type,
					weight: 0,
					definition: ""
				};
				if (obj.hasOwnProperty("flashvars") && obj["flashvars"]) {
					//trace("包含flashvars");
					var temp: String = script.replace(obj["flashvars"], ["{"], [""]);
					var arr: Array = temp.split("}");
					var fObj: Object = {};
					for (i = 0; i < arr.length; i++) {
						var temp2: String = arr[i];
						if (temp2 != "") {
							var arr2: Array = temp2.split("->");
							if (arr2[0] != "" && arr2[1] != "") {
								fObj[arr2[0]] = arr2[1];
							}
						}
					}
					//script.traceObject(fObj);
					C.CONFIG["flashvars"] = script.mergeOldFlashvars(C.CONFIG["flashvars"], fObj);
				}
				videoArr = [nObj];
				trace("执行analysisArr,267");
				analysisArr();
			} catch (event: Error) {
				videoArr = null;
				trace("执行analysisArr,271");
				analysisArr();
			}
		}
		private function loadUrl(url: String) { //加载网址获取视频地址后应该判断是旧式的还是新式的
			//trace(url);
			new loadXml(url, function (data: * ) {
				//trace(data);
				//script.traceObject(data);
				if (data) {
					analysis(data);
				} else {
					videoArr = null;
					trace("执行analysisArr,284");
					analysisArr();
				}
			});
		}
		private function getAD(adv: String = "", time: String = "", link: String = ""): Array {
			var vars: Object = C.CONFIG["flashvars"];
			var adArr: Array = vars[adv].split(",");
			var timeArr: Array = [],
				linkArr: Array = [];
			var ad: Array = [];
			if (vars.hasOwnProperty(time)) {
				timeArr = vars[time].split(",");
			}
			if (vars.hasOwnProperty(link)) {
				linkArr = vars[link].split(",");
			}
			for (var i: int = 0; i < adArr.length; i++) {
				var obj: Object = {
					file: adArr[i],
					type: script.getFileExt(adArr[i]).replace(".", "")
				};
				if (timeArr.length > i) {
					obj["time"] = timeArr[i];
				} else {
					obj["time"] = C.CONFIG["style"]["advertisement"]["time"];
				}
				if (linkArr.length > i) {
					obj["link"] = linkArr[i];
				} else {
					obj["link"] = "";
				}
				ad.push(obj);
			}
			return ad;
		}
		private function analysisArr(): void {
			var n: int = 0,
				m: int = 0,
				i: int = 0;
			if (videoArr) {
				C.CONFIG["flashvars"]["video"] = videoArr;
				for (i = 0; i < videoArr.length; i++) {
					if (videoArr[i].hasOwnProperty("weight")) {
						if (videoArr[i]["weight"] > n) {
							n = videoArr[i]["weight"];
							m = i;
						}
					}
					else{
						n=0;
						m=i;
					}
				}
			}
			
			//
			//分析广告
			var fvars: Object = C.CONFIG["flashvars"];
			var front: Array = [];
			var ad: Object = {};
			var isAd: Boolean = false;
			if (fvars.hasOwnProperty("adfront")) {
				ad["front"] = getAD("adfront", "adfronttime", "adfrontlink");
				isAd = true;
			}
			if (fvars.hasOwnProperty("adpause")) {
				ad["pause"] = getAD("adpause", "adpausetime", "adpauselink");
				isAd = true;
			}
			if (fvars.hasOwnProperty("adinsert")) {
				ad["insert"] = getAD("adinsert", "adinserttime", "adinsertlink");
				isAd = true;
			}
			if (fvars.hasOwnProperty("adend")) {
				ad["end"] = getAD("adend", "adendtime", "adendlink");
				isAd = true;
			}
			if (isAd && ad) {
				C.CONFIG["flashvars"]["advertisements"] = ad;
			}

			//分析广告
			//分析提示点
			if (fvars.hasOwnProperty("promptspot") && fvars.hasOwnProperty("promptspottime")) {
				if (script.getType(fvars["promptspot"]) == "string") {
					var prompt: Array = fvars["promptspot"].split(",");
					var prompttime: Array = fvars["promptspottime"].split(",");
					var promptSpot: Array = [];
					if (prompt.length == prompttime.length) {
						for (i = 0; i < prompt.length; i++) {
							promptSpot.push({
								words: prompt[i],
								time: prompttime[i]
							});
						}
						C.CONFIG["flashvars"]["promptSpot"] = promptSpot;
					}
				}
			}
			//trace(fvars["previewscale"]);
			if (fvars.hasOwnProperty("preview") && fvars["preview"]) {
				if (script.getType(fvars["preview"]) == "string") {
					C.CONFIG["flashvars"]["preview"] = {
						file: fvars["preview"].split(","),
						scale: fvars["previewscale"]
					};
				}
			}
			
			if (videoArr) {
				//script.traceObject(videoArr[m]);
				if (videoArr[m].hasOwnProperty("video")) {
					if (script.getType(videoArr[m]["video"]) == "array") {
						var nArr: Array = videoArr[m]["video"];
						var timeTotal: Number = 0;
						for (i = 0; i < nArr.length; i++) {
							if (nArr[i].hasOwnProperty("duration")) {
								timeTotal += Number(nArr[i]["duration"]);
							}
						}
						C.CONFIG["flashvars"]["duration"] = timeTotal;
						//trace("总时间：",timeTotal);
					}
				}
			}
			trace("发送一次newPlayerHandler");
			script.traceObject(videoArr);
			videoHandler(videoArr, m);
		}

	}

}