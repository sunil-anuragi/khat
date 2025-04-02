import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_demo/constants/constants.dart';

class MessageChat {
  final String idFrom;
  final String idTo;
  final String timestamp;
  final String content;
  final int type;
  final bool istyping;
  final bool isonline;
  final bool status;
  final String whotyping;
  final bool isRead;

  const MessageChat({
    required this.idFrom,
    required this.idTo,
    required this.timestamp,
    required this.content,
    required this.type,
    required this.istyping,
    required this.whotyping,
    required this.isonline,
    required this.status,
    required this.isRead,
  });

  Map<String, dynamic> toJson() {
    return {
      FirestoreConstants.idFrom: this.idFrom,
      FirestoreConstants.idTo: this.idTo,
      FirestoreConstants.timestamp: this.timestamp,
      FirestoreConstants.content: this.content,
      FirestoreConstants.type: this.type,
      FirestoreConstants.istyping: this.istyping,
      FirestoreConstants.whotyping: this.whotyping,
      FirestoreConstants.isonline: this.isonline,
      FirestoreConstants.status: this.status,
      FirestoreConstants.isRead: this.isRead,
    };
  }

  factory MessageChat.fromDocument(DocumentSnapshot doc) {
    String idFrom = doc.get(FirestoreConstants.idFrom);
    String idTo = doc.get(FirestoreConstants.idTo);
    String timestamp = doc.get(FirestoreConstants.timestamp);
    String content = doc.get(FirestoreConstants.content);
    String whotyping = doc.get(FirestoreConstants.whotyping);
    int type = doc.get(FirestoreConstants.type);
    bool istyping = doc.get(FirestoreConstants.istyping);
    bool isonline = doc.get(FirestoreConstants.isonline);
    bool status = doc.get(FirestoreConstants.status);
    bool isRead = doc.get(FirestoreConstants.isRead);
    return MessageChat(
        idFrom: idFrom,
        idTo: idTo,
        timestamp: timestamp,
        content: content,
        type: type,
        istyping: istyping,
        whotyping: whotyping,
        isonline: isonline,
        status: status,
        isRead: isRead);
  }
}
