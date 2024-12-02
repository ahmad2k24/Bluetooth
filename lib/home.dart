import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  BluetoothScreenState createState() => BluetoothScreenState();
}

class BluetoothScreenState extends State<BluetoothScreen> {
  static const platform = MethodChannel('com.example.bluetooth');

  bool isBluetoothOn = false; // Tracks Bluetooth ON/OFF state
  List<Map<String, String>> _devices = []; // Holds the list of devices
  String _connectionStatus = "Not connected"; // Tracks connection status

  @override
  void initState() {
    super.initState();
    _getBluetoothStatus(); // Fetch initial Bluetooth status
  }

  Future<void> _getBluetoothStatus() async {
    try {
      final String result = await platform.invokeMethod('checkBluetooth');
      setState(() {
        isBluetoothOn = result == "Bluetooth is ON";
      });
    } catch (e) {
      print("Error fetching Bluetooth status: $e");
    }
  }

  Future<void> _toggleBluetooth(bool value) async {
    try {
      final String result = await platform.invokeMethod(
        value ? 'enableBluetooth' : 'disableBluetooth',
      );
      setState(() {
        isBluetoothOn = result == "Bluetooth is ON";
        if (isBluetoothOn) _startScan(); // Automatically start scanning if enabled
      });
    } catch (e) {
      print("Error toggling Bluetooth: $e");
    }
  }

  Future<void> _startScan() async {
    try {
      final List devices = await platform.invokeMethod('startScan');
      setState(() {
        _devices = List<Map<String, String>>.from(
          devices.map((device) => {
                'name': device['name'] ?? 'Unknown',
                'address': device['address'] ?? 'Unknown',
              }),
        );
      });
    } catch (e) {
      print("Error scanning for devices: $e");
    }
  }

  Future<void> _connectToDevice(String address) async {
    try {
      final String result = await platform.invokeMethod(
        'connectToDevice',
        {'address': address},
      );
      setState(() {
        _connectionStatus = result;
      });
    } catch (e) {
      print("Error connecting to device: $e");
      setState(() {
        _connectionStatus = "Connection failed";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bluetooth Connectivity"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Bluetooth", style: TextStyle(fontSize: 18)),
                Switch(
                  value: isBluetoothOn,
                  onChanged: _toggleBluetooth,
                ),
              ],
            ),
          ),
          const Divider(),
          Text("Connection Status: $_connectionStatus"),
          const Divider(),
          isBluetoothOn
              ? Expanded(
                  child: ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return ListTile(
                        title: Text(device['name'] ?? 'Unknown'),
                        subtitle: Text(device['address'] ?? 'Unknown'),
                        onTap: () {
                          _connectToDevice(device['address']!);
                        },
                      );
                    },
                  ),
                )
              : const Center(child: Text("Bluetooth is OFF. Please enable it.")),
        ],
      ),
    );
  }
}
