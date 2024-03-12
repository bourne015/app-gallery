import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../models/pages.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../utils/constants.dart';
import '../utils/utils.dart';

class ChatInputField extends StatefulWidget {
  const ChatInputField({super.key});

  @override
  State createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final dio = Dio();
  final ChatSSE chatServer = ChatSSE();
  final _controller = TextEditingController();
  bool _hasInputContent = false;
  XFile? _imageFile;
  List<int>? _imageBytes;

  @override
  Widget build(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    return Container(
      decoration: BoxDecoration(
          color: AppColors.inputBoxBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(7),
            topRight: Radius.circular(7),
            bottomLeft: Radius.circular(7),
            bottomRight: Radius.circular(7),
          )),
      margin: const EdgeInsets.only(left: 50, right: 50, top: 5, bottom: 15),
      padding: const EdgeInsets.only(left: 7, right: 1, top: 1, bottom: 1),
      child: Row(
        children: [
          if ((!pages.displayInitPage &&
                  pages.currentPage?.modelVersion ==
                      ModelVersion.gptv40Vision) ||
              (pages.displayInitPage &&
                  pages.defaultModelVersion == ModelVersion.gptv40Vision))
            pickButton(context),
          inputField(context),
          (!pages.displayInitPage && pages.currentPage!.onGenerating)
              ? generatingAnimation(context)
              : sendButton(context),
        ],
      ),
    );
  }

  Widget inputField(BuildContext context) {
    return Expanded(
        child: Stack(alignment: Alignment.topLeft, children: <Widget>[
      Column(children: [
        imageField(context),
        const SizedBox(width: 8),
        textField(context),
      ]),
    ]));
  }

  Widget imageField(BuildContext context) {
    if (_imageFile == null) {
      return Container();
    }
    return Container(
      decoration: BoxDecoration(
          color: AppColors.inputBoxBackground,
          borderRadius: const BorderRadius.all(Radius.circular(15))),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.all(1),
      child: Row(
        children: [
          Image.network(_imageFile!.path,
              height: 60, width: 60, fit: BoxFit.cover),
          IconButton(
            icon: const Icon(
              Icons.close,
              size: 12,
            ),
            onPressed: () {
              setState(() {
                _imageFile = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget textField(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    String hintText = "Send a message";

    if ((pages.displayInitPage &&
            pages.defaultModelVersion == ModelVersion.gptv40Vision) ||
        (!pages.displayInitPage &&
            pages.currentPage!.modelVersion == ModelVersion.gptv40Vision)) {
      hintText = "pick image and input questions";
    } else if ((pages.displayInitPage &&
            pages.defaultModelVersion == ModelVersion.gptv40Dall) ||
        (!pages.displayInitPage &&
            pages.currentPage!.modelVersion == ModelVersion.gptv40Dall)) {
      hintText = "describe the image";
    }

    return TextFormField(
      onChanged: (value) {
        setState(() {
          _hasInputContent = value.isNotEmpty;
        });
      },
      decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.inputBoxBackground,
          border: InputBorder.none,
          hintText: hintText),
      minLines: 1,
      maxLines: 10,
      textInputAction: TextInputAction.newline,
      controller: _controller,
    );
  }

  Widget pickButton(BuildContext context) {
    return IconButton(
        icon: const Icon(
          Icons.image_rounded,
          size: 20,
        ),
        onPressed: _pickImage);
  }

  Widget generatingAnimation(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(right: 7),
        child: const SpinKitSpinningLines(
          color: AppColors.generatingAnimation,
          size: AppSize.generatingAnimation,
        ));
  }

  Widget sendButton(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    return IconButton(
      icon: const Icon(Icons.send),
      color: ((_imageFile != null || _hasInputContent) &&
              (pages.displayInitPage ||
                  (pages.currentPageID >= 0 &&
                      !pages.currentPage!.onGenerating)))
          ? Colors.blue
          : Colors.grey,
      onPressed: ((_imageFile != null || _hasInputContent) &&
              (pages.displayInitPage ||
                  (pages.currentPageID >= 0 &&
                      !pages.currentPage!.onGenerating)))
          ? () {
              int handlePageID;
              if (pages.currentPageID == -1) {
                handlePageID = pages.assignNewPageID;
                pages.currentPageID = handlePageID;
                pages.addPage(handlePageID,
                    Chat(chatId: handlePageID, title: "Chat $handlePageID"));
                pages.displayInitPage = false;
                pages.currentPage?.modelVersion = pages.defaultModelVersion;
              } else {
                handlePageID = pages.currentPageID;
              }
              _submitText(
                pages,
                handlePageID,
                _controller.text,
              );
              _hasInputContent = false;
              _imageFile = null;
            }
          : () {},
    );
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _imageFile = pickedFile;
      } else {
        _imageFile = null;
      }
    });
    _imageBytes = await _imageFile!.readAsBytes();
  }

  void titleGenerate(Pages pages, int handlePageID) async {
    String q;
    if (pages.getPage(handlePageID).modelVersion == ModelVersion.gptv40Dall) {
      q = pages.getMessages(handlePageID)!.first.content;
    } else if (pages.getMessages(handlePageID)!.length > 1) {
      q = pages.getMessages(handlePageID)![1].content;
    } else {
      //in case no input
      return;
    }
    var chatData1 = {
      "model": ModelVersion.gptv35,
      "question": "为这段话写一个5个字左右的标题:$q"
    };
    final response = await dio.post(chatUrl, data: chatData1);
    var title = response.data;
    pages.setPageTitle(handlePageID, title);
  }

  void _submitText(Pages pages, int handlePageID, String text) async {
    bool append = false;
    _controller.clear();
    Message msgQ = Message(
        id: '0',
        pageID: handlePageID,
        role: MessageRole.user,
        type: _imageFile == null ? MsgType.text : MsgType.mix,
        content: text,
        file: _imageFile,
        fileBytes: _imageBytes,
        timestamp: DateTime.now());
    pages.addMessage(handlePageID, msgQ);

    if (pages.defaultModelVersion == ModelVersion.gptv40Dall) {
      String q = pages.getMessages(handlePageID)!.last.content;
      var chatData1 = {"model": ModelVersion.gptv40Dall, "question": q};
      pages.getPage(handlePageID).onGenerating = true;
      final response = await dio.post(imageUrl, data: chatData1);
      pages.getPage(handlePageID).onGenerating = false;
      if (response.statusCode == 200 &&
          pages.getPage(handlePageID).title == "Chat $handlePageID") {
        titleGenerate(pages, handlePageID);
      }

      Message msgA = Message(
          id: '1',
          pageID: handlePageID,
          role: MessageRole.assistant,
          type: MsgType.image,
          content: response.data,
          timestamp: DateTime.now());
      pages.addMessage(handlePageID, msgA);
    } else {
      try {
        var chatData = {
          "model": pages.currentPage?.modelVersion,
          "question": pages.getPage(handlePageID).msgsToMap()
        };
        final stream = chatServer.connect(
          sseChatUrl,
          "POST",
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream'
          },
          body: jsonEncode(chatData),
        );
        pages.getPage(handlePageID).onGenerating = true;
        stream.listen((data) {
          if (append == false) {
            Message msgA = Message(
                id: '1',
                pageID: handlePageID,
                role: MessageRole.assistant,
                type: MsgType.text,
                content: data,
                timestamp: DateTime.now());
            pages.addMessage(handlePageID, msgA);
          } else {
            pages.appendMessage(handlePageID, data);
          }
          pages.getPage(handlePageID).onGenerating = true;
          append = true;
        }, onError: (e) {
          debugPrint('SSE error: $e');
          pages.getPage(handlePageID).onGenerating = false;
        }, onDone: () {
          debugPrint('SSE complete');
          if (pages.getPage(handlePageID).title == "Chat $handlePageID") {
            titleGenerate(pages, handlePageID);
          }
          pages.getPage(handlePageID).onGenerating = false;
        });
      } catch (e) {
        debugPrint("error: $e");
        pages.getPage(handlePageID).onGenerating = false;
      }
    }
  }
}
