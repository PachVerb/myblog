package ckaction.act {
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	
	public class timeInterval {
		private var timer:Timer=null;
		private var success:Function=null;
		public function timeInterval(time:Number,fun:Function) {
			// constructor code
			success=fun;
			timer=new Timer(time)
			timer.addEventListener(TimerEvent.TIMER,timerHandler);
		}
		public function timerHandler(event:TimerEvent):void{
			//trace("正在运行计时器",success);
			success();
		}
		public function start():void{
			if(timer && !timer.running){
				timer.start();
			}
		}
		public function stop():void{
			if(timer && timer.running){
				timer.stop();
			}
		}
		public function close():void{
			if(timer){
				if(timer.running){
					timer.stop();
				}
				timer.removeEventListener(TimerEvent.TIMER,timerHandler);
				timer=null;
			}
		}
		public function running():Boolean{
			return timer.running;
		}

	}
	
}
