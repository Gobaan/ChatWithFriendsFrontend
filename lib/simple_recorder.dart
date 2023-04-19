/*
 * Copyright 2018, 2019, 2020, 2021 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL2.0),
 * as published by the Mozilla organization.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MPL General Public License for more details.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:chat_with_friends/conversation.dart';
import 'package:chat_with_friends/web_recorder.dart';

/*
 * This is an example showing how to record to a Dart Stream.
 * It writes all the recorded data from a Stream to a File, which is completely stupid:
 * if an App wants to record something to a File, it must not use Streams.
 *
 * The real interest of recording to a Stream is for example to feed a
 * Speech-to-Text engine, or for processing the Live data in Dart in real time.
 *
 */

///
typedef _Fn = void Function();

/* This does not work. on Android we must have the Manifest.permission.CAPTURE_AUDIO_OUTPUT permission.
 * But this permission is _is reserved for use by system components and is not available to third-party applications._
 * Pleaser look to [this](https://developer.android.com/reference/android/media/MediaRecorder.AudioSource#VOICE_UPLINK)
 *
 * I think that the problem is because it is illegal to record a communication in many countries.
 * Probably this stands also on iOS.
 * Actually I am unable to record DOWNLINK on my Xiaomi Chinese phone.
 *
 */
//const theSource = AudioSource.voiceUpLink;
//const theSource = AudioSource.voiceDownlink;

const theSource = AudioSource.microphone;

/// Example app.
class SimpleRecorder extends StatefulWidget {
  final TextEditingController textController;
  final Conversation conversation;
  final void Function(Uri) onRecord;
  final void Function(String) onText;
  const SimpleRecorder(
      {required this.textController,
      required this.onRecord,
      required this.onText,
      required this.conversation});

  @override
  _SimpleRecorderState createState() => _SimpleRecorderState();
}

class _SimpleRecorderState extends State<SimpleRecorder> {
  OpusOggRecorder recorder = OpusOggRecorder();
  bool _isRecording = false;

  // Create a new MediaRecorder for the audio data

  @override
  void initState() {
    super.initState();
    recorder.requestPermissions();
  }

  @override
  void dispose() {
    recorder.stopRecording();

    super.dispose();
  }

  // ----------------------  Here is the code for recording and playback -------

  void startRecorder() {
    recorder.startRecording(_uploadAudio);
    setState(() {
      _isRecording = true;
    });
  }

  void stopRecorder() async {
    recorder.stopRecording();
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _uploadAudio(String recordUrl) async {
    html.HttpRequest request =
        await html.HttpRequest.request(recordUrl, responseType: "arraybuffer");
    ByteBuffer buffer = request.response as ByteBuffer;
    Uint8List audioBytes = buffer.asUint8List();

    Uri url = Uri.parse(widget.conversation.blobUrl);

    http.Request request2 = http.Request('PUT', url)
      ..headers['x-ms-blob-type'] = 'BlockBlob'
      ..headers['Content-Type'] = 'audio/webm'
      ..bodyBytes = audioBytes;
    http.StreamedResponse response = await request2.send();

    if (response.statusCode == 201) {
      print('Uploaded successfully');
      widget.onRecord(url);
    } else {
      print('Failed to upload');
    }
  }

// ----------------------------- UI --------------------------------------------

  void _sendMessage(String message) {
    widget.onText(message);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onLongPress: widget.textController.text.isEmpty ? startRecorder : null,
        onLongPressEnd: (LongPressEndDetails details) {
          widget.textController.text.isEmpty
              ? stopRecorder()
              : _sendMessage(widget.textController.text);
        },
        child: _isRecording
            ? const Icon(Icons.stop, color: Colors.red)
            : (widget.textController.text.isEmpty
                ? const Icon(Icons.mic)
                : const Icon(Icons.send)));
  }
}
