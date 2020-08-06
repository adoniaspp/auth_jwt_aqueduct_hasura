import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:cryptography/cryptography.dart';
import 'package:corsac_jwt/corsac_jwt.dart';
import '../auth_jwt_project.dart';

class AuthJwtRefreshTokenController extends ResourceController {
  AuthJwtRefreshTokenController(this.context, this.configuration);

  final ManagedContext context;
  final AuthConfiguration configuration;

  @Operation.post()
  Future<Response> refreshToken() async {
    //Obtem os dados do body
    final bodyMap = request.body.as();
    final refreshtoken = bodyMap["input"]["refresh_token"].toString();
    final idPhone = bodyMap["input"]["id_phone"].toString();

    //Pesquisa pelo refreshtoken
    const hasuraOperation = '''
        query MyQuery(\$refreshtoken: String!, \$idphone: String!) {
          user(where: {refresh_token: {_eq: \$refreshtoken}, id_phone: {_eq: \$idphone}}) {
            id
            id_phone
          }
        }      
        ''';
    final variables = {"refreshtoken": refreshtoken.toString(), "idphone": idPhone.toString()};
    final bodyHasura =
        json.encode({"query": hasuraOperation, "variables": variables});
    final responseQuery = await http.post(configuration.hasuraUrl,
        headers: {
          "content-type": "application/json",
          "x-hasura-admin-secret": configuration.hasuraAdminSecret
        },
        body: bodyHasura);

    final bodyResponseQuery = json.decode(responseQuery.body);

    if (bodyResponseQuery["data"]["user"].toString() != "[]") {
      final idUser = bodyResponseQuery["data"]["user"][0]["id"];
      final idPhoneBD = bodyResponseQuery["data"]["user"][0]["id_phone"];

      //Se encontrou o token para o idphone correto gera o Jwt para o usuário
      final builder = JWTBuilder();
      builder
        //..subject = idUser.toString()
        ..expiresAt = DateTime.now().add(const Duration(days: 1))
        ..setClaim('https://hasura.io/jwt/claims', {
          "x-hasura-allowed-roles": ["user"],
          "x-hasura-user-id": idUser.toString(),
          "x-hasura-default-role": "user",
          "x-hasura-role": "user"
        })
        ..getToken(); // returns token without signature

      final signer = JWTHmacSha256Signer(
          configuration.jwtSecret);
      final signedToken = builder.getSignedToken(signer);

      //Gera um novo refresh token e atualiza o bd
      final Random _random = Random.secure();
      final values = List<int>.generate(32, (i) => _random.nextInt(256));
      final refreshToken = await blake2s.hash(
        values,
      );

      const hasuraOperation = '''
      mutation MyMutation(\$refresh_token: String!, \$iduser: Int!) {
        update_user(_set: {refresh_token: \$refresh_token}, where: {id: {_eq: \$iduser}}) {
          returning {
            id
          }
        }
      }     
        ''';
      final variables = {"iduser": idUser.toString(), "refresh_token": refreshToken.bytes.toString()};
      final bodyHasura =
        json.encode({"query": hasuraOperation, "variables": variables});
      final responseUpdate = await http.post(configuration.hasuraUrl,
        headers: {
          "content-type": "application/json",
          "x-hasura-admin-secret": configuration.hasuraAdminSecret
        },
        body: bodyHasura);
      //Retorna os dados de sucesso
      return Response.ok(
      {
        "id": idUser.toString(),
        "token": signedToken.toString(),
        "refreshtoken": refreshToken.bytes.toString()
      });
    } else {
      return Response.unauthorized(
          body: {"message": "token or id_phone is invalid.", "code": "401"});
    }
  }
}
