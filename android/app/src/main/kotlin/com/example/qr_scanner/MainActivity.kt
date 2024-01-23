package com.example.qr_scanner

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.net.wifi.WifiConfiguration
import android.net.wifi.WifiManager
import android.provider.ContactsContract
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant


class MainActivity : FlutterActivity() {
    private val intentEmail = "INTENT_EMAIL"
    private val intentCall = "INTENT_CALL"
    private val intentAddContacts = "INTENT_ADD_CONTACTS"
    private val intentShare = "INTENT_SHARE"
    private val intentWifi = "INTENT_WIFI"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        val intentEmail = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, intentEmail)
        val intentCall = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, intentCall)
        val intentAddContacts =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, intentAddContacts)
        val intentShare = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, intentShare)
        val intentWifi = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, intentWifi)

        intentEmail.setMethodCallHandler { call, _ ->

            if (call.method == "EMAIL") {
                val emailMap = call.arguments as Map<*, *>
                val email = emailMap["email"] as String

                println("YashEmail" + email)
                // Replace this with your recipient email address
                val subject = "Your email subject"
                val body = "Your email body"

                val recipient = email
                val intent = Intent(Intent.ACTION_SEND).apply {
                    type = "message/rfc822" // MIME type for email
                    putExtra(Intent.EXTRA_EMAIL, arrayOf(recipient))
                    putExtra(Intent.EXTRA_SUBJECT, subject)
                    putExtra(Intent.EXTRA_TEXT, body)
                }
                startActivity(Intent.createChooser(intent, "Send Email"))

                /* Directly Open Gmail App */
                /*  val uri = Uri.parse("mailto:$email")
                      .buildUpon()
                      .appendQueryParameter("subject", subject)
                      .appendQueryParameter("body", body)
                      .build()

                  val emailIntent = Intent(Intent.ACTION_SENDTO, uri)
                  startActivity(Intent.createChooser(emailIntent, "Send Email"))*/
                /*val intent = Intent(Intent.ACTION_SEND)
                intent.setType("text/html")
                intent.putExtra(Intent., email)
                intent.putExtra(Intent.EXTRA_SUBJECT, "Subject")
                intent.putExtra(Intent.EXTRA_TEXT, "I'm email body.")
                startActivity(Intent.createChooser(intent, "Send Email"))*/
            }
        }

        intentCall.setMethodCallHandler { call, _ ->

            if (call.method == "CALL") {
                val emailMap = call.arguments as Map<*, *>
                val phone = emailMap["phone"] as String

                if (ContextCompat.checkSelfPermission(this,android.Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED) {
                    ActivityCompat.requestPermissions(this, arrayOf(android.Manifest.permission.CALL_PHONE),
                        200)

                } else {
                    val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$phone"))
                    startActivity(intent)
                }
            }
        }

        intentAddContacts.setMethodCallHandler { call, _ ->

            if (call.method == "ADD_CONTACTS") {
                val emailMap = call.arguments as Map<*, *>
                val phone = emailMap["phone"] as String
                val email = emailMap["email"] as String
                val name = emailMap["name"] as String

                println("YashContact" + email)

                val intent = Intent(Intent.ACTION_INSERT)
                intent.type = ContactsContract.Contacts.CONTENT_TYPE

                // You can add additional fields if needed
                intent.putExtra(ContactsContract.Intents.Insert.NAME, name)
                intent.putExtra(ContactsContract.Intents.Insert.PHONE, phone)
                intent.putExtra(ContactsContract.Intents.Insert.EMAIL, email)
                // Start the activity
                startActivity(intent)
            }
        }

        intentShare.setMethodCallHandler { call, _ ->
            if (call.method == "SHARE") {
                val emailMap = call.arguments as Map<*, *>
                val type = emailMap["type"] as String
                val shareIntent = Intent(Intent.ACTION_SEND)

                if (type == "Contact") {
                    val phone = emailMap["phone"] as String
                    val email = emailMap["email"] as String
                    val name = emailMap["name"] as String

                    shareIntent.type = "text/plain"
                    shareIntent.putExtra(Intent.EXTRA_SUBJECT, "Share QR Information") // Optional subject
                    shareIntent.putExtra(
                        Intent.EXTRA_TEXT, "Name: $name\n Number: $phone\nEmail: $email"
                    )
                } else if (type == "WIFI") {
                    val ssid = emailMap["ssid"] as String
                    val password = emailMap["password"] as String

                    shareIntent.type = "text/plain"
                    shareIntent.putExtra(Intent.EXTRA_SUBJECT, "Share WIFI Information") // Optional subject
                    shareIntent.putExtra(
                        Intent.EXTRA_TEXT, "SSID: $ssid\nPassword:$password"
                    )
                } else if (type == "URL") {
                    val url = emailMap["url"] as String

                    shareIntent.type = "text/plain"
                    shareIntent.putExtra(Intent.EXTRA_SUBJECT, "Share QR Information") // Optional subject
                    shareIntent.putExtra(
                        Intent.EXTRA_TEXT, "URL: $url"
                    )
                }

                startActivity(Intent.createChooser(shareIntent, "Share via"))
            }
        }

        intentWifi.setMethodCallHandler { call, result ->
            if (call.method.equals("connectToWiFi")) {
                val wifiMap = call.arguments as Map<*, *>
                val ssid: String = wifiMap["ssid"] as String
                val password: String = wifiMap["password"] as String
                println("password"+password)
                connectToWifi(ssid, password)
            } else {
                result.notImplemented()
            }
        }

    }

    fun connectToWifi(ssid: String, password: String) {
        val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as WifiManager

        // Check if Wi-Fi is enabled
        if (!wifiManager.isWifiEnabled) {
            wifiManager.isWifiEnabled = true
        }

        // Create a WifiConfiguration for the network
        val wifiConfig = WifiConfiguration()
        wifiConfig.SSID = "\"$ssid\""
        wifiConfig.preSharedKey = "\"$password\""

        // Add the network configuration and enable it
        val networkId = wifiManager.addNetwork(wifiConfig)
        if (networkId != -1) {
            // Disconnect from the current network (optional)
            wifiManager.disconnect()

            // Enable the network
            wifiManager.enableNetwork(networkId, true)

            // Reconnect to the selected network
            wifiManager.reconnect()
            Log.d("WifiConnector", "Connected to $ssid")
        } else {
            Log.e("WifiConnector", "Failed to add network configuration")
        }
    }
}