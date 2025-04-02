import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/models/models.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final SharedPreferences _prefs = Get.find<SharedPreferences>();

  final RxBool isLoading = false.obs;
  final RxBool isShowSticker = false.obs;
  final RxBool isTyping = false.obs;
  final RxBool isTypingLocal = false.obs;
  final RxBool isOnline = false.obs;
  final RxBool status = false.obs;
  final RxString whoIsTyping = ''.obs;
  final RxString imageUrl = ''.obs;
  final Rx<File?> imageFile = Rx<File?>(null);
  final RxString groupChatId = ''.obs;
  final RxString currentUserId = ''.obs;
  final RxString peerId = ''.obs;
  final RxString peerAvatar = ''.obs;
  final RxString peerNickname = ''.obs;

  @override
  void onInit() {
    super.onInit();
    readLocal();
  }

  void readLocal() {
    currentUserId.value = _prefs.getString(FirestoreConstants.id) ?? '';
  }

  void setCurrentChatUser(String peerId, String peerAvatar, String peerNickname) {
    this.peerId.value = peerId;
    this.peerAvatar.value = peerAvatar;
    this.peerNickname.value = peerNickname;
    
    if (currentUserId.value.compareTo(peerId) > 0) {
      groupChatId.value = '$currentUserId-$peerId';
    } else {
      groupChatId.value = '$peerId-$currentUserId';
    }

    updateDataFirestore(
      FirestoreConstants.pathUserCollection,
      currentUserId.value,
      {FirestoreConstants.chattingWith: peerId},
    );
  }

  Future<void> uploadFile(File file) async {
    try {
      isLoading.value = true;
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = _storage.ref().child('uploads/$fileName');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      imageUrl.value = await snapshot.ref.getDownloadURL();
      
      await sendMessage(imageUrl.value, 1); // 1 for image type
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

  Future<void> updateDataFirestoreAllField(String collectionPath, String docPath, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collectionPath).doc(docPath).set(data);
    } catch (e) {
      print('Error updating data: $e');
      rethrow;
    }
  }

  Future<void> sendMessage(String content, int type) async {
    if (content.trim().isNotEmpty) {
      final message = MessageChat(
        idFrom: currentUserId.value,
        idTo: peerId.value,
        timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        type: type,
        istyping: false,
        whotyping: '',
        isonline: false,
        status: true,
      );

      await _firestore
          .collection(FirestoreConstants.pathMessageCollection)
          .doc(groupChatId.value)
          .collection(groupChatId.value)
          .add(message.toJson());
    } else {
      Get.snackbar(
        'Error',
        'Nothing to send',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Stream<QuerySnapshot> getChatStream(String groupChatId, int limit) {
    return _firestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .collection(groupChatId)
        .orderBy(FirestoreConstants.timestamp, descending: true)
        .limit(limit)
        .snapshots();
  }

  void checkIsTyping() {
    if (isTypingLocal.value != isTyping.value) {
      isTypingLocal.value = isTyping.value;
      updateDataFirestoreAllField(
        FirestoreConstants.pathMessageCollection,
        groupChatId.value,
        {
          'istyping': isTyping.value,
          'whotyping': currentUserId.value,
        },
      );
    }
  }

  void clearCurrentChatUser() {
    updateDataFirestore(
      FirestoreConstants.pathUserCollection,
      currentUserId.value,
      {FirestoreConstants.chattingWith: null},
    );
    groupChatId.value = '';
    peerId.value = '';
    peerAvatar.value = '';
    peerNickname.value = '';
  }
} 