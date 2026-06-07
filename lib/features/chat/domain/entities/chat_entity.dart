import 'package:equatable/equatable.dart';

class ChatUser extends Equatable {
  final int id;
  final String name;
  final String? email;

  const ChatUser({
    required this.id,
    required this.name,
    this.email,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    email,
  ];
}