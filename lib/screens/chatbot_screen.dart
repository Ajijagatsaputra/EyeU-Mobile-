import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:bubble/bubble.dart';

class ChatBotPanel extends StatefulWidget {
  const ChatBotPanel({Key? key});

  @override
  _ChatBotPanelState createState() => _ChatBotPanelState();
}

class _ChatBotPanelState extends State<ChatBotPanel> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  List<String> _data = [];
  // ignore: unused_field
  static const String BOT_URL = "https://b5c8-103-166-147-253.ngrok-free.app/chatbot_mobile";

  TextEditingController queryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('Chatbot'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue,
                Colors.blue
              ], // Your desired gradient colors
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          AnimatedList(
            key: _listKey,
            initialItemCount: _data.length,
            itemBuilder: (context, index, animation) {
              return buildItem(_data[index], animation, index);
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ColorFiltered(
                colorFilter: ColorFilter.linearToSrgbGamma(),
                child: Container(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.only(left: 20, right: 20),
                    child: TextField(
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                          icon: Icon(
                            Icons.message,
                            color: Colors.blue,
                          ),
                          hintText: "Enter chat",
                          fillColor: Colors.white12),
                      controller: queryController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (msg) {
                        this.getResponse();
                      },
                    ),
                  ),
                )),
          )
        ],
      ),
    );
  }

  void getResponse() {
    if (queryController.text.isNotEmpty) {
      this.insertSingleItem(queryController.text);
      var client = getClient();
      try {
        client
            .post(
          Uri.parse(
              "https://b5c8-103-166-147-253.ngrok-free.app/chatbot_mobile"),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({"chatinput": queryController.text}),
        )
            .then((response) {
          print(response.body);
          Map<String, dynamic> data = jsonDecode(response.body);
          insertSingleItem(data['response'] + "<bot>");
        });
      } finally {
        client.close();
        queryController.clear();
      }
    }
  }

  void insertSingleItem(String message) {
    _data.add(message);
    _listKey.currentState!.insertItem(_data.length - 1);
  }

  http.Client getClient() {
    return http.Client();
  }
}

Widget buildItem(String item, Animation<double> animation, int index) {
  bool mine = item.endsWith("<bot>");
  return SizeTransition(
    sizeFactor: animation,
    child: Padding(
      padding: EdgeInsets.only(top: 10),
      child: Container(
        alignment: mine ? Alignment.topLeft : Alignment.topRight,
        child: Bubble(
          child: Text(
            item.replaceAll("<bot>", ""),
            style: TextStyle(color: mine ? Colors.white : Colors.black),
          ),
          color: mine ? Colors.blue : Colors.grey[200],
          padding: BubbleEdges.all(10),
        ),
      ),
    ),
  );
}
