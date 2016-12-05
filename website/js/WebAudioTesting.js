
var audio_context;
var recorder;

  function startUserMedia(stream) {
    var input = audio_context.createMediaStreamSource(stream);
    __log('Media stream created.');

    // Uncomment if you want the audio to feedback directly
    //input.connect(audio_context.destination);
    //__log('Input connected to audio context destination.');

    recorder = new Recorder(input);
    __log('Recorder initialised.');
 }

 function startRecording(button) {
    recorder && recorder.record();
    button.disabled = true;
    button.nextElementSibling.disabled = false;
  }

  function stopRecording(button) {
    recorder && recorder.stop();
    button.disabled = true;
    button.previousElementSibling.disabled = false;

    // create WAV download link using audio data blob
    //createDownloadLink();

    recorder.clear();
  }


$(window).load( function(){
      // webkit shim
      window.AudioContext = window.AudioContext || window.webkitAudioContext;
      navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia;
      window.URL = window.URL || window.webkitURL;

      audio_context = new AudioContext;
      console.log('Audio context set up.');
      console.log('navigator.getUserMedia ' + (navigator.getUserMedia ? 'available.' : 'not present!'));

    navigator.getUserMedia({audio: true}, startUserMedia, function(e) {
      console.log('No live audio input: ' + e);
    });
    startUserMedia()
   });
