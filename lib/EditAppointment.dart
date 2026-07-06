import 'package:flutter/material.dart';
import 'package:project_flutter_final/sqlHelper.dart';
import 'package:project_flutter_final/models.dart';

class EditAppointment extends StatefulWidget {
  final int id;
  const EditAppointment({super.key, required this.id});
  @override
  State<EditAppointment> createState() => _EditAppointmentState();
}

class _EditAppointmentState extends State<EditAppointment> {
  AppointmentModel? appointment;
  DoctorModel? doctor;
  DateTime? selectedDate;
  String? selectedTime;
  List<String> availableTimes = [];
  bool _isloading = true;
  String? _message;
  Color _messageColor = Colors.red;

  final Map<int, String> weekdayMap = {
    1: "Mon", 2: "Tue", 3: "Wed", 4: "Thu", 5: "Fri", 6: "Sat", 7: "Sun"
  };

  @override
  void initState() {
    super.initState();
    _loadAppointment();
  }

  void _loadAppointment() async {
    final appt = await SqlHelper.getAppointmentById(widget.id);
    if (appt == null) {
      setState(() { _isloading = false; });
      return;
    }

    final doctors = await SqlHelper.getDoctors();
    final matches = doctors.where((d) => d.idD == appt.doctorId);
    final doc = matches.isNotEmpty ? matches.first : null;

    setState(() {
      appointment = appt;
      doctor = doc;
      selectedDate = DateTime.tryParse(appt.appointmentDate);
      selectedTime = appt.appointmentTime;
      _isloading = false;
    });
    await _generateAvailableTimes();
  }

  //عشان الاقي اقرب تاريخ من ايام دوام الدكتور (يبلش من اليوم)
  DateTime _firstAvailableDate(List<String> workingDays) {
    var date = DateTime.now();
    for (int i = 0; i < 14; i++) {
      final dayName = weekdayMap[date.weekday];
      if (workingDays.contains(dayName)) return date;
      date = date.add(Duration(days: 1));
    }
    return DateTime.now();
  }

  Future<void> _pickDate() async {
    if (doctor == null) return;
    final workingDays = doctor!.workingDays.split(",");

    final defaultDate = (selectedDate != null && workingDays.contains(weekdayMap[selectedDate!.weekday])) ? selectedDate! : _firstAvailableDate(workingDays);

    final picked = await showDatePicker(
      context: context,
      initialDate: defaultDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 60)),
      selectableDayPredicate: (date) {
        final dayName = weekdayMap[date.weekday];
        return workingDays.contains(dayName);
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedTime = null;
      });
      await _generateAvailableTimes();
    }
  }

  Future<void> _generateAvailableTimes() async {
    if (doctor == null || selectedDate == null) return;

    setState(() { _isloading = true; });

    final start = _parseTime(doctor!.startTime);
    final end = _parseTime(doctor!.endTime);
    final dateStr = _formatDate(selectedDate!);

    List<String> slots = [];
    var current = start;
    while (current.isBefore(end)) {
      final timeStr = _formatTime(current);

      final isFree = await SqlHelper.isAppointmentAvailable(doctor!.idD, dateStr, timeStr);
      final isCurrent = (dateStr == appointment!.appointmentDate && timeStr == appointment!.appointmentTime);

      if (isFree || isCurrent) slots.add(timeStr);
      current = current.add(Duration(minutes: 30));
    }

    setState(() {availableTimes = slots;_isloading = false;});
  }

  DateTime _parseTime(String time) {
    final format = time.trim().split(" ");
    final hm = format[0].split(":");
    int hour = int.parse(hm[0]);
    int minute = int.parse(hm[1]);
    final isPM = format[1].toUpperCase() == "PM";
    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;
    return DateTime(2000, 1, 1, hour, minute);
  }

  String _formatTime(DateTime time) {
    int hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final isPM = hour >= 12;
    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;
    return "${hour.toString().padLeft(2, '0')}:$minute ${isPM ? 'PM' : 'AM'}";
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _saveChanges() async {
    try {
      await SqlHelper.updateAppointment(widget.id, _formatDate(selectedDate!), selectedTime!,);
      setState(() { _messageColor = Colors.green ; _message = "Appointment updated successfully";});
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() { _messageColor = Colors.red ; _message = "This time is no longer available, choose another";});
      await _generateAvailableTimes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Appointment"),
        backgroundColor: Color(0xFFC9E2F5),
      ),
      body: _isloading
          ? Center(child: CircularProgressIndicator())
          : appointment == null
          ? Center(child: Text("Appointment not found"))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Dr. ${doctor?.name ?? ""}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _pickDate,
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFC9E2F5), foregroundColor: Colors.black),
              child: Text(selectedDate == null ? "Select Date" : _formatDate(selectedDate!)),
            ),

            SizedBox(height: 20),
            if (selectedDate != null)
              DropdownButtonFormField<String>(
                value: availableTimes.contains(selectedTime) ? selectedTime : null,
                decoration: InputDecoration(
                  labelText: "Select Time",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                items: availableTimes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (t) => setState(() { selectedTime = t; }),
              ),

            SizedBox(height: 20),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _messageColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),

            ElevatedButton(
              onPressed: (selectedDate != null && selectedTime != null) ? _saveChanges : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFC9E2F5),
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
