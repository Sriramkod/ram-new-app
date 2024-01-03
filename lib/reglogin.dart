import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:progress_dialog2/progress_dialog2.dart';

void main() {
  runApp(RegLoginHome());
}

class RegLoginHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthenticationWrapper(),
    );
  }
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  @override
  void initState() {
    super.initState();
    checkAuthenticationStatus();
  }

  void checkAuthenticationStatus() {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is already authenticated, navigate to the home page.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(user)),
      );
    } else {
      // User is not authenticated, continue with registration or login flow.
      // Display the registration page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RegistrationPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // You can replace it with your UI
      ),
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  @override
  _AuthenticationWrapperState createState() => _AuthenticationWrapperState();
}

// class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
//   @override
//   void initState() {
//     super.initState();
//     checkAuthenticationStatus();
//   }

// void checkAuthenticationStatus() {
//   User? user = FirebaseAuth.instance.currentUser;

//   if (user != null) {
//     // User is already authenticated, navigate to the home page.
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => HomePage(user)),
//     );
//   }
//   // User is not authenticated, continue with registration or login flow.
// }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: CircularProgressIndicator(), // You can replace it with your UI
//       ),
//     );
//   }
// }

// class RegistrationPage extends StatelessWidget {
//   final TextEditingController phoneNumberController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Registration Page'),
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             TextField(
//               controller: phoneNumberController,
//               decoration: InputDecoration(labelText: 'Phone Number'),
//             ),
//             SizedBox(height: 16.0),
//             ElevatedButton(
//               onPressed: () async {
//                 await verifyPhoneNumber(phoneNumberController.text, context);
//               },
//               child: Text('Register'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> verifyPhoneNumber(
//       String phoneNumber, BuildContext context) async {
//     await FirebaseAuth.instance.verifyPhoneNumber(
//       phoneNumber: phoneNumber,
//       verificationCompleted: (PhoneAuthCredential credential) async {
//         await FirebaseAuth.instance.signInWithCredential(credential);
//         // After successful login, navigate to the home page
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//               builder: (context) =>
//                   HomePage(FirebaseAuth.instance.currentUser!)),
//         );
//       },
//       verificationFailed: (FirebaseAuthException e) {
//         // Handle verification failure
//         print('Verification Failed: $e');
//       },
//       codeSent: (String verificationId, int? resendToken) {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => OtpVerificationScreen(verificationId),
//           ),
//         );
//       },
//       codeAutoRetrievalTimeout: (String verificationId) {
//         // Auto-retrieval timed out
//         print('Code Auto Retrieval Timeout');
//       },
//     );
//   }
// }

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController phoneNumberController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final ProgressDialog _progressDialog;
  //= ProgressDialog();

  @override
  Widget build(BuildContext context) {
    _progressDialog = ProgressDialog(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Registration Page'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: phoneNumberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: 'Phone Number'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                await _verifyPhoneNumber(phoneNumberController.text, context);
              },
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyPhoneNumber(
      String phoneNumber, BuildContext context) async {
    // Phone number validation for Indian numbers
    if (phoneNumber.isEmpty) {
      _showErrorDialog('Please enter a phone number.');
      return;
    }

    // Regular expression for validating Indian phone numbers
    RegExp indianNumberRegExp = RegExp(r'^\+91[1-9]\d{9}$');
    if (!indianNumberRegExp.hasMatch(phoneNumber)) {
      _showErrorDialog('Please enter a valid Indian phone number.');
      return;
    }

    _progressDialog.show();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          // After successful login, navigate to the home page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => HomePage(_auth.currentUser!)),
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          _progressDialog.hide();
          _showErrorDialog('Verification Failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          _progressDialog.hide();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(verificationId),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _progressDialog.hide();
          _showErrorDialog('Code Auto Retrieval Timeout');
        },
      );
    } catch (e) {
      _progressDialog.hide();
      _showErrorDialog('An error occurred: $e');
    }
  }

  // Future<void> _verifyPhoneNumber(
  //     String phoneNumber, BuildContext context) async {
  //   // Phone number validation
  //   if (phoneNumber.isEmpty) {
  //     _showErrorDialog('Please enter a phone number.');
  //     return;
  //   }

  //   if (!RegExp(r'^\+\d{1,3}-\d{6,14}$').hasMatch(phoneNumber)) {
  //     _showErrorDialog('Please enter a valid phone number.');
  //     return;
  //   }

  //   _progressDialog.show();

  //   try {
  //     await _auth.verifyPhoneNumber(
  //       phoneNumber: phoneNumber,
  //       verificationCompleted: (PhoneAuthCredential credential) async {
  //         await _auth.signInWithCredential(credential);
  //         // After successful login, navigate to the home page
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(
  //               builder: (context) => HomePage(_auth.currentUser!)),
  //         );
  //       },
  //       verificationFailed: (FirebaseAuthException e) {
  //         _progressDialog.hide();
  //         _showErrorDialog('Verification Failed: ${e.message}');
  //       },
  //       codeSent: (String verificationId, int? resendToken) {
  //         _progressDialog.hide();
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => OtpVerificationScreen(verificationId),
  //           ),
  //         );
  //       },
  //       codeAutoRetrievalTimeout: (String verificationId) {
  //         _progressDialog.hide();
  //         _showErrorDialog('Code Auto Retrieval Timeout');
  //       },
  //     );
  //   } catch (e) {
  //     _progressDialog.hide();
  //     _showErrorDialog('An error occurred: $e');
  //   }
  // }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;

  OtpVerificationScreen(this.verificationId);

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final ProgressDialog _progressDialog;
  //= ProgressDialog();

  @override
  Widget build(BuildContext context) {
    _progressDialog = ProgressDialog(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('OTP Verification'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Enter OTP'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                await _verifyOtp(otpController.text, context);
              },
              child: Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyOtp(String smsCode, BuildContext context) async {
    // OTP validation
    if (smsCode.isEmpty) {
      _showErrorDialog('Please enter the OTP.');
      return;
    }

    _progressDialog.show();

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: smsCode,
      );

      await _auth.signInWithCredential(credential);

      _progressDialog.hide();

      // After successful login, navigate to the additional details page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdditionalDetailsPage()),
      );
    } catch (e) {
      _progressDialog.hide();
      _showErrorDialog('Invalid OTP. Please try again.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

// class OtpVerificationScreen extends StatelessWidget {
//   final String verificationId;
//   final TextEditingController otpController = TextEditingController();

//   OtpVerificationScreen(this.verificationId);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('OTP Verification'),
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             TextField(
//               controller: otpController,
//               decoration: InputDecoration(labelText: 'Enter OTP'),
//             ),
//             SizedBox(height: 16.0),
//             ElevatedButton(
//               onPressed: () async {
//                 await signInWithPhoneNumber(
//                     verificationId, otpController.text, context);
//               },
//               child: Text('Verify'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> signInWithPhoneNumber(
//       String verificationId, String smsCode, BuildContext context) async {
//     PhoneAuthCredential credential = PhoneAuthProvider.credential(
//       verificationId: verificationId,
//       smsCode: smsCode,
//     );

//     await FirebaseAuth.instance.signInWithCredential(credential);

//     // After successful login, navigate to the additional details page
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => AdditionalDetailsPage()),
//     );
//   }
// }

class AdditionalDetailsPage extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Additional Details'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                await storeUserDetails(
                  FirebaseAuth.instance.currentUser!.uid,
                  nameController.text,
                  passwordController.text,
                );

                // After storing details, navigate to the home page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          HomePage(FirebaseAuth.instance.currentUser!)),
                );
              },
              child: Text('Complete Registration'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> storeUserDetails(
      String uid, String name, String password) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': name,
      'password': password,
    });
  }
}

class HomePage extends StatelessWidget {
  final User user;

  HomePage(this.user);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, ${user.displayName}!'),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AuthenticationWrapper()),
                );
              },
              child: Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}
