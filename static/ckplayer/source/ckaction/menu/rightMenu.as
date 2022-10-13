package ckaction.menu {
	import flash.display.Sprite;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.display.Sprite;
	import flash.events.ContextMenuEvent;
	import ckaction.C.C;
	import ckaction.act.script;
	import ckaction.act.MD5;

	public class rightMenu {
		private var THIS: Sprite = null;
		private var menu: Object = {};
		private var moreArr: Array = [];
		public function rightMenu(sprite: Sprite) {
			trace("构建右键菜单实例");
			// constructor code
			THIS = sprite;
			//
			var ckNemu: Object = {
				name: "ckplayer",
				link: "http://www.ckplayer.com",
				domain: "",
				version: "version:X2"
			};
			var i:int=0;
			menu = C.CONFIG["menu"];
			if (menu["ckkey"] == "") {
				menu = ckNemu;
			} else {
				if (menu["name"]) {
					C.CVKEY = md5(menu["ckkey"] + "CKPLAYER_CVKEY_BVS1welO");
					var path:String=C.PATH["path"];
					trace("path",menu["domain"]);
					if(menu["domain"]!=""){
						if(path.indexOf(".")==-1){
							C.CVKEY="";
						}
						path=script.replace(path,["http://","https://"],["",""]);
						var pathArr:Array=path.split("/");
						var startInt:int=0;
						var domainArr:Array=menu["domain"].split(",");
						var isNull:Boolean=false;
						for(i=0;i<domainArr.length;i++){
							startInt=pathArr[0].toString().length-domainArr[i].toString().length;
							//trace(pathArr[0].toString().substr(startInt),domainArr[i]);
							if(pathArr[0].toString().substr(startInt)==domainArr[i]){
								isNull=true;
							}
						}
						if(!isNull){
							C.CVKEY="";
						}
					}
					
				} else {
					menu = ckNemu;
				}
				//只要修改过注册码，就生成一个加密码
				C.CEKEY = md5(menu["ckkey"] + "CKPLAYER_CEKEY_ELP1Pjt3");
			}
			//
			if (menu["name"] == "" || menu["link"] == "") {
				menu = ckNemu;
			}
			script.traceObject(menu);
			var newContextMenu: ContextMenu = new ContextMenu();
			newContextMenu.hideBuiltInItems();
			//添加第一行和第二行
			var itemN: ContextMenuItem = new ContextMenuItem(menu["name"]);
			itemN.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, itemNClickHandler);
			newContextMenu.customItems.push(itemN);
			if (menu["version"]) {
				itemN = new ContextMenuItem(menu["version"], false, false);
				newContextMenu.customItems.push(itemN);
			}
			trace("购建新右争封");
			script.traceObject(menu);
			trace("======================");
			if (menu["more"]) {
				if (script.getType(menu["more"]) == "object") {
					moreArr = [menu["more"]];
				} else {
					moreArr = menu["more"]
				}
				if(moreArr){
					for (i = 0; i < moreArr.length; i++) {
						var obj: Object = moreArr[i];
						if (obj.hasOwnProperty("name") && obj["name"]) {

							var click: Boolean = obj.hasOwnProperty("clickEvent");
							var item: ContextMenuItem = new ContextMenuItem(obj["name"], false, click);
							if (obj.hasOwnProperty("separatorBefore") && (obj["separatorBefore"] == "true" || obj["separatorBefore"] == true)) {
								item.separatorBefore = true;
							}
							if (obj.hasOwnProperty("clickEvent") && obj["clickEvent"] != "") {
								item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, itemClickHandler);
							}
							newContextMenu.customItems.push(item);
						}
					}
				}
				
			}
			/**/
			THIS.contextMenu = newContextMenu;
			THIS["loadFace"]();
		}
		private function itemNClickHandler(event: ContextMenuEvent) {
			THIS["openUrl"](menu["link"]);
		}
		private function itemClickHandler(event: ContextMenuEvent) {
			//THIS["openUrl"](menu["link"]);
			var itemText: String = event.target.caption;
			var obj: Object = {};
			for (var i: int = 0; i < moreArr.length; i++) {
				if (moreArr[i]["name"] == itemText) {
					obj = moreArr[i];
					break;
				}
			}
			var flashvars: Object = C.CONFIG["flashvars"];
			//===========================================================
			if (obj.hasOwnProperty("clickEvent") && obj["clickEvent"]) {
				if (obj.hasOwnProperty("clickEvent") && obj["clickEvent"]) {
					THIS["clickEvent"](obj["clickEvent"]);
				}
			}
			//===========================================================
		}
		private function md5(s: String): String {
			var m: String = "";
			if (s) {
				m = MD5.hash(MD5.hash(s));
			}
			return m;
		}

	}

}