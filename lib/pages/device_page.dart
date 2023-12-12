import 'dart:async';

import 'package:flutter/material.dart';

import '../device/my_device.dart';

class DevicePage extends StatefulWidget {
  final MyDevice device;
  const DevicePage({super.key, required this.device});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  late MyDevice device;

  @override
  void initState() {
    super.initState();
    device = widget.device;

    device.setOnDisconnect(() => onDeviceDisconnect());
  }

  void onDeviceDisconnect() {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Izgubljena veza'),
          content: const Text('Veza s Bluetooth uređajem je izgubljena'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Moj uređaj"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: LedWidget(device: device),
                ),
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.topLeft,
                  child: AccelerometerWidget(device: device),
                ),
                const SizedBox(height: 80),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Zatvori uređaj'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    device.dispose();
  }
}

class LedWidget extends StatefulWidget {
  final MyDevice device;
  const LedWidget({super.key, required this.device});

  @override
  State<LedWidget> createState() => _LedWidgetState();
}

class _LedWidgetState extends State<LedWidget> {
  late MyDevice device;

  List<Color> ledColors = [];
  bool ledEnabled = false;
  int ledBrightness = 51;

  @override
  void initState() {
    super.initState();
    device = widget.device;

    device.setLedEnabled(ledEnabled);
    device.setBrightness(ledBrightness);
    device.showColor(Colors.black);

    ledColors.addAll([
      const Color.fromRGBO(255, 0, 0, 1),
      const Color.fromRGBO(255, 128, 0, 1),
      const Color.fromRGBO(255, 255, 0, 1),
      const Color.fromRGBO(128, 255, 0, 1),
      const Color.fromRGBO(0, 255, 0, 1),
      const Color.fromRGBO(0, 255, 255, 1),
      const Color.fromRGBO(0, 128, 255, 1),
      const Color.fromRGBO(0, 0, 255, 1),
      const Color.fromRGBO(128, 0, 255, 1),
      const Color.fromRGBO(255, 0, 255, 1),
      const Color.fromRGBO(255, 0, 128, 1),
      const Color.fromRGBO(255, 255, 255, 1),
    ]);
  }

  @override
  void didUpdateWidget(covariant LedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void setLedEnabled(bool value) {
    setState(() {
      ledEnabled = value;
      device.setLedEnabled(ledEnabled);
    });
  }

  void setLedBrightness(double value, bool finish) {
    setState(() {
      ledBrightness = value.floor();
      if (finish) {
        device.setBrightness(ledBrightness);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LEDica', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        SwitchListTile(
          value: ledEnabled,
          title: Text(ledEnabled ? 'LEDica uključena' : 'LEDica isključena'),
          onChanged: (value) => setLedEnabled(value),
        ),
        const SizedBox(height: 10),
        Text('Postavi boju', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 10),
        Center(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ledColors.map(_buildColorButton).toList(),
          ),
        ),
        const SizedBox(height: 20),
        Text('Jačina svjetla: ${(ledBrightness / 255 * 100).floor()} %',
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 10),
        Slider(
          value: ledBrightness.toDouble(),
          min: 0,
          max: 255,
          onChanged: (value) => setLedBrightness(value, false),
          onChangeEnd: (value) => setLedBrightness(value, true),
        ),
      ],
    );
  }

  Widget _buildColorButton(Color color) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black),
      ),
      child: ClipOval(
        child: Material(
          color: color,
          child: InkWell(
            onTap: () {
              device.showColor(color);
            },
          ),
        ),
      ),
    );
  }
}

class AccelerometerWidget extends StatefulWidget {
  final MyDevice device;
  const AccelerometerWidget({super.key, required this.device});

  @override
  State<AccelerometerWidget> createState() => _AccelerometerWidgetState();
}

class _AccelerometerWidgetState extends State<AccelerometerWidget> {
  late MyDevice device;
  late StreamSubscription<AccelerometerData> accelerometerDataSubscription;

  bool accelerometerEnabled = false;
  AccelerometerData accelerometerData = AccelerometerData.empty();

  @override
  void initState() {
    super.initState();
    device = widget.device;

    accelerometerDataSubscription =
        device.accelerometerDataStream.listen((data) {
      setState(() {
        accelerometerData = data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Akcelerometar', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        SwitchListTile(
          value: accelerometerEnabled,
          title: Text(accelerometerEnabled
              ? 'Akcelerometar uključen'
              : 'Akcelerometar isključen'),
          onChanged: (value) {
            setState(() {
              accelerometerEnabled = value;
              device.setAccelerometerEnabled(accelerometerEnabled);
            });
          },
        ),
        const SizedBox(height: 10),
        Text('Akceleracija', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 10),
        Text('X: ${accelerometerData.x.toStringAsFixed(2)} m/s\u00b2'),
        const SizedBox(height: 5),
        _buildAccelerationIndicator(accelerometerData.x),
        const SizedBox(height: 10),
        Text('Y: ${accelerometerData.y.toStringAsFixed(2)} m/s\u00b2'),
        const SizedBox(height: 5),
        _buildAccelerationIndicator(accelerometerData.y),
        const SizedBox(height: 10),
        Text('Z: ${accelerometerData.z.toStringAsFixed(2)} m/s\u00b2'),
        const SizedBox(height: 5),
        _buildAccelerationIndicator(accelerometerData.z),
      ],
    );
  }

  Widget _buildAccelerationIndicator(double value) {
    const double maxAcceleration = 20;

    bool negative = false;
    if (value < 0) {
      negative = true;
      value = -value;
    }

    if (value > maxAcceleration) {
      value = maxAcceleration;
    }

    return LinearProgressIndicator(
      value: value / maxAcceleration,
      color: negative ? Colors.blue : Colors.deepPurple,
    );
  }

  @override
  void dispose() {
    accelerometerDataSubscription.cancel();
    super.dispose();
  }
}
