import 'package:flutter/material.dart';
import 'package:project_flutter_final/sqlHelper.dart';
import 'package:project_flutter_final/models.dart';

class Booking extends StatefulWidget {
  final String patientId;
  const Booking({super.key, required this.patientId});
  @override
  State<Booking> createState() => _BookingState();
}

class _BookingState extends State<Booking> {
  List<DoctorModel> _allDoctors = [];
  List<String> _specialties = [];
  List<DoctorModel> _filteredDoctors = [];
  String? selectedSpecialty;
  DoctorModel? selectedDoctor;
  DateTime? selectedDate;
  String? selectedTime;
  List<String> availableTimes = [];
  bool _isloading = false;
  String? _message;
  Color _messageColor = Colors.red;

  final Map<int, String> weekdayMap = {
    1: "Mon", 2: "Tue", 3: "Wed", 4: "Thu", 5: "Fri", 6: "Sat", 7: "Sun"
  };

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  void _loadDoctors() async {
    setState(() { _isloading = true; });
    final doctors = await SqlHelper.getDoctors();
    final specialties = doctors.map((d) => d.specialty).toSet().toList();
    setState(() {
      _allDoctors = doctors;
      _specialties = specialties;
      _isloading = false;
    });
  }

  void _onSpecialtyChanged(String? specialty) {
    setState(() {
      selectedSpecialty = specialty;
      selectedDoctor = null;
      selectedDate = null;
      selectedTime = null;
      availableTimes = [];
      _filteredDoctors = _allDoctors.where((d) => d.specialty == specialty).toList();
    });
  }

  void _onDoctorChanged(DoctorModel? doctor) {
    setState(() {
      selectedDoctor = doctor;
      selectedDate = null;
      selectedTime = null;
      availableTimes = [];
    });
  }

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
    if (selectedDoctor == null) return;

    final workingDays = selectedDoctor!.workingDays.split(",");
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstAvailableDate(workingDays),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 60)),
      selectableDayPredicate: (date) {
        final dayName = weekdayMap[date.weekday];
        return workingDays.contains(dayName);
      },
    );

    if (picked != null) { setState(() {selectedDate = picked; selectedTime = null; }); await _generateAvailableTimes(); }
  }

  Future<void> _generateAvailableTimes() async {
    if (selectedDoctor == null || selectedDate == null) return;
    setState(() { _isloading = true; });
    final start = _parseTime(selectedDoctor!.startTime);
    final end = _parseTime(selectedDoctor!.endTime);
    final dateStr = _formatDate(selectedDate!);
    List<String> slots = [];
    var current = start;
    while (current.isBefore(end)) {
      final timeStr = _formatTime(current);
      final isFree = await SqlHelper.isAppointmentAvailable(
        selectedDoctor!.idD,
        dateStr,
        timeStr,
      );
      if (isFree) slots.add(timeStr);
      current = current.add(Duration(minutes: 30));
    }
    setState(() {
      availableTimes = slots;
      _isloading = false;
    });
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

  Future<void> _bookAppointment() async {
    try {
      final remoteId = "${widget.patientId}_${DateTime.now().microsecondsSinceEpoch}";
      await SqlHelper.createAppointment(
        AppointmentModel(
          remoteId: remoteId,
          patientId: widget.patientId,
          doctorId: selectedDoctor!.idD,
          appointmentDate: _formatDate(selectedDate!),
          appointmentTime: selectedTime!,
        ),
      );

      setState(() {
        _messageColor = Colors.green;
        _message = "Appointment booked successfully";
      });

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pop(context);

    } catch (e) {
      setState(() {
        _messageColor = Colors.red;
        _message = "This time is no longer available, choose another";
      });
      await _generateAvailableTimes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Book Appointment"),
        backgroundColor: Color(0xFFC9E2F5),
      ),
      body: _isloading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            DropdownButtonFormField<String>(
              value: selectedSpecialty,
              decoration: InputDecoration(
                labelText: "Select Specialty",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: _onSpecialtyChanged,
            ),

            SizedBox(height: 20),

            DropdownButtonFormField<DoctorModel>(
              value: selectedDoctor,
              decoration: InputDecoration(
                labelText: "Select Doctor",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              items: _filteredDoctors.map((d) => DropdownMenuItem(
                value: d,
                child: Text(d.name),
              )).toList(),
              onChanged: selectedSpecialty == null ? null : _onDoctorChanged,
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: selectedDoctor == null ? null : _pickDate,
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFC9E2F5), foregroundColor: Colors.black),
              child: Text(selectedDate == null ? "Select Date" : _formatDate(selectedDate!)),
            ),

            SizedBox(height: 20),

            if (selectedDate != null)
              DropdownButtonFormField<String>(
                value: selectedTime,
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
              onPressed: (selectedDoctor != null && selectedDate != null && selectedTime != null)
                  ? _bookAppointment
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFC9E2F5),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Color(0xFFF9C339), width: 1.5)),
                minimumSize: Size(200, 60),
              ),
              child: Text("Book Appointment", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
