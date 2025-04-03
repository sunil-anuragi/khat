import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/models/models.dart';
import 'package:intl/intl.dart';

class MessageItem extends StatelessWidget {
  final MessageChat messageChat;
  final bool isLastMessageRight;
  final bool isLastMessageLeft;
  final String peerAvatar;
  final String currentUserId;

  const MessageItem({
    Key? key,
    required this.messageChat,
    required this.isLastMessageRight,
    required this.isLastMessageLeft,
    required this.peerAvatar,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (messageChat.idFrom == currentUserId) {
      return _buildRightMessage();
    } else {
      return _buildLeftMessage();
    }
  }

  Widget _buildRightMessage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        messageChat.type == 0
            ? _buildTextMessage(isRight: true)
            : messageChat.type == 1
                ? _buildImageMessage(isRight: true)
                : _buildStickerMessage(isRight: true),
      ],
    );
  }

  Widget _buildLeftMessage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        isLastMessageLeft
            ? _buildAvatar()
            : Container(width: 35),
        messageChat.type == 0
            ? _buildTextMessage(isRight: false)
            : messageChat.type == 1
                ? _buildImageMessage(isRight: false)
                : _buildStickerMessage(isRight: false),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: CircleAvatar(
        radius: 18,
        child: ClipOval(
          child: Image.network(
            peerAvatar,
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
    );
  }

  Widget _buildTextMessage({required bool isRight}) {
    return Flexible(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isRight ? ColorConstants.primaryColor : ColorConstants.greyColor2,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: isRight ? Radius.circular(20) : Radius.circular(0),
            bottomRight: isRight ? Radius.circular(0) : Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              messageChat.content,
              style: TextStyle(
                color: isRight ? Colors.white : ColorConstants.primaryColor,
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
                    color: isRight ? Colors.white70 : ColorConstants.blackgrey,
                    fontSize: 12,
                  ),
                ),
                if (isRight) ...[
                  SizedBox(width: 4),
                  if (messageChat.isRead)
                    Icon(Icons.done_all, size: 16, color: Colors.blue)
                  else if (messageChat.status)
                    Icon(Icons.done_all, size: 16, color: Colors.white70)
                  else
                    Icon(Icons.done, size: 16, color: Colors.white70),
                ],
              ],
            ),
          ],
        ),
        margin: EdgeInsets.only(
          bottom: isRight ? (isLastMessageRight ? 20 : 10) : (isLastMessageLeft ? 20 : 10),
          right: isRight ? 10 : 50,
          left: isRight ? 50 : 0,
        ),
      ),
    );
  }

  Widget _buildImageMessage({required bool isRight}) {
    return Container(
      margin: EdgeInsets.only(
        bottom: isRight ? (isLastMessageRight ? 20 : 10) : (isLastMessageLeft ? 20 : 10),
        right: isRight ? 10 : 50,
        left: isRight ? 50 : 0,
      ),
      child: OutlinedButton(
        child: Material(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              messageChat.content,
              loadingBuilder: (BuildContext context, Widget child,
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
          // Navigate to full photo page
        },
        style: ButtonStyle(
          padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(0)),
        ),
      ),
    );
  }

  Widget _buildStickerMessage({required bool isRight}) {
    return Container(
      margin: EdgeInsets.only(
        bottom: isRight ? (isLastMessageRight ? 20 : 10) : (isLastMessageLeft ? 20 : 10),
        right: isRight ? 10 : 50,
        left: isRight ? 50 : 0,
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
    );
  }
} 