import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:get/get.dart';

class TypingIndicator extends StatelessWidget {
  final RxMap<String, bool> typingStatus;
  final String currentUserId;
  final String peerId;
  final String peerNickname;

  const TypingIndicator({
    Key? key,
    required this.typingStatus,
    required this.currentUserId,
    required this.peerId,
    required this.peerNickname,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final typingUsers = typingStatus.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
      
      final otherTypingUsers = typingUsers
          .where((userId) => userId != currentUserId)
          .toList();
      
      if (otherTypingUsers.isEmpty) return Container();
      
      final typingText = otherTypingUsers
          .map((userId) => userId == peerId 
              ? peerNickname 
              : 'Someone')
          .join(', ');
      
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        child: Text(
          "$typingText ${otherTypingUsers.length == 1 ? 'is' : 'are'} typing...",
          style: TextStyle(
            fontSize: 12,
            color: ColorConstants.greyColor,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    });
  }
} 