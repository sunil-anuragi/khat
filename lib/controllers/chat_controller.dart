import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/models/models.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/firebase_service.dart';

class ChatController extends GetxController with WidgetsBindingObserver {
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
  final RxBool isOffline = false.obs;
  final RxList<Map<String, dynamic>> pendingMessages =
      <Map<String, dynamic>>[].obs;
  var messageStream =
      Rx<Stream<QuerySnapshot<Map<String, dynamic>>>>(Stream.empty());

  @override
  void onInit() {
    WidgetsBinding.instance.addObserver(this);
    readLocal();
    enableOfflinePersistence();

    super.onInit();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);

    super.onClose();
  }

  Future<void> enableOfflinePersistence() async {
    try {
      await _firestore.enablePersistence(
        const PersistenceSettings(synchronizeTabs: true),
      );
    } catch (e) {
      if (e is FirebaseException) {
        if (e.code == 'failed-precondition') {
          // Multiple tabs open, persistence can only be enabled in one tab at a time
          print(
              'Multiple tabs open, persistence can only be enabled in one tab at a time');
        } else if (e.code == 'unimplemented') {
          // The current browser doesn't support persistence
          print('The current browser doesn\'t support persistence');
        }
      }
    }
  }

  void readLocal() {
    currentUserId.value = _prefs.getString(FirestoreConstants.id) ?? '';
  }

  // Add method to check network connectivity
  Future<void> checkConnectivity() async {
    try {
      await _firestore.collection('test').doc('test').get();
      isOffline.value = false;
      // If we're back online, try to send pending messages
      if (pendingMessages.isNotEmpty) {
        await sendPendingMessages();
      }
    } catch (e) {
      isOffline.value = true;
    }
  }

  // Add method to send pending messages
  Future<void> sendPendingMessages() async {
    for (var message in pendingMessages) {
      try {
        await _firestore
            .collection(FirestoreConstants.pathMessageCollection)
            .doc(groupChatId.value)
            .collection(groupChatId.value)
            .add(message);

        // Update last message and time
        await FirebaseService().updateDataFirestoreAllField(
          FirestoreConstants.pathMessageCollection,
          groupChatId.value,
          {
            'lastMessage': message['content'],
            'lastMessageTime': message['timestamp'],
            'lastMessageStatus': message['status'],
            'lastMessageRead': message['isRead'],
          },
        );
      } catch (e) {
        print('Error sending pending message: $e');
      }
    }
    pendingMessages.clear();
  }

  Future<void> setCurrentChatUser(
      String peerId, String peerAvatar, String peerNickname) async {
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
          // 'isonline': false,
          // 'status': false,
        });
      } else {
        // Update current user's online status
        await FirebaseService().updateDataFirestore(
          FirestoreConstants.pathMessageCollection,
          groupChatId.value,
          {
            'onlineStatus.${currentUserId.value}': true,
          },
        );

        // If current user is the receiver, mark all messages as read
        if (currentUserId.value == peerId) {
          await markMessagesAsRead();
        }
      }

      // Update current user's chatting status
      await FirebaseService().updateDataFirestore(
        FirestoreConstants.pathUserCollection,
        currentUserId.value,
        {FirestoreConstants.chattingWith: peerId},
      );

      // Listen to chat updates
      _firestore
          .collection(FirestoreConstants.pathMessageCollection)
          .doc(groupChatId.value)
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          participants.value = List<String>.from(data['participants'] ?? []);
          lastMessage.value = data['lastMessage'] ?? '';
          lastMessageTime.value = data['lastMessageTime'] ?? '';
          typingStatus.value =
              Map<String, bool>.from(data['typingStatus'] ?? {});
          // isOnline.value = data['isonline'] ?? false;
          // status.value = data['status'] ?? false;

          // If current user is the receiver, mark all messages as read
          if (currentUserId.value == peerId) {
            await markMessagesAsRead();
          }
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

//***** For upload file ***************//

  // Future<void> uploadFile(File file) async {
  //   if (groupChatId.value.isEmpty) {
  //     Get.snackbar(
  //       'Error',
  //       'Chat not initialized',
  //       snackPosition: SnackPosition.BOTTOM,
  //     );
  //     return;
  //   }
  //   try {
  //     isLoading.value = true;
  //     String fileName = DateTime.now().millisecondsSinceEpoch.toString();
  //     final ref = _storage.ref().child('uploads/$fileName');
  //     final uploadTask = ref.putFile(file);
  //     final snapshot = await uploadTask;
  //     imageUrl.value = await snapshot.ref.getDownloadURL();
  //     await sendMessage(imageUrl.value, 1); // 1 for image type
  //   } catch (e) {
  //     print('Error uploading file: $e');
  //     Get.snackbar(
  //       'Error',
  //       'Failed to upload file',
  //       snackPosition: SnackPosition.BOTTOM,
  //     );
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

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
        // Check if receiver is online and in chat screen
        final chatDoc = await _firestore
            .collection(FirestoreConstants.pathMessageCollection)
            .doc(groupChatId.value)
            .get();

        final onlineStatus =
            chatDoc.data()?['onlineStatus'] as Map<String, dynamic>?;
        final isReceiverOnline =
            onlineStatus != null && onlineStatus[peerId.value] == true;

        // Check if receiver is in chat screen
        final userDoc = await _firestore
            .collection(FirestoreConstants.pathUserCollection)
            .doc(peerId.value)
            .get();

        final isReceiverInChat =
            userDoc.data()?[FirestoreConstants.chattingWith] ==
                currentUserId.value;

        final message = MessageChat(
          idFrom: currentUserId.value,
          idTo: peerId.value,
          timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
          content: content,
          type: type,
          istyping: false,
          whotyping: '',
          isonline: false,
          status: isReceiverOnline,
          isRead: isReceiverOnline,
        );

        // Check if we're offline
        if (isOffline.value) {
          // Store message locally
          pendingMessages.add(message.toJson());
          Get.snackbar(
            'Offline',
            'Message will be sent when you\'re back online',
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          // Send message immediately
          await _firestore
              .collection(FirestoreConstants.pathMessageCollection)
              .doc(groupChatId.value)
              .collection(groupChatId.value)
              .add(message.toJson());

          // Update last message and time
          await FirebaseService().updateDataFirestoreAllField(
            FirestoreConstants.pathMessageCollection,
            groupChatId.value,
            {
              'lastMessage': content,
              'lastMessageTime': message.timestamp,
              'lastMessageStatus': isReceiverOnline,
              'lastMessageRead': isReceiverOnline,
            },
          );
          print("dssadsd"+ isReceiverInChat.toString());
          // Only send notification if receiver is not in chat screen
          if (!isReceiverInChat) {
            sendNotificationToUser(content);
          }
        }
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
      FirebaseService().updateDataFirestore(
        FirestoreConstants.pathMessageCollection,
        groupChatId.value,
        {
          'typingStatus.${currentUserId.value}': isTyping.value,
        },
      );
    }
  }

  void clearCurrentChatUser() {
    if (currentUserId.value.isNotEmpty) {
      // Update current user's online status to false
      FirebaseService().updateDataFirestore(
        FirestoreConstants.pathMessageCollection,
        groupChatId.value,
        {
          'onlineStatus.${currentUserId.value}': false,
        },
      );

      FirebaseService().updateDataFirestore(
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

  // ************* continues update read satatus *********//

  // Future<void> listenForUnreadMessages() async {
  //   // Check if receiver is in chat screen
  //   final userDoc = await _firestore
  //           .collection(FirestoreConstants.pathUserCollection)
  //           .doc(peerId.value)
  //           .get();

  //       final isReceiverInChat =
  //           userDoc.data()?[FirestoreConstants.chattingWith] ==
  //               currentUserId.value;
      

  //   messageStream.value = _firestore
  //       .collection(FirestoreConstants.pathMessageCollection)
  //       .doc(groupChatId.value)
  //       .collection(groupChatId.value)
  //       .where('idTo', isEqualTo: currentUserId.value)
  //       .where('isRead', isEqualTo: false)
  //       .snapshots();

  //   messageStream.value.listen((snapshot) {
  //     print("saddsdsada16542516216356");
  //       print("reveivecr chat"+ isReceiverInChat.toString());
  //     // if (!isScreenOpen.value) return;
  //     for (var doc in snapshot.docs) {
  //       if (isReceiverInChat) {
  //         doc.reference.update({'isRead': true});
  //       }
  //     }
  //   });
  // }

  // Update markMessagesAsRead to handle receiver's messages

  Future<void> markMessagesAsRead() async {
    if (groupChatId.value.isEmpty) return;

    try {
      // Get all unread messages for the current user (receiver)
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
      await FirebaseService().updateDataFirestore(
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check connectivity when app resumes
      checkConnectivity();

      Future.delayed(const Duration(milliseconds: 500), () {
        FirebaseService().updateDataFirestoreAllField(
          FirestoreConstants.pathMessageCollection,
          groupChatId.value,
          {'isonline': true},
        );
      });
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        FirebaseService().updateDataFirestoreAllField(
          FirestoreConstants.pathMessageCollection,
          groupChatId.value,
          {'isonline': false},
        );
      });
    }
  }

  Future<String?> sendNotificationToUser(content) async {
    try {
      final userDoc = await _firestore
          .collection(FirestoreConstants.pathUserCollection)
          .doc(peerId.value)
          .get();

      if (userDoc.exists) {
        await FirebaseService().sendFCMMessage(userDoc.data()?['pushToken'],
            title: "You have new message", body: content);
      }
      return null;
    } catch (e) {
      print('Error getting receiver push token: $e');
      return null;
    }
  }
}
