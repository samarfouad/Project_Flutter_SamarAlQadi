import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_flutter_final/sqlHelper.dart';
import 'package:project_flutter_final/models.dart';
import 'package:project_flutter_final/SyncService.dart';
import 'package:project_flutter_final/session_prefs.dart';
import 'login.dart';
import 'ProfilD.dart';

class D_Dashbord extends StatefulWidget {
  final int doctorId;
  const D_Dashbord({super.key, required this.doctorId});

  @override
  State<D_Dashbord> createState() => _D_DashbordState();
}

class _D_DashbordState extends State<D_Dashbord> {
  String doctorN = "";
  bool _isloading = false;
  List<AppointmentModel> _datastorge = [];
  Map<String, String> _patientsNames = {};
  static const Duration _networkTimeout = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _loadDoctorName();
    _refeeshData();
    _syncInBackground();
  }

  Future<void> _syncInBackground() async {
    await SyncService.syncAll();
    await SyncService.pullAppointmentsForDoctor(widget.doctorId);
    await SyncService.pullDoctor(widget.doctorId);
    if (!mounted) return;
    _loadDoctorName();
    _refeeshData();
  }

  void _loadDoctorName() async {
    final doctors = await SqlHelper.getDoctors();
    final doc = doctors.where((d) => d.idD == widget.doctorId);
    setState(() {
      doctorN = doc.isNotEmpty ? doc.first.name : "";
    });
  }

  void _refeeshData() async {
    try {
      setState(() { _isloading = true; });
      final data = await SqlHelper.getAppointmentsByDoctor(widget.doctorId);
      Map<String, String> names = {};
      for (var appt in data) {
        final pId = appt.patientId;
        if (!names.containsKey(pId)) {
          names[pId] = await _getPatientName(pId);
        }
      }

      setState(() {_datastorge = data;_patientsNames = names;});

    } catch (e) {
      print("ERROR: $e");
    } finally {
      setState(() { _isloading = false; });
    }
  }

  Future<String> _getPatientName(String patientId) async {
    final local = await SqlHelper.getPatientById(patientId);
    if (local != null) return local.name;
    try {
      final doc = await FirebaseFirestore.instance.collection("patients").doc(patientId).get().timeout(_networkTimeout);
      if (doc.exists) {
        final data = doc.data()!;
        await SqlHelper.createOrUpdatePatient(
          PatientModel(
            idP: patientId,
            name: data["name"] ?? "Unknown",
            email: data["email"] ?? "",
            password: data["password"] ?? "",
            phone: data["phone"] ?? "",
            isSynced: 1,
          ),
        );
        return data["name"] ?? "Unknown";
      }
    } catch (e) {
      print("Error fetching patient $patientId from Firestore: $e");
    }
    return "Unknown";
  }

  bool _isUpcoming(AppointmentModel appointment) {
    if (appointment.status != "Pending") return false;
    final date = DateTime.tryParse(appointment.appointmentDate);
    if (date == null) return true;
    final today = DateTime.now();
    return !date.isBefore(DateTime(today.year, today.month, today.day));
  }

  DateTime _apptDateTime(AppointmentModel a) {
    final date = DateTime.tryParse(a.appointmentDate) ?? DateTime(2000);
    try {
      final format = a.appointmentTime.trim().split(" ");
      final hm = format[0].split(":");
      int hour = int.parse(hm[0]);
      final minute = int.parse(hm[1]);
      final isPM = format[1].toUpperCase() == "PM";
      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      return date;
    }
  }

  Color _statusColor(String status) {
    if (status == "Completed") return Colors.green[300]!;
    if (status == "Cancelled") return Colors.red[300]!;
    return Colors.orange[300]!; // Pending
  }

  void completeItem(int id) async {await SqlHelper.updateAppointmentStatus(id, "Completed");_refeeshData();SyncService.syncAll();}

  void deletItem(int id) async {await SyncService.deleteAppointmentEverywhere(id);_refeeshData();}

  void showConfirmDialog(int id, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action == "Complete" ? "Complete Appointment" : "Delete Appointment"),
        content: Text("Are you sure you want to $action this appointment?"),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); }, child: Text("No")),
          TextButton(onPressed: () {
            if (action == "Complete") { completeItem(id); } else { deletItem(id); }
            Navigator.pop(context);
          }, child: Text("Yes")),
        ],
      ),
    );
  }

  Widget _AppointmentCard(AppointmentModel appt) {
    final patientName = _patientsNames[appt.patientId] ?? "Unknown";
    final isPending = appt.status == "Pending";

    return Card(
      color: _statusColor(appt.status),
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        title: Text(patientName),
        subtitle: Text(
            "${appt.appointmentDate}  -  ${appt.appointmentTime}\nStatus: ${appt.status}"),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPending)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                onPressed: () => showConfirmDialog(appt.idA!, "Complete"),
                icon: Icon(Icons.check_circle, size: 20, color: Colors.green[800]),
              ),
            if (isPending) SizedBox(width: 6),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              onPressed: () => showConfirmDialog(appt.idA!, "Delete"),
              icon: Icon(Icons.delete, size: 20, color: Colors.red[800]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _datastorge.where(_isUpcoming).toList()
      ..sort((a, b) => _apptDateTime(a).compareTo(_apptDateTime(b)));
    final past = _datastorge.where((a) => !_isUpcoming(a) && a.status != "Cancelled").toList()
      ..sort((a, b) => _apptDateTime(b).compareTo(_apptDateTime(a)));
    return DefaultTabController(
      length: 2,
      child: Scaffold(

        appBar: AppBar(
          title: Text("Welcome Dr. $doctorN"),
          backgroundColor: Color(0xFFC9E2F5),
          actions: [
            IconButton( onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilD(doctorId: widget.doctorId)),
            ).then((value) {_loadDoctorName();SyncService.syncAll();});},
              icon: Icon(Icons.person_pin, color: Colors.black),
            ),

            IconButton(
              onPressed: () async {await clearSession();Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const Login()),(route) => false,
                );},
              icon: Icon(Icons.logout, color: Colors.black),
            ),

          ],
          bottom: TabBar(
            labelColor: Colors.black,
            tabs: [Tab(text: "Upcoming"), Tab(text: "Past"),],
          ),
        ),

        body: _isloading ? Center(child: CircularProgressIndicator()) : TabBarView(
          children: [
            upcoming.isEmpty ? Center(child: Text("No upcoming appointments")) : ListView.builder(itemCount: upcoming.length,
              itemBuilder: (context, index) => _AppointmentCard(upcoming[index]),
            ),

            past.isEmpty ? Center(child: Text("No past appointments")) : ListView.builder(itemCount: past.length,
              itemBuilder: (context, index) => _AppointmentCard(past[index]),
            ),
          ],
        ),
      ),
    );
  }
}
