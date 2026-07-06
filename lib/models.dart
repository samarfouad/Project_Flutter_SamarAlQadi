class PatientModel {
  final String idP;
  final String name;
  final String email;
  final String password;
  final String phone;
  final int isSynced;

  PatientModel({
    required this.idP,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    this.isSynced = 0,
  });

  factory PatientModel.fromMap(Map<String, dynamic> map) {
    return PatientModel(
      idP: map["id_P"] ?? "",
      name: map["name"] ?? "",
      email: map["email"] ?? "",
      password: map["password"] ?? "",
      phone: map["phone"] ?? "",
      isSynced: map["isSynced"] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {"id_P": idP, "name": name, "email": email, "password": password, "phone": phone, "isSynced": isSynced};
  }
}

//***********************************************************************************************************************

class DoctorModel {
  final int idD;
  final String name;
  final String specialty;
  final String phone;
  final String email;
  final String password;
  final String workingDays;
  final String startTime;
  final String endTime;
  final int isSynced;

  DoctorModel({
    required this.idD,
    required this.name,
    required this.specialty,
    required this.phone,
    required this.email,
    required this.password,
    required this.workingDays,
    required this.startTime,
    required this.endTime,
    this.isSynced = 0,
  });

  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    return DoctorModel(
      idD: map["id_D"] is String ? int.parse(map["id_D"]) : (map["id_D"] ?? 0),
      name: map["name"] ?? "",
      specialty: map["specialty"] ?? "",
      phone: map["phone"] ?? "",
      email: map["email"] ?? "",
      password: map["password"] ?? "",
      workingDays: map["workingDays"] ?? "",
      startTime: map["startTime"] ?? "",
      endTime: map["endTime"] ?? "",
      isSynced: map["isSynced"] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {"id_D": idD, "name": name, "specialty": specialty, "phone": phone, "email": email, "password": password,
             "workingDays": workingDays, "startTime": startTime, "endTime": endTime, "isSynced": isSynced};
  }
}

//***********************************************************************************************************************

class AppointmentModel {
  final int? idA;
  final String? remoteId;
  final String patientId;
  final int doctorId;
  final String appointmentDate;
  final String appointmentTime;
  final String status;
  final int isSynced;

  AppointmentModel({
    this.idA,
    this.remoteId,
    required this.patientId,
    required this.doctorId,
    required this.appointmentDate,
    required this.appointmentTime,
    this.status = "Pending",
    this.isSynced = 0,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      idA: map["id_A"],
      remoteId: map["remoteId"],
      patientId: map["patientId"] ?? "",
      doctorId: map["doctorId"] is String ? int.parse(map["doctorId"]) : (map["doctorId"] ?? 0),
      appointmentDate: map["appointmentDate"] ?? "",
      appointmentTime: map["appointmentTime"] ?? "",
      status: map["status"] ?? "Pending",
      isSynced: map["isSynced"] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {"id_A": idA, "patientId": patientId, "doctorId": doctorId, "appointmentDate": appointmentDate,
            "appointmentTime": appointmentTime, "status": status, "isSynced": isSynced};
  }
}
