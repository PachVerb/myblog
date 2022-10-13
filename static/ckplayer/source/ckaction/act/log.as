package ckaction.act {
	import ckaction.C.C;

	public class log {

		public function log(val: * ) {
			// constructor code
			//trace("log:", val);
			if (C.CONFIG["flashvars"]["debug"]) {
				script.callJs("console.log", val);
			}

		}

	}

}