import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/constants.dart';

class StickerPicker extends StatelessWidget {
  final Function(String) onStickerSelected;

  const StickerPicker({
    Key? key,
    required this.onStickerSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        child: Column(
          children: <Widget>[
            _buildStickerRow(['mimi1', 'mimi2', 'mimi3']),
            _buildStickerRow(['mimi4', 'mimi5', 'mimi6']),
            _buildStickerRow(['mimi7', 'mimi8', 'mimi9']),
          ],
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        ),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: ColorConstants.greyColor2, width: 0.5),
          ),
          color: Colors.white,
        ),
        padding: EdgeInsets.all(5),
        height: 180,
      ),
    );
  }

  Widget _buildStickerRow(List<String> stickerNames) {
    return Row(
      children: stickerNames.map((sticker) => _buildStickerButton(sticker)).toList(),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    );
  }

  Widget _buildStickerButton(String stickerName) {
    return TextButton(
      onPressed: () => onStickerSelected(stickerName),
      child: Image.asset(
        'images/$stickerName.gif',
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      ),
    );
  }
} 