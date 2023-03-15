import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:upload_file/all_files_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({Key? key}) : super(key: key);

  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  PlatformFile? pickedFile;
  UploadTask? uploadTask;

  Future selectFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;
    setState(() {
      pickedFile = result.files.first;
    });
  }

  Future uploadFile() async {
    if (pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please, select file'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      final path = 'files/${pickedFile!.name}';
      final file = File(pickedFile!.path!);
      final ref = FirebaseStorage.instance.ref().child(path);
      setState(() {
        uploadTask = ref.putFile(file);
      });
      final snapshot = await uploadTask!.whenComplete(() {});
      final urlDownload = await snapshot.ref.getDownloadURL();
      print('Download Link: $urlDownload');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload file successfully'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        uploadTask = null;
        pickedFile = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Upload File'),
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AllFilesScreen(),
              ),
            );
            setState(() {});
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pickedFile != null)
            Expanded(
              child: Container(
                height: 200,
                color: Colors.blue[100],
                child: Center(
                  child: pickedFile!.name.contains('.jpg') ||
                          pickedFile!.name.contains('.jpeg') ||
                          pickedFile!.name.contains('.png')
                      ? Image.file(
                          File(pickedFile!.path!),
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Text(pickedFile!.name.toString()),
                ),
              ),
            ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: ElevatedButton(
              onPressed: selectFile,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 50),
              ),
              child: const Text('Select File'),
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: ElevatedButton(
              onPressed: uploadFile,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 50),
              ),
              child: const Text('Upload File'),
            ),
          ),
          const SizedBox(height: 30),
          buildProgress(),
        ],
      ),
    );
  }

  Widget buildProgress() => StreamBuilder(
        stream: uploadTask?.snapshotEvents,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data!;
            double progress = data.bytesTransferred / data.totalBytes;
            return SizedBox(
              height: 50,
              child: uploadTask != null
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey,
                            color: Colors.green,
                          ),
                          Center(
                            child: Text(
                              '${(100 * progress).roundToDouble()}%',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
            );
          } else {
            return const SizedBox(height: 50);
          }
        },
      );
}
