import 'package:auth_jwt_project/auth_jwt_project.dart';

class _User
{
  @Column(primaryKey: true)
  int id;
  String user;
  String password;
  String salt;
  String refreshToken;
  String idPhone;
}