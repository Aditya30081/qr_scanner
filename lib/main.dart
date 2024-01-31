import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';

import 'SharedPreferencesHelper.dart';
import 'package:wifi_iot/wifi_iot.dart';

late SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const MaterialApp(home: QRViewExample()));
}

class MyHome extends StatelessWidget {
  const MyHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Demo Home Page')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const QRViewExample(),
            ));
          },
          child: const Text('qrView'),
        ),
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  const QRViewExample({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> with SingleTickerProviderStateMixin {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool dialogOpen = false;
  List<Map<String, dynamic>> jsonDataList = [];
  bool historyItemTapped = false;
  bool wifiTimeStamp = false;
  bool vCardTimeStamp = false;
  bool urlTimeStamp = false;
  bool textTimeStamp = false;
  bool calendarTimeStamp = false;
  bool barCodeTimeStamp = false;
  bool geoTimeStamp = false;
  var channel = const MethodChannel("INTENT_EMAIL");
  var channelWifi = const MethodChannel("INTENT_WIFI");
  var channelPhone = const MethodChannel("INTENT_CALL");
  var channelContacts = const MethodChannel("INTENT_ADD_CONTACTS");
  var channelShare = const MethodChannel("INTENT_SHARE");
  var channelAddEvent = const MethodChannel("INTENT_ADD_EVENT");
  var channelMap = const MethodChannel("INTENT_MAP");
  var channelUPI = const MethodChannel("INTENT_UPI");
  late AnimationController _controller;
  late Animation<double> _animation;
  late AdManagerBannerAd bannerAd;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  Future<List<Map<String, dynamic>>> loadJsonDataList() async {
    prefs = await SharedPreferences.getInstance();
    final jsonStringList = prefs.getStringList('scanHistory') ?? [];
    jsonDataList = jsonStringList.map((jsonString) => Map<String, dynamic>.from(json.decode(jsonString))).toList();

    return jsonDataList;
  }
  Future<void> saveJsonDataList(List<Map<String, dynamic>> dataList) async {
    prefs = await SharedPreferences.getInstance();
    final jsonStringList = dataList.map((data) => json.encode(data)).toList();

    await prefs.setStringList('scanHistory', jsonStringList);
  }

  Future<void> addJsonDataToList(Map<String, dynamic> newData) async {
    print('scanHistory'+jsonDataList.toString());
    final updatedList = List<Map<String, dynamic>>.from(jsonDataList);

    updatedList.add(newData);

    setState(() {
      jsonDataList = updatedList;
    });

    await saveJsonDataList(updatedList);
  }
    @override
  void initState() {
    super.initState();
    loadAd();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _animation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.bounceOut, // Use any curve you prefer
      ),
    );

    _controller.repeat(reverse: true);
    loadJsonDataList();
  }

  void loadAd() {
    bannerAd = AdManagerBannerAd(
      adUnitId: '/21928950349/unibots_alarm_clock_320x100',
      request: const AdManagerAdRequest(),
      sizes: [AdSize.banner],
      listener: AdManagerBannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          setState(() {});
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (ad, err) {
          // Dispose the ad here to free resources.
          ad.dispose();
        },
        // Called when an ad opens an overlay that covers the screen.
        onAdOpened: (Ad ad) {},
        // Called when an ad removes an overlay that covers the screen.
        onAdClosed: (Ad ad) {},
        // Called when an impression occurs on the ad.
        onAdImpression: (Ad ad) {},
      ),
    )..load();
  }


  Future<void> vibrate() async {
    if (await Vibration.hasVibrator() != null && await Vibration.hasVibrator() == true) {
      // Check if the device has a vibrator
      Vibration.vibrate(duration: 100); // Vibrate for 200 milliseconds
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          _buildQrView(context),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin:const EdgeInsets.only(top: 50),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: const Column(
                children: [
                  Text('Looking for QR code',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white,fontSize: 20),),
                  Text('Place QR code inside the frame to scan',style: TextStyle(color: Colors.white),)
                ],
              ),
            ),
          ),
          Align(
            alignment:Alignment.bottomCenter,
            child:
            Container(
              alignment: Alignment.bottomCenter,
              height: 150,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(topLeft:Radius.circular(33),topRight: Radius.circular(33)),
                //color: Color(0x41205ac4)
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xb2ab37ee), // Starting color
                    Colors.transparent, // Ending color
                  ],
                ),
              ),
              child:Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton(

                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.transparent, // Background color
                            // padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Padding
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10), // Border radius
                            ),
                          ),
                          onPressed: () async {
                            await controller?.toggleFlash();
                            setState(() {});
                          },
                          child: FutureBuilder(
                            future: controller?.getFlashStatus(),
                            builder: (context, snapshot) {
                              return SvgPicture.asset(
                                'assets/flash.svg',
                                semanticsLabel: 'My SVG Image',
                                color: Colors.white,
                              );//Text('Flash: ${snapshot.data}',style: const TextStyle(color: Colors.white),);
                            },
                          )),
                      GestureDetector(
                        onVerticalDragEnd: (details) {
                          // Check if the swipe is upwards
                          if (details.primaryVelocity! < 0) {
                            // Show the bottom sheet
                            _showBottomSheet(context);
                          }
                        },
                        child: Column(
                          children: [
                            AnimatedBuilder(
                                animation: _animation,
                                builder: (context, child){
                                return Transform.translate(
                                  offset: Offset(0, -_animation.value),
                                  child: IconButton(
                                    onPressed: () {
                                      _showBottomSheet(context);
                                    },
                                    //(){_showBottomSheet(context);},
                                    icon: Icon(Icons.expand_less,color: Colors.white,size: 34,),),
                                );
                            }

                            ),
                            GestureDetector(
                                onTap: () {
                                  _showBottomSheet(context);
                                },
                                child: Text('Scan History',style: TextStyle(color: Colors.white),)),
                            GestureDetector(
                                onTap: () {
                                  _showBottomSheet(context);
                                },
                                child: Text('Swipe up',style: TextStyle(color: Colors.white,fontSize: 10),)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.transparent, // Background color
                            // padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Padding
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10), // Border radius
                            ),
                          ),
                          onPressed: () async {
                            await controller?.flipCamera();
                            setState(() {});
                          },
                          child: FutureBuilder(
                            future: controller?.getCameraInfo(),
                            builder: (context, snapshot) {
                              if (snapshot.data != null) {
                                return const Icon(Icons.cameraswitch,color: Colors.white,);
                                //Text('Camera facing ${describeEnum(snapshot.data!)}',style: const TextStyle(color: Colors.white),);
                              } else {
                                return const Text('loading');
                              }
                            },
                          )),
                    ],
                  ),
                  Spacer(),
                  SizedBox(
                      width: 320,
                      height: 50,
                      child: AdWidget(ad: bannerAd)
                  )
                ],
              ),

            ),
          ),


        ],
      ),
    );
  }




  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,

      //scrollControlDisabledMaxHeightRatio: 800,//MediaQuery.of(context).size.height * 3 / 4,

      builder: (BuildContext context) {

        return Container(
          color: Colors.white,
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height , // Set a minimum height (adjust as needed)
          ),
          child: NotificationListener<ScrollNotification>(
            onNotification: (scrollNotification) {
              double offsetThreshold = -2.0;
              if (scrollNotification is ScrollEndNotification) {
                if (scrollNotification.metrics.pixels ==
                    scrollNotification.metrics.minScrollExtent) {
                  Navigator.of(context).pop(); // Close the bottom sheet
                }
              }
              return false;
            },
            /*onNotification: (scrollNotification) {
              double offsetThreshold = -2.0;
              if (scrollNotification is ScrollEndNotification) {
                if (scrollNotification.metrics.pixels ==
                    scrollNotification.metrics.minScrollExtent) {
                  Navigator.of(context).pop(); // Close the bottom sheet
                }
              }
              return false;
            },*/
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 60,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.transparent, // Background color
                            // padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Padding
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10), // Border radius
                            ),
                          ),
                          onPressed: () async {
                            await controller?.toggleFlash();
                            setState(() {});
                          },
                          child: FutureBuilder(
                            future: controller?.getFlashStatus(),
                            builder: (context, snapshot) {
                              return SvgPicture.asset(
                                'assets/flash.svg',
                                semanticsLabel: 'My SVG Image',
                              );//Text('Flash: ${snapshot.data}',style: const TextStyle(color: Colors.white),);
                            },
                          )),
                      const Padding(
                        padding: EdgeInsets.only(right: 16.0),
                        child: Column(
                          children: [
                            Icon(Icons.expand_more),
                            Text('Scanning history',style: TextStyle(color: Colors.black,fontSize: 20),),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: (){
                          _showSettingsDialog();
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SvgPicture.asset(
                            'assets/settings.svg',
                            semanticsLabel: 'My SVG Image',
                          ),
                        ),
                      ),
                    ],
                  ),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: loadJsonDataList(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        List<Map<String, dynamic>> loadedList = snapshot.data as List<Map<String, dynamic>> ?? [];
                        return loadedList.isNotEmpty ?
                          Column(
                          children: [
                            for (Map<String, dynamic> item in loadedList)
                              GestureDetector(
                                  onTap:(){
                                    setState(() {
                                      historyItemTapped = true;
                                    });
                                    print(item);
                                    _showHistoryDialog(context, item, item['type']);
                                    /*showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return item['type'] == 'URL'?
                                        AlertDialog(
                                          //backgroundColor: Colors.white,
                                          content:
                                          Container(
                                            color: Colors.white,
                                            height: MediaQuery.of(context).size.height*3/4,
                                            width: MediaQuery.of(context).size.width*3/4,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex:1,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      const Text('Url'),
                                                      Text(DateTime.now().toString()),
                                                    ],
                                                  ),
                                                ),
                                                const Expanded(
                                                    flex: 1,
                                                    child: Text('Url Name')),
                                                const Expanded(
                                                    flex:3,
                                                    child: Text('jdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisl,jdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisl')),
                                                Expanded(
                                                  flex: 3,
                                                  child: SizedBox(
                                                    height: (MediaQuery.of(context).size.height * 3/4)/3,
                                                  ),
                                                ),
                                                const Expanded(
                                                  flex: 1,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                    children: [
                                                      ElevatedButton(onPressed:null, child: Text('Open')),
                                                      ElevatedButton(onPressed:null, child: Text('Copy')),
                                                    ],
                                                  ),
                                                ),
                                                const Flexible(
                                                    flex: 1,
                                                    child: ElevatedButton(onPressed:null, child: Text('Share')))
                                              ],
                                            ),
                                          ),
                                          // actions: [
                                          //   TextButton(
                                          //     onPressed: () {
                                          //       //_launchURL(url);
                                          //
                                          //     },
                                          //     child: const Text('Visit Url'),
                                          //   ),
                                          //   TextButton(
                                          //     onPressed: () {
                                          //       setState(() {
                                          //         dialogOpen = false;
                                          //       });
                                          //       Navigator.of(context).pop();// Close the dialog
                                          //     },
                                          //     child: const Text('Close'),
                                          //   ),
                                          // ],
                                        ):
                                        item['type'] == 'WIFI' ?
                                        AlertDialog(
                                          //backgroundColor: Colors.white,
                                          content:
                                          Container(
                                            color: Colors.white,
                                            height: MediaQuery.of(context).size.height*3/4,
                                            width: MediaQuery.of(context).size.width*3/4,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex:1,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      const Text('Wifi'),
                                                      Text(DateTime.now().toString()),
                                                    ],
                                                  ),
                                                ),
                                                const Expanded(
                                                    flex: 3,
                                                    child: Row(
                                                      children: [
                                                        Column(
                                                          crossAxisAlignment: CrossAxisAlignment.end,
                                                          children: [
                                                            Text('SSID'),
                                                            Text('Password'),
                                                          ],
                                                        ),
                                                        Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text('Aditya'),
                                                            Text('Adityanand'),
                                                          ],
                                                        ),
                                                      ],
                                                    )),
                                                Expanded(
                                                  flex: 3,
                                                  child: SizedBox(
                                                    height: (MediaQuery.of(context).size.height * 3/4)/3,
                                                  ),
                                                ),
                                                const Expanded(
                                                  flex: 1,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                    children: [
                                                      ElevatedButton(onPressed:null, child: Text('Connect')),
                                                      ElevatedButton(onPressed:null, child: Text('Copy')),
                                                    ],
                                                  ),
                                                ),
                                                const Flexible(
                                                    flex: 1,
                                                    child: Align(
                                                        alignment: Alignment.center,
                                                        child: ElevatedButton(onPressed:null, child: Text('Share'))))
                                              ],
                                            ),
                                          ),
                                          // actions: [
                                          //   TextButton(
                                          //     onPressed: () {
                                          //       //_launchURL(url);
                                          //
                                          //     },
                                          //     child: const Text('Visit Url'),
                                          //   ),
                                          //   TextButton(
                                          //     onPressed: () {
                                          //       setState(() {
                                          //         dialogOpen = false;
                                          //       });
                                          //       Navigator.of(context).pop();// Close the dialog
                                          //     },
                                          //     child: const Text('Close'),
                                          //   ),
                                          // ],
                                        ) :
                                        item['type'] == 'Text' ?
                                        AlertDialog(
                                          //backgroundColor: Colors.white,
                                          content:
                                          Container(
                                            color: Colors.white,
                                            height: MediaQuery.of(context).size.height*3/4,
                                            width: MediaQuery.of(context).size.width*3/4,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex:1,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      const Text('Text'),
                                                      Text(DateTime.now().toString()),
                                                    ],
                                                  ),
                                                ),
                                                const Expanded(
                                                    flex:3,
                                                    child: Text('jdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisl,jdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisl')),
                                                Expanded(
                                                  flex: 3,
                                                  child: SizedBox(
                                                    height: (MediaQuery.of(context).size.height * 3/4)/3,
                                                  ),
                                                ),
                                                const Expanded(
                                                  flex: 1,
                                                  child: ElevatedButton(onPressed:null, child: Text('Copy')),
                                                ),
                                                const Flexible(
                                                    flex: 1,
                                                    child: ElevatedButton(onPressed:null, child: Text('Share')))
                                              ],
                                            ),
                                          ),
                                          // actions: [
                                          //   TextButton(
                                          //     onPressed: () {
                                          //       //_launchURL(url);
                                          //
                                          //     },
                                          //     child: const Text('Visit Url'),
                                          //   ),
                                          //   TextButton(
                                          //     onPressed: () {
                                          //       setState(() {
                                          //         dialogOpen = false;
                                          //       });
                                          //       Navigator.of(context).pop();// Close the dialog
                                          //     },
                                          //     child: const Text('Close'),
                                          //   ),
                                          // ],
                                        ) :
                                        item['type'] == 'Geo' ?
                                        AlertDialog(
                                          //backgroundColor: Colors.white,
                                          content:
                                          Container(
                                            color: Colors.white,
                                            height: MediaQuery.of(context).size.height*3/4,
                                            width: MediaQuery.of(context).size.width*3/4,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex:1,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      const Text('Geo'),
                                                      Text(DateTime.now().toString()),
                                                    ],
                                                  ),
                                                ),
                                                const Expanded(
                                                    flex:3,
                                                    child: Text('jdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisl,jdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisl')),
                                                Expanded(
                                                  flex: 3,
                                                  child: SizedBox(
                                                    height: (MediaQuery.of(context).size.height * 3/4)/3,
                                                  ),
                                                ),
                                                const Expanded(
                                                  flex: 1,
                                                  child: Row(
                                                    children: [
                                                      ElevatedButton(onPressed:null, child: Text('Maps')),
                                                      ElevatedButton(onPressed:null, child: Text('Copy')),
                                                    ],
                                                  ),
                                                ),
                                                const Flexible(
                                                    flex: 1,
                                                    child: ElevatedButton(onPressed:null, child: Text('Share')))
                                              ],
                                            ),
                                          ),
                                          // actions: [
                                          //   TextButton(
                                          //     onPressed: () {
                                          //       //_launchURL(url);
                                          //
                                          //     },
                                          //     child: const Text('Visit Url'),
                                          //   ),
                                          //   TextButton(
                                          //     onPressed: () {
                                          //       setState(() {
                                          //         dialogOpen = false;
                                          //       });
                                          //       Navigator.of(context).pop();// Close the dialog
                                          //     },
                                          //     child: const Text('Close'),
                                          //   ),
                                          // ],
                                        ) :
                                        item['type'] == 'BarCode' ?
                                        AlertDialog(
                                          //backgroundColor: Colors.white,
                                          content:
                                          Container(
                                            color: Colors.white,
                                            height: MediaQuery.of(context).size.height*3/4,
                                            width: MediaQuery.of(context).size.width*3/4,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex:1,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      const Text('Barcode'),
                                                      Text(DateTime.now().toString()),
                                                    ],
                                                  ),
                                                ),
                                                const Expanded(
                                                    flex:3,
                                                    child: Text('jdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisl,jdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisl')),
                                                Expanded(
                                                  flex: 3,
                                                  child: SizedBox(
                                                    height: (MediaQuery.of(context).size.height * 3/4)/3,
                                                  ),
                                                ),
                                                const Expanded(
                                                  flex: 1,
                                                  child: ElevatedButton(onPressed:null, child: Text('Copy')),
                                                ),
                                                const Flexible(
                                                    flex: 1,
                                                    child: ElevatedButton(onPressed:null, child: Text('Share')))
                                              ],
                                            ),
                                          ),
                                          // actions: [
                                          //   TextButton(
                                          //     onPressed: () {
                                          //       //_launchURL(url);
                                          //
                                          //     },
                                          //     child: const Text('Visit Url'),
                                          //   ),
                                          //   TextButton(
                                          //     onPressed: () {
                                          //       setState(() {
                                          //         dialogOpen = false;
                                          //       });
                                          //       Navigator.of(context).pop();// Close the dialog
                                          //     },
                                          //     child: const Text('Close'),
                                          //   ),
                                          // ],
                                        ) :
                                        item['type'] == 'Calendar' ?
                                        AlertDialog(
                                          //backgroundColor: Colors.white,
                                          content:
                                          Container(
                                            color: Colors.white,
                                            height: MediaQuery.of(context).size.height*3/4,
                                            width: MediaQuery.of(context).size.width*3/4,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex:1,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      const Text('Calendar'),
                                                      Text(DateTime.now().toString()),
                                                    ],
                                                  ),
                                                ),
                                                const Expanded(
                                                    flex:5,
                                                    child: Row(
                                                      children: [
                                                        Column(
                                                          crossAxisAlignment: CrossAxisAlignment.end,
                                                          children: [
                                                            Text('Event Name'),
                                                            Text('Event Date'),
                                                            Text('Event Derails'),
                                                          ],
                                                        ),
                                                        Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(''),
                                                            Text(''),
                                                            Text(''),
                                                          ],
                                                        ),

                                                      ],
                                                    )),

                                                const Expanded(
                                                  flex: 1,
                                                  child: Row(
                                                    children: [
                                                      ElevatedButton(onPressed:null, child: Text('Calendar')),
                                                      ElevatedButton(onPressed:null, child: Text('Copy')),
                                                    ],
                                                  ),
                                                ),
                                                const Flexible(
                                                    flex: 1,
                                                    child: ElevatedButton(onPressed:null, child: Text('Share')))
                                              ],
                                            ),
                                          ),
                                          // actions: [
                                          //   TextButton(
                                          //     onPressed: () {
                                          //       //_launchURL(url);
                                          //
                                          //     },
                                          //     child: const Text('Visit Url'),
                                          //   ),
                                          //   TextButton(
                                          //     onPressed: () {
                                          //       setState(() {
                                          //         dialogOpen = false;
                                          //       });
                                          //       Navigator.of(context).pop();// Close the dialog
                                          //     },
                                          //     child: const Text('Close'),
                                          //   ),
                                          // ],
                                        ) :
                                        AlertDialog(
                                          title: const Text('Dialog Title'),
                                          content: Text(item.toString()),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                //_launchURL(url);

                                              },
                                              child: const Text('Visit Url'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  dialogOpen = false;
                                                });
                                                Navigator.of(context).pop();// Close the dialog
                                              },
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        );
                                      },
                                    );*/
                                  },
                                  child: Container(
                                      height: 80,
                                      width: double.infinity,
                                      decoration:const BoxDecoration(
                                        color: Color(0xffF4F4F4),
                                        borderRadius: BorderRadius.all(Radius.circular(8))
                                      ),
                                      margin: const EdgeInsets.all(10),
                                      child: Row(

                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            //mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                              Container(
                                                  margin: const EdgeInsets.only(left: 8,right: 8),
                                                  color: Colors.white,
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(8.0),
                                                    child: Icon(Icons.qr_code,size: 30,),
                                                  )),
                                              Padding(
                                                padding: const EdgeInsets.only(top:16,left: 5),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    item['type']=='WIFI'?Text(item['ssid']?? ''):
                                                    item['type']=='Calendar' ? Text(item['summary']??'') :
                                                    item['type']=='Location'? Text('${item['latitude']??''} , ${item['longitude']?? ''}') :
                                                    item['type']=='BarCode'? Text(item['BarCodeData']):
                                                    item['type']=='URL'? Text(item['Web Url']):
                                                    item['type']=='Undefined'? const Text('unknown') :const Text('hi'),
                                                    Padding(
                                                      padding: const EdgeInsets.only(top:8.0),
                                                      child: Text(item['type'] ?? 'Text',overflow:TextOverflow.ellipsis,),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(formatDateTime(DateTime.parse(item['scannedTime'])),),
                                          )
                                        ],
                                      ))),
                          ],
                        ) : const Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(height: 300,),
                            Text('No History', style: TextStyle(fontSize: 20, color: Colors.black),),
                          ],
                        );
                      }
                    },
                  )

                ],
              ),
            ),
          ),
        );
      },
    );
  }







  // Widget _buildTransparentOverlayBottomSheet() {
  //   return Positioned(
  //     bottom: 0,
  //     left: 0,
  //     right: 0,
  //     child: Container(
  //       color: const Color(0xff21212114),
  //       child: Padding(
  //         padding: const EdgeInsets.all(16.0),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.stretch,
  //           children: [
  //             const Text(
  //               'Overlay Bottom Sheet Content',
  //               style: TextStyle(color: Colors.white),
  //             ),
  //             ElevatedButton(
  //               onPressed: () {
  //                 // Handle button click inside the bottom sheet
  //               },
  //               child: const Text('Click Me'),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? 200.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.pink,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      setState(() {
        result = scanData;
      });
      //_showDialog(context,scanData.code!);
      if(!dialogOpen) {
        if (await SharedPreferencesHelper().getVibrateData() == true) {
          vibrate();
        }
        setState(() {
          dialogOpen = true;
        });

        String type = '';
        if(scanData.code!.contains('VCARD')){
          type = 'VCARD';
        }
        else if(scanData.code!.startsWith('https://')){
          type = 'WebUrl';
        }
        else if(scanData.code!.startsWith('WIFI')){
          type = 'WIFI';
        }
        else if(scanData.code!.contains('BEGIN:VEVENT')){
          type = 'Calendar';
        }
        else if(scanData.code!.startsWith('geo:')){
          type = 'Location';
        }
        else if(scanData.format.toString() =='BarcodeFormat.ean13'){
          type = 'BarCode';
        } else if(scanData.code.toString().startsWith('upi://pay')) {
          type = 'upi';
        }
        else{
          type = 'Undefined';
        }
        _showDialog(context,scanData.code!,type);



      }
      print("aditya${scanData.code!} type ${scanData.format}");
    });
  }
  // String vcardString =
  //     "BEGIN:VCARD\nVERSION:3.0\nN:raheja;adityanand \nFN:adityanand  raheja\nTEL;CELL:8766257408\nEMAIL;WORK;INTERNET:adityanand.raheja@unibots.com\nEND:VCARD";

  Map<String, dynamic> vCardToJSON(String vCardData) {
    // Split vCard data into lines
    List<String> lines = vCardData.split('\n');

    // Initialize an empty JSON object
    Map<String, dynamic> jsonResult = {};

    // Iterate through each line in vCard
    for (String line in lines) {
      // Split each line into key and value
      List<String> parts = line.split(':');

      if (parts.length == 2) {
        String key = parts[0].trim();
        String value = parts[1].trim();
        print("jsonResult" + jsonResult.toString());
        // Handle specific cases, you may need to customize this based on your needs
        if (key == 'N') {
          // Split the name into parts
          List<String> nameParts = value.split(';');
          jsonResult['firstName'] = nameParts[1].trim();
          jsonResult['lastName'] = nameParts[0].trim();
        }
        else if (key.contains('TEL')){
          jsonResult['TEL'] = value;
        } else if (key.contains('EMAIL')){
          jsonResult['EMAIL'] = value;
        } else if (key.contains('FN')){
          jsonResult['FN'] = value;
        }
        else {
          // Store other fields directly
          jsonResult[key] = value;
        }
      }
    }
    jsonResult['type']='Contact';
    if(!vCardTimeStamp){
      setState(() {
        vCardTimeStamp = true;
      });
      jsonResult['scannedTime'] = DateTime.now().toString();
    }
    print(jsonResult);

    return jsonResult;
  }

  Map<String, dynamic> geoUriToJson(String geoUri) {
    Map<String, dynamic> jsonResult = {};

    if (geoUri.startsWith("geo:")) {
      // Remove the "geo:" prefix
      geoUri = geoUri.substring(4);

      // Split the remaining string into latitude, longitude, and query parameters
      List<String> parts = geoUri.split("?");

      // Extract latitude and longitude
      List<String> latLng = parts[0].split(",");
      if (latLng.length == 2) {
        jsonResult['latitude'] = double.tryParse(latLng[0]);
        jsonResult['longitude'] = double.tryParse(latLng[1]);
      }

      // Parse query parameters if available
      if (parts.length == 2) {
        Map<String, dynamic> queryParams = {};
        List<String> queryParts = parts[1].split("&");

        for (String queryPart in queryParts) {
          List<String> keyValue = queryPart.split("=");
          if (keyValue.length == 2) {
            queryParams[keyValue[0]] = keyValue[1];
          }
        }
        jsonResult['type']='Location';
        if(!geoTimeStamp){
          setState(() {
            geoTimeStamp = true;
          });
          jsonResult['scannedTime'] = DateTime.now().toString();
        }
        jsonResult['queryParams'] = queryParams;
      }
    }
    print('jsonResult1'+jsonResult.toString());

    return jsonResult;
  }

  Map<String, dynamic> wifiToJSON(String wifiData) {
    // Remove the prefix "WIFI:"
    wifiData = wifiData.substring(5);

    // Split wifiData into key-value pairs
    List<String> pairs = wifiData.split(';');

    // Initialize an empty JSON object
    Map<String, dynamic> jsonResult = {};

    // Iterate through each key-value pair
    for (String pair in pairs) {
      // Split each pair into key and value
      List<String> keyValue = pair.split(':');

      if (keyValue.length == 2) {
        String key = keyValue[0].trim();
        String value = keyValue[1].trim();

        // Handle specific cases, you may need to customize this based on your needs
        if (key == 'S') {
          jsonResult['ssid'] = value;
        } else if (key == 'P') {
          jsonResult['password'] = value;
        } else if (key == 'H') {
          jsonResult['hidden'] = value == 'true';
        } else {
          // Store other fields directly
          jsonResult[key] = value;
        }
      }
    }
    jsonResult['type'] = 'WIFI';
    if(!wifiTimeStamp){
      setState(() {
        wifiTimeStamp = true;
      });
      jsonResult['scannedTime'] = DateTime.now().toString();
    }
    return jsonResult;
  }

  Map<String, dynamic> eventToJson(String vevent) {
    // Remove the prefix "BEGIN:VEVENT" and "END:VEVENT"
    vevent = vevent.replaceAll('BEGIN:VEVENT', '').replaceAll('END:VEVENT', '').trim();

    // Split vevent into lines
    List<String> lines = vevent.split('\n');

    // Initialize an empty JSON object
    Map<String, dynamic> jsonResult = {};

    // Iterate through each line
    for (String line in lines) {
      // Split each line into key and value
      List<String> keyValue = line.split(':');

      if (keyValue.length == 2) {
        String key = keyValue[0].trim();
        String value = keyValue[1].trim();

        // Handle specific cases, customize this based on your needs
        if (key.contains('SUMMARY')) {
          jsonResult['summary'] = value;
        } else if (key.contains('LOCATION')) {
          jsonResult['location'] = value;
        } else if (key.contains('DTSTART')) {
          jsonResult['startDate'] = value;
        } else if (key.contains('DTEND')) {
          jsonResult['endDate'] = value;
        } else if (key.contains('DESCRIPTION')) {
          jsonResult['description'] = value;
        } else {
          // Store other fields directly
          jsonResult[key.toLowerCase()] = value;
        }
      }
    }

    // Add a type field
    jsonResult['type'] = 'Calendar';
    if(!calendarTimeStamp){
      setState(() {
        calendarTimeStamp = true;
      });
      jsonResult['scannedTime'] = DateTime.now().toString();
    }

    return jsonResult;
  }

  String formatDateTime(DateTime dateTime) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(const Duration(days: 1));
    DateTime yesterday = today.subtract(const Duration(days: 1));

    if (dateTime.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (dateTime.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow';
    } else if (dateTime.isAtSameMomentAs(yesterday)) {
      return 'Yesterday';
    } else {
      // Format the date as 'MM/dd/yyyy'
      return DateFormat('MM/dd/yyyy').format(dateTime);
    }
  }
  //
  // void connectToWiFi(String ssid, String password) async {
  //   try {
  //     // Check if the device is already connected to a Wi-Fi network
  //     bool isConnected = await WiFiForIoTPlugin.isConnected();
  //
  //     if (!isConnected) {
  //       // Disconnect from the current network if connected
  //       await WiFiForIoTPlugin.disconnect();
  //
  //       // Connect to the new Wi-Fi network
  //       WiFiForIoTPlugin.connect(ssid, password, security: NetworkSecurity.WPA, onConnectionChanged: (bool isConnected) {
  //         if (isConnected) {
  //           print("Connected to $ssid");
  //         } else {
  //           print("Failed to connect to $ssid");
  //         }
  //       });
  //     } else {
  //       print("Already connected to a Wi-Fi network");
  //     }
  //   } catch (e) {
  //     print("Error: $e");
  //   }
  // }
  void connectToWiFi(String ssid, String password) async {
    try {
      // Check if the device is already connected to a Wi-Fi network
      bool isConnected = await WiFiForIoTPlugin.isConnected();
      isConnected = false;
      if (!isConnected) {
        // Disconnect from the current network if connected
        await WiFiForIoTPlugin.disconnect();

        // Connect to the new Wi-Fi network
        await WiFiForIoTPlugin.connect(ssid, security: NetworkSecurity.WPA, password: password ,withInternet: true);

        // Wait for the connection to be established
        await Future.delayed(const Duration(seconds: 5));

        // Check the connection status again
        isConnected = await WiFiForIoTPlugin.isConnected();

        if (isConnected) {
          print("Connected to $ssid");
        } else {
          print("Failed to connect to $ssid");
        }
      } else {
        print("Already connected to a Wi-Fi network");
      }

      print("Is connected to Wi-Fi: $isConnected");
    } catch (e) {
      print("Error: $e");
    }
  }

  void _showDialog(BuildContext context,String url,String type) async {


    print('url'+url);
    Map<String, dynamic> jsonResult;
    if(type == 'VCARD'){
      jsonResult= vCardToJSON(url);

      // print("jsonResult$jsonResult");
      // print("jsonResult${jsonResult["lastName"]}");
    }
    else if( type == 'WebUrl'){
      jsonResult = {'Web Url': url,'type':'URL'};
      if(!urlTimeStamp){
        setState(() {
          urlTimeStamp = true;
        });
        jsonResult['scannedTime'] = DateTime.now().toString();
      }
    }
    else if( type == 'WIFI'){
      jsonResult = wifiToJSON(url);
    }
    else if( type == 'Calendar'){
      jsonResult = eventToJson(url);
    }
    else if( type == 'Location'){
      jsonResult = geoUriToJson(url);
    }
    else if( type == 'BarCode'){
      jsonResult = {'BarCodeData': url,'type':'BarCode'};
      if(!barCodeTimeStamp){
        setState(() {
          barCodeTimeStamp = true;
        });
        jsonResult['scannedTime'] = DateTime.now().toString();
      }
    }
    else if (type == 'upi') {
      jsonResult = {'URL': url,'type':'upi'};
      jsonResult['scannedTime'] = DateTime.now().toString();
      openPaymentURL(jsonResult['URL']);
    }
    else {
      jsonResult = {'Blank': url , 'type': 'Undefined'};//,'scannedTime':DateTime.now().toString()};
      if(!textTimeStamp){
        setState(() {
          textTimeStamp = true;
        });
        jsonResult['scannedTime'] = DateTime.now().toString();
      }
    }
    print("TYPE: $type");
    print('jsonResult'+jsonResult.toString());


    showDialog(
      barrierDismissible: false,
      context: context,
      builder:(BuildContext context) {
        return jsonResult['type'] == 'URL'?
        AlertDialog(
          //backgroundColor: Colors.white,
          content:
          WillPopScope(
            onWillPop: () async {
              // Return false to prevent the dialog from closing
              return false;
            },
            child: Container(
              height: MediaQuery.of(context).size.height*3/4,
              width: MediaQuery.of(context).size.width*3/4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex:1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                      Expanded(
                        child: Container(
                            child: const Center(
                                child: Text('Url',style: TextStyle(fontSize: 24),))),
                      ),
                        GestureDetector(
                            onTap: () {
                              setState(() {
                                dialogOpen = false;
                                urlTimeStamp = false;
                                historyItemTapped = false;
                              });
                              Navigator.of(context).pop();
                            },
                            child: historyItemTapped ? Text(formatDateTime(DateTime.parse(jsonResult['scannedTime']))) : const Icon(Icons.close)
                        ),
                      ],
                    ),
                  ),
                  const Expanded(
                      flex: 1,
                      child: Text('Url Name')),
                  Expanded(
                      flex:3,
                      child: Text(jsonResult['Web Url'] ?? "")),
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: (MediaQuery.of(context).size.height * 3/4)/3,
                    ),
                  ),
                  Visibility(
                    visible: jsonResult['Web Url'] != null && jsonResult['Web Url'] != "",
                    child: Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xff1976D2),
                              borderRadius: BorderRadius.circular(8.0), // Set border radius for a rectangular shape
                            ),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0, // Set elevation to 0 to remove it
                                  backgroundColor: Colors.transparent
                                ),
                                onPressed:() {
                            _launchURL(jsonResult['Web Url']);
                            }, child: const Text('Open',style: TextStyle(color: Colors.white))),
                          ),
                        ),
                        const SizedBox(width: 10,),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color:  const Color(0xff71717A),
                              borderRadius: BorderRadius.circular(8.0), // Set border radius for a rectangular shape
                            ),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0, // Set elevation to 0 to remove it
                                  backgroundColor: Colors.transparent
                                ),
                                onPressed:() {
                            copyToClipboard(jsonResult['Web Url']);
                            }, child: const Text('Copy',style: TextStyle(color: Colors.white),)),
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: jsonResult['Web Url'] != null && jsonResult['Web Url'] != "",
                    child: Flexible(
                        flex: 1,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0), // Set border radius for a rectangular shape
                          border: Border.all(
                            color: Colors.black, // Set border color
                            width: 2.0, // Set border width
                          ),
                        ),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0, // Set elevation to 0 to remove it
                            ),
                            onPressed:() {
                          callShareIntentURL(jsonResult['Web Url'], jsonResult["type"]);
                        }, child: const Text('Share',style: TextStyle(color: Colors.black),)),
                      )),
                  )
                ],
              ),
            ),
          ),
        )://done
        jsonResult['type'] == 'WIFI' ?
        AlertDialog(
          content:
          WillPopScope(
            onWillPop: () async {
              // Return false to prevent the dialog from closing
              return false;
            },
            child: Container(
              height: MediaQuery.of(context).size.height*3/4,
              width: MediaQuery.of(context).size.width*3/4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex:1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                      Expanded(
                          child: Container(
                              child: const Center(
                                  child: Text('Wifi',style: TextStyle(fontSize: 24))))),
                        GestureDetector(
                            onTap: () {
                              setState(() {
                                dialogOpen = false;
                                wifiTimeStamp = false;
                                historyItemTapped = false;
                              });
                              Navigator.of(context).pop();
                            },
                            child:historyItemTapped? Text(formatDateTime(DateTime.parse(jsonResult['scannedTime']))) : const Icon(Icons.close)
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('SSID'),
                              Text('Password'),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 8,right: 8),
                            child: Column(
                              children: [
                                Text(':'),
                                Text(':'),
                              ],),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(jsonResult['ssid'] ?? ''),
                              Text(jsonResult['password'] ?? ''),
                            ],
                          ),
                        ],
                      )),
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: (MediaQuery.of(context).size.height * 3/4)/3,
                    ),
                  ),
                  Visibility(
                    visible: (jsonResult['ssid'] != null && jsonResult['ssid'] != '')
                        && (jsonResult['password'] != null && jsonResult['password'] != ''),
                    child: Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xff1976D2),
                              borderRadius: BorderRadius.circular(8.0), // Set border radius for a rectangular shape
                            ),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    elevation: 0, // Set elevation to 0 to remove it
                                    backgroundColor: Colors.transparent
                                ),
                                onPressed: () async {
                            print("object" + jsonResult['ssid']);
                            // await PluginWifiConnect. ;
                            /* WiFiForIoTPlugin.connect(jsonResult['ssid'],
                                password: jsonResult['password'],
                                joinOnce: true,
                                security: NetworkSecurity.WPA);

            */
                            // await PluginWifiConnect.connect(ssid);
                            // bool isConnected =  await WiFiForIoTPlugin.isConnected();
                            // print("Is connected to Wi-Fi: $isConnected");
                            connectToWiFi(jsonResult['ssid'],jsonResult['password']);
                            //(jsonResult['ssid'], jsonResult['password']);
                            connectWifiChannel(jsonResult['ssid'], jsonResult['password']);
                            }, child: const Text('Connect',style: TextStyle(color: Colors.white))),
                          ),
                        ),
                        const SizedBox(width: 10,),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xff71717A),
                              borderRadius: BorderRadius.circular(8.0), // Set border radius for a rectangular shape
                            ),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    elevation: 0, // Set elevation to 0 to remove it
                                    backgroundColor: Colors.transparent
                                ),
                                onPressed:() {
                            copyToClipboard("SSID: ${jsonResult['ssid'] ?? ""}\nPassword: ${jsonResult['password'] ?? ""}");
                            }, child: const Text('Copy',style: TextStyle(color: Colors.white))),
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: (jsonResult['ssid'] != null && jsonResult['ssid'] != '')
                        && (jsonResult['password'] != null && jsonResult['password'] != ''),
                    child: Flexible(
                        flex: 1,
                        child: Align(
                            alignment: Alignment.center,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0), // Set border radius for a rectangular shape
                              border: Border.all(
                                color: Colors.black, // Set border color
                                width: 2.0, // Set border width
                              ),
                            ),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                ),
                                onPressed:(){
                              callShareIntentWifi(jsonResult["ssid"], jsonResult["password"], jsonResult["type"]);
                            }, child: const Text('Share',style: TextStyle(color: Colors.black),)),
                          ))),
                  )
                ],
              ),
            ),
          ),
        ) ://done
        jsonResult['type'] == 'Location' ?
        AlertDialog(
          content:
          WillPopScope(
            onWillPop: () async {
              // Return false to prevent the dialog from closing
              return false;
            },
            child: Container(
              height: MediaQuery.of(context).size.height*3/4,
              width: MediaQuery.of(context).size.width*3/4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex:1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                      Expanded(
                          child: Container(
                              child: const Center(
                                  child: Text('Geo',style: TextStyle(fontSize: 24))))),
                        GestureDetector(
                            onTap: () {
                              setState(() {
                                dialogOpen = false;
                                geoTimeStamp = false;
                                historyItemTapped = false;
                              });
                              Navigator.of(context).pop();
                            },
                            child: const Icon(Icons.close),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                      flex:3,
                      child: Text('Geo : ${jsonResult['latitude'] ?? ''} , ${jsonResult['longitude'] ?? ''}')),
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: (MediaQuery.of(context).size.height * 3/4)/3,
                    ),
                  ),
                  Visibility(
                    visible: (jsonResult['latitude'] != null && jsonResult['latitude'] != '')
                        || (jsonResult['longitude'] != null && jsonResult['longitude'] != ''),
                    child: Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color:  const Color(0xff71717A),
                              borderRadius: BorderRadius.circular(8.0), // Set border radius for a rectangular shape
                            ),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    elevation: 0, // Set elevation to 0 to remove it
                                    backgroundColor: Colors.transparent
                                ),
                                onPressed:() {
                            openMap(jsonResult['latitude'].toString(), jsonResult['longitude'].toString());
                            }, child: const Text('Maps',style: TextStyle(color: Colors.white))),
                          ),
                        ),
                        const SizedBox(width:10),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color:  const Color(0xff71717A),
                              borderRadius: BorderRadius.circular(8.0), // Set border radius for a rectangular shape
                            ),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    elevation: 0, // Set elevation to 0 to remove it
                                    backgroundColor: Colors.transparent
                                ),
                                onPressed:() {
                            copyToClipboard("Latitude ${jsonResult['latitude']} Longitude ${jsonResult['longitude']}");
                            }, child: const Text('Copy',style: TextStyle(color: Colors.white))),
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: (jsonResult['latitude'] != null && jsonResult['latitude'] != '')
                        || (jsonResult['longitude'] != null && jsonResult['longitude'] != ''),
                    child: Flexible(
                        flex: 1,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0), // Set border radius for a rectangular shape
                          border: Border.all(
                            color: Colors.black, // Set border color
                            width: 2.0, // Set border width
                          ),
                        ),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation:0,
                            ),
                            onPressed:() {
                          callIntentGeo(jsonResult['latitude'].toString(), jsonResult['longitude'].toString(), jsonResult['type']);
                        }, child: const Text('Share',style: TextStyle(color: Colors.black),)),
                      )),
                  )
                ],
              ),
            ),
          ),
        ) ://done
        jsonResult['type'] == 'BarCode' ?
        AlertDialog(
          //backgroundColor: Colors.white,
          content:
          WillPopScope(
            onWillPop: () async {
              // Return false to prevent the dialog from closing
              return false;
            },
            child: Container(
              height: MediaQuery.of(context).size.height*3/4,
              width: MediaQuery.of(context).size.width*3/4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex:1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                      Expanded(
                          child: Container(
                              child: const Center(
                                  child: Text('Barcode',style: TextStyle(fontSize: 24))))),
                        GestureDetector(
                            onTap: () {
                              setState(() {
                                dialogOpen = false;
                                barCodeTimeStamp = false;
                                historyItemTapped = false;
                              });
                              Navigator.of(context).pop();
                            },
                            child: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                      flex:3,
                      child: Text(jsonResult['BarCodeData'])
                  ),
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: (MediaQuery.of(context).size.height * 3/4)/3,
                    ),
                  ),
                  Visibility(
                    visible: jsonResult['BarCodeData'] != null && jsonResult['BarCodeData'] != '',
                    child: Expanded(
                      flex: 1,
                    child: Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 8,bottom: 8),
                        decoration: BoxDecoration(
                          color:  const Color(0xff71717A),
                          borderRadius: BorderRadius.circular(8.0), // Set border radius for a rectangular shape
                        ),
                        width: double.infinity,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                elevation: 0, // Set elevation to 0 to remove it
                                backgroundColor: Colors.transparent
                            ),
                            onPressed:() {
                        copyToClipboard(jsonResult['BarCodeData']);
                        }, child: const Text('Copy',style: TextStyle(color: Colors.white))),
                      ),
                    ),
                    ),
                  ),
                  Visibility(
                    visible: jsonResult['BarCodeData'] != null && jsonResult['BarCodeData'] != '',
                    child: Flexible(
                        flex: 1,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0), // Set border radius for a rectangular shape
                          border: Border.all(
                            color: Colors.black, // Set border color
                            width: 2.0, // Set border width
                          ),
                        ),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                            ),
                            onPressed:() {
                          callIntentBarCode(jsonResult['BarCodeData'], jsonResult['type']);
                        }, child: const Text('Share',style: TextStyle(color: Colors.black),)),
                      )),
                  )
                ],
              ),
            ),
          ),
        ) ://done
        jsonResult['type'] == 'Calendar' ?
        AlertDialog(
          content:
          WillPopScope(
            onWillPop: () async {
              // Return false to prevent the dialog from closing
              return false;
            },
            child: Container(
              height: MediaQuery.of(context).size.height*3/4,
              width: MediaQuery.of(context).size.width*3/4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex:1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Container(
                                child: const Center(
                                    child: Text('Calendar',style: TextStyle(fontSize: 24))))),
                        GestureDetector(
                            onTap: () {
                              setState(() {
                                dialogOpen = false;
                                calendarTimeStamp = false;
                                historyItemTapped = false;
                              });
                              Navigator.of(context).pop();
                            },
                            child:const Icon(Icons.close)
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                      flex:5,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Event Name'),
                              Text('Event Date'),
                              Text('Event Details'),
                            ],
                          ),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(':'),
                              Text(':'),
                              Text(':'),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(jsonResult['summary'] ?? ""),
                              Text(formatDate(DateTime.parse(jsonResult['startDate']), 'd MMMM y')),
                              Text(jsonResult['description'] ?? ""),
                            ],
                          ),


                        ],
                      )),

                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        Visibility(
                          visible: jsonResult["summary"] != null || jsonResult["startDate"] != null ||
                              jsonResult["endDate"] != null || jsonResult["location"] != null || jsonResult["description"],
                          child: Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color:  const Color(0xff71717A),
                                borderRadius: BorderRadius.circular(8.0), // Set border radius for a rectangular shape
                              ),
                              child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      elevation: 0, // Set elevation to 0 to remove it
                                      backgroundColor: Colors.transparent
                                  ),
                                  onPressed:() {
                                openIntentCalenderAddEvent(jsonResult["summary"] ?? "",jsonResult['startDate'] ?? "",
                                    jsonResult['endDate'] ?? "",jsonResult["location"] ?? ""
                                    ,jsonResult["description"] ?? "",jsonResult["type"]);
                              }, child: const Text('Calendar',style: TextStyle(color: Colors.white))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10,),
                        Visibility(
                            visible: jsonResult["summary"] != null || jsonResult["startDate"] != null ||
                                jsonResult["endDate"] != null || jsonResult["location"] != null || jsonResult["description"],
                            child: Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color:  const Color(0xff71717A),
                                  borderRadius: BorderRadius.circular(8.0), // Set border radius for a rectangular shape
                                ),
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        elevation: 0, // Set elevation to 0 to remove it
                                        backgroundColor: Colors.transparent
                                    ),
                                    onPressed:() {
                                  copyToClipboard("Summary: ${jsonResult["summary"] ?? ""}\nStart Date:${jsonResult["startDate"] ?? ""}\n End Date: ${jsonResult["endDate"] ?? ""}\n Location:${jsonResult["location"] ?? ""}\n Description: ${jsonResult["description"] ?? ""}");
                                }, child: const Text('Copy',style: TextStyle(color: Colors.white))),
                              ),
                            )),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: jsonResult["summary"] != null || jsonResult["startDate"] != null ||
                    jsonResult["endDate"] != null || jsonResult["location"] != null || jsonResult["description"],
                    child: Flexible(
                        flex: 1,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0), // Set border radius for a rectangular shape
                            border: Border.all(
                              color: Colors.black, // Set border color
                              width: 2.0, // Set border width
                            ),
                          ),
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                              ),
                              onPressed:() {
                              callIntentCalender(jsonResult["summary"] ?? "",formatDate(DateTime.parse(jsonResult['startDate'] ?? DateTime.now()), 'd MMMM y'),
                                  formatDate(DateTime.parse(jsonResult['endDate'] ?? DateTime.now()), 'd MMMM y'),jsonResult["location"] ?? ""
                                  ,jsonResult["description"] ?? "",jsonResult["type"]);
                          }, child: const Text('Share',style: TextStyle(color: Colors.black))),
                        )),
                  )
                ],
              ),
            ),
          ),
        ) ://done
        jsonResult['type'] == 'Contact' ?
        AlertDialog(
          // title: const Text('Dialog Title'),
          content: WillPopScope(
            onWillPop: () async {
              // Return false to prevent the dialog from closing
              return false;
            },
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: MediaQuery.of(context).size.width * 3/4,
              height: MediaQuery.of(context).size.height * 3/4,
              child: Column(
                children: [
                  Flexible(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                          Expanded(
                              child: Container(
                                  child: const Center(
                                      child:Text("Contact",style: TextStyle(fontSize: 24))))),
                            GestureDetector(
                              child: const Icon(Icons.close),
                              onTap: () {
                                setState(() {
                                  dialogOpen = false;
                                  vCardTimeStamp = false;
                                  historyItemTapped = false;
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                            historyItemTapped? Text(formatDateTime(DateTime.parse(jsonResult['scannedTime']))) : const Icon(Icons.close)
                          ]),
                    ),
                  ),
                  Flexible(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Name', style: TextStyle(fontSize: 20)),
                              Text('Number', style: TextStyle(fontSize: 20)),
                              Text('Email', style: TextStyle(fontSize: 20)),
                              // Text('Address', style: TextStyle(fontSize: 20)),
                            ],
                          ),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(': ', style: TextStyle(fontSize: 20)),
                              Text(': ', style: TextStyle(fontSize: 20)),
                              Text(': ', style: TextStyle(fontSize: 20)),
                              // Text(': ', style: TextStyle(fontSize: 20)),
                            ],
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(jsonResult["FN"] ?? "", style: const TextStyle(fontSize: 20)),
                                Text(jsonResult["TEL"] ?? "", style: const TextStyle(fontSize: 20)),
                                Text(jsonResult["EMAIL"] ?? "", style: const TextStyle(fontSize: 20)),
                                // Text(jsonResult[""],
                                //     style: TextStyle(fontSize: 20),
                                //   softWrap: true,
                                // ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Flexible(flex: 4,
                      child: SizedBox(
                        width: 300,
                        height: 250,
                      )),
                  Flexible(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Visibility(
                          visible: jsonResult["TEL"] != null,
                          child: Flexible(
                            flex: 1,
                            child: Container(
                                width: 80,
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.blue, // Background color
                                  border: Border.all(
                                    color: Colors.blue, // Border color
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      8.0), // Adjust the border radius
                                ),
                                child: GestureDetector(onTap: () {
                                    callPhoneIntent(jsonResult["TEL"]);
                                },
                                    child: const Icon(Icons.call))),
                          ),
                        ),
                        Visibility(
                          visible: (jsonResult["TEL"] != null && jsonResult["TEL"] != ""),
                              // || (jsonResult["EMAIL"] != null && jsonResult["EMAIL"] != "")
                              // || (jsonResult["FN"] != null && jsonResult["FN"] != ""),
                          child: Flexible(
                            flex: 1,
                            child: Container(
                                width: 80,
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.blue, // Background color
                                  border: Border.all(
                                    color: Colors.blue, // Border color
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      8.0), // Adjust the border radius
                                ),
                                child: GestureDetector(onTap: () {
                                  callContactsIntent(jsonResult["TEL"], jsonResult["EMAIL"], jsonResult["FN"]);
                                },
                                    child: const Icon(Icons.add_card_outlined))),
                          ),
                        ),
                        Visibility(
                          visible: jsonResult["EMAIL"] != null,
                          child: Flexible(
                            flex: 1,
                            child: Container(
                                width: 80,
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.blue, // Background color
                                  border: Border.all(
                                    color: Colors.blue, // Border color
                                    width: 2.0, // Border width
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      8.0), // Adjust the border radius
                                ),
                                child: GestureDetector(onTap: () {
                                          callEmailIntent(jsonResult["EMAIL"]);
                                        },
                                    child: const Icon(Icons.email))),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: (jsonResult["TEL"] != null && jsonResult["TEL"] != "")
                        || (jsonResult["EMAIL"] != null && jsonResult["EMAIL"] != "")
                        || (jsonResult["FN"] != null && jsonResult["FN"] != ""),
                    child: Flexible(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () {
                            callShareIntent(jsonResult["TEL"] ?? "", jsonResult["EMAIL"] ?? "", jsonResult["FN"] ?? "", jsonResult["type"]);
                          },
                          child: Container(
                              margin: const EdgeInsets.only(top: 40),
                              alignment: Alignment.center,
                            width: double.infinity,
                              decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0), // Set border radius for a rectangular shape
                                border: Border.all(
                                color: Colors.black, // Set border color
                                width: 2.0, // Set border width
                                ),
                              ),
                              height: 50,
                            child: const Text('Share', style: TextStyle(fontSize: 20,color: Colors.white))),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        )://done
        jsonResult['type'] == 'upi' ?
        AlertDialog(
          content:
          WillPopScope(
            onWillPop: () async {
              // Return false to prevent the dialog from closing
              return false;
            },
            child: Container(
              height: MediaQuery.of(context).size.height*3/4,
              width: MediaQuery.of(context).size.width*3/4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex:1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(width: 220,
                          child: Text(jsonResult["URL"],
                            overflow: TextOverflow.ellipsis,
                            maxLines: 10,),
                        ),
                        GestureDetector(
                            onTap: () {
                              setState(() {
                                dialogOpen = false;
                              });
                              Navigator.of(context).pop();
                            },
                            child: const Icon(Icons.close)
                        ),
                      ],
                    ),
                  ),
                  /*Expanded(
                      flex:3,
                      child: Text(jsonResult['URL'] ?? "")),*/
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: (MediaQuery.of(context).size.height * 3/4)/3,
                    ),
                  ),
                  Visibility(
                    visible: jsonResult['URL'] != null && jsonResult['URL'] != "",
                    child: Expanded(
                      flex: 1,
                      child: ElevatedButton(onPressed:() {
                        copyToClipboard(jsonResult['URL']);
                      }, child: const Text('Copy')),
                    ),
                  ),
                  Visibility(
                    visible: jsonResult['URL'] != null && jsonResult['URL'] != "",
                    child: Flexible(
                        flex: 1,
                        child: ElevatedButton(onPressed:() {
                          callIntentText(jsonResult['URL'], jsonResult['type']);
                        }, child: const Text('Share'))),
                  )
                ],
              ),
            ),
          ),
          // actions: [
          //   TextButton(
          //     onPressed: () {
          //       //_launchURL(url);
          //
          //     },
          //     child: const Text('Visit Url'),
          //   ),
          //   TextButton(
          //     onPressed: () {
          //       setState(() {
          //         dialogOpen = false;
          //       });
          //       Navigator.of(context).pop();// Close the dialog
          //     },
          //     child: const Text('Close'),
          //   ),
          // ],
        ) :
        AlertDialog(
          content:
          WillPopScope(
            onWillPop: () async {
              // Return false to prevent the dialog from closing
              return false;
            },
            child: Container(
              height: MediaQuery.of(context).size.height*3/4,
              width: MediaQuery.of(context).size.width*3/4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex:1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                      Expanded(
                          child: Container(
                              child: const Center(
                                  child: Text('Text',style: TextStyle(fontSize: 24))))),
                        GestureDetector(
                            onTap: () {
                              setState(() {
                                dialogOpen = false;
                              });
                              Navigator.of(context).pop();
                            },
                            child: const Icon(Icons.close)
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                      flex:3,
                      child: Text(jsonResult['Blank'] ?? "")),
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: (MediaQuery.of(context).size.height * 3/4)/3,
                    ),
                  ),
                  Visibility(
                    visible: jsonResult['Blank'] != null && jsonResult['Blank'] != "",
                    child: Expanded(
                      flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(top:8.0, bottom: 8.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color:  const Color(0xff71717A),
                          borderRadius: BorderRadius.circular(8.0), // Set border radius for a rectangular shape
                        ),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                elevation: 0, // Set elevation to 0 to remove it
                                backgroundColor: Colors.transparent
                            ),
                            onPressed:() {
                        copyToClipboard(jsonResult['Blank']);
                        }, child: const Text('Copy',style: TextStyle(color: Colors.white),)),
                      ),
                    ),
                    ),
                  ),
                  Visibility(
                    visible: jsonResult['Blank'] != null && jsonResult['Blank'] != "",
                    child: Flexible(
                        flex: 1,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0), // Set border radius for a rectangular shape
                          border: Border.all(
                            color: Colors.black, // Set border color
                            width: 2.0, // Set border width
                          ),
                        ),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                            ),
                            onPressed:() {
                          callIntentText(jsonResult['Blank'], jsonResult['type']);
                        }, child: const Text('Share',style:TextStyle(color: Colors.black))),
                      )),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
    await addJsonDataToList(jsonResult);
    if(jsonResult['type'] == 'URL') {
      if (await SharedPreferencesHelper().getOpenURLAutoData() == true) {
        _launchURL(jsonResult['Web Url']);
      }
    }
    // await controller!.pauseCamera();
  }

  String formatDate(DateTime date,String format) {
    // Use the intl package for formatting dates
    final formatter = DateFormat(format);
    return formatter.format(date);
  }

  void _showSettingsDialog(){

    print('show dialog');
    showDialog(
      barrierDismissible: false,
      context: context,
      builder:(BuildContext context) {
        return const SettingsAlert();
        /*AlertDialog(
          //backgroundColor: Colors.white,
          content:
          Container(
            height: MediaQuery.of(context).size.height*3/4,
            width: MediaQuery.of(context).size.width,
            child:  Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  flex: 1,
                    child: Text('Settings',style: TextStyle(fontSize: 30),)),
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Vibrate',
                          ),
                          Spacer(),
                          Switch(
                            onChanged: toggleSwitchVibrate,
                            value: isSwitchedVibrate,
                            activeColor: Colors.white,
                            activeTrackColor: Theme.of(context).colorScheme.primary,
                            inactiveThumbColor: Theme.of(context).colorScheme.onError,
                            inactiveTrackColor: Theme.of(context).colorScheme.onBackground,
                          )
                        ],
                      ),
                      const Row(
                        children: [
                          Text(
                            'Open websites\nautomatically',
                          ),
                          Spacer(),
                          Switch(value: true, onChanged: null)
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: double.infinity,
                        child: TextButton(
                            style: ButtonStyle(
                              shape: MaterialStateProperty.all<OutlinedBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // Set your desired border radius
                                ),
                              ),
                              backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                            ),
                            onPressed: null,
                            child: const Text('Clear History',style: TextStyle(color: Colors.white),)),
                      )
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Container(
                      // margin: EdgeInsets.only(top: 8),
                      width: double.infinity,
                      child: TextButton(
                          style: ButtonStyle(
                            shape: MaterialStateProperty.all<OutlinedBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0), // Set your desired border radius
                              ),
                            ),
                            backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                          ),
                          onPressed: null,
                          child: const Text('Rate Us',style: TextStyle(color: Colors.white),)),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Container(
                      // margin: EdgeInsets.only(top: 8),
                      width: double.infinity,
                      child: TextButton(
                          style: ButtonStyle(
                            shape: MaterialStateProperty.all<OutlinedBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0), // Set your desired border radius
                              ),
                            ),
                            backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                          ),
                          onPressed: null,
                          child: const Text('Explore More Apps',style: TextStyle(color: Colors.white),)),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Container(
                      // margin: EdgeInsets.only(top: 8),
                      width: double.infinity,
                      child: TextButton(
                          style: ButtonStyle(
                            shape: MaterialStateProperty.all<OutlinedBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0), // Set your desired border radius
                              ),
                            ),
                            backgroundColor: MaterialStateProperty.all<Color>(Colors.yellow),
                          ),
                          onPressed: null,
                          child: const Text('Ad',style: TextStyle(color: Colors.white),)),
                    ),
                  ),
                )

              ],
            ),
          ),
        );*/

        /*AlertDialog(
          title: const Text('Dialog Title'),
          content: Container(
              margin: const EdgeInsets.only(top: 10),
              width: MediaQuery.of(context).size.width * 3/4,
              height: MediaQuery.of(context).size.height * 3/4,
              child: Column(
                children: [
                  Text(jsonResult['Blank']),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        dialogOpen = false;
                      });
                      Navigator.of(context).pop();// Close the dialog
                    },
                    child: const Text('Close'),
                  ),
                ],
              )),
          // actions: [
          //   // TextButton(
          //   //   onPressed: () {
          //   //     //_launchURL(url);
          //   //
          //   //   },
          //   //   child: const Text('Visit Url'),
          //   // ),
          //   // TextButton(
          //   //   onPressed: () {
          //   //     setState(() {
          //   //       dialogOpen = false;
          //   //     });
          //   //     Navigator.of(context).pop();// Close the dialog
          //   //   },
          //   //   child: const Text('Close'),
          //   // ),
          // ],
        );*/
      },
      /*(BuildContext context) {
        return AlertDialog(
          title: const Text('Dialog Title'),
          content: Text(jsonResult.toString()),
          actions: [
            TextButton(
              onPressed: () {
                _launchURL(url);

              },
              child: const Text('Visit Url'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  dialogOpen = false;
                });
                Navigator.of(context).pop();// Close the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },*/
    );
  }

  void _showHistoryDialog(BuildContext context,Map<String,dynamic> url,String type)  {

    showDialog(
      barrierDismissible: false,
      context: context,
      builder:(BuildContext context) {
        return url['type'] == 'URL'?
        AlertDialog(
          //backgroundColor: Colors.white,
          content:
          Container(
            height: MediaQuery.of(context).size.height*3/4,
            width: MediaQuery.of(context).size.width*3/4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex:1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Container(
                              child: const Center(
                                  child: Text('Url',style: TextStyle(fontSize: 24),)))),
                      GestureDetector(
                          onTap: () {
                            setState(() {
                              dialogOpen = false;
                              urlTimeStamp = false;
                              historyItemTapped = false;
                            });
                            Navigator.of(context).pop();
                          },
                          child: historyItemTapped ? Text(formatDateTime(DateTime.parse(url['scannedTime']))) : const Icon(Icons.close)
                      ),
                    ],
                  ),
                ),
                const Expanded(
                    flex: 1,
                    child: Text('Url Name')),
                Expanded(
                    flex:3,
                    child: Text(url['Web Url'] ?? '')
                ),
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: (MediaQuery.of(context).size.height * 3/4)/3,
                  ),
                ),
                Visibility(
                  visible: url['Web Url'] != null && url['Web Url'] != "",
                  child: Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xff1976D2),
                              borderRadius: BorderRadius.circular(8.0), // Set border radius for a rectangular shape
                            ),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    elevation: 0, // Set elevation to 0 to remove it
                                    backgroundColor: Colors.transparent
                                ),
                                onPressed:() {
                                  _launchURL(url['Web Url']);
                                }, child: const Text('Open',style: TextStyle(color: Colors.white))),
                          ),
                        ),
                        const SizedBox(width: 10,),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color:  const Color(0xff71717A),
                              borderRadius: BorderRadius.circular(8.0), // Set border radius for a rectangular shape
                            ),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    elevation: 0, // Set elevation to 0 to remove it
                                    backgroundColor: Colors.transparent
                                ),
                                onPressed:() {
                                  copyToClipboard(url['Web Url']);
                                }, child: const Text('Copy',style: TextStyle(color: Colors.white),)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Visibility(
                  visible: url['Web Url'] != null && url['Web Url'] != "",
                  child: Flexible(
                      flex: 1,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0), // Set border radius for a rectangular shape
                          border: Border.all(
                            color: Colors.black, // Set border color
                            width: 2.0, // Set border width
                          ),
                        ),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0, // Set elevation to 0 to remove it
                            ),
                            onPressed:() {
                              callShareIntentURL(url['Web Url'], url["type"]);
                            }, child: const Text('Share',style: TextStyle(color: Colors.black),)),
                      )),
                )
              ],
            ),
          ),

        )://done
        url['type'] == 'WIFI' ?
        AlertDialog(
          content:
          Container(
            height: MediaQuery.of(context).size.height*3/4,
            width: MediaQuery.of(context).size.width*3/4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex:1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Wifi'),
                      GestureDetector(
                          onTap: () {
                            setState(() {
                              dialogOpen = false;
                              wifiTimeStamp = false;
                              historyItemTapped = false;
                            });
                            Navigator.of(context).pop();
                          },
                          child:Text(formatDateTime(DateTime.parse(url['scannedTime'])))
                      ),
                    ],
                  ),
                ),
                Expanded(
                    flex: 3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('SSID'),
                            Text('Password'),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 8,right: 8),
                          child: Column(
                            children: [
                              Text(':'),
                              Text(':'),
                            ],),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(url['ssid'].toString() ?? ''),
                            Text(url['password'].toString() ?? ''),
                          ],
                        ),
                      ],
                    )),
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: (MediaQuery.of(context).size.height * 3/4)/3,
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(onPressed:null, child: Text('Connect')),
                      ElevatedButton(onPressed:null, child: Text('Copy')),
                    ],
                  ),
                ),
                const Flexible(
                    flex: 1,
                    child: Align(
                        alignment: Alignment.center,
                        child: ElevatedButton(onPressed:null, child: Text('Share'))))
              ],
            ),
          ),
          // actions: [
          //   TextButton(
          //     onPressed: () {
          //       //_launchURL(url);
          //
          //     },
          //     child: const Text('Visit Url'),
          //   ),
          //   TextButton(
          //     onPressed: () {
          //       setState(() {
          //         dialogOpen = false;
          //       });
          //       Navigator.of(context).pop();// Close the dialog
          //     },
          //     child: const Text('Close'),
          //   ),
          // ],
        ) ://done
        /*url['type'] == 'Text' ?
        AlertDialog(
          content:
          Container(
            height: MediaQuery.of(context).size.height*3/4,
            width: MediaQuery.of(context).size.width*3/4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex:1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Text'),
                      GestureDetector(
                          onTap: () {
                            setState(() {
                              dialogOpen = false;
                            });
                            Navigator.of(context).pop();
                          },
                          child: Text(formatDateTime(url['scannedTime']))),
                    ],
                  ),
                ),
                const Expanded(
                    flex:3,
                    child: Text('jdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisl,jdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisljdliujfpiosjdfoisjdfoisl')),
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: (MediaQuery.of(context).size.height * 3/4)/3,
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: ElevatedButton(onPressed:null, child: Text('Copy')),
                ),
                const Flexible(
                    flex: 1,
                    child: ElevatedButton(onPressed:null, child: Text('Share')))
              ],
            ),
          ),
          // actions: [
          //   TextButton(
          //     onPressed: () {
          //       //_launchURL(url);
          //
          //     },
          //     child: const Text('Visit Url'),
          //   ),
          //   TextButton(
          //     onPressed: () {
          //       setState(() {
          //         dialogOpen = false;
          //       });
          //       Navigator.of(context).pop();// Close the dialog
          //     },
          //     child: const Text('Close'),
          //   ),
          // ],
        ) :*/
        url['type'] == 'Location' ?
        AlertDialog(
          content:
          Container(
            height: MediaQuery.of(context).size.height*3/4,
            width: MediaQuery.of(context).size.width*3/4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex:1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Geo'),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            dialogOpen = false;
                            geoTimeStamp = false;
                            historyItemTapped = false;
                          });
                          Navigator.of(context).pop();
                        },
                        child: Text(formatDateTime(DateTime.parse(url['scannedTime'])))
                      )
                    ],
                  ),
                ),
                Expanded(
                    flex:3,
                    child: Text('Geo : ${url['latitude'] ?? ''} , ${url['longitude'] ?? ''}')),
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: (MediaQuery.of(context).size.height * 3/4)/3,
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      ElevatedButton(onPressed:null, child: Text('Maps')),
                      ElevatedButton(onPressed:null, child: Text('Copy')),
                    ],
                  ),
                ),
                const Flexible(
                    flex: 1,
                    child: ElevatedButton(onPressed:null, child: Text('Share')))
              ],
            ),
          ),
          // actions: [
          //   TextButton(
          //     onPressed: () {
          //       //_launchURL(url);
          //
          //     },
          //     child: const Text('Visit Url'),
          //   ),
          //   TextButton(
          //     onPressed: () {
          //       setState(() {
          //         dialogOpen = false;
          //       });
          //       Navigator.of(context).pop();// Close the dialog
          //     },
          //     child: const Text('Close'),
          //   ),
          // ],
        ) ://done
        url['type'] == 'BarCode' ?
        AlertDialog(
          //backgroundColor: Colors.white,
          content:
          Container(
            height: MediaQuery.of(context).size.height*3/4,
            width: MediaQuery.of(context).size.width*3/4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex:1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Barcode'),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            dialogOpen = false;
                            barCodeTimeStamp = false;
                            historyItemTapped = false;
                          });
                          Navigator.of(context).pop();
                        },
                        child: Text(formatDateTime(DateTime.parse(url['scannedTime'])))
                      ),
                    ],
                  ),
                ),
                Expanded(
                    flex:3,
                    child: Text(url['BarCodeData'])
                ),
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: (MediaQuery.of(context).size.height * 3/4)/3,
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: ElevatedButton(onPressed:null, child: Text('Copy')),
                ),
                const Flexible(
                    flex: 1,
                    child: ElevatedButton(onPressed:null, child: Text('Share')))
              ],
            ),
          ),
          // actions: [
          //   TextButton(
          //     onPressed: () {
          //       //_launchURL(url);
          //
          //     },
          //     child: const Text('Visit Url'),
          //   ),
          //   TextButton(
          //     onPressed: () {
          //       setState(() {
          //         dialogOpen = false;
          //       });
          //       Navigator.of(context).pop();// Close the dialog
          //     },
          //     child: const Text('Close'),
          //   ),
          // ],
        )  ://done
        url['type'] == 'Calendar' ?
        AlertDialog(
          content:
          WillPopScope(
            onWillPop: () async {
              // Return false to prevent the dialog from closing
              return false;
            },
            child: Container(
              height: MediaQuery.of(context).size.height*3/4,
              width: MediaQuery.of(context).size.width*3/4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex:1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Calendar'),
                        GestureDetector(
                            onTap: () {
                              setState(() {
                                dialogOpen = false;
                                calendarTimeStamp = false;
                                historyItemTapped = false;
                              });
                              Navigator.of(context).pop();
                            },
                            child:Text(formatDateTime(DateTime.parse(url['scannedTime'])))
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                      flex:5,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Event Name'),
                              Text('Event Date'),
                              Text('Event Details'),
                            ],
                          ),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(':'),
                              Text(':'),
                              Text(':'),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(url['summary'].toString() ?? ''),
                              Text(formatDate(DateTime.parse(url['startDate']), 'd MMMM y') ?? ''),
                              Text(url['description'].toString() ?? ''),
                            ],
                          ),


                        ],
                      )),


                  const Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        ElevatedButton(onPressed:null, child: Text('Calendar')),
                        ElevatedButton(onPressed:null, child: Text('Copy')),
                      ],
                    ),
                  ),
                  const Flexible(
                      flex: 1,
                      child: ElevatedButton(onPressed:null, child: Text('Share')))
                ],
              ),
            ),
          ),
          // actions: [
          //   TextButton(
          //     onPressed: () {
          //       //_launchURL(url);
          //
          //     },
          //     child: const Text('Visit Url'),
          //   ),
          //   TextButton(
          //     onPressed: () {
          //       setState(() {
          //         dialogOpen = false;
          //       });
          //       Navigator.of(context).pop();// Close the dialog
          //     },
          //     child: const Text('Close'),
          //   ),
          // ],
        ) : //done
        url['type'] == 'Contact' ?
        AlertDialog(
          // title: const Text('Dialog Title'),
          content: Container(
            margin: const EdgeInsets.only(top: 10),
            width: MediaQuery.of(context).size.width * 3/4,
            height: MediaQuery.of(context).size.height * 3/4,
            child: Column(
              children: [
                Flexible(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Contact", style: TextStyle(fontSize: 20)),
                          GestureDetector(
                            child: const Icon(Icons.close),
                            onTap: () {
                              setState(() {
                                dialogOpen = false;
                                vCardTimeStamp = false;
                                historyItemTapped = false;
                              });
                              Navigator.of(context).pop();
                            },
                          ),
                          Text(formatDateTime(DateTime.parse(url['scannedTime'])))
                        ]),
                  ),
                ),
                Flexible(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Name', style: TextStyle(fontSize: 20)),
                            Text('Number', style: TextStyle(fontSize: 20)),
                            Text('Email', style: TextStyle(fontSize: 20)),
                            // Text('Address', style: TextStyle(fontSize: 20)),
                          ],
                        ),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(': ', style: TextStyle(fontSize: 20)),
                            Text(': ', style: TextStyle(fontSize: 20)),
                            Text(': ', style: TextStyle(fontSize: 20)),
                            // Text(': ', style: TextStyle(fontSize: 20)),
                          ],
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(url["FN"] ?? "", style: const TextStyle(fontSize: 20)),
                              Text(url["TEL"] ?? "", style: const TextStyle(fontSize: 20)),
                              Text(url["EMAIL"] ?? "", style: const TextStyle(fontSize: 20)),
                              // Text(jsonResult[""],
                              //     style: TextStyle(fontSize: 20),
                              //   softWrap: true,
                              // ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Flexible(flex: 4,
                    child: SizedBox(
                      width: 300,
                      height: 250,
                    )),
                Flexible(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Visibility(
                        visible: url["TEL"] != null,
                        child: Flexible(
                          flex: 1,
                          child: Container(
                              width: 80,
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.blue, // Background color
                                border: Border.all(
                                  color: Colors.blue, // Border color
                                  width: 2.0, // Border width
                                ),
                                borderRadius: BorderRadius.circular(
                                    8.0), // Adjust the border radius
                              ),
                              child: GestureDetector(onTap: () {
                                  callPhoneIntent(url["TEL"]);
                              },
                                  child: const Icon(Icons.call))),
                        ),
                      ),
                      Visibility(
                        visible: (url["TEL"] != null && url["TEL"] != "")
                            || (url["EMAIL"] != null && url["EMAIL"] != "")
                            || (url["FN"] != null && url["FN"] != ""),
                        child: Flexible(
                          flex: 1,
                          child: Container(
                              width: 80,
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.blue, // Background color
                                border: Border.all(
                                  color: Colors.blue, // Border color
                                  width: 2.0, // Border width
                                ),
                                borderRadius: BorderRadius.circular(
                                    8.0), // Adjust the border radius
                              ),
                              child: GestureDetector(onTap: () {
                                callContactsIntent(url["TEL"], url["EMAIL"], url["FN"]);
                              },
                                  child: const Icon(Icons.add_card_outlined))),
                        ),
                      ),
                      Visibility(
                        visible: url["EMAIL"] != null,
                        child: Flexible(
                          flex: 1,
                          child: Container(
                              width: 80,
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.blue, // Background color
                                border: Border.all(
                                  color: Colors.blue, // Border color
                                  width: 2.0, // Border width
                                ),
                                borderRadius: BorderRadius.circular(
                                    8.0), // Adjust the border radius
                              ),
                              child: GestureDetector(onTap: () {
                                        callEmailIntent(url["EMAIL"]);
                                      },
                                  child: const Icon(Icons.email))),
                        ),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: (url["TEL"] != null && url["TEL"] != "")
                      || (url["EMAIL"] != null && url["EMAIL"] != "")
                      || (url["FN"] != null && url["FN"] != ""),
                  child: Flexible(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () {
                          callShareIntent(url["TEL"], url["EMAIL"], url["FN"], url["type"]);
                        },
                        child: Container(
                            margin: const EdgeInsets.only(top: 40),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.blue, // Border color
                                width: 2.0, // Border width
                              ),
                              borderRadius: BorderRadius.circular(8.0), // Adjust the border radius
                            ),
                            width: 300,
                            height: 50,
                            child: const Text('Share', style: TextStyle(fontSize: 20,color: Colors.black))),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        )://done
        AlertDialog(
          content:
          Container(
            height: MediaQuery.of(context).size.height*3/4,
            width: MediaQuery.of(context).size.width*3/4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex:1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Text'),
                      GestureDetector(
                          onTap: () {
                            setState(() {
                              dialogOpen = false;
                              textTimeStamp = false;
                              historyItemTapped = false;
                            });
                            Navigator.of(context).pop();
                          },
                          child: Text(formatDateTime(DateTime.parse(url['scannedTime'])))
                      ),
                    ],
                  ),
                ),
                Expanded(
                    flex:3,
                    child: Text(url['Blank'])),
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: (MediaQuery.of(context).size.height * 3/4)/3,
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: ElevatedButton(onPressed:null, child: Text('Copy')),
                ),
                const Flexible(
                    flex: 1,
                    child: ElevatedButton(onPressed:null, child: Text('Share')))
              ],
            ),
          ),
          // actions: [
          //   TextButton(
          //     onPressed: () {
          //       //_launchURL(url);
          //
          //     },
          //     child: const Text('Visit Url'),
          //   ),
          //   TextButton(
          //     onPressed: () {
          //       setState(() {
          //         dialogOpen = false;
          //       });
          //       Navigator.of(context).pop();// Close the dialog
          //     },
          //     child: const Text('Close'),
          //   ),
          // ],
        );
      },
      /*(BuildContext context) {
        return AlertDialog(
          title: const Text('Dialog Title'),
          content: Text(jsonResult.toString()),
          actions: [
            TextButton(
              onPressed: () {
                _launchURL(url);

              },
              child: const Text('Visit Url'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  dialogOpen = false;
                });
                Navigator.of(context).pop();// Close the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },*/
    );


  }

  callEmailIntent(String email) {
    Map map = {
      "email": email,
    };
    channel.invokeMethod("EMAIL", map);
  }


  openPaymentURL(String url) {
    Map map = {
      "url": url,
    };
    channelUPI.invokeMethod("UPI", map);
  }
  connectWifiChannel(String ssid,String password) {
    Map map = {
      "ssid": ssid,
      "password": password
    };
    channelWifi.invokeMethod("WIFI", map);
  }

  callPhoneIntent(String phone) {
    Map map = {
      "phone": phone,
    };
    channelPhone.invokeMethod("CALL", map);
  }

  callContactsIntent(String phone, String email, String name) {
    Map map = {
      "phone": phone,
      "email": email,
      "name": name,
    };
    print("Contacts" + map.toString());
    channelContacts.invokeMethod("ADD_CONTACTS", map);
  }

  callShareIntent(String phone, String email, String name, String type) {
    Map map = {
      "phone": phone,
      "email": email,
      "name": name,
      "type": type,
    };
    channelShare.invokeMethod("SHARE", map);
  }

  callShareIntentWifi(String ssid, String password, String type) {
    Map map = {
      "ssid": ssid,
      "password": password,
      "type": type,
    };
    channelShare.invokeMethod("SHARE", map);
  }

  callShareIntentURL(String url, String type) {
    Map map = {
      "url": url,
      "type": type,
    };
    channelShare.invokeMethod("SHARE", map);
  }

/*
  callWifiIntent(String ssid, String password) {
    Map map = {
      "ssid": ssid,
      "password": password,
    };
    channelWifi.invokeMethod("connectToWiFi", map);
  }
*/

  callIntentBarCode(String barcode, String type) {
    Map map = {
      "barcode": barcode,
      "type": type,
    };
    channelShare.invokeMethod("SHARE", map);
  }

  callIntentText(String text, String type) {
    Map map = {
      "text": text,
      "type": type,
    };
    channelShare.invokeMethod("SHARE", map);
  }

  callIntentGeo(String lat, String long, String type) {
    Map map = {
      "lat": lat,
      "lng": long,
      "type": type,
    };
    channelShare.invokeMethod("SHARE", map);
  }

  callIntentCalender(String summary, String sDate, String eDate, String loc, String desc, String type) {
    Map map = {
      "summary": summary,
      "sdate": sDate,
      "edate": eDate,
      "location": loc,
      "description": desc,
      "type": type,
    };
    channelShare.invokeMethod("SHARE", map);
  }

  openIntentCalenderAddEvent(String summary, String sDate, String eDate, String loc, String desc, String type) {
    Map map = {
      "summary": summary,
      "sdate": sDate,
      "edate": eDate,
      "location": loc,
      "description": desc,
      "type": type,
    };
    channelAddEvent.invokeMethod("Calendar", map);
  }

  openMap(String lat, String long) {
    Map map = {
      "lat": lat,
      "lng": long,
    };
    channelMap.invokeMethod("map", map);
  }

  void copyToClipboard(String copyText) {
    Clipboard.setData(ClipboardData(text: copyText));
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //   content: Text('Text copied to clipboard: $copyText'),
    // ));
  }

  void _launchURL(String url) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url'; // prepend with http:// if missing
    }

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      print(await canLaunchUrl(Uri.parse(url)));
      print('Could not launch $url');
    }
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    bannerAd.dispose();
    super.dispose();
  }
}

class SettingsAlert extends StatefulWidget {
  const SettingsAlert({super.key});

  @override
  State<SettingsAlert> createState() => _SettingsAlertState();
}

class _SettingsAlertState extends State<SettingsAlert> {
  final SharedPreferencesHelper prefsHelper = SharedPreferencesHelper();
  bool isSwitchedVibrate = true;
  bool isSwitchedOpenURL = false;

  getSwitchValues() async {
    isSwitchedVibrate = await prefsHelper.getVibrateData();
    isSwitchedOpenURL = await prefsHelper.getOpenURLAutoData();
    setState(() {});
  }

  @override
  void initState() {
    getSwitchValues();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    void toggleSwitchVibrate(bool value) async {
      if (await prefsHelper.getVibrateData() == false) {
        setState(() {
          // NavigationService.isSoundAlarm = true;
          prefsHelper.saveVibrateData(true);
          isSwitchedVibrate = true;
          //VolumeController().maxVolume();
        });
      } else {
        setState(() {
          isSwitchedVibrate = false;
          prefsHelper.saveVibrateData(false);
        });
      }
    }

    void toggleSwitchOpenURLAuto(bool value) async {
      if (await prefsHelper.getOpenURLAutoData() == false) {
        setState(() {
          // NavigationService.isSoundAlarm = true;
          prefsHelper.saveOpenURLAutoData(true);
          isSwitchedOpenURL = true;
          //VolumeController().maxVolume();
        });
      } else {
        setState(() {
          isSwitchedOpenURL = false;
          prefsHelper.saveOpenURLAutoData(false);
        });
      }
    }

    return AlertDialog(
      //backgroundColor: Colors.white,
      content:
      Container(
        height: MediaQuery.of(context).size.height*3/4,
        width: MediaQuery.of(context).size.width,
        child:  Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                    flex: 1,
                    child: Center(child: Text('Settings',
                      style: TextStyle(fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),))),
                GestureDetector(
                    onTap: () {
                      // Dismiss the AlertDialog
                      Navigator.pop(context);

                      // Dismiss the BottomSheet
                      Navigator.of(context).pop();
                    },
                    child: Icon(Icons.close, color: Colors.black,)),
              ],
            ),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5,50,10,0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Vibrate',
                            style: TextStyle(fontSize: 15,
                                color: Colors.black),),
                            Text('Vibration for precision',
                              style: TextStyle(fontSize: 14,
                                  color: Color(0xFFB2B0B0)
                              ),
                            ),
                          ],
                        ),
                        Spacer(),
                        Switch(
                          onChanged: toggleSwitchVibrate,
                          value: isSwitchedVibrate,
                          activeColor: Colors.white,
                          activeTrackColor: Color(0xFF1976D2),
                          // inactiveThumbColor: Theme.of(context).colorScheme.onError,
                          // inactiveTrackColor: Theme.of(context).colorScheme.onBackground,
                        )
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Row(
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Open websites directly',
                                style: TextStyle(fontSize: 15,
                                    color: Colors.black
                                ),
                              ),Text(
                                'Instant Website',
                                style: TextStyle(fontSize: 14,
                                    color: Color(0xFFB2B0B0)
                                ),
                              ),
                            ],
                          ),
                          Spacer(),
                          Switch(
                            onChanged: toggleSwitchOpenURLAuto,
                            value: isSwitchedOpenURL,
                            activeColor: Colors.white,
                            activeTrackColor: Color(0xFF1976D2),
                            // inactiveThumbColor: Theme.of(context).colorScheme.onError,
                            // inactiveTrackColor: Theme.of(context).colorScheme.onBackground,
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 12),
                      width: double.infinity,
                      height: 85,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 30.0),
                        child: TextButton(
                            style: ButtonStyle(
                              shape: MaterialStateProperty.all<OutlinedBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // Set your desired border radius
                                ),
                              ),
                              backgroundColor: MaterialStateProperty.all<Color>(Color(0xFFFEE2E2)),
                            ),
                            onPressed: () {
                              prefs.clear();
                              Fluttertoast.showToast(
                                msg:
                                "History Cleared.",
                                toastLength: Toast.LENGTH_LONG,
                              );
                            },
                            child: const Text('Clear History',style: TextStyle(color: Color(0xFFEF4444)),)),
                      ),
                    )
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  // margin: EdgeInsets.only(top: 8),
                  width: double.infinity,
                  child: TextButton(
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all<OutlinedBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0), // Set your desired border radius
                          ),
                        ),
                        backgroundColor: MaterialStateProperty.all<Color>(Color(0xFFDCFCE7)),
                      ),
                      onPressed: null,
                      child: const Text('Rate Us',style: TextStyle(color: Color(0xFF22C55E)),)),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  // margin: EdgeInsets.only(top: 8),
                  width: double.infinity,
                  child: TextButton(
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all<OutlinedBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0), // Set your desired border radius
                          ),
                        ),
                        backgroundColor: MaterialStateProperty.all<Color>(Color(0xFFCAE3FC)),
                      ),
                      onPressed: null,
                      child: const Text('More Apps Like This',style: TextStyle(color: Color(0xFF1976D2)),)),
                ),
              ),
            ),
           /* Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  // margin: EdgeInsets.only(top: 8),
                  width: double.infinity,
                  child: TextButton(
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all<OutlinedBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0), // Set your desired border radius
                          ),
                        ),
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.yellow),
                      ),
                      onPressed: null,
                      child: const Text('Ad',style: TextStyle(color: Colors.white),)),
                ),
              ),
            )*/

          ],
        ),
      ),
    );
  }
}
