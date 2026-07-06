import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:project_flutter_final/SyncService.dart';
import 'package:project_flutter_final/session_prefs.dart';
import 'login.dart';
import 'P_Dashbord.dart';
import 'D_Dashbord.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCqmjAFXqb-FqLo0H9ZQV1K56Yt494MzH8",
      appId: "1:692703851580:android:f66bed3ee28b67ee6f3f39",
      messagingSenderId: "692703851580",
      projectId: "projectfinal-14024",
    ),
  );

  SyncService.syncAll();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Map<String, String>?>(
        future: getSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }

          final session = snapshot.data;
          if (session != null && session["role"] == "patient") {
            return P_Dashbord(patientId: session["userId"]!);
          }
          if (session != null && session["role"] == "doctor") {
            return D_Dashbord(doctorId: int.parse(session["userId"]!));
          }
          return const HomeScreen();
        },
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Color(0xFFFFFFFF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('asset/Images/image1.jpg', width: 400, height: 400, fit: BoxFit.contain,),
              SizedBox(height: 80),
              ElevatedButton(onPressed:(){
                Navigator.push(context, MaterialPageRoute(builder:(context)=>const Login()));
              },style:ElevatedButton.styleFrom(backgroundColor: Color(0xFFC9E2F5),
                  foregroundColor:Color(0xFF000000),shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(15.0)),minimumSize: Size(200, 60)),
                  child:Text("Log in",style: TextStyle(fontSize:25.0,fontWeight:FontWeight.bold))
              ),
            ],
          ),
        )
    );
  }
}
