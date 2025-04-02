import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateDataFirestore(
      String collectionPath, String docPath, Map<String, dynamic> data) async {
    if (collectionPath.isEmpty || docPath.isEmpty) {
      print('Error: Collection path or document path is empty');
      return;
    }

    try {
      await _firestore.collection(collectionPath).doc(docPath).update(data);
    } catch (e) {
      print('Error updating data: $e');
      rethrow;
    }
  }

  Future<void> updateDataFirestoreAllField(
      String collectionPath, String docPath, Map<String, dynamic> data) async {
    if (collectionPath.isEmpty || docPath.isEmpty) {
      print('Error: Collection path or document path is empty');
      return;
    }

    try {
      await _firestore.collection(collectionPath).doc(docPath).set(data);
    } catch (e) {
      print('Error updating data: $e');
      rethrow;
    }
  }

  Future<String> getAccessToken() async {
    // Your client ID and client secret obtained from Google Cloud Console
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "khat-d3d55",
      "private_key_id": "455bcc32ad205465eda66be4e22379bf3702aff8",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDGqGL2weKKgJSI\n9Kvrl+KknsXlaVF+Fd3fJVgWh1nfnBKQYXEQRHsf+s1G73vJuAO10HFxhKDO6CWd\nIvtu0ISm85ZGFLDrDOc52xsnqC92nwLBa4cQDeiDV2YnIUN37YvCpvV7cUr+wswR\nTQsTwUa72IlTdFLqRIN8veJfFsc/X30orZXUXDSVCn2WTcsl/vgGgoAMjS2RLzIt\nn0vVJVCdB+8C689An55MOF97QRSqzMKpGxRdT6WtRDzFh3uhzhNnVBajkBpyi2zS\nuBckGBzuoo3oXqqufkZkq9Z2SmktL8borqt9gxvVy4UY4KJ9ffrjRTDbIKCe/LGz\njxwJBju7AgMBAAECggEAAULQXgCdD4QBbV0gOj6cka7wUqR4f/RjlCcIiBwT1feH\npqL3tMK6hVlyNCERCBbC70SDc9UDsEyI8JZoQivQq76gFZHMDbHnRda+NWI76uTX\nf6LPGKr97td/LoBnjTtUx8eHh2EQuM1Dvlhe2aFAcbDOLllurU4CB6is5y2d1iki\nH9E7JoriUwFqNFxTXb6305smWbEFSqPjc/apufQJFmbnD6qAufH/ILzG7nScFcEE\nFTvo5rq/VVGsj8QQHgCbUO9OHm+d7ZsRuOdyoILR0r5juEt66s86ETHgHYts/Jun\nAYpHUoNSxaGh+zN6a6N5ixhxOLqTED8lwDLH/nMoAQKBgQD+7E3ARFch48rVAFYX\nmUETOAJKzyRqYkoUuJBWfiaw/S8Ykq/rZLNo8UghW6L7ZzeLj59sXXvoKDepOlgn\nb9gAMk/RWDk/U3NIbPemG/aXhq90y75YOWpMhjhtw2z4VQvs//x9FO2zpfamAtSo\nzgrxltJtNb7MoVy95mM6SM/x2wKBgQDHfzuL2xNPEWjCkfLyRok7/eZjfcvZi7UO\nx3LXbBBx0RV5x+MIgaGzrDpK50jXzzaL3mkch22MP4GSqFbJE/ovzATaYGzJI2dT\nLuC65z2fhVttnR5YbtXl6ss30yW6q3Ble5kI/5InmW25pmEhnQ1iyzn0J/gcGc1+\nDNgSOVmzoQKBgDcUN3hjS7A214xOFkvjAPx2DYi8WNHjir4PYqBNgW6cRaC5kOj7\nSQhTmZIbiotnMcklrvxq9mqixeP6hzF+KN1iAXzp4vSbwzzSzm9Fe3Ih16cUnnvR\na/Y8ydRtdQ3y0jDS3mroKrO2GCSmV+xhGFw6ihyukBsGglNFhAsD0GohAoGAP8s6\n4m0qzoT1qAp90uWlas61Rqlqb2WSf2heG+8NjyfaIzg9LHIvoEH53gv5qjEz8yQr\nHplb+ZYxPBGitugxf+lQv/hHsUYl+16pNHtPpFxDsVil5IeE1OHxHCfkD75U0c7l\nUBBRz2HryYsf0lzjc+0i2iWR3IKPyLgYvDMksSECgYEA3WCsBoW3Jn8gR9rDVtr1\ngejlN+HmLsBlxn2VLzodHsNP7mz/sklEXbVurWVMWaKBSOXap6IB85XohiHwRyWj\nSI68vpsy2HKI2KWHvGbBOfmYhn7f8t+si/4U/C8BHgptRYgisK5PMdI1Wj/Ta4EN\nXN7dGWTyyt0QDFiVis5iK3Q=\n-----END PRIVATE KEY-----\n",
      "client_email": "pushnotification@khat-d3d55.iam.gserviceaccount.com",
      "client_id": "106351683166666070630",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/pushnotification%40khat-d3d55.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };

    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging"
    ];

    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    // Obtain the access token
    auth.AccessCredentials credentials =
        await auth.obtainAccessCredentialsViaServiceAccount(
            auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
            scopes,
            client);
    client.close();
    return credentials.accessToken.data;
  }

  Future<void> sendFCMMessage(fcmToken, {body, title}) async {
    final String serverKey = await getAccessToken(); // Your FCM server key
    final String fcmEndpoint =
        'https://fcm.googleapis.com/v1/projects/khat-d3d55/messages:send';

    // log("fcmkey : $fcmToken");
    final Map<String, dynamic> message = {
      'message': {
        'token': fcmToken,
        'notification': {'body': body, 'title': title},
        'data': {
          'current_user_fcm_token': fcmToken,
        },
      }
    };

    final http.Response response = await http.post(
      Uri.parse(fcmEndpoint),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverKey',
      },
      body: jsonEncode(message),
    );
    // log("Tpke ==> " + 'Bearer' + serverKey.toString());

    if (response.statusCode == 200) {
      print('FCM message sent successfully');
    } else {
      print('Failed to send FCM message: ${response.statusCode}');
    }
  }
}
