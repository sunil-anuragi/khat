import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/controllers/chat_controller.dart';
import 'package:get/get.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String peerNickname;
  final String groupChatId;
  final int limit;

  const ChatAppBar({
    Key? key,
    required this.peerNickname,
    required this.groupChatId,
    required this.limit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _chatController = Get.find<ChatController>();
    
    return AppBar(
      automaticallyImplyLeading: false,
      title: StreamBuilder<QuerySnapshot>(
        stream: _chatController.getChatStream(groupChatId, limit),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          return Container(
            alignment: Alignment.centerLeft,
            child: Text(
              peerNickname,
              style: TextStyle(
                color: ColorConstants.primaryColor,
                fontSize: 18,
              ),
            ),
          );
        },
      ),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
} 