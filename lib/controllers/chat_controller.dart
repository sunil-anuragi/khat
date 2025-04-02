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
  final RxString lastMessage = ''.obs;
  final RxString lastMessageTime = ''.obs;
  final RxList<String> participants = <String>[].obs;
  final RxMap<String, bool> typingStatus = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    readLocal();
  }

  void readLocal() {
    currentUserId.value = _prefs.getString(FirestoreConstants.id) ?? '';
  }

  Future<void> setCurrentChatUser(String peerId, String peerAvatar, String peerNickname) async {
    if (currentUserId.value.isEmpty) {
      Get.snackbar(
        'Error',
        'User not logged in',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    this.peerId.value = peerId;
    this.peerAvatar.value = peerAvatar;
    this.peerNickname.value = peerNickname;
    
    if (currentUserId.value.compareTo(peerId) > 0) {
      groupChatId.value = '$currentUserId-$peerId';
    } else {
      groupChatId.value = '$peerId-$currentUserId';
    }

    try {
      // Check if chat exists
      final chatDoc = await _firestore
          .collection(FirestoreConstants.pathMessageCollection)
          .doc(groupChatId.value)
          .get();

      if (!chatDoc.exists) {
        // Create new chat
        await _firestore
            .collection(FirestoreConstants.pathMessageCollection)
            .doc(groupChatId.value)
            .set({
          'participants': [currentUserId.value, peerId],
          'lastMessage': '',
          'lastMessageTime': DateTime.now().millisecondsSinceEpoch.toString(),
          'typingStatus': {
            currentUserId.value: false,
            peerId: false,
          },
          'onlineStatus': {
            currentUserId.value: true,
            peerId: false,
          },
          'isonline': false,
          'status': false,
        });
      } else {
        // Update current user's online status
        await updateDataFirestore(
          FirestoreConstants.pathMessageCollection,
          groupChatId.value,
          {
            'onlineStatus.${currentUserId.value}': true,
          },
        );
      }

      // Update current user's chatting status
      await updateDataFirestore(
        FirestoreConstants.pathUserCollection,
        currentUserId.value,
        {FirestoreConstants.chattingWith: peerId},
      );

      // Listen to chat updates
      _firestore
          .collection(FirestoreConstants.pathMessageCollection)
          .doc(groupChatId.value)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          participants.value = List<String>.from(data['participants'] ?? []);
          lastMessage.value = data['lastMessage'] ?? '';
          lastMessageTime.value = data['lastMessageTime'] ?? '';
          typingStatus.value = Map<String, bool>.from(data['typingStatus'] ?? {});
          isOnline.value = data['isonline'] ?? false;
          status.value = data['status'] ?? false;
        }
      });

    } catch (e) {
      print('Error setting up chat: $e');
      Get.snackbar(
        'Error',
        'Failed to setup chat',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> uploadFile(File file) async {
    if (groupChatId.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Chat not initialized',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

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
    if (collectionPath.isEmpty || docPath.isEmpty) {
      print('Error: Collection path or document path is empty');
      return;
    }

    try {
      await _firestore.collection(collectionPath).doc(docPath).update(data);
    } catch (e) {
      print('Error updating data: $e');
      rethrow;
    }
  }

  Future<void> updateDataFirestoreAllField(String collectionPath, String docPath, Map<String, dynamic> data) async {
    if (collectionPath.isEmpty || docPath.isEmpty) {
      print('Error: Collection path or document path is empty');
      return;
    }

    try {
      await _firestore.collection(collectionPath).doc(docPath).set(data);
    } catch (e) {
      print('Error updating data: $e');
      rethrow;
    }
  }

  Future<void> sendMessage(String content, int type) async {
    if (groupChatId.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Chat not initialized',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (content.trim().isNotEmpty) {
      try {
        final message = MessageChat(
          idFrom: currentUserId.value,
          idTo: peerId.value,
          timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
          content: content,
          type: type,
          istyping: false,
          whotyping: '',
          isonline: false,
          status: false,
          isRead: false,
        );

        // Add message to chat collection
        await _firestore
            .collection(FirestoreConstants.pathMessageCollection)
            .doc(groupChatId.value)
            .collection(groupChatId.value)
            .add(message.toJson());

        // Update last message and time
        await updateDataFirestoreAllField(
          FirestoreConstants.pathMessageCollection,
          groupChatId.value,
          {
            'lastMessage': content,
            'lastMessageTime': message.timestamp,
            'lastMessageStatus': false,
            'lastMessageRead': false,
          },
        );

      } catch (e) {
        print('Error sending message: $e');
        Get.snackbar(
          'Error',
          'Failed to send message',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } else {
      Get.snackbar(
        'Error',
        'Nothing to send',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Stream<QuerySnapshot> getChatStream(String groupChatId, int limit) {
    if (groupChatId.isEmpty) {
      print('Error: Group chat ID is empty');
      return Stream.empty();
    }

    return _firestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .collection(groupChatId)
        .orderBy(FirestoreConstants.timestamp, descending: true)
        .limit(limit)
        .snapshots();
  }

  void checkIsTyping() {
    if (groupChatId.value.isEmpty) {
      return;
    }

    if (isTypingLocal.value != isTyping.value) {
      isTypingLocal.value = isTyping.value;
      updateDataFirestore(
        FirestoreConstants.pathMessageCollection,
        groupChatId.value,
        {
          'typingStatus.${currentUserId.value}': isTyping.value,
        },
      );
    }
  }

  bool isUserTyping(String userId) {
    return typingStatus[userId] ?? false;
  }

  void clearCurrentChatUser() {
    if (currentUserId.value.isNotEmpty) {
      // Update current user's online status to false
      updateDataFirestore(
        FirestoreConstants.pathMessageCollection,
        groupChatId.value,
        {
          'onlineStatus.${currentUserId.value}': false,
        },
      );
      
      updateDataFirestore(
        FirestoreConstants.pathUserCollection,
        currentUserId.value,
        {FirestoreConstants.chattingWith: null},
      );
    }
    groupChatId.value = '';
    peerId.value = '';
    peerAvatar.value = '';
    peerNickname.value = '';
    lastMessage.value = '';
    lastMessageTime.value = '';
    participants.clear();
  }

  // Add method to check if both users are online
  Future<bool> areBothUsersOnline() async {
    final doc = await _firestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId.value)
        .get();
    
    final onlineStatus = doc.data()?['onlineStatus'] as Map<String, dynamic>?;
    if (onlineStatus == null) return false;
    
    return onlineStatus[currentUserId.value] == true && 
           onlineStatus[peerId.value] == true;
  }

  // Add method to mark messages as read
  Future<void> markMessagesAsRead() async {
    if (groupChatId.value.isEmpty) return;

    try {
      // Get all unread messages
      final unreadMessages = await _firestore
          .collection(FirestoreConstants.pathMessageCollection)
          .doc(groupChatId.value)
          .collection(groupChatId.value)
          .where('idTo', isEqualTo: currentUserId.value)
          .where('isRead', isEqualTo: false)
          .get();

      // Update each message as read
      for (var doc in unreadMessages.docs) {
        await doc.reference.update({
          'isRead': true,
          'status': true,
        });
      }

      // Update last message status in chat document
      await updateDataFirestore(
        FirestoreConstants.pathMessageCollection,
        groupChatId.value,
        {
          'lastMessageStatus': true,
          'lastMessageRead': true,
        },
      );
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Add method to check if message is read
  bool isMessageRead(DocumentSnapshot message) {
    return message.get('isRead') ?? false;
  }

  // Add method to check if message is delivered
  bool isMessageDelivered(DocumentSnapshot message) {
    return message.get('status') ?? false;
  }
} 