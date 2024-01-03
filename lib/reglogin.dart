import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/index.dart';
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

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController phoneNumberController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final ProgressDialog _progressDialog;
  // = ProgressDialog();

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
                await _checkExistingUserAndRegister(
                    phoneNumberController.text, context);
              },
              child: Text('Register'),
            ),
            SizedBox(height: 16.0),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkExistingUserAndRegister(
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
      // Check if the user already exists in Firestore
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // User already exists, show an error
        _progressDialog.hide();
        _showErrorDialog('User with this phone number already exists.');
      } else {
        // User doesn't exist, proceed with phone number verification
        await _verifyPhoneNumber(phoneNumber, context);
      }
    } catch (e) {
      _progressDialog.hide();
      _showErrorDialog('An error occurred: $e');
    }
  }

  Future<void> _verifyPhoneNumber(
      String phoneNumber, BuildContext context) async {
    // Continue with the phone number verification logic...
    // (unchanged from the previous implementation)

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
              builder: (context) =>
                  OtpVerificationScreen(verificationId, phoneNumber),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _progressDialog.hide();
          //_showErrorDialog('Code Auto Retrieval Timeout');
        },
      );
    } catch (e) {
      _progressDialog.hide();
      _showErrorDialog('An error occurred: $e');
    }
    // _progressDialog
    //     .hide(); // Hide the progress dialog after the verification process
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
            Text('Welcome, ${user.displayName}'),
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

class AdditionalDetailsPage extends StatefulWidget {
  final String phoneNumber; // Add phoneNumber parameter

  AdditionalDetailsPage(this.phoneNumber);

  @override
  _AdditionalDetailsPageState createState() => _AdditionalDetailsPageState();
}

class _AdditionalDetailsPageState extends State<AdditionalDetailsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final ProgressDialog _progressDialog;
  // = ProgressDialog();

  @override
  Widget build(BuildContext context) {
    _progressDialog = ProgressDialog(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Additional Details'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                'Phone Number: ${widget.phoneNumber}'), // Display the phone number
            SizedBox(height: 16.0),
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
                await _storeUserDetails(
                  widget.phoneNumber,
                  nameController.text,
                  passwordController.text,
                );

                // After storing details, navigate to the home page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => HomePage(_auth.currentUser!)),
                );
              },
              child: Text('Complete Registration'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _storeUserDetails(
      String phoneNumber, String name, String password) async {
    // Store additional information in Firestore along with the phone number
    await _firestore.collection('users').doc(phoneNumber).set({
      'name': name,
      'phoneNumber': phoneNumber,
      'password': password,
      // Add more fields as needed
    });
  }
}

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber; // Add phoneNumber parameter

  OtpVerificationScreen(this.verificationId, this.phoneNumber);

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

      // Pass the phone number to the AdditionalDetailsPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdditionalDetailsPage(widget.phoneNumber),
        ),
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

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final ProgressDialog _progressDialog;

  @override
  void initState() {
    super.initState();
    _progressDialog = ProgressDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Page'),
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
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                await _loginUser(
                  phoneNumberController.text,
                  passwordController.text,
                );
              },
              child: Text('Login'),
            ),
            SizedBox(height: 16.0),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegistrationPage()),
                );
              },
              child: Text('Don\'t have an account? Register'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loginUser(String phoneNumber, String password) async {
    // Phone number validation for Indian numbers
    if (phoneNumber.isEmpty) {
      _showErrorDialog('Please enter a phone number.');
      return;
    }

    // Password validation
    if (password.isEmpty) {
      _showErrorDialog('Please enter a password.');
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
      // Check if the user exists in Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(phoneNumber).get();

      if (userDoc.exists) {
        // User exists, validate password
        var userData = userDoc.data() as Map<String, dynamic>?; // Cast to Map
        if (userData != null && userData['password'] == password) {
          // Password is correct, navigate to the home page
          _progressDialog.hide();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => UploadApp()),
          );
        } else {
          _progressDialog
              .hide(); // Hide the progress dialog on unsuccessful login
          _showErrorDialog('Incorrect password. Please try again.');
        }
      } else {
        _progressDialog
            .hide(); // Hide the progress dialog if the user doesn't exist
        _showErrorDialog('User not found. Please register first.');
      }
    } catch (e) {
      _progressDialog.hide(); // Hide the progress dialog on error
      _showErrorDialog('An error occurred: $e');
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
