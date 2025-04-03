import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/controllers/chat_controller.dart';
import 'package:flutter_chat_demo/models/models.dart';
import 'package:flutter_chat_demo/widgets/message_item.dart';
import 'package:flutter_chat_demo/widgets/new_message_button.dart';
import 'package:flutter_chat_demo/widgets/typing_indicator.dart';
import 'package:get/get.dart';

class MessageList extends StatefulWidget {
  final String groupChatId;
  final String peerAvatar;
  final String peerNickname;
  final int limit;
  final ScrollController listScrollController;
  final RxBool showNewMessageButton;
  final Function() scrollToBottom;

  const MessageList({
    Key? key,
    required this.groupChatId,
    required this.peerAvatar,
    required this.peerNickname,
    required this.limit,
    required this.listScrollController,
    required this.showNewMessageButton,
    required this.scrollToBottom,
  }) : super(key: key);

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final _chatController = Get.find<ChatController>();
  List<QueryDocumentSnapshot> listMessage = [];
  int lastMessageCount = 0;

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

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: widget.groupChatId.isNotEmpty
          ? StreamBuilder<QuerySnapshot>(
              stream: _chatController.getChatStream(widget.groupChatId, widget.limit),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  listMessage = snapshot.data!.docs;
                  
                  if (listMessage.length > lastMessageCount && 
                      widget.listScrollController.hasClients &&
                      widget.listScrollController.position.pixels > 100) {
                    widget.showNewMessageButton.value = true;
                  }
                  lastMessageCount = listMessage.length;

                  if (listMessage.length > 0) {
                    return Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.all(10),
                                itemBuilder: (context, index) {
                                  final document = snapshot.data?.docs[index];
                                  if (document != null) {
                                    final messageChat = MessageChat.fromDocument(document);
                                    return MessageItem(
                                      messageChat: messageChat,
                                      isLastMessageRight: isLastMessageRight(index),
                                      isLastMessageLeft: isLastMessageLeft(index),
                                      peerAvatar: widget.peerAvatar,
                                      currentUserId: _chatController.currentUserId.value,
                                    );
                                  }
                                  return SizedBox.shrink();
                                },
                                itemCount: snapshot.data?.docs.length,
                                reverse: true,
                                controller: widget.listScrollController,
                              ),
                            ),
                            TypingIndicator(
                              typingStatus: _chatController.typingStatus,
                              currentUserId: _chatController.currentUserId.value,
                              peerId: _chatController.peerId.value,
                              peerNickname: widget.peerNickname,
                            ),
                          ],
                        ),
                        NewMessageButton(
                          showNewMessageButton: widget.showNewMessageButton,
                          onPressed: widget.scrollToBottom,
                        ),
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