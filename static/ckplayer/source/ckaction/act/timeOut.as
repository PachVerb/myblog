package ckaction.act {
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	public class timeOut {
		private var timer: Timer = null;
		private var success: Function = null;
		private var parNum:int=-1;
		private var isStop:Boolean=false;
		public function timeOut(time: Number, fun: Function, num: int = -1) {
			// constructor code
			success = fun;
			parNum=num;
			timer = new Timer(time, 1);
			timer.addEventListener(TimerEvent.TIMER, timerHandler);
			timer.start();
		}
		private function timerHandler(event: TimerEvent): void {
			
			if(isStop){
				return;
			}
			if(parNum>-1){
				success(parNum);
			}
			else{
				//trace("++",success);
				success();
				//trace("+---+",success);
			}
			stop();
		}
		public function stop():void{
			isStop=true;
			if (timer != null) {
				if (timer.running) {
					timer.stop();
				}
				timer.removeEventListener(TimerEvent.TIMER, timerHandler);
				timer = null;
			};
		}
	}

}