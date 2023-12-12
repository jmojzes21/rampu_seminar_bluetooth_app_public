import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class AccelerometerData {
  late final double x;
  late final double y;
  late final double z;

  AccelerometerData({required this.x, required this.y, required this.z});

  AccelerometerData.empty()
      : x = 0,
        y = 0,
        z = 0;

  AccelerometerData.fromBytes(List<int> bytes) {
    ByteData byteData = Uint8List.fromList(bytes).buffer.asByteData();

    x = byteData.getFloat32(0, Endian.little);
    y = byteData.getFloat32(4, Endian.little);
    z = byteData.getFloat32(8, Endian.little);
  }
}

class MyDeviceConnectException implements Exception {
  String message;
  MyDeviceConnectException(this.message);

  @override
  String toString() => message;
}

abstract class MyDevice {
  @protected
  var accelerometerDataStreamController =
      StreamController<AccelerometerData>.broadcast();

  @protected
  void Function()? onDisconnectCallback;

  Future<void> connect();
  Future<void> disconnect();

  Future<void> setLedEnabled(bool enabled);
  Future<void> setAccelerometerEnabled(bool enabled);

  Future<void> showColor(Color color);
  Future<void> setBrightness(int brightness);

  void setOnDisconnect(void Function() callback) {
    onDisconnectCallback = callback;
  }

  @mustCallSuper
  Future<void> dispose() async {
    await accelerometerDataStreamController.close();
    await disconnect();
  }

  Stream<AccelerometerData> get accelerometerDataStream =>
      accelerometerDataStreamController.stream;
}
