import 'package:flutter/material.dart';
import 'package:project_flutter_final/SignUp.dart';
import 'package:project_flutter_final/session_prefs.dart';
import 'P_Dashbord.dart';
import 'D_Dashbord.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sqlHelper.dart';

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController Email = TextEditingController();
  final TextEditingController Password = TextEditingController();
  bool _isLoading = false;
  String? _message;

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter your email";
    }
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return "Email : XXX@XX.com";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your password";
    }
    return null;
  }

  Future<void> _login() async {
    final emailError = _validateEmail(Email.text);
    final passwordError = _validatePassword(Password.text);

    if (emailError != null) {setState(() { _message = emailError; });return;}
    if (passwordError != null) {setState(() { _message = passwordError; });return;}

    setState(() {_isLoading = true;_message = null;});

    try {
      UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: Email.text.trim(),
        password: Password.text.trim(),
      ).timeout(const Duration(seconds: 5));
      await saveSession("patient", cred.user!.uid);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (context) => P_Dashbord(patientId: cred.user!.uid)));
      return;
    } catch (e) {
    }

    final patientResult = await SqlHelper.getPatientByEmail(Email.text.trim());
    if (patientResult != null && patientResult.password == Password.text.trim()) {
      await saveSession("patient", patientResult.idP);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (context) => P_Dashbord(patientId: patientResult.idP)));
      return;
    }

    final doctorResult = await SqlHelper.getDoctorByEmail(Email.text.trim());
    if (doctorResult != null && doctorResult.password == Password.text.trim()) {
      await saveSession("doctor", doctorResult.idD.toString());
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (context) => D_Dashbord(doctorId: doctorResult.idD)));
      return;
    }

    setState(() {_isLoading = false;_message = "Email or Password is incorrect";});
  }

  @override
  void dispose() {
    Email.dispose();
    Password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      appBar: AppBar(title: Text("Smilee"), titleTextStyle: TextStyle(color: Color(0xFF000000), fontSize: 30, fontWeight: FontWeight.bold), backgroundColor: Color(0xFFC9E2F5), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 50),
                Image.asset('asset/Images/image1.jpg', width: 200, height: 200, fit: BoxFit.contain),

                SizedBox(height: 50),
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

                SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    keyboardType: TextInputType.text,
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

                SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 30.0),
                    child: GestureDetector(
                      onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => SignUp())); },
                      child: Text('Sign up', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFF9C339), fontFamily: 'Cairo')),
                    ),
                  ),
                ),

                SizedBox(height: 15),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Text(_message!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),),
                  ),

                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFC9E2F5),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0), side: BorderSide(color: Color(0xFFF9C339), width: 1.5)),
                          minimumSize: Size(200, 60),
                        ),
                        child: Text("Log in ", style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
                      ),
                SizedBox(height: 30),
              ],
          ),
        ),
      ),
    );
  }
}
