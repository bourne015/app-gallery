import 'package:flutter/widgets.dart';

//all chat pages
class User with ChangeNotifier {
  bool _isLogedin = false;
  int _id = 0;
  String? _name;
  String? _email;
  String? _phone;
  String? _avatar;
  bool _signUP = true;

  int get id => _id;
  set id(int user_id) {
    _id = user_id;
    notifyListeners();
  }

  String? get name => _name;
  set name(String? name) {
    _name = name;
    notifyListeners();
  }

  String? get email => _email;
  set email(String? mail) {
    _email = mail;
    notifyListeners();
  }

  String? get phone => _phone;
  set phone(String? num) {
    _phone = num;
    notifyListeners();
  }

  String? get avatar => _avatar;
  set avatar(String? avatarNum) {
    _avatar = avatarNum;
    notifyListeners();
  }

  bool get isLogedin => _isLogedin;
  set isLogedin(bool v) {
    _isLogedin = v;
    notifyListeners();
  }

  bool get signUP => _signUP;
  set signUP(bool v) {
    _signUP = v;
    notifyListeners();
  }
}
