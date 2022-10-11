package ckaction.process {
	import flash.external.ExternalInterface;
	import flash.display.Stage;
	import ckaction.act.script;
	import ckaction.act.loadXml;
	import ckaction.C.C;
	import ckaction.act.log;

	public class config {
		private var path: Object = {};
		private var CONFIG: Object = null; //配置
		private var flashvars: Object = null; //flashvars
		private var loadHandler: Function = null;
		private var loadxml: loadXml = null;
		public function config(stage: Stage, fun: Function) {
			loadHandler = fun;
			flashvars = stage.loaderInfo.parameters;
			if(flashvars.hasOwnProperty("video")){
				if(flashvars["video"].toString().indexOf("%3f")>-1 || flashvars["video"].toString().indexOf("%2f")>-1 || flashvars["video"].toString().indexOf("%26")>-1){
					flashvars["video"]=unescape(flashvars["video"]);
				}
			}
			flashvars = script.mergeObject(C.CONFIG["flashvars"], flashvars);
			//
			if (flashvars["config"] != "" && (flashvars["config"] == "false" || flashvars["config"] == "no")) {
				CONFIG = C.CONFIG;
				configHandler();
				return;
			}
			path = script.getPath(stage.loaderInfo.url);
			C.PATH = path;
			if (ExternalInterface.available) {
				var cf: String = "ckplayerConfig";
				if (flashvars["config"] != "") {
					cf = script.formatSsl(flashvars["config"]);
				}
				var temp = ExternalInterface.call(cf);
				if(temp){
					CONFIG=temp;
				}
				else{
					temp=ExternalInterface.call("function(){return "+flashvars["variable"]+".getCkplayerConfig()}");
					if(temp){
						CONFIG=temp;
					}
				}
				
			}
			if (CONFIG == null || !CONFIG) {
				var url: String = flashvars["config"] ? flashvars["config"] : path["path"] + path["fileName"] + ".json";
				loadxml = new loadXml(url, function (data: Object = null) {
					if (data) {
						CONFIG = data;
						flashvars = script.supplementObject(flashvars, CONFIG["flashvars"]);
						//script.traceObject(CONFIG["flashvars"]);
						CONFIG["flashvars"] = flashvars;
						loadLanguage();
					} else {
						new log("error:Failed to load " + url);
						//flashvars = script.mergeObject(flashvars, CONFIG["flashvars"]);
						CONFIG = C.CONFIG;
						CONFIG["flashvars"] = flashvars;
						configHandler();
						return;
					}

				});
			} else {
				flashvars = script.supplementObject(flashvars, CONFIG["flashvars"]);
				CONFIG["flashvars"] = flashvars;
				loadLanguage();
			}

		}
		private function loadLanguage(): void { //加载语言包
			CONFIG["flashvars"]["config"]=script.formatSsl(CONFIG["flashvars"]["config"]);
			CONFIG["flashvars"]["loaded"]=script.formatSsl(CONFIG["flashvars"]["loaded"]);
			//script.traceObject(C.CONFIG["flashvars"]);
			if (ExternalInterface.available) {
				var cf: String = "ckplayerLanguage";
				if (flashvars["language"]) {
					cf = script.formatSsl(flashvars["language"]);
					
				}
				if (!CONFIG.hasOwnProperty("language")) {
					CONFIG["language"] = new Object();
				} else {
					if (script.getType(CONFIG["language"]) != "object") {
						CONFIG["language"] = new Object();
					}
				}
				var temp = ExternalInterface.call(cf);
				var languageTemp=null;
				if(temp){
					languageTemp=temp;
				}
				else{
					temp=ExternalInterface.call("function(){return "+flashvars["variable"]+".getCkplayerLanguage()}");
					if(temp){
						languageTemp=temp;
					}
				}
				
				if(languageTemp){
					CONFIG["language"] = script.mergeObject(CONFIG["language"], temp);
					loadStyle();
					return;
				}
			}
			
			var languagePath: String = "";
			if (CONFIG.hasOwnProperty("languagePath")) {
				languagePath = CONFIG["languagePath"];
			}

			if (languagePath == "false" || languagePath == "no") {
				configHandler();
				return;
			}
			if (languagePath != "" && languagePath != null) {
				if (!languagePath.indexOf("/") && !languagePath.indexOf("\\")) {
					languagePath = path["path"] + languagePath;
				}
			} else {
				languagePath = path["path"] + "language.json";
			}
			if (loadxml) {
				loadxml = null;
			}
			loadxml = new loadXml(languagePath, function (data: Object) {
				if (data) {
					var language: Object = data;
					if (!CONFIG.hasOwnProperty("language")) {
						CONFIG["language"] = new Object();
					} else {
						if (script.getType(CONFIG["language"]) != "object") {
							CONFIG["language"] = new Object();
						}
					}
					CONFIG["language"] = script.mergeObject(CONFIG["language"], language);
					loadStyle();

				} else {
					new log("error:Failed to load " + languagePath);
					loadStyle();
				}

			});
		}
		private function loadStyle(): void { //加载风格
			if (ExternalInterface.available) {
				var cf: String = "ckplayerStyle";
				if (flashvars["style"]) {
					cf = script.formatSsl(flashvars["style"]);
					
				}
				var temp = ExternalInterface.call(cf);
				var styleTemp=null;
				if(temp){
					styleTemp=temp;
				}
				else{
					temp=ExternalInterface.call("function(){return "+flashvars["variable"]+".getCkplayerStyle()}");
					if(temp){
						styleTemp=temp;
					}
				}
				
				if(!styleTemp){
					if (!CONFIG.hasOwnProperty("style")) {
						CONFIG["style"] = new Object();
					} else {
						if (script.getType(CONFIG["style"]) != "object") {
							CONFIG["style"] = new Object();
						}
					}
					
				}
				if(styleTemp){
					CONFIG["style"]["advertisement"]=script.mergeObject(CONFIG["style"]["advertisement"], styleTemp["advertisement"]);
					CONFIG["style"] = script.mergeObject(CONFIG["style"], styleTemp);
					flashvars = script.supplementObject(flashvars, styleTemp["flashvars"]);
					CONFIG["flashvars"] = flashvars;
					configHandler();
					return;
				}
					
			}
			var stylePath: String = CONFIG["stylePath"];
			if (CONFIG["stylePath"] == "false" || CONFIG["stylePath"] == "no") {
				CONFIG["style"] = null;
				configHandler();
				return;
			}
			if (stylePath != "" && stylePath != null) {
				if (!stylePath.indexOf("/") && !stylePath.indexOf("\\")) {
					stylePath = path["path"] + stylePath;

				}
			} else {
				stylePath = path["path"] + "style.json";
			}
			var url: String = stylePath;
			//var url: String = CONFIG["stylePath"] ? CONFIG["stylePath"] : path["path"] + "style.xml";
			if (loadxml) {
				loadxml = null;
			}
			loadxml = new loadXml(url, function (data: Object) {
				if (data) {
					var style: Object = data;
					if (!CONFIG.hasOwnProperty("style")) {
						CONFIG["style"] = new Object();
					} else {
						if (script.getType(CONFIG["style"]) != "object") {
							CONFIG["style"] = new Object();
						}
					}
					CONFIG["style"]["advertisement"]=script.mergeObject(CONFIG["style"]["advertisement"], style["advertisement"]);
					CONFIG["style"] = script.mergeObject(CONFIG["style"], style);
					flashvars = script.supplementObject(flashvars, style["flashvars"]);
					CONFIG["flashvars"] = flashvars
					configHandler();

				} else {
					new log("error:Failed to load " + url);
					configHandler();
				}

			});
		}
		private function configHandler(): void {
			if (CONFIG["config"]["timeStamp"]) {
				loadxml = new loadXml(CONFIG["config"]["timeStamp"], function (data: * ) {
					if (data) {
						//script.traceObject(data);
						if (script.getType(data) == "string") {
							CONFIG["config"]["time"] = Number(data) * 1000;
						} else {
							CONFIG["config"]["time"] = Number(data["result"]["timestamp"]) * 1000;
						}
						configEnd();
					} else {
						configEnd();
					}
				});
			} else {
				configEnd();
			}

		}
		private function getAD(adv: String = "", time: String = "", link: String = ""): Array {
			var vars: Object = CONFIG["flashvars"];
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
					obj["time"] = CONFIG["style"]["advertisement"]["time"];
				}
				if (linkArr.length > i) {
					obj["link"] = linkArr[i];
				} else {
					obj["link"] = "";
				}
				ad.push(obj);
			}
			//script.traceObject(ad);
			return ad;
		}
		private function configEnd(): void {
			//分析广告
			var fvars: Object = CONFIG["flashvars"];
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
				CONFIG["flashvars"]["advertisements"] = ad;
			}
			//分析广告
			//分析提示点
			if (fvars.hasOwnProperty("promptspot") && fvars.hasOwnProperty("promptspottime")) {
				if (script.getType(fvars["promptspot"]) == "string") {
					var prompt: Array = fvars["promptspot"].split(",");
					var prompttime: Array = fvars["promptspottime"].split(",");
					var promptSpot: Array = [];
					if (prompt.length == prompttime.length) {
						for (var i: int = 0; i < prompt.length; i++) {
							promptSpot.push({
								words: prompt[i],
								time: prompttime[i]
							});
						}
						CONFIG["flashvars"]["promptSpot"] = promptSpot;
					}
				}
			}
			if (fvars.hasOwnProperty("preview") && fvars["preview"]) {
				if (script.getType(fvars["preview"]) == "string") {
					CONFIG["flashvars"]["preview"] = {
						file: fvars["preview"].split(","),
						scale: fvars["previewscale"]
					};
				}
			}

			C.CONFIG = script.mergeObject(C.CONFIG, CONFIG);
			//script.traceObject(C.CONFIG);
			loadHandler();
		}

	}

}