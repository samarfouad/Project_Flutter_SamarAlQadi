import 'package:flutter/material.dart';
import 'package:project_flutter_final/sqlHelper.dart';
import 'package:project_flutter_final/models.dart';

class ProfilP extends StatefulWidget {
  final String patientId;
  const ProfilP({super.key, required this.patientId});
  @override
  State<ProfilP> createState() => _ProfilPState();
}

class _ProfilPState extends State<ProfilP> {
  bool _isloading = true;
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String? _message;
  Color _messageColor = Colors.red;

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
    if (value == null || value.isEmpty) return "Please enter your password";
    return null;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  void _loadPatient() async {
    final patient = await SqlHelper.getPatientById(widget.patientId);
    if (patient != null) {
      nameController.text = patient.name;
      phoneController.text = patient.phone;
      emailController.text = patient.email;
      passwordController.text = patient.password;
    }

    setState(() {
      _isloading = false;
    });
  }

  Future<void> _saveChanges() async {
    final errors = [
      _validateName(nameController.text),
      _validatePhone(phoneController.text),
      _validateEmail(emailController.text),
      _validatePassword(passwordController.text),
    ];
    final firstError = errors.firstWhere((e) => e != null, orElse: () => null);
    if (firstError != null) {
      setState(() {_messageColor = Colors.red;_message = firstError;});
      return;
    }

    await SqlHelper.updatePatient(
      PatientModel(
        idP: widget.patientId,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      ),
    );

    setState(() {_messageColor = Colors.green;_message = "Profile updated successfully";});
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Profile"), backgroundColor: Color(0xFFC9E2F5),),
      body: _isloading ? Center(child: CircularProgressIndicator()) : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            TextField(controller: nameController, style: TextStyle(color: Colors.black, fontSize: 20), decoration: InputDecoration(
              filled: true, fillColor: Colors.white, labelText: "Name", labelStyle: TextStyle(color: Color(0xFF4A2F25)), prefixIcon: Icon(Icons.person, color: Color(0xFFF9C339)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Color(0xFF4A2F25), width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Color(0xFFF9C339), width: 2.0)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
              ),
            ),

            SizedBox(height: 15),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: Colors.black, fontSize: 20),
              decoration: InputDecoration(filled: true, fillColor: Colors.white, labelText: "Phone", labelStyle: TextStyle(color: Color(0xFF4A2F25)),
                prefixIcon: Icon(Icons.phone, color: Color(0xFFF9C339)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Color(0xFF4A2F25), width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Color(0xFFF9C339), width: 2.0)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
              ),
            ),

            SizedBox(height: 15),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: Colors.black, fontSize: 20),
              decoration: InputDecoration(filled: true, fillColor: Colors.white, labelText: "Email", labelStyle: TextStyle(color: Color(0xFF4A2F25)),
                prefixIcon: Icon(Icons.alternate_email, color: Color(0xFFF9C339)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Color(0xFF4A2F25), width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Color(0xFFF9C339), width: 2.0)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
              ),
            ),

            SizedBox(height: 15),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: TextStyle(color: Colors.black, fontSize: 20),
              decoration: InputDecoration(filled: true, fillColor: Colors.white, labelText: "Password", labelStyle: TextStyle(color: Color(0xFF4A2F25)),
                prefixIcon: Icon(Icons.password, color: Color(0xFFF9C339)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Color(0xFF4A2F25), width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Color(0xFFF9C339), width: 2.0)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
              ),
            ),

            SizedBox(height: 15),

            if (_message != null)
              Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_message!, textAlign: TextAlign.center,
                  style: TextStyle(color: _messageColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),

            ElevatedButton(onPressed: _saveChanges, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFC9E2F5),
              foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Color(0xFFF9C339), width: 1.5)),
                minimumSize: Size(200, 60),
              ),
              child: Text("Save Changes", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
