package  {

	import flash.display.MovieClip;
	import fl.controls.Button;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	import flash.events.Event;
	import flash.events.MouseEvent;	
	import flash.events.IOErrorEvent;		
	import flash.net.Responder;
	import flash.display.Sprite;
	import flash.media.Video;
	import flash.media.Camera;
	import flash.media.StageVideo;
	import flash.media.StageVideoAvailability;
	import flash.events.StageVideoAvailabilityEvent;
	import flash.events.StageVideoEvent;
	import flash.events.StatusEvent;	
	import fl.data.DataProvider; 
	import flash.geom.Rectangle;	
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.media.CameraPosition;
	import flash.geom.*;
	import flash.display.Shape;
	import flash.display.BitmapData;
	import fl.controls.*;
	import flash.utils.ByteArray;

	import com.rainbowcreatures.*;
	import com.rainbowcreatures.swf.*;	
	
	public class FWWebcam extends MovieClip {
				
		
		private var mode:String = "record";
		private var state:String = "none";
		private const w:int = 480;
		private const h:int = 270;		
		private var myEncoder:FWVideoEncoder;		
		private var stageVideo:StageVideo;
		private var camera:Camera;
		private var video:Video;
		private var recordStopButton:Button; 
		private var minMaxButton:Button;
		private var circle:Sprite;
		private var recordPlaybackBox:Shape;
		private var saveButton:Button;
		private var cam:Camera;
		private var xvideo:Video;
		private var count:int;
		private var xfile:File;


		public var useStageVideo:Boolean = false;
		var _file:File = File.desktopDirectory.resolvePath("videoTake.mp4");

		
		public function FWWebcam() {	
	
			addEventListener(Event.ADDED_TO_STAGE, init);					
		}		
				
		private function init(e:Event):void {			
		
			removeEventListener(Event.ADDED_TO_STAGE, init);								
			addEventListener(Event.REMOVED_FROM_STAGE, dispose);					
			// Always hand over the root DisplayObject in the getInstance constructor
			myEncoder = FWVideoEncoder.getInstance(this);			
			myEncoder.addEventListener(StatusEvent.STATUS, onStatus);			
			myEncoder.load("../../../lib/FlashPlayer/");
			if (useStageVideo) {																		
				stage.addEventListener(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, availabilityChanged);
			}
			prepareForRecording();
			setRecordingAssets();
			
		}// end of init
		
		
		protected function setRecordingAssets(): void {
        
        		minMaxButton = new Button();
   				minMaxButton.label = "MINIMIZE CAMERA"; 
				minMaxButton.width = 335;
   				minMaxButton.selected = true;    
				minMaxButton.toggle = true;  
  				minMaxButton.addEventListener(MouseEvent.CLICK,camMinMax);
				minMaxButton.move(80,10);
				addChild(minMaxButton); 
				
				recordStopButton = new Button();
   				recordStopButton.label = "Click to record video"; 
   				recordStopButton.selected = true;    
				recordStopButton.toggle = true;  
  				recordStopButton.addEventListener(MouseEvent.CLICK,recordStop);
				recordStopButton.move(25,360);
				recordStopButton.width = 125;
				addChild(recordStopButton);
				
				circle = new Sprite();
         		circle.graphics.beginFill(0x000000);
         		circle.graphics.drawCircle(170,372, 9);
         		circle.graphics.endFill();
         		addChild(circle);
        		
				recordPlaybackBox = new Shape;
				recordPlaybackBox.graphics.beginFill(0xcccccc); // choosing the colour for the fill (grey)
				recordPlaybackBox.graphics.drawRoundRect(10, 40, 500,300,25,25); // (x spacing, y spacing, width, height , rounding x and y)
				recordPlaybackBox.graphics.endFill(); 
				addChildAt(recordPlaybackBox,0);
				
				saveButton = new Button();
				saveButton.label = "Click to save image";
				saveButton.width = 150;
				saveButton.move(195, 360);
				saveButton.addEventListener(MouseEvent.CLICK, saveStill);
 				addChild(saveButton);
				
    		} // setRecordingAssets
			
	
		
		protected function availabilityChanged(e:StageVideoAvailabilityEvent):void {
            trace("StageVideo => " + e.availability);
            if(e.availability == StageVideoAvailability.AVAILABLE){
                stageVideo = stage.stageVideos[0];
                attachCamera();
            }
        }
	
		protected function attachCamera():void {
            trace("Camera.isSupported => " + Camera.isSupported);
            if(Camera.isSupported){
                camera = tryGetFrontCamera();
				if (camera == null) {
					throw new Error("Camera is needed");
				}
				camera.setMode(stage.stageWidth, stage.stageHeight, 25);
				camera.setQuality(0, 100);
                stageVideo.addEventListener(StageVideoEvent.RENDER_STATE, onRenderState);
                stageVideo.attachCamera(camera);
            }
        }
		
		
		protected function onRenderState(e:StageVideoEvent):void {
            stageVideo.viewPort = new Rectangle(0, 0, w, h);
        }				
				

		private function initRecord():void {// reinitialize recording (notice the myEncoder.init is there)	
		
			// initialize FW with microphone recording
			myEncoder.setDimensions(w, h);
			myEncoder.start(20, FWVideoEncoder.AUDIO_MICROPHONE);
		}
		

		private function onStatus(e:StatusEvent):void {
				
			// the encoder class is loaded (this is triggered only once)
			if (e.code == "ready") {					
					
				myEncoder.askMicPermission();
				if (!useStageVideo) {
					// add webcam view
					video = new Video(w, h);
					video.x = 20;
					video.y = 60;
					addChild(video);
					var camera:Camera = tryGetFrontCamera();
					if (camera == null) {
						throw new Error("Camera is needed");
					}
					camera.setMode(w, h, 60);
					camera.setQuality(0, 100);
					video.attachCamera(camera);
				}				
				addEventListener(Event.ENTER_FRAME, onFrame);
			}
												
			// video was encoded
			if (e.code == "encoded") {				
				trace("Video encoded!");
				// enable the button				
				//button_save.enabled = true;								
				
				// get the final video
				var bo:ByteArray = myEncoder.getVideo();									
				trace("Saving " + bo.length + " bytes...");
				/*if (myEncoder.platform != "IOS" && myEncoder.platform != "ANDROID") {
					var saveFile:FileReference = new FileReference();
				saveFile.addEventListener(Event.COMPLETE, saveCompleteHandler);
				saveFile.addEventListener(IOErrorEvent.IO_ERROR, saveIOErrorHandler);
				saveFile.save(bo, filename);
				} else {*/
				
				// AIR only
				var file:File;
				
				// for iOS
				if (myEncoder.platform == FWVideoEncoder.PLATFORM_IOS) {
					myEncoder.iOS_saveToCameraRoll();				
				} else {
	   								_file.browseForSave("Save Your File");
   					var fileStream:FileStream = new FileStream();
   					fileStream.open(_file, FileMode.WRITE);
  						fileStream.writeBytes(bo, 0, bo.length);
   					fileStream.close();
					dispatchEvent(new Event(Event.COMPLETE));
				}
				
																								
				
				//}
				
				// on iOS we saved to cameraroll and we will prepareForRecording only after we know 
				// that the video finished saving
				if (myEncoder.platform != FWVideoEncoder.PLATFORM_IOS) {
					prepareForRecording();
				}									
			}							
			
			if (e.code == "stopped") {
				trace("Encoding was forced to stop. Please try again.");
				state = "none";
				prepareForRecording();
				
			}
			
			// for mobile
			if (e.code == "cameraroll_saved") {
				prepareForRecording();
			}
			
			// for mobile
			if (e.code == "encoding_cancel") {
				trace("Encoding cancelled.");
			}
			
			// for mobile			
			if (e.code == "cameraroll_failed") {
				trace("Saving to camera roll has failed, permissions for access to camera roll are probably not enabled correctly for this app");
				prepareForRecording();
			}
		}


		private function tryGetFrontCamera():Camera {// utility function trying to get front camera, otherwise get the standard one
    		
			var numCameras:uint = (Camera.isSupported) ? Camera.names.length : 0;
    		for (var i:uint = 0; i < numCameras; i++) {
        		var cam:Camera = Camera.getCamera(String(i));
        		if (cam && cam.position == CameraPosition.FRONT) {
            		return cam;
        		}
   			} 
    		return Camera.getCamera();
		}
		
		
		private function onFrame(e:Event):void {
			
			// record mode - this records the animation
			if (state == "record") {
				myEncoder.capture(video);
			}
						
			// finish recording
			if (state == "finish") {				
				// send the "finish" command - this doesn't guarantee instant finishing as some background threads need to be stopped yet
				myEncoder.finish();
				// thats why we switch to "finishing" state and we're there until we get 'encoded' status event. During "finishing" we can still try to display progress
				// because on iOS it is finalizing the movie and actually returns the progress of that(it might take several seconds)
				state = "finishing";
			}					
			
			// show encoding progress if needed
			if (state == "finishing") {				
			}
			
		}
		
		
		private function onRecordClick(e:MouseEvent):void { // record  click handler
			
			if (mode == "record") {
				state = "record";
				initRecord();
				mode = "stop";
			} 			
		}

		
		private function onSaveClick(e:MouseEvent):void { // save button click handler
			
				if (mode == "stop") {											
					state = "finish";				
				}
		}
		
		
		private function prepareForRecording():void {

			mode = "record";			
		}
		

		private function saveCompleteHandler(e:Event):void {
			
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		
		private function saveIOErrorHandler(e:IOErrorEvent):void {// some error happened, oops
		
			dispatchEvent(e);
		}		
		
			
			
		private function recordStop(e:MouseEvent):void {

    			if(e.target.selected==true){
					
				// code to start encoding/saving the video
					var stopColor:ColorTransform = new ColorTransform();
 						stopColor.color = 0x000000;
 						circle.transform.colorTransform = stopColor;
						recordStopButton.label = "Click to record video";
						
						if (mode == "stop") {											
							state = "finish";				
						}
						
    			} else {
				
				// code to start recording the video
					var recordColor:ColorTransform = new ColorTransform();
 						recordColor.color = 0xFF0000;
 						circle.transform.colorTransform = recordColor;
        				recordStopButton.label = "STOP";
					
						if (mode == "record") {
							state = "record";
							initRecord();
							mode = "stop";
						}
						
    			} // end of main iff
			
	  		} // end of recordStop	
			
			
		private function camMinMax(e:MouseEvent):void {

    			if(e.target.selected==true){
					
				// min function
					minMaxButton.label = "MINIMIZE CAMERA";
					video.visible = true;
					circle.visible = true;
					recordStopButton.visible = true;
					recordPlaybackBox.visible = true;
					saveButton.visible = true;
					
    			} else {
					
				// max function
					minMaxButton.label = "MAXIMIZE CAMERA";
					video.visible = false;
					circle.visible = false;
					recordStopButton.visible = false;
					recordPlaybackBox.visible = false;
					saveButton.visible = false;
						
    			} // end of if
			
	  		} // end of camMinMax
			
			
		private function dispose(e:Event):void {// after removed from stage, erase all event listeners
		
			removeEventListener(Event.REMOVED_FROM_STAGE, dispose);											
			removeEventListener(Event.ENTER_FRAME, onFrame);
		}		
		
		
		function saveStill(e:Event):void {
	
			xfile = File.desktopDirectory.resolvePath ("webcamStill" + count++ +".png");
			xfile.addEventListener(Event.SELECT, onSelect);
			xfile.browseForSave("Save Your File");
				
		} // end of saveStill
		
						
		function onSelect(e:Event):void{
				
			var bmd:BitmapData = new BitmapData(330,240);
				bmd.draw(video);
			var ba:ByteArray = PNGEncoder.encode(bmd);
			
			var filestream:FileStream = new FileStream();
				filestream.addEventListener(Event.CLOSE, pngWritten);
				filestream.openAsync(xfile, FileMode.WRITE);
				filestream.writeBytes(ba);
				filestream.close();
			}
		
		
		function pngWritten(e:Event):void{
	
			trace("PNG file written to desktop");
			
		} // end of function pngWritten

	}
}
