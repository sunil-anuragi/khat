import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/app_constants.dart';
import 'package:flutter_chat_demo/controllers/auth_controller.dart';
import 'package:flutter_chat_demo/controllers/chat_controller.dart';
import 'package:flutter_chat_demo/controllers/home_controller.dart';
import 'package:flutter_chat_demo/controllers/setting_controller.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/color_constants.dart';
import 'pages/pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

 
  final firebaseAuth = FirebaseAuth.instance;
  final googleSignIn = GoogleSignIn();
  final firebaseFirestore = FirebaseFirestore.instance;
  // final firebaseStorage = FirebaseStorage.instance;

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  Get.put(prefs);

  // Initialize Firebase Messaging
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
    String? token = await messaging.getToken();
    print('Token: $token');
  } else {
    print('User declined or has not accepted permission');
  }
  Get.put(AuthController(
    firebaseAuth: firebaseAuth,
    googleSignIn: googleSignIn,
    prefs: prefs,
    firebaseFirestore: firebaseFirestore,
  ));
  Get.put(SettingController());
  Get.put(HomeController());
  Get.put(ChatController());

  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  MyApp({required this.prefs});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appTitle,
      theme: ThemeData(
        primaryColor: ColorConstants.themeColor,
        primarySwatch: MaterialColor(0xfff5a623, ColorConstants.swatchColor),
      ),
      home: SplashPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
