import 'dart:io';
import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import 'package:flutter_sound/flutter_sound.dart';

detectSnoring(String filePath) async {
  final audioFile = File(filePath);
  final audioData = await audioFile.readAsBytes();
  final audioBuffer = Uint8List.fromList(audioData);

  var snoringFrames = [];
  const sampleRate = 44100; // Example sample rate
  const frameSize = 2048;
  const hopSize = 512;

  for (int i = 0; i < audioBuffer.length - frameSize; i += hopSize) {
    final frame = audioBuffer.sublist(i, i + frameSize);
    final spectralCentroid = await computeSpectralCentroid(frame, sampleRate);
    // ignore: avoid_print
    // print(spectralCentroid);
    // if (spectralCentroid < 0.02) {
    snoringFrames.add(spectralCentroid);
    // }
  }

  return snoringFrames;
}

Future<double> computeSpectralCentroid(Uint8List frame, int sampleRate) async {
  final fft = FFT(frame.length);
  final List<double> doubleFrame =
      frame.map((value) => value.toDouble()).toList();
  final freq = fft.realFft(doubleFrame);

  double weightedSum = 0;
  double totalSum = 0;

  for (int i = 0; i < freq.length; i++) {
    final frequency = i * sampleRate / frame.length;
    weightedSum += frequency * freq[i].abs().x;
    totalSum += freq[i].abs().x;
  }

  return weightedSum / totalSum;
}
