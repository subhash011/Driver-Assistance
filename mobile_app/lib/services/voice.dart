import 'package:flutter_tts/flutter_tts.dart';
// import 'package:flutter_tts/flutter_tts_web.dart';

class Voice {
  FlutterTts flutterTts = FlutterTts();
  // TtsState ttsState = TtsState.stopped;

  Voice () {
    flutterTts.setLanguage("en-Us");

    flutterTts.setStartHandler(() {
        print("playing");
        // ttsState = TtsState.playing;
    });
    flutterTts.setCompletionHandler(() {
        print("Complete");
        // ttsState = TtsState.stopped;
    });
    flutterTts.setErrorHandler((msg) {
        print("error: $msg");
        // ttsState = TtsState.stopped;
    });
  }

  speak(text) async {
    var result = await flutterTts.speak(text);
    // if (result == 1) ttsState = TtsState.playing;
  }

  stop() async {
    var result = await flutterTts.stop();
    // if (result == 1) ttsState = TtsState.stopped;
  }


}