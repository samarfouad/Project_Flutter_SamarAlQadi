import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class SqlHelper {
  static Future<void> createTables(Database database) async {
    await database.execute("""
      CREATE TABLE patients (
        id_P TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        phone TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0
      );
    """);

    await database.execute("""
      CREATE TABLE doctors (
        id_D INTEGER PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        specialty TEXT NOT NULL,
        phone TEXT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        workingDays TEXT,
        startTime TEXT,
        endTime TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0
      );
    """);

    await database.execute("""
      CREATE TABLE appointments (
        id_A INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        remoteId TEXT,
        patientId TEXT NOT NULL,
        doctorId INTEGER NOT NULL,
        appointmentDate TEXT NOT NULL,
        appointmentTime TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Pending',
        isSynced INTEGER NOT NULL DEFAULT 0,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(patientId) REFERENCES patients(id_P),
        FOREIGN KEY(doctorId) REFERENCES doctors(id_D),
        UNIQUE(doctorId, appointmentDate, appointmentTime)
      );
    """);
  }

  static Future<Database> initializeDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "clinicAppointment.db");
    return openDatabase(path, version: 1, onCreate: (Database database, int version) async {
      await createTables(database);

        await database.insert("doctors", {
          "id_D": 1, "name": "Dr.Samar Al Qadi", "specialty": "Orthodontist",
          "phone": "0591111111", "email": "Sammmar@gmail.com", "password": "123456",
          "workingDays": "Sat,Mon,Wed", "startTime": "08:00 AM", "endTime": "02:00 PM",
          "isSynced": 1,
        });
        await database.insert("doctors", {
          "id_D": 2, "name": "Dr.Samar Al Shaer", "specialty": "Endodontist",
          "phone": "0592222222", "email": "sam@gmail.com", "password": "123456",
          "workingDays": "Sun,Tue,Thu", "startTime": "08:00 AM", "endTime": "04:00 PM",
          "isSynced": 1,
        });
        await database.insert("doctors", {
          "id_D": 3, "name": "Dr.Fouad Al Qadi", "specialty": "Prosthodontist",
          "phone": "0593333333", "email": "Fouad@gmail.com", "password": "123456",
          "workingDays": "Sat,Sun,Mon", "startTime": "09:00 AM", "endTime": "02:00 PM",
          "isSynced": 1,
        });
        await database.insert("doctors", {
          "id_D": 4, "name": "Dr.Hassan Al Qadi", "specialty": "Oral Surgeon",
          "phone": "0594444444", "email": "Hassan@clinic.com", "password": "123456",
          "workingDays": "Mon,Wed,Thu", "startTime": "11:00 AM", "endTime": "05:00 PM",
          "isSynced": 1,
        });
      },
    );
  }

  //****************************************************************************************************

  static Future<int> createOrUpdatePatient(PatientModel patient) async {
    final db = await SqlHelper.initializeDB();
    return await db.insert("patients", patient.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<PatientModel?> getPatientById(String id_P) async {
    final db = await SqlHelper.initializeDB();
    final result = await db.query("patients", where: "id_P = ?", whereArgs: [id_P], limit: 1);
    return result.isNotEmpty ? PatientModel.fromMap(result[0]) : null;
  }

  static Future<PatientModel?> getPatientByEmail(String email) async {
    final db = await SqlHelper.initializeDB();
    final result = await db.query("patients", where: "email = ?", whereArgs: [email], limit: 1);
    return result.isNotEmpty ? PatientModel.fromMap(result[0]) : null;
  }

  static Future<int> updatePatient(PatientModel patient) async {
    final db = await SqlHelper.initializeDB();
    return await db.update("patients", patient.toMap(), where: "id_P = ?", whereArgs: [patient.idP]);
  }

  static Future<int> updatePatientSyncStatus(String id_P, int isSynced) async {
    final db = await SqlHelper.initializeDB();
    return await db.update("patients", {"isSynced": isSynced}, where: "id_P = ?", whereArgs: [id_P]);
  }

  static Future<List<PatientModel>> getUnsyncedPatients() async {
    final db = await SqlHelper.initializeDB();
    final result = await db.query("patients", where: "isSynced = ?", whereArgs: [0]);
    return result.map((map) => PatientModel.fromMap(map)).toList();
  }

  //****************************************************************************************************

  static Future<List<DoctorModel>> getDoctors() async {
    final db = await SqlHelper.initializeDB();
    final result = await db.query("doctors", orderBy: "name");
    return result.map((map) => DoctorModel.fromMap(map)).toList();
  }

  static Future<DoctorModel?> getDoctorByEmail(String email) async {
    final db = await SqlHelper.initializeDB();
    final result = await db.query("doctors", where: "email = ?", whereArgs: [email], limit: 1);
    return result.isNotEmpty ? DoctorModel.fromMap(result[0]) : null;
  }

  static Future<int> updateDoctor(DoctorModel doctor) async {
    final db = await SqlHelper.initializeDB();
    return await db.update("doctors", doctor.toMap(), where: "id_D = ?", whereArgs: [doctor.idD]);
  }

  static Future<int> updateDoctorSyncStatus(int id_D, int isSynced) async {
    final db = await SqlHelper.initializeDB();
    return await db.update("doctors", {"isSynced": isSynced}, where: "id_D = ?", whereArgs: [id_D]);
  }

  static Future<List<DoctorModel>> getUnsyncedDoctors() async {
    final db = await SqlHelper.initializeDB();
    final result = await db.query("doctors", where: "isSynced = ?", whereArgs: [0]);
    return result.map((map) => DoctorModel.fromMap(map)).toList();
  }

  //****************************************************************************************************

  static Future<bool> isAppointmentAvailable(int doctorId, String appointmentDate, String appointmentTime) async {
    final db = await SqlHelper.initializeDB();
    final result = await db.query("appointments", where: "doctorId = ? AND appointmentDate = ? AND appointmentTime = ? AND status != ?",
                                   whereArgs: [doctorId, appointmentDate, appointmentTime, "Cancelled"],
    );
    return result.isEmpty;
  }

  static Future<int> createAppointment(AppointmentModel appointment) async {
    final db = await SqlHelper.initializeDB();
    final data = appointment.toMap();
    data["remoteId"] = appointment.remoteId;
    return await db.insert("appointments", data, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  static Future<AppointmentModel?> getAppointmentById(int id) async {
    final db = await SqlHelper.initializeDB();
    final result = await db.query("appointments", where: "id_A = ?", whereArgs: [id], limit: 1);
    return result.isNotEmpty ? AppointmentModel.fromMap(result[0]) : null;
  }

  static Future<AppointmentModel?> getAppointmentByRemoteId(String remoteId) async {
    final db = await SqlHelper.initializeDB();
    final result = await db.query("appointments", where: "remoteId = ?", whereArgs: [remoteId], limit: 1);
    return result.isNotEmpty ? AppointmentModel.fromMap(result[0]) : null;
  }

  static Future<List<AppointmentModel>> getAppointmentsByPatient(String patientId) async {
    final db = await SqlHelper.initializeDB();
    final result = await db.query("appointments", where: "patientId = ?", whereArgs:
                                  [patientId], orderBy: "appointmentDate DESC, appointmentTime ASC",
    );
    return result.map((map) => AppointmentModel.fromMap(map)).toList();
  }

  static Future<List<AppointmentModel>> getAppointmentsByDoctor(int doctorId) async {
    final db = await SqlHelper.initializeDB();
    final result = await db.query("appointments", where: "doctorId = ?", whereArgs:
                                  [doctorId], orderBy: "appointmentDate DESC, appointmentTime ASC",
    );
    return result.map((map) => AppointmentModel.fromMap(map)).toList();
  }

  static Future<int> updateAppointment(int id, String appointmentDate, String appointmentTime) async {
    final db = await SqlHelper.initializeDB();
    final data = {"appointmentDate": appointmentDate, "appointmentTime": appointmentTime, "isSynced": 0};
    return await db.update("appointments", data, where: "id_A = ?", whereArgs: [id]);
  }

  static Future<int> updateAppointmentStatus(int id, String status) async {
    final db = await SqlHelper.initializeDB();
    final data = {"status": status, "isSynced": 0};
    return await db.update("appointments", data, where: "id_A = ?", whereArgs: [id]);
  }

  static Future<void> deleteAppointment(int id) async {
    final db = await SqlHelper.initializeDB();
    try {
      await db.delete("appointments", where: "id_A = ?", whereArgs: [id]);
    } catch (err) {
      print("Error: $err"); }
  }

  static Future<int> updateAppointmentSyncStatus(int id, int isSynced) async {
    final db = await SqlHelper.initializeDB();
    return await db.update("appointments", {"isSynced": isSynced}, where: "id_A = ?", whereArgs: [id]);
  }

  static Future<int> setAppointmentRemoteId(int id, String remoteId) async {
    final db = await SqlHelper.initializeDB();
    return await db.update("appointments", {"remoteId": remoteId}, where: "id_A = ?", whereArgs: [id]);
  }

  static Future<List<AppointmentModel>> getUnsyncedAppointments() async {
    final db = await SqlHelper.initializeDB();
    final result = await db.query("appointments", where: "isSynced = ?", whereArgs: [0]);
    return result.map((map) => AppointmentModel.fromMap(map)).toList();
  }

  static Future<void> insertAppointmentFromRemote(AppointmentModel appt, String remoteId) async {
    final db = await SqlHelper.initializeDB();
    final data = {"remoteId": remoteId,
      "patientId": appt.patientId,
      "doctorId": appt.doctorId,
      "appointmentDate": appt.appointmentDate,
      "appointmentTime": appt.appointmentTime,
      "status": appt.status,
      "isSynced": 1,
    };
    try {
      await db.insert("appointments", data, conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (e) {
      print("insertAppointmentFromRemote error: $e");
    }
  }

  static Future<void> updateAppointmentFromRemote(int localId, AppointmentModel appt) async {
    final db = await SqlHelper.initializeDB();
    final data = {
      "appointmentDate": appt.appointmentDate,
      "appointmentTime": appt.appointmentTime,
      "status": appt.status,
      "isSynced": 1,
    };
    await db.update("appointments", data, where: "id_A = ?", whereArgs: [localId]);
  }
}
