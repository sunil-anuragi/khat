import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/controllers/chat_controller.dart';
import 'package:flutter_chat_demo/models/models.dart';
import 'package:flutter_chat_demo/widgets/chat_app_bar.dart';
import 'package:flutter_chat_demo/widgets/chat_input.dart';
import 'package:flutter_chat_demo/widgets/message_list.dart';
import 'package:flutter_chat_demo/widgets/sticker_picker.dart';
import 'package:get/get.dart';
import '../service/firebase_service.dart';
import '../widgets/chatargu.dart';

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
  int _limit = 20;
  int _limitIncrement = 20;
  final RxBool showNewMessageButton = false.obs;

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
    _chatController.markMessagesAsRead();
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
    
    final isNearBottom = listScrollController.position.pixels >=
        listScrollController.position.maxScrollExtent - 100;
    
    if (isNearBottom) {
      showNewMessageButton.value = false;
    }

    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange &&
        _limit <= listScrollController.position.maxScrollExtent) {
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
      appBar: ChatAppBar(
        peerNickname: widget.arguments.peerNickname,
        groupChatId: _chatController.groupChatId.value,
        limit: _limit,
      ),
      body: SafeArea(
        child: WillPopScope(
          child: Stack(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  MessageList(
                    groupChatId: _chatController.groupChatId.value,
                    peerAvatar: widget.arguments.peerAvatar,
                    peerNickname: widget.arguments.peerNickname,
                    limit: _limit,
                    listScrollController: listScrollController,
                    showNewMessageButton: showNewMessageButton,
                    scrollToBottom: scrollToBottom,
                  ),
                  Obx(() => _chatController.isShowSticker.value
                      ? StickerPicker(
                          onStickerSelected: (sticker) => onSendMessage(sticker, 2),
                        )
                      : SizedBox.shrink()),
                  ChatInput(
                    textEditingController: textEditingController,
                    focusNode: focusNode,
                    onSendMessage: (content) => onSendMessage(content, 0),
                    onStickerPressed: getSticker,
                    isShowSticker: _chatController.isShowSticker,
                  ),
                ],
              ),
              Obx(() => Positioned(
                    child: _chatController.isLoading.value
                        ? CircularProgressIndicator(
                            color: ColorConstants.themeColor,
                          )
                        : SizedBox.shrink(),
                  )),
            ],
          ),
          onWillPop: onBackPress,
        ),
      ),
    );
  }
}


