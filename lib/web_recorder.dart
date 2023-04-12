import 'dart:html' as html;
import 'dart:js' as js;

typedef RecordingCallback = void Function(String blobUrl);

class OpusOggRecorder {
  html.MediaRecorder? _mediaRecorder;
  html.MediaStream? _mediaStream;
  bool isStopped = true;
  bool isBlocked = false;

  Future<html.MediaStream> getStream() async {
    _mediaStream = await html.window.navigator.mediaDevices?.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      }
    });
    return _mediaStream!;
  }

  void requestPermissions() async {
    var stream = await getStream();
    stream.getTracks().forEach((track) {
      if (track.readyState == 'live') {
        track.stop();
      }
    });
  }

  void startRecording(RecordingCallback callback) async {
    _mediaStream = await getStream();
    html.Blob blob = html.Blob([]);
    if (isBlocked) {
      return;
    }
    isBlocked = true;

    _mediaRecorder = html.MediaRecorder(_mediaStream!, {
      'mimeType': 'audio/webm; codecs=opus',
    });

    _mediaRecorder?.addEventListener('dataavailable', (event) {
      blob = js.JsObject.fromBrowserObject(event)['data'];
    }, true);

    _mediaRecorder?.start();
    isStopped = false;
    _mediaRecorder?.addEventListener('stop', (event) {
      _mediaStream?.getTracks().forEach((track) {
        if (track.readyState == 'live') {
          track.stop();
        }
      });
      final url = html.Url.createObjectUrl(blob);
      isStopped = true;
      callback(url);
    });
    isBlocked = false;
  }

  void stopRecording() {
    if (!isStopped) {
      _mediaRecorder!.stop();
    }
  }
}
