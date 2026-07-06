import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_flutter_final/sqlHelper.dart';
import 'package:project_flutter_final/models.dart';
import 'login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});
  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController Email = TextEditingController();
  final TextEditingController Name = TextEditingController();
  final TextEditingController Phone = TextEditingController();
  final TextEditingController Password = TextEditingController();
  final TextEditingController ConfirmPassword = TextEditingController();
  bool _isLoading = false;
  String? _message;

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return "Please enter your name";
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return "Please enter your phone number";
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return "Please enter your email";
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return "Email : XXX@XX.com";
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Please enter a password";
    if (value.length < 8 || value.length > 15) return "Password must be 8-15 characters";
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return "Please confirm your password";
    if (value != Password.text) return "Passwords do not match";
    return null;
  }

  Future<void> _signUp() async {
    final errors = [_validateEmail(Email.text), _validateName(Name.text), _validatePhone(Phone.text), _validatePassword(Password.text),
                    _validateConfirmPassword(ConfirmPassword.text),];

    final firstError = errors.firstWhere((e) => e != null, orElse: () => null);
    if (firstError != null) {setState(() { _message = firstError; });return;}

    setState(() { _isLoading = true; _message = null; });

    final existing = await SqlHelper.getPatientByEmail(Email.text.trim());
    if (existing != null) { setState(() {_isLoading = false; _message = "Email already found";});return; }

    try {
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: Email.text.trim(),
        password: Password.text.trim(),
      ).timeout(const Duration(seconds: 8));

      final patient = PatientModel(
        idP: cred.user!.uid,
        name: Name.text.trim(),
        email: Email.text.trim(),
        password: Password.text.trim(),
        phone: Phone.text.trim(),
        isSynced: 1
      );

      await firestore.collection("patients").doc(patient.idP).set(patient.toMap());
      await SqlHelper.createOrUpdatePatient(patient);

      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()));

    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _message = e.code == 'email-already-in-use' ? "Email already found" : "Sign up failed: ${e.message}";
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = "Sign up failed, please check your internet connection";
      });
    }
  }

  @override
  void dispose() {
    Email.dispose();
    Name.dispose();
    Phone.dispose();
    Password.dispose();
    ConfirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      appBar: AppBar(title: Text("Sign up"), titleTextStyle: TextStyle(color: Color(0xFF000000), fontSize: 30, fontWeight: FontWeight.bold), backgroundColor: Color(0xFFC9E2F5), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 30),
                Image.asset('asset/Images/image1.jpg', width: 200, height: 200, fit: BoxFit.contain),

                SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    keyboardType: TextInputType.text,
                    controller: Email,
                    style: TextStyle(color: Colors.black, fontSize: 20),
                    decoration: InputDecoration(filled: true, fillColor: const Color(0xFFFFFFFF), labelText: "Enter Email : XXXXX@XXX.com", labelStyle: TextStyle(color: Color(0xFF4A2F25)), prefixIcon: Icon(Icons.alternate_email, color: Color(0xFFF9C339)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Color(0xFF4A2F25), width: 1.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Color(0xFFF9C339), width: 2.0)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
                    ),
                  ),
                ),

                SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    keyboardType: TextInputType.text,
                    controller: Name,
                    style: TextStyle(color: Colors.black, fontSize: 20),
                    decoration: InputDecoration(filled: true, fillColor: const Color(0xFFFFFFFF), labelText: "Name", labelStyle: TextStyle(color: Color(0xFF4A2F25)), prefixIcon: Icon(Icons.person, color: Color(0xFFF9C339)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Color(0xFF4A2F25), width: 1.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Color(0xFFF9C339), width: 2.0)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
                    ),
                  ),
                ),

                SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    keyboardType: TextInputType.phone,
                    controller: Phone,
                    style: TextStyle(color: Colors.black, fontSize: 20),
                    decoration: InputDecoration(filled: true, fillColor: const Color(0xFFFFFFFF), labelText: "Phone", labelStyle: TextStyle(color: Color(0xFF4A2F25)), prefixIcon: Icon(Icons.phone, color: Color(0xFFF9C339)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Color(0xFF4A2F25), width: 1.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Color(0xFFF9C339), width: 2.0)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
                    ),
                  ),
                ),

                SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    obscureText: true,
                    controller: Password,
                    style: TextStyle(color: Colors.black, fontSize: 20),
                    decoration: InputDecoration(filled: true, fillColor: const Color(0xFFFFFFFF), labelText: "Enter Password", labelStyle: TextStyle(color: Color(0xFF4A2F25)), prefixIcon: Icon(Icons.password, color: Color(0xFFF9C339)),
                      suffixIcon: Icon(Icons.visibility, color: Color(0xFFF9C339)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Color(0xFF4A2F25), width: 1.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Color(0xFFF9C339), width: 2.0)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
                    ),
                  ),
                ),

                SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    obscureText: true,
                    controller: ConfirmPassword,
                    style: TextStyle(color: Colors.black, fontSize: 20),
                    decoration: InputDecoration(filled: true, fillColor: const Color(0xFFFFFFFF), labelText: "Confirm Password", labelStyle: TextStyle(color: Color(0xFF4A2F25)), prefixIcon: Icon(Icons.password, color: Color(0xFFF9C339)),
                      suffixIcon: Icon(Icons.visibility, color: Color(0xFFF9C339)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Color(0xFF4A2F25), width: 1.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Color(0xFFF9C339), width: 2.0)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
                    ),
                  ),
                ),

                SizedBox(height: 15),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),

                SizedBox(height: 10),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFC9E2F5),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0), side: BorderSide(color: Color(0xFFF9C339), width: 1.5)),
                          minimumSize: Size(200, 60),
                        ),
                        child: Text("Sign Up", style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
                      ),
                SizedBox(height: 30),
              ],
          ),
        ),
      ),
    );
  }
}
