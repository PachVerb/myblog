package ckaction.C {
	public final
	class C extends Object {
		public static var VERSION: String = "20180215190700";
		public static var CONFIG: Object = {
			config: {
				schedule: 1,
				autoLoad: false,
				timeFrequency: 100,
				loadNext: 0,
				smartRemove: false,
				definition: false,
				subtitle:false,
				bufferTime: 100,
				rtmpBufferTime:0,
				bufferTimeMax:0,
				doubleClick: false,
				click: false,
				doubleClickInterval: 200,
				fullInteractive: false,
				delay: 100,
				keyDown: {
					space: false,
					left: false,
					right: false,
					up: false,
					down: false
				},
				timeJump: 10,
				volumeJump: 0.1,
				timeScheduleAdjust: 1,
				previewDefaultLoad: false,
				promptSpotTime: false,
				buttonMode: {
					player: false,
					controlBar: false,
					timeSchedule: false,
					volumeSchedule: false
				},
				liveAndVod: {
					open: false,
					vodTime: 1,
					start: "start"
				},
				timeStamp: "",
				time: 0,
				crossdomain: "",
				playCorrect: false,
				timeCorrect:false,
				m3u8Definition: {
					tags: []
				},
				m3u8MaxBufferLength: 60,
				usehardwareeecoder:false,//是否采用硬件加速
				errorNum: 0,
				split:",",
				addCallback: "adPlay,adPause,playOrPause,videoPlay,videoPause,videoMute,videoEscMute,videoClear,changeVolume,fastBack,fastNext,videoSeek,newVideo,getMetaDate,videoRotation,videoBrightness,videoContrast,videoSaturation,videoHue,videoZoom,videoProportion,videoError,addListener,removeListener,addElement,getElement,deleteElement,animate,animateResume,animatePause,changeConfig,getConfig,openUrl,fullScreen,quitFullScreen,switchFull,screenshot,custom"
			},
			menu: {
				codes: "",
				name: "ckplayer",
				link: "http://www.ckplayer.com",
				domain: "",
				version: ""
			},
			language: {
				m3u8Definition: {
					name: []
				},
				error: {
					cannotFindUrl: "",
					streamNotFound: "",
					formatError: ""
				}
			},
			style: {
				advertisement: {
					linkButtonShow: false,
					closeButtonShow: false,
					frontSkipButtonDelay: 0,
					videoVolume: 0.8,
					pauseStretched: 2,
					time: 5,
					muteButtonShow: false,
					endStretched: 2,
					frontStretched: 2,
					endSkipButtonDelay: 0,
					videoForce: false,
					insertSkipButtonDelay: 0,
					insertStretched: 0,
					method: "get",
					skipButtonShow: false,
					closeOtherButtonShow: false,
					reserve: {
						spacingLeft: 0,
						spacingTop: 0,
						spacingRight: 0,
						spacingBottom: 0,
						stretched: 1,
						align: "center",
						vAlign: "middle"
					}
				},
				video: {
					defaultWidth: 4,
					defaultHeight: 3,
					reserve: {
						spacingLeft: 0,
						spacingTop: 0,
						spacingRight: 0,
						spacingBottom: 0,
						stretched: 1,
						align: "center",
						vAlign: "middle"
					},
					controlBarHideReserve: {
						spacingLeft: 0,
						spacingTop: 0,
						spacingRight: 0,
						spacingBottom: 0,
						stretched: 1,
						align: "center",
						vAlign: "middle"
					}
				}
			},
			flashvars: {
				playerID:"",
				variable: "",
				autoplay: false,
				loop: false,
				live: false,
				volume: 0.8,
				inserttime: "",
				rotation: 0, //默认旋转的角度
				loaded: "",
				poster: "",
				drag: "",
				debug: false,
				crossdomain: "",
				cktrack: null,
				cktrackdelay:0,
				config: "",
				definition: "",
				weight: "",
				type: "",
				video: "",
				promptSpot:null,
				previewscale:0,
				preview:"",
				cannotFindUrl:"",
				streamNotFound:"",
				formatError:"",
				securetoken:"",
				fcsubscribe:false,
				username:"",
				password:"",
				userid:0,
				duration:0,
				forceduration:0,
				unescape:false
			}
		};
		public static var CEKEY: String = "";
		public static var CVKEY: String = "";
		public static var PATH: Object = {};
	}
}