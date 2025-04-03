import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/models/models.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final SharedPreferences _prefs = Get.find<SharedPreferences>();
  final RxBool isLoading = false.obs;
  final RxString id = ''.obs;
  final RxString nickname = ''.obs;
  final RxString aboutMe = ''.obs;
  final RxString photoUrl = ''.obs;
  final Rx<File?> avatarImageFile = Rx<File?>(null);

  

  @override
  void onInit() {
    super.onInit();
    readLocal();
  }

  void readLocal() {
    id.value = _prefs.getString(FirestoreConstants.id) ?? "";
    nickname.value = _prefs.getString(FirestoreConstants.nickname) ?? "";
    aboutMe.value = _prefs.getString(FirestoreConstants.aboutMe) ?? "";
    photoUrl.value = _prefs.getString(FirestoreConstants.photoUrl) ?? "";
  }

  Future<void> uploadFile(File file) async {
    try {
      isLoading.value = true;
      String fileName = id.value;
      final ref = _storage.ref().child('uploads/$fileName');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      photoUrl.value = await snapshot.ref.getDownloadURL();
      
      UserChat updateInfo = UserChat(
        id: id.value,
        photoUrl: photoUrl.value,
        nickname: nickname.value,
        aboutMe: aboutMe.value,
      );

      await updateDataFirestore(
        FirestoreConstants.pathUserCollection,
        id.value,
        updateInfo.toJson(),
      );
      
      await _prefs.setString(FirestoreConstants.photoUrl, photoUrl.value);
      Get.snackbar(
        'Success',
        'Upload successful',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error uploading file: $e');
      Get.snackbar(
        'Error',
        'Failed to upload file',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateDataFirestore(String collectionPath, String docPath, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collectionPath).doc(docPath).update(data);
    } catch (e) {
      print('Error updating data: $e');
      rethrow;
    }
  }

  Future<void> handleUpdateData() async {
    try {
      isLoading.value = true;
      UserChat updateInfo = UserChat(
        id: id.value,
        photoUrl: photoUrl.value,
        nickname: nickname.value,
        aboutMe: aboutMe.value,
      );

      await updateDataFirestore(
        FirestoreConstants.pathUserCollection,
        id.value,
        updateInfo.toJson(),
      );

      await _prefs.setString(FirestoreConstants.nickname, nickname.value);
      await _prefs.setString(FirestoreConstants.aboutMe, aboutMe.value);
      await _prefs.setString(FirestoreConstants.photoUrl, photoUrl.value);

      Get.snackbar(
        'Success',
        'Update successful',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error updating data: $e');
      Get.snackbar(
        'Error',
        'Failed to update data',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
} 