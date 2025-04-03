import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/models/models.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SharedPreferences _prefs = Get.find<SharedPreferences>();
  final RxList<UserChat> users = <UserChat>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  String? getCurrentUserId() {
    return _prefs.getString(FirestoreConstants.id);
  }

  String? getCurrentUserNickname() {
    return _prefs.getString(FirestoreConstants.nickname);
  }

  String? getCurrentUserPhotoUrl() {
    return _prefs.getString(FirestoreConstants.photoUrl);
  }

  Future<void> updateDataFirestore(String collectionPath, String docPath, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collectionPath).doc(docPath).update(data);
    } catch (e) {
      print('Error updating data: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getStreamFireStore(String pathCollection, int limit, String searchQuery) {
    if (searchQuery.isEmpty) {
      return _firestore
          .collection(pathCollection)
          .limit(limit)
          .snapshots();
    }

    return _firestore
        .collection(pathCollection)
        .where('nickname', isGreaterThanOrEqualTo: searchQuery)
        .where('nickname', isLessThanOrEqualTo: searchQuery + '\uf8ff')
        .limit(limit)
        .snapshots();
  }

  Future<void> loadUsers() async {
    try {
      isLoading.value = true;
      final QuerySnapshot querySnapshot = await _firestore
          .collection(FirestoreConstants.pathUserCollection)
          .get();
      
      users.value = querySnapshot.docs
          .map((doc) => UserChat.fromDocument(doc))
          .where((user) => user.id != getCurrentUserId())
          .toList();
    } catch (e) {
      print('Error loading users: $e');
      Get.snackbar(
        'Error',
        'Failed to load users',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      await loadUsers();
      return;
    }

    try {
      isLoading.value = true;
      final QuerySnapshot querySnapshot = await _firestore
          .collection(FirestoreConstants.pathUserCollection)
          .where(FirestoreConstants.nickname, isEqualTo: query)
          .get();
      
      users.value = querySnapshot.docs
          .map((doc) => UserChat.fromDocument(doc))
          .where((user) => user.id != getCurrentUserId())
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      Get.snackbar(
        'Error',
        'Failed to search users',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile({
    String? nickname,
    String? photoUrl,
    String? aboutMe,
  }) async {
    try {
      final String? userId = getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      final Map<String, dynamic> data = {};
      if (nickname != null) {
        data[FirestoreConstants.nickname] = nickname;
        await _prefs.setString(FirestoreConstants.nickname, nickname);
      }
      if (photoUrl != null) {
        data[FirestoreConstants.photoUrl] = photoUrl;
        await _prefs.setString(FirestoreConstants.photoUrl, photoUrl);
      }
      if (aboutMe != null) {
        data[FirestoreConstants.aboutMe] = aboutMe;
      }

      if (data.isNotEmpty) {
        await updateDataFirestore(
          FirestoreConstants.pathUserCollection,
          userId,
          data,
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      Get.snackbar(
        'Error',
        'Failed to update profile',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    }
  }

  Future<void> updateUserStatus(String userId, bool isOnline) async {
    try {
      await _firestore
          .collection(FirestoreConstants.pathUserCollection)
          .doc(userId)
          .update({
        'isOnline': isOnline,
        'lastSeen': DateTime.now().millisecondsSinceEpoch.toString(),
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update user status',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
} 