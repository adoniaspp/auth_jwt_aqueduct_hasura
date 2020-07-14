import 'package:auth_jwt_project/auth_jwt_project.dart';

class AuthConfiguration extends Configuration {
  AuthConfiguration(String fileName) : super.fromFile(File(fileName));
  String jwtSecret;
  String claims;
  String hasuraUrl;
  String hasuraAdminSecret;
}