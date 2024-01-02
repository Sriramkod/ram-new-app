import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_2/home.dart';
import 'package:flutter_application_2/index.dart';
import 'package:flutter_application_2/register.dart';
import 'package:flutter_application_2/registration_screen.dart';
import 'firebase_options.dart';
import 'package:flutter_application_2/otp.dart';
import 'package:flutter_application_2/phone.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MaterialApp(
    initialRoute: 'upload-file',
    debugShowCheckedModeBanner: false,
    routes: {
      'upload-file': (context) => UploadApp(),
      'register-with-phone': (context) => PhoneRegistrationScreen(),
      'register': (context) => RegistrationScreen(),
      'phone': (context) => MyPhone(),
      'home': (context) => MyHome(),
      'otp': (context) => MyVerify()
    },
  ));
}
