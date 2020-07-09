import 'package:auth_jwt_project/auth_jwt_project.dart';

class AuthJwtProjectChannel extends ApplicationChannel {
  ManagedContext context;
 
  @override
  Future prepare() async {
    logger.onRecord.listen((rec) => print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}"));
  }
 
  @override
  Controller get entryPoint {
    final router = Router();

    router
        .route("/auth/signin")
        .link(() => AuthJwtSigninController(context));

    router
        .route("/auth/signup")
        .link(() => AuthJwtSignupController(context));

    router
        .route("/auth/refreshtoken")
        .link(() => AuthJwtSignupController(context));

    return router;
  }
}