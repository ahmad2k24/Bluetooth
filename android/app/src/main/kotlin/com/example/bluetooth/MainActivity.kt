package com.example.bluetoothapp

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.bluetooth"
    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
    private var bluetoothSocket: BluetoothSocket? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkBluetooth" -> result.success(checkBluetoothStatus())
                "startScan" -> result.success(scanForDevices())
                "connectToDevice" -> {
                    val address: String? = call.argument("address")
                    if (address != null) {
                        result.success(connectToDevice(address))
                    } else {
                        result.error("INVALID_ADDRESS", "Device address is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun checkBluetoothStatus(): String {
        return when {
            bluetoothAdapter == null -> "Bluetooth not supported"
            bluetoothAdapter.isEnabled -> "Bluetooth is ON"
            else -> "Bluetooth is OFF"
        }
    }

    private fun scanForDevices(): List<Map<String, String>> {
        val devicesList = mutableListOf<Map<String, String>>()
        val pairedDevices: Set<BluetoothDevice>? = bluetoothAdapter?.bondedDevices

        pairedDevices?.forEach { device ->
            val deviceName = device.name ?: "Unknown"
            val deviceAddress = device.address ?: "Unknown"
            devicesList.add(mapOf("name" to deviceName, "address" to deviceAddress))
        }
        return devicesList
    }

    private fun connectToDevice(address: String): String {
        return try {
            val device: BluetoothDevice = bluetoothAdapter!!.getRemoteDevice(address)
            bluetoothSocket = device.createRfcommSocketToServiceRecord(UUID.randomUUID())
            bluetoothSocket?.connect()
            "Connected to ${device.name}"
        } catch (e: IOException) {
            "Connection failed: ${e.message}"
        }
    }
}
