import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pages.dart';
import './input_field.dart';
import '../utils/utils.dart';
import './drawer_button.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    Key? key,
  }) : super(key: key);

  @override
  State createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    return Column(children: [
      if (isDisplayDesktop(context) && !pages.isDrawerOpen)
        const ChatDrawerButton(),
      messageList(context),
      const ChatInputField(),
    ]);
  }

  Widget messageList(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    final msgBoxes = pages.getMessageBox(pages.currentPageID);
    return Flexible(
      child: ListView.builder(
        key: UniqueKey(),
        padding: const EdgeInsets.all(8.0),
        reverse: true,
        itemBuilder: (context, index) => msgBoxes?[index],
        itemCount: msgBoxes?.length,
      ),
    );
  }
}
