import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../device/my_ble_device.dart';
import '../device/my_device.dart';
import 'device_page.dart';

class BleDeviceDiscoveryPage extends StatefulWidget {
  const BleDeviceDiscoveryPage({super.key});

  @override
  State<BleDeviceDiscoveryPage> createState() => _BleDeviceDiscoveryPageState();
}

class _BleDeviceDiscoveryPageState extends State<BleDeviceDiscoveryPage> {
  StreamSubscription<List<ScanResult>>? discoverySubscription;
  StreamSubscription<BluetoothAdapterState>? adapterStateSubscription;

  bool isBluetoothEnabled = false;
  bool isDiscovering = false;
  bool isConnecting = false;
  List<BluetoothDevice> devices = [];

  @override
  void initState() {
    super.initState();

    adapterStateSubscription =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      isBluetoothEnabled = state == BluetoothAdapterState.on;
    });
  }

  Future<void> startDiscovery() async {
    if (isBluetoothEnabled == false) {
      showAlertDialog(
        title: 'Bluetooth',
        content: 'Bluetooth nije uključen',
      );
      return;
    }

    bool isLocationGranted = await Permission.locationWhenInUse.isGranted;
    if (isLocationGranted == false) {
      var result = await Permission.locationWhenInUse.request();
      if (result.isGranted == false) {
        showAlertDialog(
          title: 'Lokacija',
          content: 'Lokacija nije dopuštena',
        );
        return;
      }
    }

    bool isLocationEnabled =
        await Permission.locationWhenInUse.serviceStatus.isEnabled;
    if (isLocationEnabled == false) {
      showAlertDialog(
        title: 'Lokacija',
        content: 'Lokacija nije uključena',
      );
      return;
    }

    setState(() {
      isDiscovering = true;
      devices.clear();
    });

    await FlutterBluePlus.startScan();

    var discoveryStream = FlutterBluePlus.onScanResults;
    discoverySubscription = discoveryStream.listen((List<ScanResult> results) {
      setState(() {
        devices.clear();
        devices.addAll(results.map((e) => e.device));
      });
    });
  }

  Future<void> stopDiscovery() async {
    await discoverySubscription?.cancel();
    await FlutterBluePlus.stopScan();
    setState(() {
      isDiscovering = false;
    });
  }

  void startOrStopDiscovery() {
    if (isDiscovering) {
      stopDiscovery();
    } else {
      startDiscovery();
    }
  }

  Future<void> openDevice(BluetoothDevice device) async {
    setState(() {
      isConnecting = true;
    });

    if (isDiscovering) {
      await stopDiscovery();
    }

    try {
      var myDevice = MyBleDevice(device);
      await myDevice.connect();

      setState(() {
        isConnecting = false;
        devices.clear();
      });

      if (!context.mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DevicePage(
            device: myDevice,
          ),
        ),
      );
    } on MyDeviceConnectException catch (exception) {
      setState(() {
        isConnecting = false;
      });

      showAlertDialog(title: 'Greška', content: exception.toString());
    }
  }

  void showAlertDialog({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (isConnecting) {
      body = buildConnectingWidget(context);
    } else {
      body = buildDiscoveryWidget(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pretraživanje uređaja'),
      ),
      body: body,
    );
  }

  Widget buildDiscoveryWidget(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            ListTile(
              title: Text('Dostupni uređaji',
                  style: Theme.of(context).textTheme.titleLarge),
              trailing:
                  isDiscovering ? const CircularProgressIndicator() : null,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  var device = devices[index];
                  var deviceName = device.platformName;
                  if (deviceName == "") deviceName = "Nepoznati uređaj";

                  return ListTile(
                    title: Text(deviceName),
                    subtitle: Text(device.remoteId.str),
                    leading: const Icon(Icons.devices),
                    onTap: () {
                      openDevice(device);
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                startOrStopDiscovery();
              },
              child: Text(isDiscovering
                  ? 'Zaustavi pretraživanje'
                  : 'Pretraži uređaje'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildConnectingWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox.square(
            dimension: 80,
            child: CircularProgressIndicator(
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Povezivanje',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    discoverySubscription?.cancel();
    adapterStateSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }
}
