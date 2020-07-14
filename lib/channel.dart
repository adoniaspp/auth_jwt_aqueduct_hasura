import 'package:auth_jwt_project/auth_jwt_project.dart';


class AuthJwtProjectChannel extends ApplicationChannel {
  ManagedContext context;
  AuthConfiguration configurations;
 
  @override
  Future prepare() async {
    configurations = AuthConfiguration(options.configurationFilePath);
    logger.onRecord.listen((rec) => print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}"));
  }
 
  @override
  Controller get entryPoint {
    final router = Router();

    router
        .route("/auth/signin")
        .link(() => AuthJwtSigninController(context,configurations));

    router
        .route("/auth/signup")
        .link(() => AuthJwtSignupController(context,configurations));

    router
        .route("/auth/refreshtoken")
        .link(() => AuthJwtRefreshTokenController(context));

    return router;
  }
}