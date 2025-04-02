import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/controllers/setting_controller.dart';
import 'package:flutter_chat_demo/models/models.dart';
import 'package:flutter_chat_demo/widgets/loading_view.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final _settingController = Get.find<SettingController>();
  final TextEditingController controllerNickname = TextEditingController();
  final TextEditingController controllerAboutMe = TextEditingController();

  final FocusNode focusNodeNickname = FocusNode();
  final FocusNode focusNodeAboutMe = FocusNode();

  @override
  void initState() {
    super.initState();
    controllerNickname.text = _settingController.nickname.value;
    controllerAboutMe.text = _settingController.aboutMe.value;
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.gallery).catchError((err) {
      Get.snackbar(
        'Error',
        err.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    });
    if (pickedFile != null) {
      _settingController.avatarImageFile.value = File(pickedFile.path);
      if (_settingController.avatarImageFile.value != null) {
        await _settingController.uploadFile(_settingController.avatarImageFile.value!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.settingsTitle,
          style: TextStyle(color: ColorConstants.primaryColor),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Avatar
                CupertinoButton(
                  onPressed: getImage,
                  child: Container(
                    margin: EdgeInsets.all(20),
                    child: Obx(() => _settingController.avatarImageFile.value == null
                        ? _settingController.photoUrl.value.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(45),
                                child: Image.network(
                                  _settingController.photoUrl.value,
                                  fit: BoxFit.cover,
                                  width: 90,
                                  height: 90,
                                  errorBuilder: (context, object, stackTrace) {
                                    return Icon(
                                      Icons.account_circle,
                                      size: 90,
                                      color: ColorConstants.greyColor,
                                    );
                                  },
                                  loadingBuilder:
                                      (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 90,
                                      height: 90,
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
                                ),
                              )
                            : Icon(
                                Icons.account_circle,
                                size: 90,
                                color: ColorConstants.greyColor,
                              )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(45),
                            child: Image.file(
                              _settingController.avatarImageFile.value!,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          )),
                  ),
                ),

                // Input
                Column(
                  children: <Widget>[
                    // Username
                    Container(
                      child: Text(
                        'Nickname',
                        style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.primaryColor),
                      ),
                      margin: EdgeInsets.only(left: 10, bottom: 5, top: 10),
                    ),
                    Container(
                      child: Theme(
                        data: Theme.of(context).copyWith(primaryColor: ColorConstants.primaryColor),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Sweetie',
                            contentPadding: EdgeInsets.all(5),
                            hintStyle: TextStyle(color: ColorConstants.greyColor),
                          ),
                          controller: controllerNickname,
                          onChanged: (value) {
                            _settingController.nickname.value = value;
                          },
                          focusNode: focusNodeNickname,
                        ),
                      ),
                      margin: EdgeInsets.only(left: 30, right: 30),
                    ),

                    // About me
                    Container(
                      child: Text(
                        'About me',
                        style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.primaryColor),
                      ),
                      margin: EdgeInsets.only(left: 10, top: 30, bottom: 5),
                    ),
                    Container(
                      child: Theme(
                        data: Theme.of(context).copyWith(primaryColor: ColorConstants.primaryColor),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Fun, like travel and play PES...',
                            contentPadding: EdgeInsets.all(5),
                            hintStyle: TextStyle(color: ColorConstants.greyColor),
                          ),
                          controller: controllerAboutMe,
                          onChanged: (value) {
                            _settingController.aboutMe.value = value;
                          },
                          focusNode: focusNodeAboutMe,
                        ),
                      ),
                      margin: EdgeInsets.only(left: 30, right: 30),
                    ),
                  ],
                  crossAxisAlignment: CrossAxisAlignment.start,
                ),

                // Button
                Container(
                  child: TextButton(
                    onPressed: () {
                      focusNodeNickname.unfocus();
                      focusNodeAboutMe.unfocus();
                      _settingController.handleUpdateData();
                    },
                    child: Text(
                      'Update',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(ColorConstants.primaryColor),
                      padding: MaterialStateProperty.all<EdgeInsets>(
                        EdgeInsets.fromLTRB(30, 10, 30, 10),
                      ),
                    ),
                  ),
                  margin: EdgeInsets.only(top: 50, bottom: 50),
                ),
              ],
            ),
            padding: EdgeInsets.only(left: 15, right: 15),
          ),

          // Loading
          Obx(() => Positioned(child: _settingController.isLoading.value ? LoadingView() : SizedBox.shrink())),
        ],
      ),
    );
  }
}
