import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/constants.dart';
import '../utils/utils.dart';
import '../models/pages.dart';

class ChatDrawer extends StatefulWidget {
  const ChatDrawer({super.key});

  @override
  State<ChatDrawer> createState() => ChatDrawerState();
}

class ChatDrawerState extends State<ChatDrawer> {
  @override
  Widget build(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    return Drawer(
      width: drawerWidth,
      backgroundColor: AppColors.drawerBackground,
      shape: isDisplayDesktop(context)
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            )
          : null,
      child: Column(
        //padding: EdgeInsets.zero,
        children: [
          newchatButton(context),
          chatPageTabList(context),
          const Divider(
            height: 20,
            thickness: 1,
            indent: 10,
            endIndent: 10,
            color: AppColors.drawerDivider,
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            minLeadingWidth: 0,
            title: RichText(
                text: TextSpan(
              text: 'clear conversations',
              style: TextStyle(fontSize: 17, color: AppColors.msgText),
            )),
            onTap: () {
              if (pages.currentPage?.onGenerating == false) {
                pages.clearMsg(pages.currentPageID);
              }
              pages.currentPage?.title = "Chat ${pages.currentPage?.id}";
              if (!isDisplayDesktop(context)) Navigator.pop(context);
            },
          ),
          ListTile(
              leading: const Icon(Icons.info),
              minLeadingWidth: 0,
              title: RichText(
                  text: TextSpan(
                text: 'about',
                style: TextStyle(fontSize: 17, color: AppColors.msgText),
              )),
              onTap: () {
                if (!isDisplayDesktop(context)) {
                  Navigator.pop(context); // hide sidebar
                }
                aboutButton(context);
              }),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget newchatButton(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      Expanded(
          flex: 4,
          child: Container(
              margin: const EdgeInsets.fromLTRB(10, 15, 10, 25),
              child: OutlinedButton.icon(
                onPressed: () {
                  // var newId = pages.assignNewPageID;
                  // pages.addPage(
                  //     newId, Chat(chatId: newId, title: "Chat $newId"));
                  // pages.currentPageID = newId;
                  pages.displayInitPage = true;
                  pages.currentPageID = -1;
                  if (!isDisplayDesktop(context)) Navigator.pop(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('New Chat'),
                style: ButtonStyle(
                  minimumSize: MaterialStateProperty.all(
                      const Size(double.infinity, 52)),
                  padding: MaterialStateProperty.all(EdgeInsets.zero),
                  //padding: EdgeInsets.symmetric(horizontal: 20.0),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
                ),
              ))),
    ]);
  }

  Widget delChattabButton(BuildContext context, Pages pages, int removeID) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        icon: const Icon(Icons.close),
        iconSize: 15,
        onPressed: () {
          pages.delPage(removeID);
          pages.currentPageID = -1;
          pages.displayInitPage = true;
        },
      ),
    ]);
  }

  Widget chatPageTab(BuildContext context, Pages pages, int index) {
    final page = pages.getPage(pages.getNthPageID(index));
    return Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          selectedTileColor: AppColors.drawerTabSelected,
          selected: pages.currentPageID == page.id,
          leading: const Icon(Icons.chat_bubble_outline, size: 16),
          minLeadingWidth: 0,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          title: RichText(
              text: TextSpan(
                text: page.title,
                style: TextStyle(fontSize: 15.5, color: AppColors.msgText),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1),
          onTap: () {
            pages.currentPageID = page.id;
            pages.displayInitPage = false;
            if (!isDisplayDesktop(context)) Navigator.pop(context);
          },
          //always keep chat 0
          trailing: (pages.currentPageID == page.id && pages.pagesLen > 1)
              ? delChattabButton(context, pages, page.id)
              : null,
        ));
  }

  Widget chatPageTabList(BuildContext context) {
    Pages pages = Provider.of<Pages>(context);
    return Expanded(
      child: ListView.builder(
        shrinkWrap: false,
        itemCount: pages.pagesLen,
        itemBuilder: (context, index) => chatPageTab(context, pages, index),
      ),
    );
  }

  Future aboutButton(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: const Text('About'),
              content: const SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(aboutText),
                    Text('Version $appVersion'),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
  }
}
