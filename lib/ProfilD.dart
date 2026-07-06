import 'package:flutter/material.dart';
import 'package:project_flutter_final/sqlHelper.dart';
import 'package:project_flutter_final/models.dart';

class ProfilD extends StatefulWidget {
  final int doctorId;
  const ProfilD({super.key, required this.doctorId});

  @override
  State<ProfilD> createState() => _ProfilDState();
}

class _ProfilDState extends State<ProfilD> {
  DoctorModel? doctor;
  bool _isloading = true;

  TextEditingController phoneController = TextEditingController();
  String? startTimeStr;
  String? endTimeStr;
  List<String> selectedDays = [];

  String? _message;
  Color _messageColor = Colors.red;

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return "Please enter your phone number";
    return null;
  }

  final List<String> allDays = ["Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri"];

  @override
  void initState() {
    super.initState();
    _loadDoctor();
  }

  void _loadDoctor() async {
    final doctors = await SqlHelper.getDoctors();
    final matches = doctors.where((d) => d.idD == widget.doctorId);
    final doc = matches.isNotEmpty ? matches.first : null;

    if (doc != null) {
      phoneController.text = doc.phone;
      startTimeStr = doc.startTime;
      endTimeStr = doc.endTime;
      selectedDays = doc.workingDays.split(",").where((e) => e.isNotEmpty).toList();
    }

    setState(() {doctor = doc;_isloading = false;});

  }

  String _formatTimeOfDay(TimeOfDay t) {
    int hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    String minute = t.minute.toString().padLeft(2, '0');
    String period = t.period == DayPeriod.am ? "AM" : "PM";
    return "${hour.toString().padLeft(2, '0')}:$minute $period";
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 8, minute: 0));
    if (picked != null) {
      setState(() { startTimeStr = _formatTimeOfDay(picked); });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 14, minute: 0));
    if (picked != null) {
      setState(() { endTimeStr = _formatTimeOfDay(picked); });
    }
  }

  void _toggleDay(String day) {
    setState(() {
      if (selectedDays.contains(day)) {
        selectedDays.remove(day);
      } else {
        selectedDays.add(day);
      }
    });
  }

  Future<void> _saveChanges() async {
    final phoneError = _validatePhone(phoneController.text);
    if (phoneError != null) {
      setState(() {_messageColor = Colors.red;_message = phoneError;});
      return;
    }

    if (selectedDays.isEmpty || startTimeStr == null || endTimeStr == null || doctor == null) {
      setState(() {_messageColor = Colors.red;_message = "Please select your working days and hours";});
      return;
    }

    await SqlHelper.updateDoctor(
      DoctorModel(
        idD: doctor!.idD,
        name: doctor!.name,
        specialty: doctor!.specialty,
        email: doctor!.email,
        password: doctor!.password,
        phone: phoneController.text.trim(),
        workingDays: selectedDays.join(","),
        startTime: startTimeStr!,
        endTime: endTimeStr!,
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
      body: _isloading ? Center(child: CircularProgressIndicator()) : doctor == null ? Center(child: Text("Doctor not found")) : Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("Dr. ${doctor!.name}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

            SizedBox(height: 4),
            Text(doctor!.specialty, style: TextStyle(fontSize: 16, color: Colors.grey[700])),

            SizedBox(height: 4),
            Text(doctor!.email, style: TextStyle(fontSize: 14, color: Colors.grey[600])),

            SizedBox(height: 25),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: Colors.black, fontSize: 20),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: "Phone",
                labelStyle: TextStyle(color: Color(0xFF4A2F25)),
                prefixIcon: Icon(Icons.phone, color: Color(0xFFF9C339)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Color(0xFF4A2F25), width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Color(0xFFF9C339), width: 2.0)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
              ),
            ),

            SizedBox(height: 25),
            Text("Working Days", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: allDays.map((day) {
                final isSelected = selectedDays.contains(day);
                return FilterChip(label: Text(day), selected: isSelected, selectedColor: Color(0xFFC9E2F5), onSelected: (_) => _toggleDay(day),);
              }).toList(),
            ),

            SizedBox(height: 25),
            Text("Working Hours", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(onPressed: _pickStartTime, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFC9E2F5), foregroundColor: Colors.black), child: Text(startTimeStr ?? "Start Time"),),
                ),

                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(onPressed: _pickEndTime, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFC9E2F5), foregroundColor: Colors.black), child: Text(endTimeStr ?? "End Time"),),
                ),
              ],
            ),

            SizedBox(height: 20),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10), child: Text(_message!, textAlign: TextAlign.center,
                style: TextStyle(color: _messageColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),

            ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFC9E2F5), foregroundColor: Colors.black,
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
