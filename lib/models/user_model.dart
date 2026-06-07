import 'package:quickblox_sdk/models/qb_user.dart';

class Users {
  final int id;
  final String name;
  final String login;

  Users({
    required this.id,
    required this.name,
    required this.login,
  });

  factory Users.fromQB(QBUser? user) {
    return Users(
      id: user?.id ?? 0,
      name: user?.fullName ?? '',
      login: user?.login ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'login': login,
    };
  }

  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(
      id: json['id'],
      name: json['name'],
      login: json['login'],
    );
  }
}