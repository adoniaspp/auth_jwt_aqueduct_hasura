import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:cryptography/cryptography.dart';
import 'package:corsac_jwt/corsac_jwt.dart';
import '../auth_jwt_project.dart';

class AuthJwtRefreshTokenController extends ResourceController{
  
  AuthJwtRefreshTokenController(this.context, this.configuration);

  final ManagedContext context;
  final AuthConfiguration configuration;

  @Operation.post()
  Future<Response> refreshToken() async 
  { 
      //Obtem os dados do body
      final bodyMap = request.body.as();
      final refreshtoken = bodyMap["input"]["refresh_token"].toString();
      final idPhone = bodyMap["input"]["id_phone"].toString();

      //Pesquisa pelo refreshtoken
       const hasuraOperation = '''
        query MyQuery(\$refreshtoken: String!) {
          user(where: {refresh_token: {_eq: \$refreshtoken}}) {
            id
            id_phone
          }
        }      
        ''';
      final variables = {"refreshtoken": refreshtoken.toString()};
      final bodyHasura =
        json.encode({"query": hasuraOperation, "variables": variables});
      final responseQuery = await http.post(configuration.hasuraUrl,
        headers: {
          "content-type": "application/json",
          "x-hasura-admin-secret": configuration.hasuraAdminSecret
        },
        body: bodyHasura);
        final bodyResponseQuery = json.decode(responseQuery.body);
        final idUser = bodyResponseQuery["data"]["user"][0]["id"];
        final idPhoneBD = bodyResponseQuery["data"]["user"][0]["id_phone"];

      //Se encontrou o token para o idphone correto Gera o Jwt para o usuário
      


      //Gera um novo refresh token e atualiza o bd

      //Retorna os dados de sucesso
  }

}