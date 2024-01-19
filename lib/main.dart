import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const MaterialApp(home: MyHome()));

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

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
      if(!dialogOpen){
        _showDialog(context,scanData.code!);
        setState(() {
          dialogOpen = true;
        });
      }
      print("aditya"+scanData.code!.toString());
    });
  }

  void _showDialog(BuildContext context,String url) {
    print('Aditya reached');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Dialog Title'),
          content: Text(url),
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
      },
    );
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