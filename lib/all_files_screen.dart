import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:upload_file/upload_screen.dart';

class AllFilesScreen extends StatefulWidget {
  const AllFilesScreen({Key? key}) : super(key: key);

  @override
  State<AllFilesScreen> createState() => _AllFilesScreenState();
}

class _AllFilesScreenState extends State<AllFilesScreen> {
  late Future<ListResult> futureFiles;
  Map<int, double> downloadProgress = {};

  @override
  void initState() {
    super.initState();
    futureFiles = FirebaseStorage.instance.ref('/files').listAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Download Files'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.upload),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UploadScreen(),
            ),
          );
        },
      ),
      body: FutureBuilder(
        future: futureFiles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            final files = snapshot.data!.items;
            return ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                double? progress = downloadProgress[index];
                return ListTile(
                  title: Text(file.name),
                  subtitle: progress != null
                      ? LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.black26,
                        )
                      : null,
                  trailing: IconButton(
                    onPressed: () async{
                      await downloadFile(progress, index, file);
                      setState(() {
                        progress = null;
                      });
                    },
                    icon: const Icon(
                      Icons.download,
                      color: Colors.black,
                    ),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error occurred'));
          } else {
            return const Center(
              child: Text(
                'No Data',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Future downloadFile(double? progress, int index, Reference ref) async {
    // final dir = await getApplicationDocumentsDirectory();
    // final file = File('${dir.path}/${ref.name}');
    // await ref.writeToFile(file);

    final url = await ref.getDownloadURL();
    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/${ref.name}';
    await Dio().download(url, path, onReceiveProgress: (received, total) {
      double progress = received / total;
      setState(() {
        downloadProgress[index] = progress;
      });
    });

    if (url.contains('.mp4')) {
      await GallerySaver.saveVideo(path, toDcim: true);
    } else if (url.contains('.jpg') ||
        url.contains('.jpeg') ||
        url.contains('.png')) {
      await GallerySaver.saveImage(path, toDcim: true);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloaded ${ref.name}'),
        backgroundColor: Colors.green,
      ),
    );
    setState(() {
      progress = null;
    });
  }
}
