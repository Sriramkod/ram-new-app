import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:progress_dialog2/progress_dialog2.dart';

class PhoneRegistrationScreen extends StatefulWidget {
  @override
  _PhoneRegistrationScreenState createState() =>
      _PhoneRegistrationScreenState();
}

class _PhoneRegistrationScreenState extends State<PhoneRegistrationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  late ProgressDialog _progressDialog;

  String _verificationId = "";

  @override
  void initState() {
    super.initState();
    _progressDialog = ProgressDialog(context);
  }

  Future<void> _verifyPhoneNumber() async {
    try {
      _progressDialog.show();
      await _auth.verifyPhoneNumber(
        phoneNumber: _phoneNumberController.text,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          // The user is already signed in (auto-retrieval of SMS code)
          // Perform any additional logic here if needed
        },
        verificationFailed: (FirebaseAuthException e) {
          throw Exception('Verification Failed: ${e.message}');
        },
        //   codeSent: (String verificationId, int resendToken) {
        //     _progressDialog.hide();
        //     _verificationId = verificationId;
        //   },
        //   codeAutoRetrievalTimeout: (String verificationId) {
        //     // Code auto-retrieval timed out
        //   },
        // );
        codeSent: (String verificationId, int? resendToken) {
          _progressDialog.hide();
          _verificationId = verificationId;
          // Navigator.pushNamed(context, 'otp');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print("Timed out....");
          _progressDialog.hide();
        },
      );
    } catch (e) {
      _progressDialog.hide();
      // Handle registration failure, show error popups
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Registration Failed'),
            content: Text(e.toString()),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _verifyOTP() async {
    try {
      _progressDialog.show();
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Store additional user details in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'phone': userCredential.user!.phoneNumber,
        // Add more fields as needed
      });

      _progressDialog.hide();
      // Redirect to a new screen
      // Navigator.pushReplacementNamed(context, 'register');
      Navigator.pushNamed(context, 'otp');
    } catch (e) {
      _progressDialog.hide();
      // Handle verification failure, show error popups
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Verification Failed'),
            content: Text(e.toString()),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Phone Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _phoneNumberController,
              decoration: InputDecoration(labelText: 'Phone Number'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _verifyPhoneNumber();
              },
              child: Text('Get OTP'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _otpController,
              decoration: InputDecoration(labelText: 'OTP'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _verifyOTP();
              },
              child: Text('Verify OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
