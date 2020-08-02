import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:simple_camera/shutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:wc_flutter_share/wc_flutter_share.dart';

class GalleryPage extends StatefulWidget {
  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  FileSystemEntity currentFile;

  Future<List<FileSystemEntity>> getFiles() async {
    final Directory extDir = await getExternalStorageDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    return Directory(dirPath).listSync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: new FutureBuilder<List>(
        future: getFiles(),
        builder: (context, photos) {
          if (photos.hasError) print(photos.error);

          if (currentFile != null &&
              !currentFile.existsSync() &&
              photos.hasData &&
              photos.data.length > 0) {
            currentFile = photos.data.reversed.toList()[0];
            print("init not found $currentFile");
          }

          if (currentFile == null &&
              photos.hasData &&
              photos.data.length > 0) {
            currentFile = photos.data.reversed.toList()[0];
            print("init null $currentFile");
          }

          return photos.hasData && photos.data.length > 0
              ? new Stack(children: [
                  new PhotoViewGallery.builder(
                      scrollDirection: Axis.vertical,
                      enableRotation: true,
                      onPageChanged: (index) {
                        setState(() {
                          currentFile = photos.data.reversed.toList()[index];
                        });
                        print("onpagechanged $currentFile");
                      },
                      itemCount: photos.data.length,
                      builder: (context, index) {
                        return PhotoViewGalleryPageOptions(
                          imageProvider: FileImage(
                            photos.data.reversed.toList()[index],
                          ),
                          // Contained = the smallest possible size to fit one dimension of the screen
                          minScale: PhotoViewComputedScale.contained * 0.8,
                          // Covered = the smallest possible size to fit the whole screen
                          maxScale: PhotoViewComputedScale.covered * 2,
                        );
                      },
                      scrollPhysics: BouncingScrollPhysics(),
                      // Set the background color to the "classic white"
                      backgroundDecoration: BoxDecoration(
                          //color: Theme.of(context).canvasColor,
                          color: Colors.amber[100]),
                      loadingChild: Center(
                        child: CircularProgressIndicator(),
                      )),
                  new Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: CircleButton(
                          iconData: Icons.delete,
                          color: Colors.red,
                          onTap: () {
                            print("DELETING $currentFile");
                            try {
                              currentFile.deleteSync();
                            } finally {
                              setState(() {});
                            }
                          },
                        ),
                      )),
                  new Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: CircleButton(
                          iconData: Icons.share,
                          color: Colors.orange,
                          onTap: () {
                            File img = File(currentFile.path);
                            Uint8List bytes = img.readAsBytesSync();
                            WcFlutterShare.share(
                                    sharePopupTitle: 'share',
                                    fileName: 'share.png',
                                    mimeType: 'image/png',
                                    bytesOfFile: bytes)
                                .then((value) => null);
                          },
                        ),
                      )),
                  new Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: new CircleButton(
                            iconData: Icons.add_a_photo,
                            iconColor: Colors.black,
                            color: Colors.blue[300],
                            size: 80,
                            onTap: () {
                              Navigator.pop(context);
                            },
                          )))
                ])
              : new Center(
                  child: new Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      //new CircularProgressIndicator(),
                      new Text(
                        "No Pictures",
                        style: TextStyle(fontSize: 34.0),
                      ),
                      new SizedBox(height: 100),
                      new CircleButton(
                        iconData: Icons.add_a_photo,
                        iconColor: Colors.black,
                        color: Colors.blue[300],
                        size: 80,
                        onTap: () {
                          Navigator.pop(context);
                        },
                      )
                    ]));
        },
      ),
    );
  }
}
