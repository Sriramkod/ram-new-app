import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';

import 'package:progress_dialog2/progress_dialog2.dart';

class UploadApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FileUploadScreen(),
    );
  }
}

class FirestoreService {
  final CollectionReference filesCollection =
      FirebaseFirestore.instance.collection('files');

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> uploadFile(String filePath) async {
    File file = File(filePath);
    String fileName = file.path.split('/').last;

    try {
      // Upload file to Firebase Storage
      TaskSnapshot uploadTask =
          await _storage.ref('files/$fileName').putFile(file);

      // Get the download URL
      String downloadUrl = await uploadTask.ref.getDownloadURL();

      // Add file reference to Firestore
      await filesCollection.add({
        'filename': fileName,
        'downloadUrl': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('File uploaded successfully.');
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  Stream<QuerySnapshot> getFiles() {
    return filesCollection.orderBy('timestamp', descending: true).snapshots();
  }
}

// class FileUploadScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('File Upload'),
//       ),
//       body: FileListWidget(),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () async {
//           if (await PermissionHandlerUtil.requestStoragePermission()) {
//             String? filePath = await FilePicker.platform
//                 .pickFiles()
//                 .then((value) => value?.files.single.path);

//             if (filePath != null) {
//               await FirestoreService().uploadFile(filePath);
//             }
//           } else {
//             // Handle permission denial
//             // You might want to show a message or request again later
//             print('Storage permission denied');
//           }
//         },
//         child: Icon(Icons.file_upload),
//       ),
//     );
//   }
// }

// ...

class FileListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirestoreService().getFiles(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        var files = snapshot.data!.docs;

        return ListView.builder(
          itemCount: files.length,
          itemBuilder: (context, index) {
            var file = files[index].data() as Map<String, dynamic>;
            String fileName = file['filename'];
            String downloadUrl = file['downloadUrl'];

            return ListTile(
              title: Text(fileName),
              trailing: IconButton(
                icon: Icon(Icons.file_download),
                onPressed: () async {
                  await downloadFile(context, downloadUrl, fileName);
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> downloadFile(
      BuildContext context, String downloadUrl, String fileName) async {
    ProgressDialog pr = ProgressDialog(context);
    pr.style(message: 'Downloading...');

    try {
      await pr.show();

      final response = await http.get(Uri.parse(downloadUrl));

      if (response.statusCode == 200) {
        final fileBytes = response.bodyBytes;

        // Get the temporary directory using path_provider
        Directory tempDir = await getTemporaryDirectory();
        String tempPath = tempDir.path;

        // Create a File instance and write the file bytes
        File file = File('$tempPath/$fileName');
        await file.writeAsBytes(fileBytes);

        pr.hide();

        // Open the file with the default file viewer
        OpenFile.open(file.path);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('File downloaded successfully.'),
        ));
      } else {
        pr.hide();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to download file. Please try again.'),
        ));
      }
    } catch (e) {
      pr.hide();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
      ));
    }
  }
}

class FileUploadScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ram\'s Upload\'s...,'),
      ),
      body: FileListWidget(),
      floatingActionButton: UploadButton(),
    );
  }
}

class UploadButton extends StatefulWidget {
  @override
  _UploadButtonState createState() => _UploadButtonState();
}

class _UploadButtonState extends State<UploadButton> {
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _uploading
          ? null
          : () async {
              if (await PermissionHandlerUtil.requestStoragePermission()) {
                setState(() {
                  _uploading = true;
                });

                String? filePath = await FilePicker.platform
                    .pickFiles()
                    .then((value) => value?.files.single.path);

                if (filePath != null) {
                  await FirestoreService().uploadFile(filePath);
                }

                setState(() {
                  _uploading = false;
                });
              } else {
                // Show a message to the user explaining why the permission is necessary
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Permission Required'),
                    content: Text(
                        'To upload files, we need storage permission. Please grant the permission in settings.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
      child: _uploading
          ? CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
          : Icon(Icons.file_upload),
    );
  }
}

// class FileListWidget extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder(
//       stream: FirestoreService().getFiles(),
//       builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
//         if (!snapshot.hasData) {
//           return Center(
//             child: CircularProgressIndicator(),
//           );
//         }

//         var files = snapshot.data!.docs;

//         return ListView.builder(
//           itemCount: files.length,
//           itemBuilder: (context, index) {
//             var file = files[index].data() as Map<String, dynamic>;
//             String fileName = file['filename'];
//             String downloadUrl = file['downloadUrl'];

//             return ListTile(
//               title: Text(fileName),
//               trailing: IconButton(
//                 icon: Icon(Icons.file_download),
//                 onPressed: () async {
//                   await downloadFile(context, downloadUrl, fileName);
//                 },
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Future<void> downloadFile(
//       BuildContext context, String downloadUrl, String fileName) async {
//     ProgressDialog pr = ProgressDialog(context);
//     pr.style(message: 'Downloading...');

//     try {
//       await pr.show();

//       final response = await http.get(Uri.parse(downloadUrl));

//       if (response.statusCode == 200) {
//         final fileBytes = response.bodyBytes;

//         // Save the file to the device
//         await FilePicker.platform
//             .saveFile(
//           fileName: fileName,
//           bytes: fileBytes,
//           allowCompression: true,
//           type: FileType.any,
//         )
//             .then((_) {
//           pr.hide();
//           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//             content: Text('File downloaded successfully.'),
//           ));
//         });
//       } else {
//         pr.hide();
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text('Failed to download file. Please try again.'),
//         ));
//       }
//     } catch (e) {
//       pr.hide();
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text('Error: $e'),
//       ));
//     }
//   }
// }
// class FileListWidget extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<bool>(
//       future: PermissionHandlerUtil.checkStoragePermission(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(
//             child: CircularProgressIndicator(),
//           );
//         }

//         bool hasStoragePermission = snapshot.data ?? false;

//         if (!hasStoragePermission) {
//           // Handle permission denial when listing files
//           // You might want to show a message or request again later
//           return Center(
//             child: Text('Storage permission denied'),
//           );
//         }

//         return StreamBuilder(
//           stream: FirestoreService().getFiles(),
//           builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
//             if (!snapshot.hasData) {
//               return Center(
//                 child: CircularProgressIndicator(),
//               );
//             }

//             var files = snapshot.data!.docs;

//             return ListView.builder(
//               itemCount: files.length,
//               itemBuilder: (context, index) {
//                 var file = files[index].data() as Map<String, dynamic>;
//                 String fileName = file['filename'];
//                 String downloadUrl = file['downloadUrl'];

//                 return ListTile(
//                   title: Text(fileName),
//                   trailing: IconButton(
//                     icon: Icon(Icons.file_download),
//                     onPressed: () {
//                       // Implement file downloading logic using the 'downloadUrl'
//                       // For example, you can use the url_launcher package to open the URL in a web browser.
//                     },
//                   ),
//                 );
//               },
//             );
//           },
//         );
//       },
//     );
//   }
// }

class PermissionHandlerUtil {
  static Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.request();
    return status == PermissionStatus.granted;
  }

  static Future<bool> checkStoragePermission() async {
    var status = await Permission.storage.status;
    return status == PermissionStatus.granted;
  }
}
