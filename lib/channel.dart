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
        .route("/auth")
        .linkFunction((request) async {
            //final bodyMap = request.body.decode();
            //await bodyMap.then((value) => print(value["input"]["usuario"].toString()));
            //response: {session_variables: {x-hasura-role: admin}, input: {usuario: adoniaspp, senha: xpto}, action: {name: userTest}}
            //regra de negócio.
            //Enviar requisição para mutation no hasura.
            //Hasura devolve o id inserido.
            //API do aqueduct retorna o id para o hasura.
            //return Response.ok({"key": "value"});
        });

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