import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/controllers/auth_controller.dart';
import 'package:flutter_chat_demo/controllers/home_controller.dart';
import 'package:flutter_chat_demo/utils/utils.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import 'pages.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  HomePageState({Key? key});

  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ScrollController listScrollController = ScrollController();

  final _authController = Get.find<AuthController>();
  final _homeController = Get.find<HomeController>();

  int _limit = 20;
  final int _limitIncrement = 20;
  String _textSearch = "";
  bool isLoading = false;

  late final String currentUserId;

  final Debouncer searchDebouncer = Debouncer(milliseconds: 300);
  final StreamController<bool> btnClearController = StreamController<bool>();
  final TextEditingController searchBarTec = TextEditingController();

  final List<PopupChoices> choices = <PopupChoices>[
    PopupChoices(title: 'Settings', icon: Icons.settings),
    PopupChoices(title: 'Log out', icon: Icons.exit_to_app),
  ];

  @override
  void initState() {
    super.initState();
    if (_authController.getUserFirebaseId()?.isNotEmpty == true) {
      currentUserId = _authController.getUserFirebaseId()!;
    } else {
      Get.offAll(() => LoginPage());
    }
    registerNotification();
    configLocalNotification();
    listScrollController.addListener(scrollListener);
  }

  @override
  void dispose() {
    super.dispose();
    btnClearController.close();
  }

  void registerNotification() {
    firebaseMessaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('onMessage: $message');
      if (message.notification != null) {
        showNotification(message.notification!);
      }
      return;
    });

    firebaseMessaging.getToken().then((token) {
      print('push token: $token');
      if (token != null) {
        _homeController.updateDataFirestore(
          FirestoreConstants.pathUserCollection,
          currentUserId,
          {'pushToken': token},
        );
      }
    }).catchError((err) {
      Get.snackbar(
        'Error',
        err.message.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    });
  }

  void configLocalNotification() {
    AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Handle notification clicks
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final data = jsonDecode(response.payload!);
          if (data['type'] == 'message') {
            Get.to(() => ChatPage(
              arguments: ChatPageArguments(
                peerId: data['senderId'],
                peerAvatar: data['senderAvatar'],
                peerNickname: data['senderName'],
              ),
            ));
          }
        }
      },
    );
  }

  void scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void onItemMenuPress(PopupChoices choice) {
    if (choice.title == 'Log out') {
      handleSignOut();
    } else {
      Get.to(() => SettingsPage());
    }
  }

  void showNotification(RemoteNotification remoteNotification) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      Platform.isAndroid
          ? 'com.dfa.flutterchatdemo'
          : 'com.duytq.flutterchatdemo',
      'Flutter chat demo',
      playSound: true,
      enableVibration: true,
      importance: Importance.max,
      priority: Priority.high,
      channelShowBadge: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('open', 'Open'),
        AndroidNotificationAction('close', 'Close'),
      ],
    );
    DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    print(remoteNotification);

    // await flutterLocalNotificationsPlugin.show(
    //   0,
    //   remoteNotification.title,
    //   remoteNotification.body,
    //   platformChannelSpecifics,
    //   payload: jsonEncode({
    //     'type': 'message',
    //     'senderId': remoteNotification. da?['senderId'] ?? '',
    //     'senderName': remoteNotification.data?['senderName'] ?? '',
    //     'senderAvatar': remoteNotification.data?['senderAvatar'] ?? '',
    //   }),
    // );
  }

  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }

  Future<void> openDialog() async {
    switch (await Get.dialog<int>(
      SimpleDialog(
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            color: ColorConstants.themeColor,
            padding: EdgeInsets.only(bottom: 10, top: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  child: Icon(
                    Icons.exit_to_app,
                    size: 30,
                    color: Colors.white,
                  ),
                  margin: EdgeInsets.only(bottom: 10),
                ),
                Text(
                  'Exit app',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  'Are you sure to exit app?',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Get.back(result: 0);
            },
            child: Row(
              children: <Widget>[
                Container(
                  child: Icon(
                    Icons.cancel,
                    color: ColorConstants.primaryColor,
                  ),
                  margin: EdgeInsets.only(right: 10),
                ),
                Text(
                  'Cancel',
                  style: TextStyle(
                      color: ColorConstants.primaryColor,
                      fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Get.back(result: 1);
            },
            child: Row(
              children: <Widget>[
                Container(
                  child: Icon(
                    Icons.check_circle,
                    color: ColorConstants.primaryColor,
                  ),
                  margin: EdgeInsets.only(right: 10),
                ),
                Text(
                  'Yes',
                  style: TextStyle(
                      color: ColorConstants.primaryColor,
                      fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
        ],
      ),
    )) {
      case 0:
        break;
      case 1:
        exit(0);
    }
  }

  Future<void> handleSignOut() async {
    await _authController.handleSignOut();
    Get.offAll(() => LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.homeTitle,
          style: TextStyle(color: ColorConstants.primaryColor),
        ),
        centerTitle: true,
        actions: <Widget>[buildPopupMenu()],
      ),
      body: SafeArea(
        child: WillPopScope(
          child: Stack(
            children: <Widget>[
              // List
              Column(
                children: [
                  buildSearchBar(),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _homeController.getStreamFireStore(
                          FirestoreConstants.pathUserCollection,
                          _limit,
                          _textSearch),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasData) {
                          if ((snapshot.data?.docs.length ?? 0) > 0) {
                            return ListView.builder(
                              padding: EdgeInsets.all(10),
                              itemBuilder: (context, index) => buildItem(
                                  context, snapshot.data?.docs[index]),
                              itemCount: snapshot.data?.docs.length,
                              controller: listScrollController,
                            );
                          } else {
                            return Center(
                              child: Text("No users"),
                            );
                          }
                        } else {
                          return Center(
                            child: CircularProgressIndicator(
                              color: ColorConstants.themeColor,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),

              // Loading
              Positioned(
                child: isLoading ? LoadingView() : SizedBox.shrink(),
              )
            ],
          ),
          onWillPop: onBackPress,
        ),
      ),
    );
  }

 Widget buildSearchBar() {
  return Container(
    height: 40,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.search, color: ColorConstants.greyColor, size: 20),
        SizedBox(width: 5),
        Expanded(
          child: TextFormField(
            textInputAction: TextInputAction.search,
            controller: searchBarTec,
            onChanged: (value) {
              searchDebouncer.run(() {
                setState(() {
                  _textSearch = value.toLowerCase().trim(); // Ensure case-insensitive search
                });
                btnClearController.add(value.isNotEmpty);
              });
            },
            decoration: InputDecoration.collapsed(
              hintText: 'Search by nickname...',
              hintStyle: TextStyle(fontSize: 13, color: ColorConstants.greyColor),
            ),
            style: TextStyle(fontSize: 13),
          ),
        ),
        StreamBuilder<bool>(
          stream: btnClearController.stream,
          builder: (context, snapshot) {
            return snapshot.data == true
                ? GestureDetector(
                    onTap: () {
                      searchBarTec.clear();
                      btnClearController.add(false);
                      setState(() {
                        _textSearch = "";
                      });
                    },
                    child: Icon(Icons.clear_rounded, color: ColorConstants.greyColor, size: 20),
                  )
                : SizedBox.shrink();
          },
        ),
      ],
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: ColorConstants.greyColor2,
    ),
    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
    margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
  );
}


  Widget buildPopupMenu() {
    return PopupMenuButton<PopupChoices>(
      onSelected: onItemMenuPress,
      itemBuilder: (BuildContext context) {
        return choices.map((PopupChoices choice) {
          return PopupMenuItem<PopupChoices>(
              value: choice,
              child: Row(
                children: <Widget>[
                  Icon(
                    choice.icon,
                    color: ColorConstants.primaryColor,
                  ),
                  Container(
                    width: 10,
                  ),
                  Text(
                    choice.title,
                    style: TextStyle(color: ColorConstants.primaryColor),
                  ),
                ],
              ));
        }).toList();
      },
    );
  }

  Widget buildItem(BuildContext context, DocumentSnapshot? document) {
    if (document != null) {
      UserChat userChat = UserChat.fromDocument(document);
      if (userChat.id == currentUserId) {
        return SizedBox.shrink();
      } else {
        // Highlight matching text if there's a search query
        Widget buildNicknameText() {
          if (_textSearch.isEmpty) {
            return Text(
              '${userChat.nickname}',
              maxLines: 1,
              style: TextStyle(color: ColorConstants.primaryColor),
            );
          }

          final nickname = userChat.nickname.toLowerCase();
          final searchQuery = _textSearch.toLowerCase();
          final matchIndex = nickname.indexOf(searchQuery);

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
                    matchIndex + searchQuery.length,
                  ),
                  style: TextStyle(
                    color: ColorConstants.primaryColor,
                    fontWeight: FontWeight.bold,
                    backgroundColor: Colors.yellow.withOpacity(0.3),
                  ),
                ),
                TextSpan(
                  text: userChat.nickname.substring(matchIndex + searchQuery.length),
                ),
              ],
            ),
          );
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
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
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
                          child: buildNicknameText(),
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.fromLTRB(10, 0, 0, 5),
                        ),
                        Container(
                          child: Text(
                            'About me: ${userChat.aboutMe}',
                            maxLines: 1,
                            style: TextStyle(color: ColorConstants.primaryColor),
                          ),
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                        )
                      ],
                    ),
                    margin: EdgeInsets.only(left: 20),
                  ),
                ),
              ],
            ),
            onPressed: () {
              if (Utilities.isKeyboardShowing()) {
                Utilities.closeKeyboard(context);
              }
              Get.to(() => ChatPage(
                    arguments: ChatPageArguments(
                      peerId: userChat.id,
                      peerAvatar: userChat.photoUrl,
                      peerNickname: userChat.nickname,
                    ),
                  ));
            },
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
    } else {
      return SizedBox.shrink();
    }
  }
}
