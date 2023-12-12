import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'my_device.dart';

class MyBleDevice extends MyDevice {
  static const String ledServiceUuid = "4fafc201-1fb5-459e-1000-ff0000000000";
  static const String ledEnabledCharacteristicUuid =
      "4fafc201-1fb5-459e-1000-000000000010";
  static const String ledColorCharacteristicUuid =
      "4fafc201-1fb5-459e-1000-000000000020";
  static const String ledBrightnessCharacteristicUuid =
      "4fafc201-1fb5-459e-1000-000000000030";

  static const String accelerometerServiceUuid =
      "4fafc201-1fb5-459e-3000-ff0000000000";
  static const String accelerometerEnabledCharacteristicUuid =
      "4fafc201-1fb5-459e-3000-000000000010";
  static const String accelerationCharacteristicUuid =
      "4fafc201-1fb5-459e-3000-000000000020";

  final BluetoothDevice _device;

  late BluetoothService _ledService;
  late BluetoothCharacteristic _ledEnabledCharacteristic;
  late BluetoothCharacteristic _ledColorCharacteristic;
  late BluetoothCharacteristic _ledBrightnessCharacteristic;

  late BluetoothService _accelerometerService;
  late BluetoothCharacteristic _accelerometerEnabledCharacteristic;
  late BluetoothCharacteristic _accelerationCharacteristic;

  StreamSubscription<List<int>>? _onAccelerometerDataSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  MyBleDevice(BluetoothDevice device) : _device = device;

  @override
  Future<void> connect() async {
    try {
      await _device.connect();

      _connectionStateSubscription =
          _device.connectionState.listen((BluetoothConnectionState event) {
        if (event == BluetoothConnectionState.disconnected) {
          disconnect();
          onDisconnectCallback?.call();
        }
      });
    } catch (_) {
      throw MyDeviceConnectException("Povezivanje na uređaj nije uspjelo");
    }

    try {
      List<BluetoothService> services = await _device.discoverServices();
      _confirmServices(services);

      await _accelerationCharacteristic.setNotifyValue(true);
      _onAccelerometerDataSubscription =
          _accelerationCharacteristic.onValueReceived.listen((bytes) {
        var data = AccelerometerData.fromBytes(bytes);
        accelerometerDataStreamController.sink.add(data);
      });

      _device.cancelWhenDisconnected(_onAccelerometerDataSubscription!);
    } catch (error) {
      await disconnect();
      throw MyDeviceConnectException("Pogrešan uređaj");
    }
  }

  @override
  Future<void> disconnect() async {
    await _connectionStateSubscription?.cancel();
    await _onAccelerometerDataSubscription?.cancel();
    await _device.disconnect();
  }

  @override
  Future<void> setLedEnabled(bool enabled) async {
    if (enabled) {
      await _ledEnabledCharacteristic.write([0x01]);
    } else {
      await _ledEnabledCharacteristic.write([0x00]);
    }
  }

  @override
  Future<void> showColor(Color color) async {
    await _ledColorCharacteristic.write([color.red, color.green, color.blue]);
  }

  @override
  Future<void> setBrightness(int brightness) async {
    await _ledBrightnessCharacteristic.write([brightness]);
  }

  @override
  Future<void> setAccelerometerEnabled(bool enabled) async {
    if (enabled) {
      await _accelerometerEnabledCharacteristic.write([0x01]);
    } else {
      await _accelerometerEnabledCharacteristic.write([0x00]);
    }
  }

  void _confirmServices(List<BluetoothService> services) {
    _ledService = _findService(services, ledServiceUuid);
    _accelerometerService = _findService(services, accelerometerServiceUuid);

    _ledEnabledCharacteristic =
        _findCharacteristic(_ledService, ledEnabledCharacteristicUuid);
    _ledColorCharacteristic =
        _findCharacteristic(_ledService, ledColorCharacteristicUuid);
    _ledBrightnessCharacteristic =
        _findCharacteristic(_ledService, ledBrightnessCharacteristicUuid);

    _accelerometerEnabledCharacteristic = _findCharacteristic(
        _accelerometerService, accelerometerEnabledCharacteristicUuid);
    _accelerationCharacteristic = _findCharacteristic(
        _accelerometerService, accelerationCharacteristicUuid);
  }

  BluetoothService _findService(List<BluetoothService> services, String uuid) {
    return services.firstWhere((e) => e.serviceUuid.str128 == uuid);
  }

  BluetoothCharacteristic _findCharacteristic(
      BluetoothService service, String uuid) {
    return service.characteristics
        .firstWhere((e) => e.characteristicUuid.str128 == uuid);
  }
}
