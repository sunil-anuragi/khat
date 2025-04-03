import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:get/get.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController textEditingController;
  final FocusNode focusNode;
  final Function(String) onSendMessage;
  final Function() onStickerPressed;
  final RxBool isShowSticker;

  const ChatInput({
    Key? key,
    required this.textEditingController,
    required this.focusNode,
    required this.onSendMessage,
    required this.onStickerPressed,
    required this.isShowSticker,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  onSubmitted: onSendMessage,
                  style: TextStyle(
                    color: ColorConstants.primaryColor,
                    fontSize: 15,
                  ),
                  controller: textEditingController,
                  textInputAction: TextInputAction.newline,
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
                onPressed: () => onSendMessage(textEditingController.text),
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
          top: BorderSide(color: ColorConstants.greyColor2, width: 0.5),
        ),
        color: Colors.white,
      ),
    );
  }
} 