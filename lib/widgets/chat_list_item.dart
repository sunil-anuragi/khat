import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/models/models.dart';
import 'package:intl/intl.dart';


class ChatListItem extends StatelessWidget {
  final UserChat userChat;
  final String currentUserId;
  final String searchQuery;
  final Function() onTap;

  const ChatListItem({
    Key? key,
    required this.userChat,
    required this.currentUserId,
    required this.searchQuery,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (userChat.id == currentUserId) {
      return SizedBox.shrink();
    }

    return Container(
      child: TextButton(
        child: Row(
          children: <Widget>[
            Material(
              child: userChat.photoUrl.isNotEmpty
                  ? Image.network(
                      userChat.photoUrl,
                      fit: BoxFit.cover,
                      width: 50,
                      height: 50,
                      loadingBuilder: (BuildContext context, Widget child,
                          ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 50,
                          height: 50,
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
                        return Icon(
                          Icons.account_circle,
                          size: 50,
                          color: ColorConstants.greyColor,
                        );
                      },
                    )
                  : Icon(
                      Icons.account_circle,
                      size: 50,
                      color: ColorConstants.greyColor,
                    ),
              borderRadius: BorderRadius.all(Radius.circular(25)),
              clipBehavior: Clip.hardEdge,
            ),
            Flexible(
              child: Container(
                child: Column(
                  children: <Widget>[
                    Container(
                      child: _buildNicknameText(),
                      alignment: Alignment.centerLeft,
                      margin: EdgeInsets.fromLTRB(10, 0, 0, 5),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                    ),
                  ],
                ),
                margin: EdgeInsets.only(left: 20),
              ),
            ),
          ],
        ),
        onPressed: onTap,
        style: ButtonStyle(
          backgroundColor:
              MaterialStateProperty.all<Color>(ColorConstants.greyColor2),
          shape: MaterialStateProperty.all<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
      ),
      margin: EdgeInsets.only(bottom: 10, left: 5, right: 5),
    );
  }

  Widget _buildNicknameText() {
    if (searchQuery.isEmpty) {
      return Text(
        userChat.nickname,
        maxLines: 1,
        style: TextStyle(color: ColorConstants.primaryColor),
      );
    }

    final nickname = userChat.nickname.toLowerCase();
    final searchText = searchQuery.toLowerCase();
    final matchIndex = nickname.indexOf(searchText);

    if (matchIndex == -1) return SizedBox.shrink();

    return RichText(
      maxLines: 1,
      text: TextSpan(
        style: TextStyle(color: ColorConstants.primaryColor),
        children: [
          TextSpan(text: userChat.nickname.substring(0, matchIndex)),
          TextSpan(
            text: userChat.nickname.substring(
              matchIndex,
              matchIndex + searchText.length,
            ),
            style: TextStyle(
              color: ColorConstants.primaryColor,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.yellow.withOpacity(0.3),
            ),
          ),
          TextSpan(
            text: userChat.nickname.substring(matchIndex + searchText.length),
          ),
        ],
      ),
    );
  }
} 