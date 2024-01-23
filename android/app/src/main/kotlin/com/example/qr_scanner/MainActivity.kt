package com.example.qr_scanner

import android.content.Intent
import android.net.Uri
import android.provider.ContactsContract
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant


class MainActivity : FlutterActivity() {
    private val intentEmail = "INTENT_EMAIL"
    private val intentCall = "INTENT_CALL"
    private val intentAddContacts = "INTENT_ADD_CONTACTS"
    private val intentShare = "INTENT_SHARE"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        val intentEmail = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, intentEmail)
        val intentCall = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, intentCall)
        val intentAddContacts =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, intentAddContacts)
        val intentShare = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, intentShare)

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

                val intent = Intent(Intent.ACTION_DIAL, Uri.parse(phone))
                if (intent.resolveActivity(packageManager) != null) {
                    startActivity(intent)
                } else {
                    // Handle the case where there's no app to handle the action
                    Toast.makeText(this, "No app to handle the action", Toast.LENGTH_SHORT).show()
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
                val phone = emailMap["phone"] as String
                val email = emailMap["email"] as String
                val name = emailMap["name"] as String

                val shareIntent = Intent(Intent.ACTION_SEND)
                shareIntent.type = "text/plain"
                shareIntent.putExtra(Intent.EXTRA_SUBJECT, "Share QR Information") // Optional subject
                shareIntent.putExtra(
                    Intent.EXTRA_TEXT, "Name: $name\n Number: $phone\nEmail: $email"
                )

                startActivity(Intent.createChooser(shareIntent, "Share via"))
            }
        }

    }
}
