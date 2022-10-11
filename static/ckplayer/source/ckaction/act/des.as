package ckaction.act {
	import ckaction.C.C;
	import com.hurlant.crypto.symmetric.DESKey;
	import com.hurlant.crypto.symmetric.ECBMode;
	import com.hurlant.util.Base64;
	import flash.utils.ByteArray;
	import flash.events.ErrorEvent;
	import flash.display.BitmapData;
	import flash.geom.Rectangle;

	public class des {
		public function des() {

		}
		public static function getString(s: String): String {
			// constructor code
			var codes: String = C.CEKEY;
			var codes2: String = "ckplayerDesKey";
			var de: String = s;
			var type: String = s.substr(0, 3);
			s = decodeURI(s);
			s=script.replace(s,[" "],["+"]);
			if (type == "CE:" || type == "CK:") {
				if (type == "CE:") {
					s = s.replace("CE:", "");
				} else {
					s = s.replace("CK:", "");
				}
				try {
					var b64: ByteArray = Base64.decodeToByteArray(s);
					if (type == "CE:") {
						//trace("codes",codes);
						de = decrypt(codes, b64);
					} else {
						de = decrypt(codes2, b64);
					}
				} catch (event: ErrorEvent) {
					return "";
				}
			}
			if (de.indexOf("base64,") > -1) {
				de = de.split("base64,")[1]
			}
			return de.split("\n").join("").split("\r").join("").split("\n\r").join("").split("\r\n").join("");
		}

		public static function getByteArray(s: String): ByteArray {
			// constructor code
			var codes: String = C.CEKEY;
			var codes2: String = "ckplayerDesKey";
			var de: String = s;
			s = decodeURI(s).split("\n").join("").split("\r").join("").split("\n\r").join("").split("\r\n").join("");
			s=script.replace(s,[" "],["+"]);
			var type: String = s.substr(0, 3);
			if (type == "CE:" || type == "CK:") {
				if (type == "CE:") {
					s = s.replace("CE:", "");
				} else {
					s = s.replace("CK:", "");
				}
				try {
					var b64: ByteArray = Base64.decodeToByteArray(s);
					if (type == "CE:") {
						de = decrypt(codes, b64);
					} else {
						de = decrypt(codes2, b64);
					}
				} catch (event: ErrorEvent) {
					return new ByteArray();
				}
			}
			if (de.indexOf("base64,") > -1) {
				de = de.split("base64,")[1]
			}
			try {
				return Base64.decodeToByteArray(de);
			} catch (event: ErrorEvent) {
				return new ByteArray();
			}
			return new ByteArray();
		}
		public static function getVString(s: String): String {
			// constructor code
			var de: String = s;
			s = decodeURI(s);
			s=script.replace(s,[" "],["+"]);
			try {
				var b64: ByteArray = Base64.decodeToByteArray(s);
				de = decrypt(C.CVKEY, b64);
			} catch (event: ErrorEvent) {
				return de;
			}
			return de;
		}
		private static function decrypt(key: String, data: ByteArray): String {
			//trace("\n执行解密方法，key:", key, "，需要解密的字符串：", data);
			//实验化key的Bytearray对象，给DESKey使用
			var b_keyByteArray: ByteArray = new ByteArray();
			b_keyByteArray.writeUTFBytes(key);
			//实例化DESKey
			var b_desKey: DESKey = new DESKey(b_keyByteArray);
			var b_ecb: ECBMode = new ECBMode(b_desKey);
			var b_byteArray: ByteArray = new ByteArray();
			b_byteArray.writeBytes(data);
			//执行解密
			b_ecb.decrypt(b_byteArray);

			return convertByteArrayToString(b_byteArray);
		}
		private static function convertByteArrayToString(bytes: ByteArray): String {
			var str: String;
			if (bytes) {
				bytes.position = 0;
				str = bytes.readUTFBytes(bytes.length);
			}
			return str;
		}

	}

}