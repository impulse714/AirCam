package  {

	import flash.display.MovieClip;
	import flash.events.Event;

	
	[SWF(width=535,height=400, frameRate='60',backgroundColor="0x999999")]	
	
	public class Document extends MovieClip {
						
		public function Document() {	
		
			addEventListener(Event.ADDED_TO_STAGE, init);
			
		} // end of constructor
		
		private function init(e:Event):void {
			
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			var webcamRecorder:FWWebcam = new FWWebcam();
				addChild(webcamRecorder);
				
		} // end of init
		
	} // end of class Document
	
} // emd of package
