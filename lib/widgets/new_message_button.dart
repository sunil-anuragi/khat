import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:get/get.dart';

class NewMessageButton extends StatelessWidget {
  final RxBool showNewMessageButton;
  final VoidCallback onPressed;

  const NewMessageButton({
    Key? key,
    required this.showNewMessageButton,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => AnimatedPositioned(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          right: showNewMessageButton.value ? 100 : -200,
          left: showNewMessageButton.value ? 100 : -200,
          bottom: showNewMessageButton.value ? 80 : -100,
          child: AnimatedOpacity(
            duration: Duration(milliseconds: 300),
            opacity: showNewMessageButton.value ? 1.0 : 0.0,
            child: ElevatedButton.icon(
              onPressed: onPressed,
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
        ));
  }
} 