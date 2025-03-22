import 'package:flutter/material.dart';
import 'package:opus/opus.dart';
import 'package:pcm/pcm.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    PCMRecorder.requestRecordPermission();
    super.initState();
  }

  SimpleOpusEncoder? opusEncoder;
  SimpleOpusDecoder? opusDecoder;
  PCMPlayer player = PCMPlayer();

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Packages'),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                TextButton(
                    onPressed: () {
                      int index = 0;
                      PCMRecorder.start(
                          preFrameSize: 960,
                          echoCancel: true,
                          onData: (data) {
                            if (data != null) {
                              if (opusDecoder == null) {
                                opusEncoder = SimpleOpusEncoder(bitrate: 8000);
                                opusDecoder = SimpleOpusDecoder();
                              }

                              if (opusEncoder != null) {
                                index++;
                                // Stopwatch stopwatch = Stopwatch();
                                // stopwatch.start();
                                Uint8List? p = opusEncoder?.encode(
                                    input: _bytesToShort(data));
                                // stopwatch.stop();
                                // print(
                                //     "time to encode: ${stopwatch.elapsedMilliseconds}");

                                // stopwatch.start();
                                ///模拟丢包
                                Int16List? p1 = opusDecoder?.decode(
                                    input: index % 2 == 0 ? null : p);
                                // stopwatch.stop();
                                // print(
                                //     "time to decode: ${stopwatch.elapsedMilliseconds}");
                                if (p1?.length != 480) {
                                  print(p1?.length);
                                }
                                if (p1 != null) {
                                  player.play();
                                  player.feed(_shortToBytes(p1));
                                }
                              }
                            } else {
                              player.stop();
                              opusEncoder?.dispose();
                              opusDecoder?.dispose();
                              opusEncoder = null;
                              opusDecoder = null;
                            }
                          });
                    },
                    child: Text(
                      'record',
                      style: TextStyle(fontSize: 50),
                    )),
                TextButton(
                    onPressed: () {
                      PCMRecorder.stop();
                    },
                    child: Text(
                      'stop',
                      style: TextStyle(fontSize: 50),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Int16List _bytesToShort(Uint8List bytes) {
    Int16List shorts = Int16List(bytes.length ~/ 2);
    for (int i = 0; i < shorts.length; i++) {
      shorts[i] = (bytes[i * 2] & 0xff | ((bytes[i * 2 + 1] & 0xff) << 8));
    }
    return shorts;
  }

  static Uint8List _shortToBytes(Int16List shorts) {
    Uint8List bytes = Uint8List(shorts.length * 2);
    for (int i = 0; i < shorts.length; i++) {
      bytes[i * 2] = (shorts[i] & 0xff);
      bytes[i * 2 + 1] = (shorts[i] >> 8 & 0xff);
    }
    return bytes;
  }
}
