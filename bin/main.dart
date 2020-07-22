import 'package:auth_jwt_project/auth_jwt_project.dart';

Future main() async {
  final app = Application<AuthJwtProjectChannel>()
      ..options.configurationFilePath = "config.yaml"
      ..options.address = "0.0.0.0"
      ..options.port = 80;

  await app.startOnCurrentIsolate();

  print("Application started on port: ${app.options.port}.");
  print("Use Ctrl-C (SIGINT) to stop running the application.");
}