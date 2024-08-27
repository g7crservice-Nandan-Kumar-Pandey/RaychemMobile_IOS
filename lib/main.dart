import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.camera.request();
  await FlutterDownloader.initialize(); // Initialize the downloader
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: InAppWebViewExample(),
    );
  }
}
class InAppWebViewExample extends StatefulWidget {
  @override
  _InAppWebViewExampleState createState() => _InAppWebViewExampleState();
}

class _InAppWebViewExampleState extends State<InAppWebViewExample> {
  late InAppWebViewController _webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: SafeArea(
        child: InAppWebView(
          initialOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(
              supportZoom: false,
              javaScriptEnabled: true,
            ),
            android: AndroidInAppWebViewOptions(
              useHybridComposition: true,
            ),
            ios: IOSInAppWebViewOptions(
              allowsInlineMediaPlayback: true,
              allowsAirPlayForMediaPlayback: true,
            ),
          ),
          initialUrlRequest: URLRequest(
            url: WebUri("https://raychemdevsa.z29.web.core.windows.net/oAuth/login/"),
          ),
          onWebViewCreated: (InAppWebViewController controller) {
            _webViewController = controller;

            // Add JavaScript channels
            _webViewController.addJavaScriptHandler(
              handlerName: 'shareApp',
              callback: (args) async {
                _shareCurrentUrl();
                return {'status': 'success'};
              },
            );

            _webViewController.addJavaScriptHandler(
              handlerName: 'requestLocation',
              callback: (args) async {
                try {
                  Position position = await _determinePosition();
                  return {
                    'latitude': position.latitude,
                    'longitude': position.longitude,
                  };
                } catch (e) {
                  return {
                    'error': e.toString(),
                  };
                }
              },
            );

        
          },
          onPermissionRequest: (controller, request) async {
            return PermissionResponse(
              resources: request.resources,
              action: PermissionResponseAction.GRANT,
            );
          },
          onLoadStart: (InAppWebViewController controller, WebUri? url) {
            print("Loading started: ${url?.toString()}");
          },
          onLoadStop: (InAppWebViewController controller, WebUri? url) {
            print("Loading stopped: ${url?.toString()}");
            // String baseUrl = extractBaseUrl(url?.toString());  
         _startDownload(url?.toString());  
          },
        ),
      ),
    );
  }

  void _shareCurrentUrl() async {
    final url = await _webViewController.getUrl();
    if (url != null) {
      Share.share('Check out this link: $url');
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _startDownload( url) async {
    print("Download request started: $url");

    final directory = await getApplicationDocumentsDirectory();
    final savedDir = Directory(directory.path);

    if (!(await savedDir.exists())) {
      await savedDir.create();
    }

    try {
      final taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: directory.path,
        showNotification: true,
        openFileFromNotification: true,
        saveInPublicStorage: false, // Use false for iOS
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download started: $url')),
      );
    } catch (error) {
      print("Error during download: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during download: $error')),
      );
    }
  }

 
}
