import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_flutter_final/SyncService.dart';
import 'package:project_flutter_final/session_prefs.dart';
import 'package:project_flutter_final/login.dart';
import 'package:project_flutter_final/sqlHelper.dart';
import 'package:project_flutter_final/models.dart';
import 'Booking.dart';
import 'EditAppointment.dart';
import 'ProfilP.dart';

class P_Dashbord extends StatefulWidget {
  final String patientId;
  const P_Dashbord({super.key, required this.patientId});

  @override
  State<P_Dashbord> createState() => _P_DashbordState();
}

class _P_DashbordState extends State<P_Dashbord> {
  String patientN = "";
  bool _isloading = false;
  List<AppointmentModel> _datastorge = [];
  List<DoctorModel> _doctorslist = [];
  static const Duration _networkTimeout = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    PatientData();
    _refeeshData();
    _syncInBackground();
  }

  Future<void> _syncInBackground() async {
    await SyncService.syncAll();
    await SyncService.pullAppointmentsForPatient(widget.patientId);
    await SyncService.pullPatient(widget.patientId);
    if (!mounted) return;
    await PatientData();
    _refeeshData();
  }

  Future<void> PatientData() async {
    final patient = await SqlHelper.getPatientById(widget.patientId);
    if (patient != null) {
      setState(() { patientN = patient.name;});
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection("patients")
          .doc(widget.patientId)
          .get()
          .timeout(_networkTimeout);
      if (doc.exists) {
        final data = doc.data()!;
        await SqlHelper.createOrUpdatePatient(
          PatientModel(
            idP: widget.patientId,
            name: data["name"] ?? "",
            email: data["email"] ?? "",
            password: data["password"] ?? "",
            phone: data["phone"] ?? "",
          ),
        );
        await SqlHelper.updatePatientSyncStatus(widget.patientId, 1);
        setState(() { patientN = data["name"] ?? ""; });
      }
    } catch (e) {
      print("Error fetching patient from Firestore: $e");
    }
  }

  void _refeeshData() async {
    try {
      setState(() {_isloading = true;});
      final data = await SqlHelper.getAppointmentsByPatient(widget.patientId);
      final doctors = await SqlHelper.getDoctors();
      setState(() { _datastorge = data;_doctorslist = doctors; });
    } catch (e) {
      print("ERROR: $e");
    } finally {
      setState(() {_isloading = false;});
    }
  }

  String _getDoctorName(int doctorId) {
    final doc = _doctorslist.where((d) => d.idD == doctorId);
    return doc.isNotEmpty ? doc.first.name : "Unknown";
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

  void deletItem(int id) async {
    await SyncService.deleteAppointmentEverywhere(id);
    _refeeshData();
  }

  void showDeleteConfirmDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Appointment"),
        content: Text("Are you sure you want to delete this appointment?"),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); }, child: Text("No")),
          TextButton(onPressed: () {
            deletItem(id);
            Navigator.pop(context);
          }, child: Text("Yes, Delete")),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    if (status == "Completed") return Colors.green[500]!;
    if (status == "Cancelled") return Colors.red[500]!;
    return Colors.orange[500]!; // Pending
  }

  Widget _buildAppointmentCard(AppointmentModel appt, bool showActions) {
    return Card(
      color: _statusColor(appt.status),
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        title: Text(_getDoctorName(appt.doctorId)),
        subtitle: Text(
            "${appt.appointmentDate} - ${appt.appointmentTime}\nStatus: ${appt.status}"),
        isThreeLine: true,
        trailing: showActions ? Row( mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(padding: EdgeInsets.zero, constraints: BoxConstraints(), onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => EditAppointment(id: appt.idA!,)));
                _refeeshData();
                SyncService.syncAll();
              },
              icon: Icon(Icons.edit, size: 20),
            ),

            SizedBox(width: 6),
            IconButton(padding: EdgeInsets.zero, constraints: BoxConstraints(), onPressed: () => showDeleteConfirmDialog(appt.idA!),
              icon: Icon(Icons.delete, size: 20),
            ),
          ],
        )

            : IconButton(onPressed: () => showDeleteConfirmDialog(appt.idA!), icon: Icon(Icons.delete)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _datastorge.where(_isUpcoming).toList()..sort((a, b) => _apptDateTime(a).compareTo(_apptDateTime(b)));
    final past = _datastorge.where((a) => !_isUpcoming(a) && a.status != "Cancelled").toList()..sort((a, b) => _apptDateTime(b).compareTo(_apptDateTime(a)));
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Welcome $patientN"),
          backgroundColor: Color(0xFFC9E2F5),
          actions: [
            IconButton(onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilP(patientId: widget.patientId)),
                ).then((value) {
                  PatientData();
                  SyncService.syncAll();
                });
              },
              icon: Icon(Icons.person_pin, color: Colors.black),
            ),

            IconButton(onPressed: () async {await clearSession();Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const Login()), (route) => false,);
              },
              icon: Icon(Icons.logout, color: Colors.black),
            ),

          ],

          bottom: TabBar(labelColor: Colors.black, tabs: [Tab(text: "Upcoming"), Tab(text: "Past"),],),
        ),

        body: _isloading ? Center(child: CircularProgressIndicator()) : TabBarView(
          children: [
            upcoming.isEmpty ? Center(child: Text("No upcoming appointments")) : ListView.builder(
              itemCount: upcoming.length, itemBuilder: (context, index) => _buildAppointmentCard(upcoming[index], true),
            ),

            past.isEmpty ? Center(child: Text("No past appointments")) : ListView.builder( itemCount: past.length,
              itemBuilder: (context, index) => _buildAppointmentCard(past[index], false),
            ),
          ],
        ),

        floatingActionButton: FloatingActionButton(onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => Booking(patientId: widget.patientId,)));
          _refeeshData();
          SyncService.syncAll();
        },
          backgroundColor: Color(0xFFC9E2F5),
          child: Icon(Icons.add, color: Colors.black),
        ),
      ),
    );
  }
}
