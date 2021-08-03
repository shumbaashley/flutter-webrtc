// ignore: uri_does_not_exist
import 'dart:core';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/*
 * getUserMedia sample
 */
class GetUserMediaSample extends StatefulWidget {
  static String tag = 'get_usermedia_sample';

  @override
  _GetUserMediaSampleState createState() => _GetUserMediaSampleState();
}

class _GetUserMediaSampleState extends State<GetUserMediaSample> {
  MediaStream? _localStream;
  final _localRenderer = RTCVideoRenderer();
  bool _inCalling = false;

  List<MediaDeviceInfo>? _cameras;

  List<dynamic>? cameras;

  @override
  void initState() {
    super.initState();
    initRenderers();

    navigator.mediaDevices.enumerateDevices().then((md) {
      setState(() {
        cameras = md.where((d) => d.kind == 'videoinput').toList();
      });
    });
  }

  @override
  void deactivate() {
    super.deactivate();
    if (_inCalling) {
      _stop();
    }
    _localRenderer.dispose();
  }

  void initRenderers() async {
    await _localRenderer.initialize();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  void _makeCall() async {
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth':
              '1280', // Provide your own width, height and frame rate here
          'minHeight': '720',
          'minFrameRate': '30',
        },
      }
    };

    try {
      var stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _cameras = await Helper.cameras;
      _localStream = stream;
      _localRenderer.srcObject = _localStream;
    } catch (e) {
      print(e.toString());
    }
    if (!mounted) return;

    setState(() {
      _inCalling = true;
    });
  }

  Future<void> _stop() async {
    try {
      await _localStream?.dispose();
      _localStream = null;
      _localRenderer.srcObject = null;
    } catch (e) {
      print(e.toString());
    }
  }

  void _hangUp() async {
    await _stop();
    setState(() {
      _inCalling = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GetUserMedia'),
        actions: _inCalling
            ? <Widget>[
                PopupMenuButton<String>(
                  onSelected: _switchCamera,
                  itemBuilder: (BuildContext context) {
                    if (_cameras != null) {
                      return _cameras!.map((device) {
                        return PopupMenuItem<String>(
                          value: device.deviceId,
                          child: Text(device.label),
                        );
                      }).toList();
                    } else {
                      return [];
                    }
                  },
                ),
                // IconButton(
                //   icon: Icon(Icons.settings),
                //   onPressed: _switchCamera,
                // )
              ]
            : null,
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Center(
            child: Container(
              margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(color: Colors.black54),
              child: RTCVideoView(_localRenderer, mirror: true),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _inCalling ? _hangUp : _makeCall,
        tooltip: _inCalling ? 'Hangup' : 'Call',
        child: Icon(_inCalling ? Icons.call_end : Icons.phone),
      ),
    );
  }

  void _switchCamera(String deviceId) async {
    if (_localStream == null) return;

    await Helper.switchCamera(
        _localStream!.getVideoTracks()[0], deviceId, _localStream);
    setState(() {});
  }
}
