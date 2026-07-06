import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sqlHelper.dart';
import 'models.dart';

class SyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static bool _isSyncing = false;
  static const Duration _timeout = Duration(seconds: 5);

  static Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      await _syncPatients();
      await _syncDoctors();
      await _syncAppointments();
    } catch (e) {
      print("SyncService error: $e");
    } finally {
      _isSyncing = false;
    }
  }

  static Future<void> _syncPatients() async {
    final unsynced = await SqlHelper.getUnsyncedPatients();
    for (var patient in unsynced) {
      try {
        await _firestore.collection("patients").doc(patient.idP).set(patient.toMap(), SetOptions(merge: true)).timeout(_timeout);
        await SqlHelper.updatePatientSyncStatus(patient.idP, 1);
      } catch (e) {
        print("Sync patient ${patient.idP} failed: $e");
      }
    }
  }

  static Future<void> _syncDoctors() async {
    final unsynced = await SqlHelper.getUnsyncedDoctors();
    for (var doctor in unsynced) {
      try {
        await _firestore.collection("doctors").doc(doctor.idD.toString()).set(doctor.toMap(), SetOptions(merge: true)).timeout(_timeout);
        await SqlHelper.updateDoctorSyncStatus(doctor.idD, 1);
      } catch (e) {
        print("Sync doctor ${doctor.idD} failed: $e");
      }
    }
  }

  static Future<void> _syncAppointments() async {
    final unsynced = await SqlHelper.getUnsyncedAppointments();
    for (var appointment in unsynced) {
      try {
        final docId = appointment.remoteId ?? "${appointment.patientId}_${appointment.idA}";
        await _firestore.collection("appointments").doc(docId).set(appointment.toMap(), SetOptions(merge: true)).timeout(_timeout);
        if (appointment.remoteId == null) {
          await SqlHelper.setAppointmentRemoteId(appointment.idA!, docId);
        }
        await SqlHelper.updateAppointmentSyncStatus(appointment.idA!, 1);
      } catch (e) {
        print("Sync appointment ${appointment.idA} failed: $e");
      }
    }
  }

  static Future<void> pullPatient(String patientId) async {
    try {
      final doc = await _firestore.collection("patients").doc(patientId).get().timeout(_timeout);
      if (doc.exists) {
        final data = doc.data()!;
        await SqlHelper.createOrUpdatePatient(
          PatientModel(
            idP: patientId,
            name: data["name"] ?? "",
            email: data["email"] ?? "",
            password: data["password"] ?? "",
            phone: data["phone"] ?? "",
            isSynced: 1,
          ),
        );
      }
    } catch (e) {
      print("pullPatient failed: $e");
    }
  }

  static Future<void> pullDoctor(int doctorId) async {
    try {
      final doc = await _firestore.collection("doctors").doc(doctorId.toString()).get().timeout(_timeout);
      if (doc.exists) {
        final remoteDoctor = DoctorModel.fromMap(doc.data()!);
        await SqlHelper.updateDoctor(remoteDoctor);
        await SqlHelper.updateDoctorSyncStatus(doctorId, 1);
      }
    } catch (e) {
      print("pullDoctor failed: $e");
    }
  }

  static Future<void> pullAppointmentsForDoctor(int doctorId) async {
    try {
      final snapshot = await _firestore.collection("appointments").where("doctorId", isEqualTo: doctorId).get().timeout(_timeout);
      for (var doc in snapshot.docs) {
        await _mergeRemoteAppointment(doc.id, doc.data());
      }
    } catch (e) {
      print("pullAppointmentsForDoctor failed: $e");
    }
  }

  static Future<void> pullAppointmentsForPatient(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection("appointments")
          .where("patientId", isEqualTo: patientId)
          .get()
          .timeout(_timeout);

      for (var doc in snapshot.docs) {
        await _mergeRemoteAppointment(doc.id, doc.data());
      }
    } catch (e) {
      print("pullAppointmentsForPatient failed: $e");
    }
  }

  static Future<void> _mergeRemoteAppointment(String remoteId, Map<String, dynamic> data) async {
    final remoteAppt = AppointmentModel.fromMap(data);
    final existing = await SqlHelper.getAppointmentByRemoteId(remoteId);
    if (existing == null) {
      await SqlHelper.insertAppointmentFromRemote(remoteAppt, remoteId);
    } else {
      await SqlHelper.updateAppointmentFromRemote(existing.idA!, remoteAppt);
    }
  }

  static Future<void> deleteAppointmentEverywhere(int id) async {
    final appt = await SqlHelper.getAppointmentById(id);
    await SqlHelper.deleteAppointment(id);
    if (appt != null) {
      final docId = appt.remoteId ?? "${appt.patientId}_$id";
      _firestore.collection("appointments").doc(docId).delete().timeout(_timeout).catchError((e) {
        print("Delete appointment $id from Firestore failed: $e");
      });
    }
  }
}
