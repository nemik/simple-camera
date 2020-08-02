import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kid_camera/shutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class GalleryPage extends StatefulWidget {
  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  FileSystemEntity current_file;

  Future<List<FileSystemEntity>> getFiles() async {
    final Directory extDir = await getExternalStorageDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    return Directory(dirPath).listSync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*
      appBar: AppBar(
        title: Text('Gallery'),
      ),
      */
      // Implemented with a PageView, simpler than setting it up yourself
      // You can either specify images directly or by using a builder as in this tutorial
      body: new FutureBuilder<List>(
        future: getFiles(),
        builder: (context, photos) {
          if (photos.hasError) print(photos.error);

          if (current_file == null && photos.hasData && photos.data.length > 0) {
            current_file = photos.data.reversed.toList()[0];
            print("init ${current_file}");
          }

          return photos.hasData && photos.data.length > 0
              ? new Stack(children: [
                  new PhotoViewGallery.builder(
                      scrollDirection: Axis.vertical,
                      enableRotation: true,
                      onPageChanged: (index) {
                        setState(() {
                          current_file = photos.data.reversed.toList()[index];
                        });
                        print("onpagechanged ${current_file}");
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
                            /*
                            final snackBar = SnackBar(
                                content: Text('Yay! ' + current_file.path));
                            // Find the Scaffold in the widget tree and use it to show a SnackBar.
                            Scaffold.of(context).showSnackBar(snackBar);
                            */
                            print("DELETING ${current_file}");

                            try {
                              current_file.deleteSync();
                            } finally {
                              setState(() {});
                            }
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
              /*
              new GridView.builder(
                  itemCount: photos.data.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 4.0,
                      mainAxisSpacing: 4.0),
                  itemBuilder: (BuildContext context, int index) {
                    return Image.file(photos.data[index]);
                  })
                  */
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

      /*
      PhotoViewGallery.builder(
        itemCount: imageList.length,
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(
              imageList[index],
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
          color: Theme.of(context).canvasColor,
        ),
        loadingChild: Center(
          child: CircularProgressIndicator(),
        ),
        */
    );
  }
}
