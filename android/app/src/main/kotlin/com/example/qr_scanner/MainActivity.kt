package com.example.qr_scanner

import android.R.attr.name
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.content.pm.ResolveInfo
import android.net.Uri
import android.net.wifi.WifiConfiguration
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSpecifier
import android.os.Build
import android.os.PatternMatcher
import android.provider.CalendarContract
import android.provider.ContactsContract
import android.provider.Settings
import android.util.Log
import android.widget.Toast
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.text.SimpleDateFormat
import java.util.Locale


class MainActivity : FlutterActivity() {
    private val intentEmail = "INTENT_EMAIL"
    private val intentCall = "INTENT_CALL"
    private val intentAddContacts = "INTENT_ADD_CONTACTS"
    private val intentShare = "INTENT_SHARE"
    private val intentWifi = "INTENT_WIFI"
    private val intentAddEvent = "INTENT_ADD_EVENT"
    private val intentOpenMap = "INTENT_MAP"
    private val intentUPI = "INTENT_UPI"


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        val intentEmail = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, intentEmail)
        val intentCall = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, intentCall)
        val intentAddContacts =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, intentAddContacts)
        val intentShare = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, intentShare)
        val intentWifi = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, intentWifi)
        val intentAddEvent = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, intentAddEvent)
        val intentOpenMap = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, intentOpenMap)
        val intentUPI = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, intentUPI)

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

                when (type) {
                    "Contact" -> {
                        val phone = emailMap["phone"] as String
                        val email = emailMap["email"] as String
                        val name = emailMap["name"] as String

                        shareIntent.type = "text/plain"
                        shareIntent.putExtra(Intent.EXTRA_SUBJECT, "Share QR Information") // Optional subject
                        shareIntent.putExtra(
                            Intent.EXTRA_TEXT, "Name: $name\n Number: $phone\nEmail: $email"
                        )
                    }
                    "WIFI" -> {
                        val ssid = emailMap["ssid"] as String
                        val password = emailMap["password"] as String

                        shareIntent.type = "text/plain"
                        shareIntent.putExtra(Intent.EXTRA_SUBJECT, "Share WIFI Information") // Optional subject
                        shareIntent.putExtra(
                            Intent.EXTRA_TEXT, "SSID: $ssid\nPassword:$password"
                        )
                    }
                    "URL" -> {
                        val url = emailMap["url"] as String

                        shareIntent.type = "text/plain"
                        shareIntent.putExtra(Intent.EXTRA_SUBJECT, "Share URL") // Optional subject
                        shareIntent.putExtra(
                            Intent.EXTRA_TEXT, "URL: $url"
                        )
                    }
                    "Undefined" -> {
                        val text = emailMap["text"] as String

                        shareIntent.type = "text/plain"
                        shareIntent.putExtra(Intent.EXTRA_SUBJECT, "Share Information") // Optional subject
                        shareIntent.putExtra(
                            Intent.EXTRA_TEXT, "Text: $text"
                        )
                    }
                    "BarCode" -> {
                        val barcode = emailMap["barcode"] as String

                        shareIntent.type = "text/plain"
                        shareIntent.putExtra(Intent.EXTRA_SUBJECT, "Share Barcode") // Optional subject
                        shareIntent.putExtra(
                            Intent.EXTRA_TEXT, "Barcode: $barcode"
                        )
                    }
                    "Location" -> {
                        val lat = emailMap["lat"] as String
                        val long = emailMap["lng"] as String

                        shareIntent.type = "text/plain"
                        shareIntent.putExtra(Intent.EXTRA_SUBJECT, "Share Location") // Optional subject
                        shareIntent.putExtra(
                            Intent.EXTRA_TEXT, "Latitude: $lat Longitude: $long"
                        )
                    }
                    "Calendar" -> {
                        val summary = emailMap["summary"] as String
                        val sdate = emailMap["sdate"] as String
                        val edate = emailMap["edate"] as String
                        val loc = emailMap["location"] as String
                        val desc = emailMap["description"] as String
                        println(desc)
                        shareIntent.type = "text/plain"
                        shareIntent.putExtra(Intent.EXTRA_SUBJECT, "Share Event Details") // Optional subject
                        shareIntent.putExtra(
                            Intent.EXTRA_TEXT, "Summary: $summary\nStart Date:$sdate\n End Date: $edate\n Location:$loc\n Description: $desc"
                        )
                    }
                }

                startActivity(Intent.createChooser(shareIntent, "Share via"))
            }
        }

        intentWifi.setMethodCallHandler { call, result ->
            if (call.method.equals("WIFI")) {
                val wifiMap = call.arguments as Map<*, *>
                val ssid: String = wifiMap["ssid"] as String
                val password: String = wifiMap["password"] as String
                println("password"+password)
                //connectToWifi(ssid, password)
                openWifiSettings()
//                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
//                    //connectToWiFi(ssid, password)
//                    //openWifiSettings()
//                }
//                else {
//                    connectToWifi(ssid, password)
//                    openWifiSettings()
//                    //result.notImplemented()
//                    }
            }

        }

        intentOpenMap.setMethodCallHandler { call, _ ->
            if (call.method.equals("map")) {
                val mMap = call.arguments as Map<*, *>
                val lat: String = mMap["lat"] as String
                val lng: String = mMap["lng"] as String

                val geoUri = Uri.parse("geo:0,0?q=$lat,$lng")

                val mapIntent = Intent(Intent.ACTION_VIEW, geoUri)
                mapIntent.setPackage("com.google.android.apps.maps")

                // Check if Google Maps is installed
                if (mapIntent.resolveActivity(packageManager) != null) {
                    // Start the activity
                    startActivity(mapIntent)
                } else {
                    // If Google Maps is not installed, you can handle it accordingly
                    val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng"))
                    startActivity(browserIntent)
                }
            }
        }

        intentAddEvent.setMethodCallHandler { call, result ->
            if (call.method.equals("Calendar")) {
                val calendarMap = call.arguments as Map<*, *>
                val summary = calendarMap["summary"] as String
                val sdate = calendarMap["sdate"] as String
                val edate = calendarMap["edate"] as String
                val loc = calendarMap["location"] as String
                val desc = calendarMap["description"] as String

                val dateFormatStart = SimpleDateFormat("yyyyMMdd'T'HHmmss", Locale.getDefault())
                val customDateMillisStart = dateFormatStart.parse(sdate)?.time ?: System.currentTimeMillis()

                val dateFormatEnd = SimpleDateFormat("yyyyMMdd'T'HHmmss", Locale.getDefault())
                val customDateMillisEnd = dateFormatEnd.parse(edate)?.time ?: System.currentTimeMillis()

//                val duration: Long = customDateMillisEnd - customDateMillisStart
//                println("duration" + duration)
                val calendarIntent = Intent(Intent.ACTION_INSERT)
                    .setData(CalendarContract.Events.CONTENT_URI)
                    .putExtra(CalendarContract.Events.TITLE, summary)
                    .putExtra(CalendarContract.Events.EVENT_LOCATION, loc)
                    .putExtra(CalendarContract.Events.DESCRIPTION, desc)
                    .putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, customDateMillisStart)
                    .putExtra(CalendarContract.EXTRA_EVENT_END_TIME, customDateMillisEnd) // 1 hour
                startActivity(calendarIntent)
            } else {
                result.notImplemented()
            }
        }

        intentUPI.setMethodCallHandler { call, result ->
            if (call.method.equals("UPI")) {
                val upiMap = call.arguments as Map<*, *>
                val mURL = upiMap["url"] as String

                val payeeVPA = extractPayeeVPA(mURL)
                val payeeName = extractPayeeName(mURL)

                // will always show a dialog to user to choose an app
                val uri = Uri.parse("upi://pay").buildUpon()
                    .appendQueryParameter("pa", payeeVPA)
                    .appendQueryParameter("pn", payeeName)
//                    .appendQueryParameter("tn", note)
//                    .appendQueryParameter("am", amount)
                    //.appendQueryParameter("cu", "INR")
                    .build()

                val upiPayIntent = Intent(Intent.ACTION_VIEW)
                upiPayIntent.setData(uri)
                // will always show a dialog to user to choose an app
                val chooser = Intent.createChooser(upiPayIntent, "Pay with")

                // check if intent resolves
                if (null != chooser.resolveActivity(packageManager)) {
                    startActivityForResult(chooser, 200)
                } else {
                    Toast.makeText(
                        this,
                        "No UPI app found, please install one to continue",
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }
        }

    }

    fun connectToWifi(ssid: String, password: String) {
        println("reached here reached here")
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
        Log.e("networkId",networkId.toString())
        wifiManager.reconnect()
        if (networkId != -1) {


            // Disconnect from the current network (optional)
//            wifiManager.disconnect()
//
//            // Enable the network
//            wifiManager.enableNetwork(networkId, true)
//
//            // Reconnect to the selected network
//            wifiManager.reconnect()
//            Log.d("WifiConnector", "Connected to $ssid")
        } else {
            Log.e("WifiConnector", "Failed to add network configuration")
        }
    }



    @RequiresApi(Build.VERSION_CODES.Q)
    fun connectToWiFiA(ssid:String, pin: String ) {
        println("reachedAdiAdi")
        val connectivityManager =
            context.getSystemService(Context.CONNECTIVITY_SERVICE) as
                    ConnectivityManager
        val specifier = WifiNetworkSpecifier.Builder()
            .setSsid(ssid)
            .setWpa2Passphrase(pin)
            .setSsidPattern(PatternMatcher(ssid, PatternMatcher.PATTERN_PREFIX))
            .build()
        val request = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .removeCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .setNetworkSpecifier(specifier)
            .build()
        val networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                super.onAvailable(network)
                println("success network")
//                showToast(context,context.getString(R.string.connection_success))
            }

            override fun onUnavailable() {
                super.onUnavailable()
//                showToast(context,context.getString(R.string.connection_fail))
            }

            override fun onLost(network: Network) {
                super.onLost(network)
//                showToast(context,context.getString(R.string.out_of_range))
            }
        }
        connectivityManager.requestNetwork(request, networkCallback)
    }

    fun openWifiSettings() {
        println("wifiPageOpen")
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            Intent(WifiManager.ACTION_PICK_WIFI_NETWORK)
        } else {
            Intent(Settings.ACTION_WIFI_SETTINGS)
        }
        startActivity(intent)
    }
    fun extractPayeeVPA(upiUrl: String): String {
        val uri = Uri.parse(upiUrl)
        return uri.getQueryParameter("pa") ?: ""
    }

    fun extractPayeeName(upiUrl: String): String {
        val uri = Uri.parse(upiUrl)
        return uri.getQueryParameter("pn") ?: ""
    }
}