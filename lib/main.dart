import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';



void main() => runApp(const MaterialApp(home: QRViewExample()));

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

class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool dialogOpen = false;
  late SharedPreferences prefs;
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
  var channelPhone = const MethodChannel("INTENT_CALL");
  var channelContacts = const MethodChannel("INTENT_ADD_CONTACTS");
  var channelShare = const MethodChannel("INTENT_SHARE");
  var channelWifi = const MethodChannel("INTENT_WIFI");


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
    final prefs = await SharedPreferences.getInstance();
    final jsonStringList = prefs.getStringList('scanHistory') ?? [];
    jsonDataList = jsonStringList.map((jsonString) => Map<String, dynamic>.from(json.decode(jsonString))).toList();

    return jsonDataList;
  }
  Future<void> saveJsonDataList(List<Map<String, dynamic>> dataList) async {
    final prefs = await SharedPreferences.getInstance();
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
    // TODO: implement initState
    super.initState();
    loadJsonDataList();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          _buildQrView(context),
          Align(
            alignment:Alignment.bottomCenter,
            child:
            Container(
              alignment: Alignment.bottomCenter,
              height: 120,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(topLeft:Radius.circular(33),topRight: Radius.circular(33)),
                //color: Color(0x41205ac4)
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xb21c59d5), // Starting color
                    Colors.transparent, // Ending color
                  ],
                ),
              ),
              child:Row(
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
                          return const Icon(Icons.flash_on,color: Colors.white,);//Text('Flash: ${snapshot.data}',style: const TextStyle(color: Colors.white),);
                        },
                      )),
                  Column(
                    children: [
                      GestureDetector(
                        onVerticalDragEnd: (details) {
                          // Check if the swipe is upwards
                          if (details.primaryVelocity! < 0) {
                            // Show the bottom sheet
                            _showBottomSheet(context);
                          }
                        },
                        child: const IconButton(
                          onPressed: null,
                          //(){_showBottomSheet(context);},
                          icon: Icon(Icons.expand_less,color: Colors.white,),),
                      ),
                      const Text('Scan History',style: TextStyle(color: Colors.white),)
                    ],
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
                      )),                ],
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
        return NotificationListener<ScrollNotification>(
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40,),
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
                            return const Icon(Icons.flash_on,);//Text('Flash: ${snapshot.data}',style: const TextStyle(color: Colors.white),);
                          },
                        )),
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Column(
                        children: [
                          Icon(Icons.expand_more),
                          Row(
                            //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(Icons.history),
                              SizedBox(width: 6,),
                              Text('Scan History',style: TextStyle(color: Colors.black,fontSize: 24),),
                            ],
                          )
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.settings_applications),
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
                      return Column(
                        children: [
                          for (Map<String, dynamic> item in loadedList)
                            GestureDetector(
                                onTap:(){
                                  setState(() {
                                    historyItemTapped = true;
                                  });
                                  _showDialog(context, item.toString(), item['type']);
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
                                    height: 60,
                                    width: double.infinity,
                                    decoration:const BoxDecoration(
                                      color: Colors.white
                                    ),
                                    margin: const EdgeInsets.all(10),
                                    child: Row(

                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          //mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Icon(Icons.qr_code,size: 30,),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(top:10,left: 5),
                                              child: Column(

                                                children: [
                                                  item['type']=='WIFI'?Text(item['ssid'].toString()):Text(''),
                                                  Text(item['type'].toString(),overflow:TextOverflow.ellipsis,),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(formatDateTime(DateTime.parse(item['scannedTime'])),)
                                      ],
                                    ))),
                        ],
                      );
                    }
                  },
                )

              ],
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
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller){
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
      //_showDialog(context,scanData.code!);
      if(!dialogOpen){
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
        else if (key.contains('TEL;')){
          jsonResult['TEL'] = value;
        } else if (key.contains('EMAIL;')){
          jsonResult['EMAIL'] = value;
        } else if (key.contains('FN;')){
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

  String formatDateTime(DateTime dateTime) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(Duration(days: 1));
    DateTime yesterday = today.subtract(Duration(days: 1));

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
  void _showDialog(BuildContext context,String url,String type)  async{
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
    else {
      jsonResult = {'Blank': url};
    }
    print("TYPE: $type");

    showDialog(
      barrierDismissible: false,
      context: context,
      builder:(BuildContext context) {
        return jsonResult['type'] == 'URL'?
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
                      const Text('Url'),
                      GestureDetector(
                          onTap: () {
                            setState(() {
                              dialogOpen = false;
                              urlTimeStamp = false;
                              historyItemTapped = false;
                            });
                            Navigator.of(context).pop();
                          },
                          child: historyItemTapped? Text(formatDateTime(DateTime.parse(jsonResult['scannedTime']))) : Icon(Icons.close)
                      ),
                    ],
                  ),
                ),
                const Expanded(
                    flex: 1,
                    child: Text('Url Name')),
                Expanded(
                    flex:3,
                    child: Text(jsonResult['Web Url'])),
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
                Visibility(
                  visible: jsonResult['Web Url'] != null && jsonResult['Web Url'] != "",
                  child: Flexible(
                      flex: 1,
                      child: ElevatedButton(onPressed:() {
                        callShareIntentURL(jsonResult['Web Url'], jsonResult["type"]);
                      }, child: Text('Share'))),
                )
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
        )://done
        jsonResult['type'] == 'WIFI' ?
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
                          child:historyItemTapped? Text(formatDateTime(DateTime.parse(jsonResult['scannedTime']))) : Icon(Icons.close)
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
                        ElevatedButton(onPressed: () {
                          print("object" + jsonResult['ssid']);
                          callWifiIntent(jsonResult['ssid'], jsonResult['password']);
                        }, child: Text('Connect')),
                        ElevatedButton(onPressed:null, child: Text('Copy')),
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
                          child: ElevatedButton(onPressed:(){
                            callShareIntentWifi(jsonResult["ssid"], jsonResult["password"], jsonResult["type"]);
                          }, child: Text('Share')))),
                )
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
        jsonResult['type'] == 'Text' ?
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
                          child: Text(formatDateTime(jsonResult['scannedTime']))),
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
        jsonResult['type'] == 'Geo' ?
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
                            });
                            Navigator.of(context).pop();
                          },
                          child: Text(formatDateTime(jsonResult['scannedTime']))),
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
        jsonResult['type'] == 'BarCode' ?
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
                            });
                            Navigator.of(context).pop();
                          },
                          child: Text(formatDateTime(jsonResult['scannedTime']))),
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
        jsonResult['type'] == 'Calendar' ?
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
                      const Text('Calendar'),
                      GestureDetector(
                          onTap: () {
                            setState(() {
                              dialogOpen = false;
                            });
                            Navigator.of(context).pop();
                          },
                          child: Text(formatDateTime(jsonResult['scannedTime']))),
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
        jsonResult['type'] == 'Contact' ?
        AlertDialog(
          // title: const Text('Dialog Title'),
          content: Container(
            margin: EdgeInsets.only(top: 10),
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
                          Text("Contact", style: TextStyle(fontSize: 20)),
                          GestureDetector(
                            child: historyItemTapped? Text(formatDateTime(DateTime.parse(jsonResult['scannedTime']))) : Icon(Icons.close),
                            onTap: () {
                              setState(() {
                                dialogOpen = false;
                                vCardTimeStamp = false;
                                historyItemTapped = false;
                              });
                              Navigator.of(context).pop();
                            },
                          ),

                        ]),
                  ),
                ),
                Flexible(
                  flex: 4,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
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
                              Text(jsonResult["FN"] ?? "", style: TextStyle(fontSize: 20)),
                              Text(jsonResult["TEL"] ?? "", style: TextStyle(fontSize: 20)),
                              Text(jsonResult["EMAIL"] ?? "", style: TextStyle(fontSize: 20)),
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
                              padding: EdgeInsets.all(8.0),
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
                                  child: Icon(Icons.call))),
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
                              padding: EdgeInsets.all(8.0),
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
                                  child: Icon(Icons.add_card_outlined))),
                        ),
                      ),
                      Visibility(
                        visible: jsonResult["EMAIL"] != null,
                        child: Flexible(
                          flex: 1,
                          child: Container(
                              width: 80,
                              padding: EdgeInsets.all(8.0),
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
                                  child: Icon(Icons.email))),
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
                          print("type"+jsonResult["type"]);
                          callShareIntent(jsonResult["TEL"] ?? "", jsonResult["EMAIL"] ?? "", jsonResult["FN"] ?? "", jsonResult["type"]);
                        },
                        child: Container(
                            margin: EdgeInsets.only(top: 40),
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
                            child: Text('Share', style: TextStyle(fontSize: 20,color: Colors.black))),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        )://done
        AlertDialog(
          title: const Text('Dialog Title'),
          content: Text(jsonResult.toString()),
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
    await addJsonDataToList(jsonResult);

  }

  callEmailIntent(String email) {
    Map map = {
      "email": email,
    };
    channel.invokeMethod("EMAIL", map);
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
    print("Share" + map.toString());
    channelShare.invokeMethod("SHARE", map);
  }

  callShareIntentWifi(String ssid, String password, String type) {
    Map map = {
      "ssid": ssid,
      "password": password,
      "type": type,
    };
    print("Share" + map.toString());
    channelShare.invokeMethod("SHARE", map);
  }

  callShareIntentURL(String url, String type) {
    Map map = {
      "url": url,
      "type": type,
    };
    print("Share" + map.toString());
    channelShare.invokeMethod("SHARE", map);
  }

  callWifiIntent(String ssid, String password) {
    Map map = {
      "ssid": ssid,
      "password": password,
    };
    channelWifi.invokeMethod("connectToWiFi", map);
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
    super.dispose();
  }
}

