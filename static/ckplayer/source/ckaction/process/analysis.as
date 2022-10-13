package ckaction.process {
	import ckaction.act.script;
	import ckaction.act.loadXml;

	public class analysis {
		private var success:Function=null;
		private var advObj:Object=null;
		public function analysis(obj:*,f:Function) {
			// constructor code
			success=f;
			analysisObj(obj);
		}
		private function analysisObj(obj:*):void{
			var objType=script.getType(obj);
			if(objType=="object"){
				advObj=obj;
				
				front();
			}
			else if(objType=="string"){
				if(obj==""){
					success(null);
					return;
				}
				new loadXml(obj.replace("website:",""),analysisObj)
			}
			else{
				success(null);
			}
		}
		private function front():void{
			//分析前置广告
			if(advObj.hasOwnProperty("front")){
				analysisFrontObj(advObj["front"]);
			}
			else{
				pause();
			}
		}
		private function analysisFrontObj(obj:*):void{
			//分析前置广告
			//trace("分析前置广告");
			var objType=script.getType(obj);
			if(objType=="object"){
				if(obj.hasOwnProperty("front")){
					obj=obj["front"];
					objType=script.getType(obj);
				}
			}
			if(objType=="object" || objType=="array"){
				//trace("++||++",checkFormat(obj));
				if(checkFormat(obj)){
					advObj["front"]=obj;
				}
				else{
					advObj["front"]=null;
				}
				pause();
			}
			else{
				if(obj==""){
					pause();
					return;
				}
				new loadXml(obj,analysisFrontObj)
			}
		}
		private function pause():void{
			//分析暂停广告
			if(advObj.hasOwnProperty("pause")){
				analysisPauseObj(advObj["pause"]);
			}
			else{
				insert();
			}
		}
		private function analysisPauseObj(obj:*):void{
			//分析暂停广告
			var objType=script.getType(obj);
			if(objType=="object"){
				if(obj.hasOwnProperty("pause")){
					obj=obj["pause"];
					objType=script.getType(obj);
				}
			}
			if(objType=="object" || objType=="array"){
				if(checkFormat(obj)){
					advObj["pause"]=obj;
				}
				else{
					advObj["pause"]=null;
				}
				insert();
			}
			else{
				if(obj==""){
					insert();
					return;
				}
				new loadXml(obj,analysisPauseObj)
			}
		}
		private function insert():void{
			//分析中插广告
			if(advObj.hasOwnProperty("insert")){
				analysisInsertObj(advObj["insert"]);
			}
			else{
				end();
			}
		}
		private function analysisInsertObj(obj:*):void{
			//分析中插广告
			var objType=script.getType(obj);
			if(objType=="object"){
				if(obj.hasOwnProperty("insert")){
					obj=obj["insert"];
					objType=script.getType(obj);
				}
			}
			if(objType=="object" || objType=="array"){
				if(checkFormat(obj)){
					advObj["insert"]=obj;
				}
				else{
					advObj["insert"]=null;
				}
				end();
			}
			else{
				if(obj==""){
					end();
					return;
				}
				new loadXml(obj,analysisInsertObj)
			}
		}
		private function end():void{
			//分析结束广告
			if(advObj.hasOwnProperty("end")){
				analysisEndObj(advObj["end"]);
			}
			else{
				other();
			}
		}
		private function analysisEndObj(obj:*):void{
			//分析结束广告
			var objType=script.getType(obj);
			if(objType=="object"){
				if(obj.hasOwnProperty("end")){
					obj=obj["end"];
					objType=script.getType(obj);
				}
			}
			if(objType=="object" || objType=="array"){
				if(checkFormat(obj)){
					advObj["end"]=obj;
				}
				else{
					advObj["end"]=null;
				}
				other();
			}
			else{
				if(obj==""){
					other();
					return;
				}
				new loadXml(obj,analysisEndObj)
			}
		}
		private function other():void{
			//分析其它广告
			if(advObj.hasOwnProperty("other")){
				analysisOtherObj(advObj["other"]);
			}
			else{
				analysisEnd();
			}
		}
		private function analysisOtherObj(obj:*):void{
			//分析其它广告
			var objType=script.getType(obj);
			if(objType=="object"){
				if(obj.hasOwnProperty("other")){
					obj=obj["other"];
					objType=script.getType(obj);
				}
			}
			if(objType=="object" || objType=="array"){
				if(checkFormat(obj)){
					advObj["other"]=obj;
				}
				else{
					advObj["other"]=null;
				}
				analysisEnd();
			}
			else{
				if(obj==""){
					analysisEnd();
					return;
				}
				new loadXml(obj,analysisOtherObj)
			}
		}
		private function analysisEnd():void{
			var obj:Object={
				front:null,
				pause:null,
				insert:null,
				other:null
			};
			obj=script.mergeObject(obj,advObj);
			for(var k:String in obj){
				if(script.getType(obj[k])=="object"){
					obj[k]=[obj[k]]
				}
			}
			success(obj);
		}
		private function checkFormat(obj:*):Boolean{
			//判断广告格式是否符合要求
			//script.traceObject(obj);
			var objType=script.getType(obj);
			var objC:Object=null;
			if(objType=="object"){
				objC=obj;
			}
			else{
				if(script.getType(obj[0])=="object"){
					objC=obj[0];
				}
				else{
					return false;
				}
			}
			if(!objC.hasOwnProperty("type") || !objC.hasOwnProperty("file")){
				return false;
			}
			return true;
		}
	}
	
}
