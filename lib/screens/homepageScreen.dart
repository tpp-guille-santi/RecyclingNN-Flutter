import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:recyclingapp/screens/cameraScreen.dart';
import 'package:recyclingapp/screens/informationScreen.dart';
import 'package:recyclingapp/screens/mapScreen.dart';
import 'package:recyclingapp/screens/materialsCatalogueScreen.dart';
import 'package:recyclingapp/utils/markdownManager.dart';
import 'package:recyclingapp/utils/neuralNetworkConnector.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import '../widgets/instructionContent.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';


class Homepage extends StatefulWidget {
  PanelController _panelController = PanelController();

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late CameraController _controller;
  bool _showFab = true;
  late Future<void> _initializeControllerFuture;
  int _index = 1;
  List<Widget> screens = [
    InformationScreen(),
    CameraScreen(
      controller: null,
      future: null,
    ),
    MaterialsCatalogue(),
    MapScreen(panelController: null)
  ];
  late NeuralNetworkConnector cnnConnector;
  MarkdownManager markdownManager = new MarkdownManager();

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _index = index;
      _showFab = (index == 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SlidingUpPanel(
        controller: widget._panelController,
        minHeight: 0,
        maxHeight: MediaQuery.of(context).size.height,
        snapPoint: 0.25,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18.0), topRight: Radius.circular(18.0)),
        panelBuilder: (sc) => instructionContent(sc, context),
        body: Scaffold(
          body: screens.elementAt(_index),
          bottomNavigationBar: NavigationBar(
            destinations: const <NavigationDestination>[
              NavigationDestination(
                selectedIcon: Icon(Icons.school),
                icon: Icon(Icons.school_outlined),
                label: 'Reciclaje',
              ),
              NavigationDestination(
                selectedIcon: Icon(Icons.camera_alt),
                icon: Icon(Icons.camera_alt_outlined),
                label: 'Camera',
              ),
              NavigationDestination(
                selectedIcon: Icon(Icons.view_list),
                icon: Icon(Icons.view_list_outlined),
                label: 'Catálogo',
              ),
              NavigationDestination(
                selectedIcon: Icon(Icons.map),
                icon: Icon(Icons.map_outlined),
                label: 'Mapa',
              ),
            ],
            onDestinationSelected: _onDestinationSelected,
            selectedIndex: _index,
          ),
          floatingActionButton: Visibility(
            visible: _showFab,
            child: FloatingActionButton(
              onPressed: () async {
                try {
                  await _initializeControllerFuture;
                  final image = await _controller.takePicture();
                  //Mandar a red
                  print("saque foto");
                  var material = await cnnConnector.cataloguePicture(image.path);
                  print(material);
                  print("termine de clasificar");
                  /*var instructions =
                      await markdownManager.getInstructions(material);
                  //Pasar a resultado
                  final result = await Navigator.pushNamed(
                    context,
                    '/results',
                    arguments: {
                      'instructions': instructions,
                      'cameraIndex': 1,
                      'catalogueIndex': 2
                    },
                  );
                  print("Returns: $result");
                  _onDestinationSelected(result as int);*/
                } catch (e) {
                  // If an error occurs, log the error to the console.
                  print(e);
                }
              },
              child: const Icon(Icons.camera_alt),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> initialize() async {
    if (await Permission.camera.request().isDenied) {
      exit(0);
    }
    if (await Permission.locationWhenInUse.request().isDenied) {
      exit(0);
    }
    var cameras = await availableCameras();
    _controller = new CameraController(cameras.first, ResolutionPreset.medium,
        enableAudio: false);
    _initializeControllerFuture = _controller.initialize();
    var customModel = await FirebaseModelDownloader.instance
        .getModel(
        "recisnap-nn",
        FirebaseModelDownloadType.localModelUpdateInBackground,
        FirebaseModelDownloadConditions(
          iosAllowsCellularAccess: true,
          iosAllowsBackgroundDownloading: true,
          androidChargingRequired: false,
          androidWifiRequired: false,
          androidDeviceIdleRequired: false,
        )
    );
    var downloadedModel = customModel.file;
    //var assetModel = await copyAssetToFile("assets/model.tflite", "my_model.tflite");
    var labelFile = await copyAssetToFile("assets/labels.txt", "my_labels.txt");
    this.cnnConnector = NeuralNetworkConnector(downloadedModel, labelFile);

    setState(() {
      screens[1] = CameraScreen(
          future: _initializeControllerFuture, controller: _controller);
      screens[3] = MapScreen(panelController: widget._panelController);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<File> copyAssetToFile(String asset, String path) async{
    var bytes = await rootBundle.load(asset);
    final buffer = bytes.buffer;
    final directory = await getApplicationDocumentsDirectory();
    return new File('${directory.path}/$path').writeAsBytes(
        buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
  }
}

