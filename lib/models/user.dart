import 'package:hive/hive.dart';
part 'user.g.dart';

@HiveType(typeId: 1)
class User extends HiveObject {
  @HiveField(0)
  String firstName;

  @HiveField(1)
  String lastName;

  @HiveField(2)
  String email;

  @HiveField(3)
  String password;

  @HiveField(4)
  DateTime createdAt;

  User({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  }) : createdAt = DateTime.now();
}

