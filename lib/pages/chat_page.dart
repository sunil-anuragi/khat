import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/controllers/chat_controller.dart';
import 'package:flutter_chat_demo/models/models.dart';
import 'package:flutter_chat_demo/widgets/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../service/firebase_service.dart';
import 'pages.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.arguments});

  final ChatPageArguments arguments;

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final _chatController = Get.find<ChatController>();
  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
  List<QueryDocumentSnapshot> listMessage = [];
  int _limit = 20;
  int _limitIncrement = 20;
  final RxBool showNewMessageButton = false.obs;
  int lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    focusNode.addListener(onFocusChange);
    listScrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addObserver(this);
    _chatController.setCurrentChatUser(
      widget.arguments.peerId,
      widget.arguments.peerAvatar,
      widget.arguments.peerNickname,
    );
    // Mark messages as read when entering chat
    _chatController.markMessagesAsRead();
  //  _chatController.listenForUnreadMessages();
  }
 
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 500), () {
        FirebaseService().updateDataFirestoreAllField(
          FirestoreConstants.pathMessageCollection,
          _chatController.groupChatId.value,
          {'isonline': true},
        );
      });
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        FirebaseService().updateDataFirestoreAllField(
          FirestoreConstants.pathMessageCollection,
          _chatController.groupChatId.value,
          {'isonline': false},
        );
      });
    }
  }

  void _scrollListener() {
    if (!listScrollController.hasClients) return;
    
    // Check if we're near the bottom
    final isNearBottom = listScrollController.position.pixels >=
        listScrollController.position.maxScrollExtent - 100;
    
    // If we're near bottom, hide the new message button
    if (isNearBottom) {
      showNewMessageButton.value = false;
    }

    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange &&
        _limit <= listMessage.length) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void scrollToBottom() {
    if (listScrollController.hasClients) {
      listScrollController.animateTo(
        0,
        duration: Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
      showNewMessageButton.value = false;
    }
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      _chatController.isShowSticker.value = false;
    }
  }

  // Future getImage() async {
  //   ImagePicker imagePicker = ImagePicker();
  //   XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.gallery).catchError((err) {
  //     Get.snackbar(
  //       'Error',
  //       err.toString(),
  //       snackPosition: SnackPosition.BOTTOM,
  //     );
  //     return null;
  //   });
  //   if (pickedFile != null) {
  //     _chatController.imageFile.value = File(pickedFile.path);
  //     if (_chatController.imageFile.value != null) {
  //       await _chatController.uploadFile(_chatController.imageFile.value!);
  //     }
  //   }
  // }

  void getSticker() {
    focusNode.unfocus();
    _chatController.isShowSticker.value = !_chatController.isShowSticker.value;
  }

  void onSendMessage(String content, int type) {
    if (content.trim().isNotEmpty) {
      textEditingController.clear();
      _chatController.sendMessage(content, type);
      if (listScrollController.hasClients) {
        listScrollController.animateTo(0,
            duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } else {
      Get.snackbar(
        'Error',
        'Nothing to send',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget buildItem(int index, DocumentSnapshot? document) {
    if (document != null) {
      MessageChat messageChat = MessageChat.fromDocument(document);
      if (messageChat.idFrom == _chatController.currentUserId.value) {
        // Right (my message)
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            messageChat.type == 0
                // Text
                ? Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: ColorConstants.primaryColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            messageChat.content,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat('hh:mm a').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    int.parse(messageChat.timestamp),
                                  ),
                                ),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(width: 4),
                              if (messageChat.isRead)
                                Icon(Icons.done_all, size: 16, color: Colors.blue)
                              else if (messageChat.status)
                                Icon(Icons.done_all, size: 16, color: Colors.white70)
                              else
                                Icon(Icons.done, size: 16, color: Colors.white70),
                            ],
                          ),
                        ],
                      ),
                      margin: EdgeInsets.only(
                        bottom: isLastMessageRight(index) ? 20 : 10,
                        right: 10,
                        left: 50,
                      ),
                    ),
                  )
                : messageChat.type == 1
                    // Image
                    ? Container(
                        margin: EdgeInsets.only(
                          bottom: isLastMessageRight(index) ? 20 : 10,
                          right: 10,
                          left: 50,
                        ),
                        child: OutlinedButton(
                          child: Material(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                messageChat.content,
                                loadingBuilder: (BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 200,
                                    height: 200,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: ColorConstants.themeColor,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, object, stackTrace) {
                                  return Container(
                                    width: 200,
                                    height: 200,
                                    child: Image.asset(
                                      'images/img_not_available.jpeg',
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          onPressed: () {
                            Get.to(() => FullPhotoPage(
                                  url: messageChat.content,
                                ));
                          },
                          style: ButtonStyle(
                            padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(0)),
                          ),
                        ),
                      )
                    // Sticker
                    : Container(
                        margin: EdgeInsets.only(
                          bottom: isLastMessageRight(index) ? 20 : 10,
                          right: 10,
                          left: 50,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'images/${messageChat.content}.gif',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
          ],
        );
      } else {
        // Left (peer message)
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            isLastMessageLeft(index)
                ? Container(
                    margin: EdgeInsets.only(right: 8),
                    child: CircleAvatar(
                      radius: 18,
                      child: ClipOval(
                        child: Image.network(
                          widget.arguments.peerAvatar,
                          width: 35,
                          height: 35,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.account_circle,
                              size: 35,
                              color: ColorConstants.greyColor,
                            );
                          },
                        ),
                      ),
                    ),
                  )
                : Container(width: 35),
            messageChat.type == 0
                ? Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: ColorConstants.greyColor2,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            messageChat.content,
                            style: TextStyle(
                              color: ColorConstants.primaryColor,
                              fontSize: 16,
                            ),
                            
                          ),
                          SizedBox(height: 4),
                          Text(
                            DateFormat('hh:mm a').format(
                              DateTime.fromMillisecondsSinceEpoch(
                                int.parse(messageChat.timestamp),
                              ),
                            ),
                            style: TextStyle(
                              color: ColorConstants.blackgrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      margin: EdgeInsets.only(
                        bottom: isLastMessageLeft(index) ? 20 : 10,
                        right: 50,
                      ),
                    ),
                  )
                : messageChat.type == 1
                    ? Container(
                        margin: EdgeInsets.only(
                          bottom: isLastMessageLeft(index) ? 20 : 10,
                          right: 50,
                        ),
                        child: OutlinedButton(
                          child: Material(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                messageChat.content,
                                loadingBuilder: (BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 200,
                                    height: 200,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: ColorConstants.themeColor,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, object, stackTrace) {
                                  return Container(
                                    width: 200,
                                    height: 200,
                                    child: Image.asset(
                                      'images/img_not_available.jpeg',
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          onPressed: () {
                            Get.to(() => FullPhotoPage(
                                  url: messageChat.content,
                                ));
                          },
                          style: ButtonStyle(
                            padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(0)),
                          ),
                        ),
                      )
                    : Container(
                        margin: EdgeInsets.only(
                          bottom: isLastMessageLeft(index) ? 20 : 10,
                          right: 50,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'images/${messageChat.content}.gif',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
          ],
        );
      }
    } else {
      return SizedBox.shrink();
    }
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 &&
            listMessage[index - 1].get(FirestoreConstants.idFrom) ==
                _chatController.currentUserId.value) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
            listMessage[index - 1].get(FirestoreConstants.idFrom) !=
                _chatController.currentUserId.value) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> onBackPress() {
    if (_chatController.isShowSticker.value) {
      _chatController.isShowSticker.value = false;
    } else {
      _chatController.clearCurrentChatUser();
      Get.back();
    }

    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: StreamBuilder<QuerySnapshot>(
            stream: _chatController.getChatStream(
                _chatController.groupChatId.value, _limit),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  
              if (snapshot.hasData) {
                listMessage = snapshot.data!.docs;
                if (listMessage.length > 0) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.arguments.peerNickname,
                          style: TextStyle(
                            color: ColorConstants.primaryColor,
                            fontSize: 18,
                          ),
                        ),

                        // Obx(() => FutureBuilder<bool>(
                        //   future: _chatController.areBothUsersOnline(),
                        //   builder: (context, snapshot) {
                        //     if (snapshot.hasData && snapshot.data == true) {
                        //       return Text(
                        //         "Both Online",
                        //         style: TextStyle(
                        //           fontSize: 12,
                        //           color: ColorConstants.green,
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       );
                        //     } else {
                        //       return Text(
                        //         _chatController.isOnline.value ? "Online" : "Offline",
                        //         style: TextStyle(
                        //           fontSize: 12,
                        //           color: _chatController.isOnline.value 
                        //               ? ColorConstants.green 
                        //               : ColorConstants.red,
                        //         ),
                        //       );
                        //     }
                        //   },
                        // )),
                      ],
                    ),
                  );
                } else {
                  return Container(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.arguments.peerNickname,
                          style: TextStyle(
                            color: ColorConstants.primaryColor,
                            fontSize: 18,
                          ),
                        ),
                        // Obx(() => FutureBuilder<bool>(
                        //   future: _chatController.areBothUsersOnline(),
                        //   builder: (context, snapshot) {
                        //     if (snapshot.hasData && snapshot.data == true) {
                        //       return Text(
                        //         "Both Online",
                        //         style: TextStyle(
                        //           fontSize: 12,
                        //           color: ColorConstants.green,
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       );
                        //     } else {
                        //       return Text(
                        //         _chatController.isOnline.value ? "Online" : "Offline",
                        //         style: TextStyle(
                        //           fontSize: 12,
                        //           color: _chatController.isOnline.value 
                        //               ? ColorConstants.green 
                        //               : ColorConstants.red,
                        //         ),
                        //       );
                        //     }
                        //   },
                        // )),
                      ],
                    ),
                  );
                }
              } else {
                return Container(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.arguments.peerNickname,
                        style: TextStyle(
                          color: ColorConstants.primaryColor,
                          fontSize: 18,
                        ),
                      ),
                      // Obx(() => FutureBuilder<bool>(
                      //   future: _chatController.areBothUsersOnline(),
                      //   builder: (context, snapshot) {
                      //     if (snapshot.hasData && snapshot.data == true) {
                      //       return Text(
                      //         "Both Online",
                      //         style: TextStyle(
                      //           fontSize: 12,
                      //           color: ColorConstants.green,
                      //           fontWeight: FontWeight.bold,
                      //         ),
                      //       );
                      //     } else {
                      //       return Text(
                      //         _chatController.isOnline.value ? "Online" : "Offline",
                      //         style: TextStyle(
                      //           fontSize: 12,
                      //           color: _chatController.isOnline.value 
                      //               ? ColorConstants.green 
                      //               : ColorConstants.red,
                      //         ),
                      //       );
                      //     }
                      //   },
                      // )),
                    ],
                  ),
                );
              }
            }),
        centerTitle: true,
      ),
      body: SafeArea(
        child: WillPopScope(
          child: Stack(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // List of messages
                  buildListMessage(),

                  // Sticker
                  Obx(() => _chatController.isShowSticker.value
                      ? buildSticker()
                      : SizedBox.shrink()),

                  // Input content
                  buildInput(),
                ],
              ),
              // Loading
              Obx(() => Positioned(
                    child: _chatController.isLoading.value
                        ? LoadingView()
                        : SizedBox.shrink(),
                  )),
            ],
          ),
          onWillPop: onBackPress,
        ),
      ),
    );
  }

  Widget buildSticker() {
    return Expanded(
      child: Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                TextButton(
                  onPressed: () => onSendMessage('mimi1', 2),
                  child: Image.asset(
                    'images/mimi1.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi2', 2),
                  child: Image.asset(
                    'images/mimi2.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi3', 2),
                  child: Image.asset(
                    'images/mimi3.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
              ],
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            ),
            Row(
              children: <Widget>[
                TextButton(
                  onPressed: () => onSendMessage('mimi4', 2),
                  child: Image.asset(
                    'images/mimi4.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi5', 2),
                  child: Image.asset(
                    'images/mimi5.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi6', 2),
                  child: Image.asset(
                    'images/mimi6.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
              ],
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            ),
            Row(
              children: <Widget>[
                TextButton(
                  onPressed: () => onSendMessage('mimi7', 2),
                  child: Image.asset(
                    'images/mimi7.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi8', 2),
                  child: Image.asset(
                    'images/mimi8.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi9', 2),
                  child: Image.asset(
                    'images/mimi9.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
              ],
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            )
          ],
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        ),
        decoration: BoxDecoration(
            border: Border(
                top: BorderSide(color: ColorConstants.greyColor2, width: 0.5)),
            color: Colors.white),
        padding: EdgeInsets.all(5),
        height: 180,
      ),
    );
  }

  Widget buildInput() {
    return Container(
      child: Row(
        children: <Widget>[
          // Edit text
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(maxHeight: 500),
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: TextField(
                  onSubmitted: (value) {
                    onSendMessage(textEditingController.text, 0);
                  },
                  style: TextStyle(
                      color: ColorConstants.primaryColor, fontSize: 15),
                  controller: textEditingController,
                  textInputAction: TextInputAction.newline,
                  onChanged: (_) {
                    _chatController.isTyping.value = true;
                    _chatController.checkIsTyping();
                    // Reset typing status after 2 seconds of inactivity
                    Future.delayed(Duration(seconds: 2), () {
                      if (_chatController.isTyping.value) {
                        _chatController.isTyping.value = false;
                        _chatController.checkIsTyping();
                      }
                    });
                  },
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration.collapsed(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(color: ColorConstants.greyColor),
                  ),
                  focusNode: focusNode,
                  autofocus: true,
                ),
              ),
            ),
          ),

          // Button send message
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              child: IconButton(
                icon: Icon(Icons.send),
                onPressed: () =>
                    onSendMessage(textEditingController.text, 0),
                color: ColorConstants.primaryColor,
              ),
            ),
            color: Colors.white,
          ),
        ],
      ),
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(color: ColorConstants.greyColor2, width: 0.5)),
          color: Colors.white),
    );
  }

  Widget buildListMessage() {
    return Flexible(
      child: _chatController.groupChatId.value.isNotEmpty
          ? StreamBuilder<QuerySnapshot>(
              stream: _chatController.getChatStream(
                  _chatController.groupChatId.value, _limit),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  listMessage = snapshot.data!.docs;
                  
                  // Check for new messages
                  if (listMessage.length > lastMessageCount && 
                      listScrollController.hasClients &&
                      listScrollController.position.pixels > 100) {
                    showNewMessageButton.value = true;
                  }
                  lastMessageCount = listMessage.length;

                  if (listMessage.length > 0) {
                    _chatController.isOnline.value =
                        snapshot.data?.docs.first['isonline'];
                    _chatController.status.value =
                        snapshot.data?.docs.first['status'];
                    if (_chatController.status.value == false) {
                      FirebaseService().updateDataFirestoreAllField(
                          FirestoreConstants.pathMessageCollection,
                          _chatController.groupChatId.value,
                          {
                        'status': true,
                      });
                    }
                    return Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.all(10),
                                itemBuilder: (context, index) =>
                                    buildItem(index, snapshot.data?.docs[index]),
                                itemCount: snapshot.data?.docs.length,
                                reverse: true,
                                controller: listScrollController,
                              ),
                            ),
                            Obx(() {
                              final typingUsers = _chatController.typingStatus.entries
                                  .where((entry) => entry.value)
                                  .map((entry) => entry.key)
                                  .toList();
                              
                              final otherTypingUsers = typingUsers
                                  .where((userId) => userId != _chatController.currentUserId.value)
                                  .toList();
                              
                              if (otherTypingUsers.isEmpty) return Container();
                              
                              final typingText = otherTypingUsers
                                  .map((userId) => userId == _chatController.peerId.value 
                                      ? widget.arguments.peerNickname 
                                      : 'Someone')
                                  .join(', ');
                              
                              return Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                child: Text(
                                  "$typingText ${otherTypingUsers.length == 1 ? 'is' : 'are'} typing...",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ColorConstants.greyColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                        // New Message Button with Animation
                        Obx(() => AnimatedPositioned(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              right: showNewMessageButton.value ? 100 : -200,
                              left: showNewMessageButton.value ? 100 : -200,
                              bottom: showNewMessageButton.value ? 80 : -100,
                              child: AnimatedOpacity(
                                duration: Duration(milliseconds: 300),
                                opacity: showNewMessageButton.value ? 1.0 : 0.0,
                                child: ElevatedButton.icon(
                                  onPressed: scrollToBottom,
                                  icon: Icon(Icons.arrow_downward),
                                  label: Text('New Message'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorConstants.green,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 4,
                                  ),
                                ),
                              ),
                            )),
                      ],
                    );
                  } else {
                    return Center(child: Text("No message here yet..."));
                  }
                } else {
                  return Center(
                    child: CircularProgressIndicator(
                      color: ColorConstants.themeColor,
                    ),
                  );
                }
              },
            )
          : Center(
              child: CircularProgressIndicator(
                color: ColorConstants.themeColor,
              ),
            ),
    );
  }
}

class ChatPageArguments {
  final String peerId;
  final String peerAvatar;
  final String peerNickname;

  ChatPageArguments(
      {required this.peerId,
      required this.peerAvatar,
      required this.peerNickname});
}
