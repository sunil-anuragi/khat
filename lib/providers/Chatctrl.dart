import 'package:dio/dio.dart';
import 'package:get/get.dart';

class Chatctrl extends GetxController {
  var istyping = false.obs;
  var whoistyping = "".obs;
  var isonline = false.obs;
  var status = false.obs;
  var dio = Dio();
  sendnotification() async {
    var req = {
      "to": "FCM_TOKEN_OR_TOPIC_WILL_BE_HERE",
      "notification": {
        "body": "Body of Your Notification",
        "title": "Title of Your Notification"
      }
    };
    await dio
        .post("https://fcm.googleapis.com/fcm/send",
            data: req,
            options: Options(
              headers: {
                "Authorization":
                    "key = AAAAWd9Wmew:APA91bE_HjcWJwB6f0QOW_Y8SuCQO9FaMjclsZv1VD7VX_1naO0qTQZSNk_-0fedgSyCMgaQAlDpfIzxoufGrunqvcQlwthPiKQ6k7okDQ1c4DyVYjFhSuyD6HyNaweAHtuyfVFd9JA7", // Set the content-length.
                "Content-Type": "application/json"
              },
            ))
        .then((value) {
      print(value);
    });
  }
}
