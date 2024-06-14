// ignore_for_file: avoid_print

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'audio_processor.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snore Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SnoreMonitor(),
    );
  }
}

class SnoreMonitor extends StatefulWidget {
  const SnoreMonitor({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SnoreMonitorState createState() => _SnoreMonitorState();
}

class _SnoreMonitorState extends State<SnoreMonitor> {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  String? _filePath;
  // ignore: prefer_typing_uninitialized_variables
  var _snoringFrames = [];
  var snoreCount = 0;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    _initializeRecorder();
    _requestMicrophonePermission();
  }

  Future<void> _requestMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.status;
    if (status.isDenied || status.isRestricted) {
      await Permission.microphone.request();
    }
  }

  Future<void> _initializeRecorder() async {
    await _recorder?.openAudioSession();
  }

  Future<void> _startRecording() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String filePath = path.join(appDocDir.path, 'recording.wav');
      _filePath = filePath;

      await _recorder?.startRecorder(toFile: filePath, codec: Codec.pcm16WAV);
      setState(() {});
    } catch (e) {
      // ignore: avoid_print
      print('Error starting recording: $e');
      // Handle error (e.g., show a dialog, log error, etc.)
    }
  }

  Future<void> _stopRecording() async {
    await _recorder?.stopRecorder();
    setState(() {});
  }

  Future<void> _playRecording() async {
    if (_filePath != null) {
      await _player?.startPlayer(fromURI: _filePath);
    }
  }

  Future<void> _analyzeRecording() async {
    // ignore: avoid_print
    print(_filePath);
    if (_filePath != null) {
      var snoringFrames = await detectSnoring(_filePath!);
      setState(() {
        _snoringFrames = snoringFrames;
        if (snoringFrames.length != 0) {
          var tempcount = countSnoringEvents(_snoringFrames);
          snoreCount = tempcount;
        }
      });
      // ignore: avoid_print
      // print(_snoringFrames);
    }
  }

  countSnoringEvents(spectralCentroids) {
    print(spectralCentroids.length);
    print(spectralCentroids);
    // var minSpectralRange = 20775;
    // var maxSpectralRange = 20825;

    var tempSpectralArray = [];
    int index = 0;
    spectralCentroids.forEach((items) {
      index++;
      if (items < 20820) {
        tempSpectralArray.add({'spectralCentroids': items, 'index': index});
      }
    });

    print(tempSpectralArray);
    var indexDiff = [];

    for (int i = 0; i < tempSpectralArray.length - 1; i++) {
      indexDiff.add(
          tempSpectralArray[i + 1]['index'] - tempSpectralArray[i]['index']);
    }

    snoreCount = 0;
    print(indexDiff);
    for (var item in indexDiff) {
      if (item > 100 && item < 250) {
        snoreCount++;
      }
    }
    print(snoreCount);
    return snoreCount;
  }

  @override
  void dispose() {
    _recorder?.closeAudioSession();
    _player?.closeAudioSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snore Monitor'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: _startRecording,
                  child: const Text('Start Recording'),
                ),
                ElevatedButton(
                  onPressed: _stopRecording,
                  child: const Text('Stop Recording'),
                ),
                ElevatedButton(
                  onPressed: _playRecording,
                  child: const Text('Play Recording'),
                ),
                ElevatedButton(
                  onPressed: _analyzeRecording,
                  child: const Text('Analyze Recording'),
                ),
                // if (_snoringFrames != null) ...[
                // const Text('Snoring detected at frames:'),
                // Text(_snoringFrames.toString()),
              ],
              // ],
            ),
          ),
          _snoringFrames != null
              ? Center(
                  child: AspectRatio(
                    aspectRatio: 2,
                    child: LineChart(
                      LineChartData(
                        lineBarsData: [
                          LineChartBarData(
                            // spots: [
                            //   const FlSpot(0, 20824.877068254533),
                            //   const FlSpot(1, 20759.5844161822),
                            //   const FlSpot(2, 20861.33298278021),
                            //   const FlSpot(3, 20773.467856562173),
                            //   const FlSpot(4, 20778.06808176251),
                            //   const FlSpot(5, 20812.521826992255),
                            //   const FlSpot(6, 20706.313424701293),
                            //   const FlSpot(7, 20714.187911583565),
                            //   const FlSpot(8, 20811.816610566962),
                            //   const FlSpot(9, 20787.004343474397),
                            //   const FlSpot(10, 20888.91135439239),
                            //   const FlSpot(11, 20855.368641973015),
                            //   const FlSpot(12, 20837.638166766847),
                            //   const FlSpot(13, 20986.55620364659),
                            // ],
                            spots: _snoringFrames!
                                .asMap()
                                .entries
                                .map((e) =>
                                    FlSpot(e.key.toDouble(), e.value as double))
                                .toList(),
                            isCurved: false,
                            dotData: const FlDotData(
                              show: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const Text(''),
          Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 0, 0),
              child: Text('Snore Count:$snoreCount'))
        ],
      ),
    );
  }
}
