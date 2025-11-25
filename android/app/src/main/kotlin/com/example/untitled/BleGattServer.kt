package com.example.untitled

import android.bluetooth.*
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.os.Build
import android.os.ParcelUuid
import android.util.Log
import io.flutter.plugin.common.EventChannel
import java.util.*

class BleGattServer(private val context: Context) {
    companion object {
        private const val TAG = "BleGattServer"
        
        val SERVICE_UUID: UUID = UUID.fromString("12345678-1234-1234-1234-123456789abc")
        val CHAR_MESSAGE_UUID: UUID = UUID.fromString("abcdefab-1234-5678-1234-abcdefabcdef")
        val CCCD_UUID: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
    }

    private var bluetoothManager: BluetoothManager? = null
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var bluetoothLeAdvertiser: BluetoothLeAdvertiser? = null
    private var gattServer: BluetoothGattServer? = null
    private var messageCharacteristic: BluetoothGattCharacteristic? = null
    private var eventSink: EventChannel.EventSink? = null
    private val connectedDevices = mutableSetOf<BluetoothDevice>()
    private var isAdvertising = false
    private var serverRunning = false

    init {
        bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothAdapter = bluetoothManager?.adapter
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    fun isServerRunning(): Boolean = serverRunning

    fun startServer(): Boolean {
        if (serverRunning) {
            Log.d(TAG, "Server already running")
            return true
        }

        try {
            gattServer = bluetoothManager?.openGattServer(context, gattServerCallback)
            
            if (gattServer == null) {
                Log.e(TAG, "Failed to open GATT server")
                sendEvent("error", mapOf("message" to "Failed to open GATT server"))
                return false
            }

            // Create service
            val service = BluetoothGattService(SERVICE_UUID, BluetoothGattService.SERVICE_TYPE_PRIMARY)

            // Create message characteristic with read, write, and notify properties
            messageCharacteristic = BluetoothGattCharacteristic(
                CHAR_MESSAGE_UUID,
                BluetoothGattCharacteristic.PROPERTY_READ or
                        BluetoothGattCharacteristic.PROPERTY_WRITE or
                        BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE or
                        BluetoothGattCharacteristic.PROPERTY_NOTIFY,
                BluetoothGattCharacteristic.PERMISSION_READ or
                        BluetoothGattCharacteristic.PERMISSION_WRITE
            )

            // Add Client Characteristic Configuration Descriptor (CCCD) for notifications
            val cccd = BluetoothGattDescriptor(
                CCCD_UUID,
                BluetoothGattDescriptor.PERMISSION_READ or BluetoothGattDescriptor.PERMISSION_WRITE
            )
            messageCharacteristic?.addDescriptor(cccd)

            service.addCharacteristic(messageCharacteristic)

            val added = gattServer?.addService(service) ?: false
            if (!added) {
                Log.e(TAG, "Failed to add service")
                sendEvent("error", mapOf("message" to "Failed to add service"))
                return false
            }

            serverRunning = true
            Log.d(TAG, "GATT server started successfully")
            sendEvent("serverStarted", mapOf("success" to true))
            return true
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception: ${e.message}")
            sendEvent("error", mapOf("message" to "Permission denied: ${e.message}"))
            return false
        } catch (e: Exception) {
            Log.e(TAG, "Exception starting server: ${e.message}")
            sendEvent("error", mapOf("message" to "Error: ${e.message}"))
            return false
        }
    }

    fun stopServer() {
        try {
            stopAdvertising()
            gattServer?.close()
            gattServer = null
            serverRunning = false
            connectedDevices.clear()
            Log.d(TAG, "GATT server stopped")
            sendEvent("serverStopped", mapOf("success" to true))
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception stopping server: ${e.message}")
        }
    }

    fun startAdvertising(): Boolean {
        if (isAdvertising) {
            Log.d(TAG, "Already advertising")
            return true
        }

        try {
            bluetoothLeAdvertiser = bluetoothAdapter?.bluetoothLeAdvertiser
            
            if (bluetoothLeAdvertiser == null) {
                Log.e(TAG, "BLE Advertising not supported")
                sendEvent("error", mapOf("message" to "BLE Advertising not supported"))
                return false
            }

            val settings = AdvertiseSettings.Builder()
                .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
                .setConnectable(true)
                .setTimeout(0)
                .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
                .build()

            // Main advertising data - only service UUID (keeps under 31 byte limit)
            val data = AdvertiseData.Builder()
                .setIncludeDeviceName(false)
                .setIncludeTxPowerLevel(false)
                .addServiceUuid(ParcelUuid(SERVICE_UUID))
                .build()

            // Scan response - include device name here
            val scanResponse = AdvertiseData.Builder()
                .setIncludeDeviceName(true)
                .setIncludeTxPowerLevel(false)
                .build()

            bluetoothLeAdvertiser?.startAdvertising(settings, data, scanResponse, advertiseCallback)
            return true
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception: ${e.message}")
            sendEvent("error", mapOf("message" to "Permission denied: ${e.message}"))
            return false
        } catch (e: Exception) {
            Log.e(TAG, "Exception starting advertising: ${e.message}")
            sendEvent("error", mapOf("message" to "Error: ${e.message}"))
            return false
        }
    }

    fun stopAdvertising() {
        if (!isAdvertising) return
        
        try {
            bluetoothLeAdvertiser?.stopAdvertising(advertiseCallback)
            isAdvertising = false
            Log.d(TAG, "Advertising stopped")
            sendEvent("advertisingStopped", mapOf("success" to true))
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception stopping advertising: ${e.message}")
        }
    }

    fun sendMessage(message: String): Boolean {
        if (!serverRunning || connectedDevices.isEmpty()) {
            Log.e(TAG, "Cannot send message: server not running or no connected devices")
            return false
        }

        try {
            val bytes = message.toByteArray(Charsets.UTF_8)
            messageCharacteristic?.value = bytes

            var success = true
            for (device in connectedDevices) {
                val sent = gattServer?.notifyCharacteristicChanged(device, messageCharacteristic, false) ?: false
                if (!sent) {
                    Log.e(TAG, "Failed to notify device: ${device.address}")
                    success = false
                }
            }
            
            if (success) {
                Log.d(TAG, "Message sent to ${connectedDevices.size} device(s)")
            }
            return success
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception sending message: ${e.message}")
            return false
        } catch (e: Exception) {
            Log.e(TAG, "Exception sending message: ${e.message}")
            return false
        }
    }

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
            isAdvertising = true
            Log.d(TAG, "Advertising started successfully")
            sendEvent("advertisingStarted", mapOf("success" to true))
        }

        override fun onStartFailure(errorCode: Int) {
            isAdvertising = false
            val errorMsg = when (errorCode) {
                ADVERTISE_FAILED_DATA_TOO_LARGE -> "Data too large"
                ADVERTISE_FAILED_TOO_MANY_ADVERTISERS -> "Too many advertisers"
                ADVERTISE_FAILED_ALREADY_STARTED -> "Already started"
                ADVERTISE_FAILED_INTERNAL_ERROR -> "Internal error"
                ADVERTISE_FAILED_FEATURE_UNSUPPORTED -> "Feature unsupported"
                else -> "Unknown error: $errorCode"
            }
            Log.e(TAG, "Advertising failed: $errorMsg")
            sendEvent("error", mapOf("message" to "Advertising failed: $errorMsg"))
        }
    }

    private val gattServerCallback = object : BluetoothGattServerCallback() {
        override fun onConnectionStateChange(device: BluetoothDevice?, status: Int, newState: Int) {
            try {
                val deviceAddress = device?.address ?: "Unknown"
                
                when (newState) {
                    BluetoothProfile.STATE_CONNECTED -> {
                        device?.let { connectedDevices.add(it) }
                        Log.d(TAG, "Device connected: $deviceAddress")
                        sendEvent("deviceConnected", mapOf("address" to deviceAddress))
                    }
                    BluetoothProfile.STATE_DISCONNECTED -> {
                        device?.let { connectedDevices.remove(it) }
                        Log.d(TAG, "Device disconnected: $deviceAddress")
                        sendEvent("deviceDisconnected", mapOf("address" to deviceAddress))
                    }
                }
            } catch (e: SecurityException) {
                Log.e(TAG, "Security exception in onConnectionStateChange: ${e.message}")
            }
        }

        override fun onCharacteristicReadRequest(
            device: BluetoothDevice?,
            requestId: Int,
            offset: Int,
            characteristic: BluetoothGattCharacteristic?
        ) {
            try {
                if (characteristic?.uuid == CHAR_MESSAGE_UUID) {
                    val value = messageCharacteristic?.value ?: ByteArray(0)
                    gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, value)
                } else {
                    gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_FAILURE, offset, null)
                }
            } catch (e: SecurityException) {
                Log.e(TAG, "Security exception in read request: ${e.message}")
            }
        }

        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice?,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic?,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?
        ) {
            try {
                if (characteristic?.uuid == CHAR_MESSAGE_UUID) {
                    val message = value?.toString(Charsets.UTF_8) ?: ""
                    Log.d(TAG, "Received message: $message")
                    
                    val deviceAddress = device?.address ?: "Unknown"
                    sendEvent("messageReceived", mapOf(
                        "message" to message,
                        "from" to deviceAddress
                    ))

                    if (responseNeeded) {
                        gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, value)
                    }
                } else {
                    if (responseNeeded) {
                        gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_FAILURE, offset, null)
                    }
                }
            } catch (e: SecurityException) {
                Log.e(TAG, "Security exception in write request: ${e.message}")
            }
        }

        override fun onDescriptorWriteRequest(
            device: BluetoothDevice?,
            requestId: Int,
            descriptor: BluetoothGattDescriptor?,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?
        ) {
            try {
                if (descriptor?.uuid == CCCD_UUID) {
                    val enabled = value?.contentEquals(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE) == true
                    Log.d(TAG, "Notifications ${if (enabled) "enabled" else "disabled"} for device: ${device?.address}")
                    
                    if (responseNeeded) {
                        gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, value)
                    }
                    
                    sendEvent("notificationsChanged", mapOf(
                        "address" to (device?.address ?: "Unknown"),
                        "enabled" to enabled
                    ))
                } else {
                    if (responseNeeded) {
                        gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_FAILURE, offset, null)
                    }
                }
            } catch (e: SecurityException) {
                Log.e(TAG, "Security exception in descriptor write: ${e.message}")
            }
        }

        override fun onMtuChanged(device: BluetoothDevice?, mtu: Int) {
            Log.d(TAG, "MTU changed to $mtu for device: ${device?.address}")
            sendEvent("mtuChanged", mapOf(
                "address" to (device?.address ?: "Unknown"),
                "mtu" to mtu
            ))
        }
    }

    private fun sendEvent(type: String, data: Map<String, Any>) {
        val eventData = mutableMapOf<String, Any>("type" to type)
        eventData.putAll(data)
        
        // Run on main thread
        android.os.Handler(context.mainLooper).post {
            eventSink?.success(eventData)
        }
    }
}

