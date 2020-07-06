import '../auth_jwt_project.dart';

class AuthJwtSigninController extends ResourceController{
  
  AuthJwtSigninController(this.context);

  final ManagedContext context;

  @Operation.post()
  Future<Response> sigin() async 
  { 
      //Obtem os dados do body
      final bodyMap = request.body.as();
      final password = bodyMap["input"]["senha"].toString();

      //Obtem o usuário para recuperar a senha do banco via graphql

      //Decodifica a senha do banco

      //Compara com a senha fornecida pelo usuário

      //Gera o token jwt

      //Retorna o token

      //print(bodyMap);
  }

}