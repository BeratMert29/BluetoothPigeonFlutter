package com.example.untitled

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.example.untitled/ble_server"
    private val EVENT_CHANNEL = "com.example.untitled/ble_server_events"
    
    private var bleGattServer: BleGattServer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        bleGattServer = BleGattServer(this)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startServer" -> {
                    val success = bleGattServer?.startServer() ?: false
                    result.success(success)
                }
                "stopServer" -> {
                    bleGattServer?.stopServer()
                    result.success(true)
                }
                "startAdvertising" -> {
                    val success = bleGattServer?.startAdvertising() ?: false
                    result.success(success)
                }
                "stopAdvertising" -> {
                    bleGattServer?.stopAdvertising()
                    result.success(true)
                }
                "sendMessage" -> {
                    val message = call.argument<String>("message") ?: ""
                    val success = bleGattServer?.sendMessage(message) ?: false
                    result.success(success)
                }
                "isServerRunning" -> {
                    result.success(bleGattServer?.isServerRunning() ?: false)
                }
                else -> result.notImplemented()
            }
        }
        
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    bleGattServer?.setEventSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    bleGattServer?.setEventSink(null)
                }
            }
        )
    }

    override fun onDestroy() {
        bleGattServer?.stopServer()
        super.onDestroy()
    }
}
