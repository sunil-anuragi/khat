import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/models/models.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  authenticating,
  authenticateError,
  authenticateException,
  authenticateCanceled,
}

class AuthController extends GetxController {
  final GoogleSignIn googleSignIn;
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFirestore;
  final SharedPreferences prefs;

  final status = AuthStatus.uninitialized.obs;
  final isLoading = false.obs;

  AuthController({
    required this.firebaseAuth,
    required this.googleSignIn,
    required this.prefs,
    required this.firebaseFirestore,
  });

  String? getUserFirebaseId() {
    return prefs.getString(FirestoreConstants.id);
  }

  Future<bool> isLoggedIn() async {
    bool isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn && prefs.getString(FirestoreConstants.id)?.isNotEmpty == true) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> handleSignIn() async {
    try {
      status.value = AuthStatus.authenticating;
      isLoading.value = true;

      GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        GoogleSignInAuthentication? googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        User? firebaseUser = (await firebaseAuth.signInWithCredential(credential)).user;

        if (firebaseUser != null) {
          final QuerySnapshot result = await firebaseFirestore
              .collection(FirestoreConstants.pathUserCollection)
              .where(FirestoreConstants.id, isEqualTo: firebaseUser.uid)
              .get();
          final List<DocumentSnapshot> documents = result.docs;
          if (documents.length == 0) {
            // Writing data to server because here is a new user
            firebaseFirestore.collection(FirestoreConstants.pathUserCollection).doc(firebaseUser.uid).set({
              FirestoreConstants.nickname: firebaseUser.displayName,
              FirestoreConstants.photoUrl: firebaseUser.photoURL,
              FirestoreConstants.id: firebaseUser.uid,
              'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
              FirestoreConstants.chattingWith: null
            });

            // Write data to local storage
            User? currentUser = firebaseUser;
            await prefs.setString(FirestoreConstants.id, currentUser.uid);
            await prefs.setString(FirestoreConstants.nickname, currentUser.displayName ?? "");
            await prefs.setString(FirestoreConstants.photoUrl, currentUser.photoURL ?? "");
          } else {
            // Already sign up, just get data from firestore
            DocumentSnapshot documentSnapshot = documents[0];
            UserChat userChat = UserChat.fromDocument(documentSnapshot);
            // Write data to local
            await prefs.setString(FirestoreConstants.id, userChat.id);
            await prefs.setString(FirestoreConstants.nickname, userChat.nickname);
            await prefs.setString(FirestoreConstants.photoUrl, userChat.photoUrl);
            await prefs.setString(FirestoreConstants.aboutMe, userChat.aboutMe);
          }
          status.value = AuthStatus.authenticated;
          return true;
        } else {
          status.value = AuthStatus.authenticateError;
          return false;
        }
      } else {
        status.value = AuthStatus.authenticateCanceled;
        return false;
      }
    } catch (e) {
      status.value = AuthStatus.authenticateException;
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> handleEmailPasswordSignIn(String email, String password) async {
    try {
      status.value = AuthStatus.authenticating;
      isLoading.value = true;

      UserCredential userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        final QuerySnapshot result = await firebaseFirestore
            .collection(FirestoreConstants.pathUserCollection)
            .where(FirestoreConstants.id, isEqualTo: firebaseUser.uid)
            .get();
        final List<DocumentSnapshot> documents = result.docs;
        
        if (documents.length == 0) {
          // Writing data to server because here is a new user
          firebaseFirestore.collection(FirestoreConstants.pathUserCollection).doc(firebaseUser.uid).set({
            FirestoreConstants.nickname: firebaseUser.displayName ?? email.split('@')[0],
            FirestoreConstants.photoUrl: firebaseUser.photoURL,
            FirestoreConstants.id: firebaseUser.uid,
            'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
            FirestoreConstants.chattingWith: null
          });

          // Write data to local storage
          await prefs.setString(FirestoreConstants.id, firebaseUser.uid);
          await prefs.setString(FirestoreConstants.nickname, firebaseUser.displayName ?? email.split('@')[0]);
          await prefs.setString(FirestoreConstants.photoUrl, firebaseUser.photoURL ?? "");
        } else {
          // Already sign up, just get data from firestore
          DocumentSnapshot documentSnapshot = documents[0];
          UserChat userChat = UserChat.fromDocument(documentSnapshot);
          // Write data to local
          await prefs.setString(FirestoreConstants.id, userChat.id);
          await prefs.setString(FirestoreConstants.nickname, userChat.nickname);
          await prefs.setString(FirestoreConstants.photoUrl, userChat.photoUrl);
          await prefs.setString(FirestoreConstants.aboutMe, userChat.aboutMe);
        }
        status.value = AuthStatus.authenticated;
        return true;
      } else {
        status.value = AuthStatus.authenticateError;
        return false;
      }
    } catch (e) {
      status.value = AuthStatus.authenticateError;
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> handleEmailPasswordSignUp(String email, String password) async {
    try {
      status.value = AuthStatus.authenticating;
      isLoading.value = true;

      UserCredential userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        // Writing data to server for new user
        firebaseFirestore.collection(FirestoreConstants.pathUserCollection).doc(firebaseUser.uid).set({
          FirestoreConstants.nickname: email.split('@')[0],
          FirestoreConstants.photoUrl: firebaseUser.photoURL,
          FirestoreConstants.id: firebaseUser.uid,
          'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
          FirestoreConstants.chattingWith: null
        });

        // Write data to local storage
        await prefs.setString(FirestoreConstants.id, firebaseUser.uid);
        await prefs.setString(FirestoreConstants.nickname, email.split('@')[0]);
        await prefs.setString(FirestoreConstants.photoUrl, firebaseUser.photoURL ?? "");

        status.value = AuthStatus.authenticated;
        return true;
      } else {
        status.value = AuthStatus.authenticateError;
        return false;
      }
    } catch (e) {
      status.value = AuthStatus.authenticateError;
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> handleSignOut() async {
    status.value = AuthStatus.uninitialized;
    await firebaseAuth.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();
  }
} 