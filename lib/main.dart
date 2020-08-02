// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_camera/gallery.dart';
import 'package:simple_camera/shutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class CameraExampleHome extends StatefulWidget {
  @override
  _CameraExampleHomeState createState() {
    return _CameraExampleHomeState();
  }
}

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.landscape;
    case CameraLensDirection.front:
      return Icons.person;
    case CameraLensDirection.external:
      return Icons.camera;
  }
  throw ArgumentError('Unknown lens direction');
}

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

class _CameraExampleHomeState extends State<CameraExampleHome>
    with WidgetsBindingObserver {
  CameraController controller;
  String imagePath;
  String videoPath;
  VideoPlayerController videoController;
  VoidCallback videoPlayerListener;
  bool enableAudio = false;
  bool shutterDone = true;
  CameraDescription currentCam;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        onNewCameraSelected(controller.description);
      }
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    Widget camPreview = _cameraPreviewWidget();
    if (!shutterDone) {
      camPreview = InkWell(
        splashColor: Colors.black,
        highlightColor: Colors.white,
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      /*
      appBar: AppBar(
        title: const Text('Super Fun Camera'),
      ),
      */
      body: Stack(alignment: FractionalOffset.center, children: <Widget>[
        camPreview,
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            _captureControlRowWidget(),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: CircleButton(
              iconData: Icons.photo_library,
              color: Colors.purpleAccent,
              iconColor: Colors.black,
              size: 50,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GalleryPage()),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 38.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _cameraTogglesRowWidget(),
            ),
          ),
        ),
      ]
          //_toggleAudioWidget(),
          ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Tap a camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      final size = MediaQuery.of(context).size;
      final deviceRatio = size.width / size.height;
      return Stack(children: <Widget>[
        Center(
          child: Transform.scale(
            scale: controller.value.aspectRatio / deviceRatio,
            child: new AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: new CameraPreview(controller),
            ),
          ),
        )
      ]);
    }
  }

  /// Display the control bar with buttons to take pictures and record videos.
  Widget _captureControlRowWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Padding(
            padding: EdgeInsets.all(36.0),
            child: CircleButton(
                iconData: Icons.camera,
                size: 80,
                iconSize: 50,
                onTap: () {
                  if (controller != null &&
                      controller.value.isInitialized &&
                      !controller.value.isRecordingVideo) {
                    onTakePictureButtonPressed();
                    setState(() {
                      shutterDone = false;
                    });
                  }
                },
                color: Colors.red[300]))
        /*
        IconButton(
          icon: const Icon(Icons.camera_alt),
          color: Colors.red,
          iconSize: 40,
          onPressed: controller != null &&
                  controller.value.isInitialized &&
                  !controller.value.isRecordingVideo
              ? onTakePictureButtonPressed
              : null,
        ),
        */
      ],
    );
  }

  /// Display a row of toggle to select the camera (or a message if no camera is available).
  List<Widget> _cameraTogglesRowWidget() {
    final List<Widget> toggles = <Widget>[];

    if (cameras.isEmpty) {
      return [const Text('No camera found')];
    } else {
      for (CameraDescription cameraDescription in cameras) {
        /*
        if (cameraDescription.lensDirection == CameraLensDirection.back &&
            have_landscape == true) {
          continue;
        } else {
          have_landscape = true;
          if (controller == null || controller.value.isRecordingVideo) {
            onNewCameraSelected(cameraDescription);
          }
        }

        if (cameraDescription.lensDirection == CameraLensDirection.front &&
            have_portrait == true) {
          //continue;
        } else {
          have_portrait = true;
        }
        */

        if (toggles.length == 2) {
          continue;
        }

        toggles.add(
          CircleButton(
              iconData: getCameraLensIcon(cameraDescription.lensDirection),
              color: Colors.green,
              iconColor: Colors.black,
              size: 40,
              onTap: () {
                //showInSnackBar('Camera: ${controller}');
                if (controller == null || !controller.value.isRecordingVideo) {
                  onNewCameraSelected(cameraDescription);
                  setState(() {
                    currentCam = cameraDescription;
                  });
                  //showInSnackBar('Camera desc ${cameraDescription}');
                }
              }),
        );

        if (controller == null) {
          onNewCameraSelected(cameraDescription);
          setState(() {
            currentCam = cameraDescription;
          });
          //showInSnackBar('Camera desc ${cameraDescription}');
        }
      }
    }

    return toggles;
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.veryHigh,
      enableAudio: enableAudio,
    );

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        showInSnackBar('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onTakePictureButtonPressed() {
    takePicture().then((String filePath) {
      if (mounted) {
        setState(() {
          imagePath = filePath;
          videoController?.dispose();
          videoController = null;
        });
        if (filePath != null) {
          //showInSnackBar('Picture saved to $filePath');
        }
        setState(() {
          shutterDone = true;
        });
      }
    });
  }

  void onVideoRecordButtonPressed() {
    startVideoRecording().then((String filePath) {
      if (mounted) setState(() {});
      if (filePath != null) showInSnackBar('Saving video to $filePath');
    });
  }

  void onStopButtonPressed() {
    stopVideoRecording().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video recorded to: $videoPath');
    });
  }

  void onPauseButtonPressed() {
    pauseVideoRecording().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video recording paused');
    });
  }

  void onResumeButtonPressed() {
    resumeVideoRecording().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video recording resumed');
    });
  }

  Future<String> startVideoRecording() async {
    if (!controller.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Movies/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.mp4';

    if (controller.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return null;
    }

    try {
      videoPath = filePath;
      await controller.startVideoRecording(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  Future<void> stopVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }

    await _startVideoPlayer();
  }

  Future<void> pauseVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.pauseVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> resumeVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.resumeVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> _startVideoPlayer() async {
    final VideoPlayerController vcontroller =
        VideoPlayerController.file(File(videoPath));
    videoPlayerListener = () {
      if (videoController != null && videoController.value.size != null) {
        // Refreshing the state to update video player with the correct ratio.
        if (mounted) setState(() {});
        videoController.removeListener(videoPlayerListener);
      }
    };
    vcontroller.addListener(videoPlayerListener);
    await vcontroller.setLooping(true);
    await vcontroller.initialize();
    await videoController?.dispose();
    if (mounted) {
      setState(() {
        imagePath = null;
        videoController = vcontroller;
      });
    }
    await vcontroller.play();
  }

  Future<String> takePicture() async {
    if (!controller.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }
    final Directory extDir = await getExternalStorageDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      await controller.takePicture(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }
}

class CameraApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraExampleHome(),
      debugShowCheckedModeBanner: false
    );
  }
}

List<CameraDescription> cameras = [];

Future<void> main() async {
  // Fetch the available cameras before initializing the app.
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    logError(e.code, e.description);
  }
  runApp(CameraApp());
}
