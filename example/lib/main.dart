import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:dash_chat/dash_chat.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<DashChatState> _chatViewKey = GlobalKey<DashChatState>();

  final ChatUser otherUser = ChatUser(
    name: "Fayeed",
    uid: "123456789",
    avatar: "https://www.wrappixel.com/ampleadmin/assets/images/users/4.jpg",
  );

  final ChatUser user = ChatUser(
    name: "MrTaffy",
    uid: "256496598",
  );

  List<ChatMessage> messages = [];
  List<ChatMessage> m = [];

  var i = 0;

  @override
  void initState() {
    super.initState();
  }

  void systemMessage() {
    Timer(Duration(milliseconds: 300), () {
      if (i < 6) {
        setState(() {
          messages = [...messages, m[i]];
        });
        i++;
      }
      Timer(Duration(milliseconds: 300), () {
        _chatViewKey.currentState?.scrollController?.animateTo(
          _chatViewKey
                  .currentState?.scrollController?.position.maxScrollExtent ??
              0.0,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 300),
        );
      });
    });
  }

  void onSend(ChatMessage message) {
    print(message.toJson());
    var documentReference = FirebaseFirestore.instance
        .collection('messages')
        .doc(DateTime.now().millisecondsSinceEpoch.toString());

    FirebaseFirestore.instance.runTransaction((transaction) async {
      await transaction.set(
        documentReference,
        message.toJson(),
      );
    });
    /* setState(() {
      messages = [...messages, message];
      print(messages.length);
    });

    if (i == 0) {
      systemMessage();
      Timer(Duration(milliseconds: 600), () {
        systemMessage();
      });
    } else {
      systemMessage();
    } */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat App"),
      ),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('messages').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              );
            } else {
              List<DocumentSnapshot>? items =
                  snapshot.data as List<DocumentSnapshot<DocumentSnapshot?>>?;
              //List<DocumentSnapshot>? items = snapshot.data.document
              var messages = items
                  ?.map((i) => ChatMessage.fromJson(i.data as Map))
                  .toList();
              return DashChat(
                key: _chatViewKey,
                inverted: true,
                onSend: onSend,
                sendOnEnter: true,
                textInputAction: TextInputAction.send,
                user: user,
                inputFormatters: [],
                backgroundImageBuilder: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: Image.network(
                      'https://image.winudf.com/v2/image/Y29tLmNvZGVGYWN0b3J5LndhV2FsbHBhcGVyc19zY3JlZW5fMV8xNTMwNTY4MzE5XzA2Nw/screen-1.jpg?fakeurl=1&type=.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                inputDecoration:
                    InputDecoration.collapsed(hintText: "Add message here..."),
                dateFormat: DateFormat('yyyy-MMM-dd'),
                timeFormat: DateFormat('HH:mm'),
                messages: messages ?? List.empty(),
                showUserAvatar: false,
                shouldStartMessagesFromTop: true,
                showAvatarForEveryMessage: false,
                showAvatarForLastMessage: false,
                scrollToBottom: false,
                onPressAvatar: (ChatUser user) {
                  print("OnPressAvatar: ${user.name}");
                },
                onLongPressAvatar: (ChatUser user) {
                  print("OnLongPressAvatar: ${user.name}");
                },
                inputMaxLines: 5,
                messageContainerPadding: EdgeInsets.only(left: 5.0, right: 5.0),
                alwaysShowSend: true,
                inputTextStyle: TextStyle(fontSize: 16.0),
                inputContainerStyle: BoxDecoration(
                  border: Border.all(width: 0.0),
                  color: Colors.white,
                ),
                onQuickReply: (Reply reply) {
                  setState(() {
                    messages?.add(ChatMessage(
                        text: reply.value,
                        createdAt: DateTime.now(),
                        user: user));

                    messages = [...messages ?? List.empty()];
                  });

                  Timer(Duration(milliseconds: 300), () {
                    _chatViewKey.currentState?.scrollController?.animateTo(
                      _chatViewKey.currentState?.scrollController?.position
                              .maxScrollExtent ??
                          0.0,
                      curve: Curves.easeOut,
                      duration: const Duration(milliseconds: 300),
                    );

                    if (i == 0) {
                      systemMessage();
                      Timer(Duration(milliseconds: 600), () {
                        systemMessage();
                      });
                    } else {
                      systemMessage();
                    }
                  });
                },
                onLoadEarlier: () {
                  print("laoding...");
                },
                shouldShowLoadEarlier: false,
                showTraillingBeforeSend: true,
                trailing: <Widget>[
                  IconButton(
                    icon: Icon(Icons.photo),
                    onPressed: () async {
                      XFile? result = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                        maxHeight: 400,
                        maxWidth: 400,
                      );

                      if (result != null) {
                        final Reference storageRef =
                            FirebaseStorage.instance.ref().child("chat_images");

                        UploadTask uploadTask = storageRef.putFile(
                          File(result.path),
                          SettableMetadata(
                            contentType: 'image/jpg',
                          ),
                        );

                        String url =
                            await uploadTask.snapshot.ref.getDownloadURL();

                        ChatMessage message =
                            ChatMessage(text: "", user: user, image: url);

                        var documentReference = FirebaseFirestore.instance
                            .collection('messages')
                            .doc(DateTime.now()
                                .millisecondsSinceEpoch
                                .toString());

                        FirebaseFirestore.instance
                            .runTransaction((transaction) async {
                          await transaction.set(
                            documentReference,
                            message.toJson(),
                          );
                        });
                      }
                    },
                  )
                ],
              );
            }
          }),
    );
  }
}
