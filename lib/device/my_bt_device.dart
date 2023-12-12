import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'my_device.dart';

class MyBtDevice extends MyDevice {
  final BluetoothDevice _device;
  BluetoothConnection? _connection;

  StreamSubscription<Uint8List>? _onDataSubscription;
  final StringBuffer _tempMessage = StringBuffer();

  MyBtDevice(BluetoothDevice device) : _device = device;

  @override
  Future<void> connect() async {
    try {
      _connection = await BluetoothConnection.toAddress(_device.address);

      _onDataSubscription = _connection?.input?.listen(
        (Uint8List bytes) {
          _readInputData(bytes);
        },
        onDone: () {
          disconnect();
          onDisconnectCallback?.call();
        },
      );
    } on Exception catch (_) {
      throw MyDeviceConnectException("Povezivanje na uređaj nije uspjelo");
    }
  }

  @override
  Future<void> disconnect() async {
    await _onDataSubscription?.cancel();
    await _connection?.finish();
  }

  @override
  Future<void> setLedEnabled(bool enabled) async {
    if (enabled) {
      _writeData('led enable\n');
    } else {
      _writeData('led disable\n');
    }
  }

  @override
  Future<void> showColor(Color color) async {
    _writeData('color ${color.red} ${color.green} ${color.blue}\n');
  }

  @override
  Future<void> setBrightness(int brightness) async {
    _writeData('brightness $brightness\n');
  }

  @override
  Future<void> setAccelerometerEnabled(bool enabled) async {
    if (enabled) {
      _writeData('accelerometer enable\n');
    } else {
      _writeData('accelerometer disable\n');
    }
  }

  void _readMessage(String message) {
    List<String> parts = message.trim().split(' ');

    if (parts.isEmpty) return;

    String tag = parts[0];
    if (tag == 'acceleration') {
      if (parts.length != 4) return;

      var data = AccelerometerData(
        x: double.tryParse(parts[1]) ?? 0,
        y: double.tryParse(parts[2]) ?? 0,
        z: double.tryParse(parts[3]) ?? 0,
      );
      accelerometerDataStreamController.sink.add(data);
    }
  }

  void _readInputData(Uint8List bytes) {
    String data = String.fromCharCodes(bytes);

    for (int i = 0; i < data.length; i++) {
      String char = data[i];

      if (char == '\n') {
        String message = _tempMessage.toString();
        _readMessage(message);

        _tempMessage.clear();
      } else {
        _tempMessage.write(char);
      }
    }
  }

  void _writeData(String data) {
    _connection?.output.add(Uint8List.fromList(data.codeUnits));
  }
}
