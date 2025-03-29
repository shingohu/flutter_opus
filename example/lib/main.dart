import 'dart:async';
import 'dart:math';

import 'package:convert/convert.dart';
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
  PCMPlayer player = PCMPlayer(enableAEC: true);

  List<Uint8List> pcmData = [];
  int txIndex = 0;
  int rxIndex = -1;

  ///是否使用PLC处理丢包情况
  bool get openPLC => false;

  ///是否启用FEC处理丢包情况
  bool get openFEC => true;

  ///丢包率
  double get LOSS_RATE => 0.3;
  Random random = Random();

  bool markToStop = false;

  @override
  Widget build(BuildContext context) {
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
                      markToStop = false;
                      PCMRecorder.start(
                          preFrameSize: 960,
                          echoCancel: true,
                          onData: (data) {
                            if (data != null) {
                              sendData(data);
                            } else {
                              markToStop = true;
                              txIndex = 0;
                              opusEncoder?.dispose();
                              opusEncoder = null;
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

  Timer? _playTimer;
  Timer? _delayTimer;

  void sendData(Uint8List pcm) {
    if (opusEncoder == null) {
      opusEncoder =
          SimpleOpusEncoder(sampleRate: 8000, channels: 1, bitrate: 12000);
      if (openFEC) {
        opusEncoder?.enableFEC(true, (LOSS_RATE * 100).toInt());
      }
    }

    Uint8List? newData = opusEncoder?.encode(input: _bytesToShort(pcm));
    if (newData != null) {
      // 模拟丢包
      if (random.nextDouble() > LOSS_RATE) {
        List<int> newDataList = [];
        newDataList.addAll(int2bytes(txIndex, 2));
        newDataList.addAll(newData);
        pcmData.add(Uint8List.fromList(newDataList));
      }
    }
    txIndex++;
    startPlay();
  }

  ///int 转bytes
  List<int> int2bytes(int value, int size) {
    String hexStr = value.toRadixString(16).toUpperCase();

    if (hexStr.length % 2 != 0) {
      hexStr = "0" + hexStr;
    }
    int hexLength = hexStr.length;
    if (hexLength < size * 2) {
      for (int i = 0; i < size * 2 - hexLength; i++) {
        hexStr = "0" + hexStr;
      }
    }
    return hex.decode(hexStr);
  }

  void startPlay() {
    if (_delayTimer == null) {
      player.play();
      _delayTimer = Timer(Duration(milliseconds: 1000), () {
        if (_playTimer == null) {
          _playTimer = Timer.periodic(Duration(milliseconds: 60), (timer) {
            Uint8List? data = pcmData.isNotEmpty ? pcmData.removeAt(0) : null;
            if (data != null) {
              int index = bytes2int(data.sublist(0, 2));
              Uint8List newData = data.sublist(2);
              if (opusDecoder == null) {
                opusDecoder = SimpleOpusDecoder(sampleRate: 8000, channels: 1);
              }

              int loss = _checkLossPackage(index);
              if (loss > 0) {
                if (openPLC) {
                  ///PLC 丢包补偿
                  Int16List? plc = opusDecoder?.decode(
                      input: null, fec: false, lossDuration: loss * 60);
                  if (plc != null) {
                    Uint8List newPlc = _shortToBytes(plc);
                    print("PLC恢复包长${newPlc.length}");
                    player.feed(newPlc);
                  }
                } else if (openFEC) {
                  Int16List? fec = opusDecoder?.decode(
                      input: newData, fec: true, lossDuration: loss * 60);
                  if (fec != null) {
                    Uint8List newFEC = _shortToBytes(fec);
                    print("FEC恢复包长${newFEC.length}");
                    player.feed(newFEC);
                  }
                }
              }
              Uint8List newPcm =
                  _shortToBytes(opusDecoder!.decode(input: newData));
              player.feed(newPcm);
            } else if (markToStop) {
              print("停止播放");
              stopPlay();
            }
          });
        }
      });
    }
  }

  int _checkLossPackage(int vIndex) {
    int loss = 0;
    if (this.rxIndex != -1) {
      if (this.rxIndex + 1 != vIndex) {
        loss = vIndex - this.rxIndex - 1;
      }
    }
    if (loss != 0) {
      print(
          "语音数据包可能丢失,期望index:${this.rxIndex + 1},当前index:$vIndex,丢失${loss}个包");

      ///这里到时看看是否需要做丢包补充
    }
    this.rxIndex = vIndex;
    return loss;
  }

  void stopPlay() {
    _playTimer?.cancel();
    _playTimer = null;
    _delayTimer?.cancel();
    _delayTimer = null;
    opusDecoder?.dispose();
    opusDecoder = null;
    player.stop();
    rxIndex = -1;
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

  ///bytes 转 int
  int bytes2int(List<int> bytes) {
    return int.parse(hex.encode(bytes), radix: 16);
  }
}
