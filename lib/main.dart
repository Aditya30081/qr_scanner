import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    final jsonStringList = prefs.getStringList('myJsonDataList') ?? [];

    return jsonStringList.map((jsonString) => Map<String, dynamic>.from(json.decode(jsonString))).toList();
  }
  Future<void> saveJsonDataList(List<Map<String, dynamic>> dataList) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStringList = dataList.map((data) => json.encode(data)).toList();

    await prefs.setStringList('myJsonDataList', jsonStringList);
  }

  Future<void> addJsonDataToList(Map<String, dynamic> newData) async {
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
                          icon: Icon(Icons.expand_less,color: Colors.white,size: 34,),),
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
        return Column(
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
                          Text('Scan History',style: TextStyle(color: Colors.black),),
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
            // DynamicBottomSheet()


            !historyItemTapped ?
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
                      const Text('Loaded JSON Data List:', style: TextStyle(fontWeight: FontWeight.bold)),
                      for (Map<String, dynamic> item in loadedList) GestureDetector(
                          onTap:(){
                            setState(() {
                              historyItemTapped = true;
                            });
                            setState(() {

                            });
                            print('historyItemTapped'+historyItemTapped.toString());
                          },
                          child: Text(item.toString())),
                    ],
                  );
                }
              },
            ) : Container(child:const Text('itemTapped'))

          ],
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

        // Handle specific cases, you may need to customize this based on your needs
        if (key == 'N') {
          // Split the name into parts
          List<String> nameParts = value.split(';');
          jsonResult['firstName'] = nameParts[1].trim();
          jsonResult['lastName'] = nameParts[0].trim();
        } else if (key.contains('TEL;')){
          jsonResult['TEL'] = value;
        } else if (key.contains('EMAIL;')){
          jsonResult['EMAIL'] = value;
        }
        else {
          // Store other fields directly
          jsonResult[key] = value;
        }
      }
    }

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

    return jsonResult;
  }

  void _showDialog(BuildContext context,String url,String type)  async{
    Map<String, dynamic> jsonResult;
    if(type == 'VCARD'){
      jsonResult= vCardToJSON(url);

      print("jsonResult$jsonResult");
      print("jsonResult${jsonResult["lastName"]}");
    }
    else if( type == 'WebUrl'){
      jsonResult = {'Web Url': url};
    }
    else if( type == 'WIFI'){
      jsonResult = wifiToJSON(url);
    }
    else {
      jsonResult = {'Blank': ''};
    }
    print("TYPE: $type");
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
                            child: Icon(Icons.close),
                            onTap: () {
                              setState(() {
                                dialogOpen = false;
                              });
                              Navigator.of(context).pop();
                            },
                          )
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
                              Text(jsonResult["FN"], style: TextStyle(fontSize: 20)),
                              Text(jsonResult["TEL"], style: TextStyle(fontSize: 20)),
                              Text(jsonResult["EMAIL"], style: TextStyle(fontSize: 20)),
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
                      Flexible(
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
                              // call method channel
                            },
                                child: Icon(Icons.call))),
                      ),
                      Flexible(
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
                            child: Icon(Icons.call)),
                      ),
                      Flexible(
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
                            child: Icon(Icons.call)),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
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
                )
              ],
            ),
          ),
          /*actions: [
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
          ],*/
        );
      },
    );
    // await addJsonDataToList(jsonResult);

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

class DynamicBottomSheet extends StatefulWidget {
  @override
  _DynamicBottomSheetState createState() => _DynamicBottomSheetState();
}

class _DynamicBottomSheetState extends State<DynamicBottomSheet> {
  List<Widget> items = [];

  @override
  void initState() {
    super.initState();
    // Initial items
    items = [
      ListTile(
        leading: const Icon(Icons.ac_unit),
        title: const Text('Item 1'),
        onTap: () {
          // Handle tap for Item 1
        },
      ),
      ListTile(
        leading: const Icon(Icons.access_alarm),
        title: const Text('Item 2'),
        onTap: () {
          // Handle tap for Item 2
        },
      ),
    ];
  }

  void _updateItems() {
    // Change items based on a condition
    setState(() {
      items = [
        ListTile(
          leading: const Icon(Icons.directions_car),
          title: const Text('Car'),
          onTap: () {
            // Handle tap for Car
          },
        ),
        ListTile(
          leading: const Icon(Icons.directions_bike),
          title: const Text('Bike'),
          onTap: () {
            // Handle tap for Bike
          },
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _updateItems,
          child: const Text('Change Items'),
        ),
        // Display dynamic items in the bottom sheet
        ...items,
      ],
    );
  }
}