import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:corsac_jwt/corsac_jwt.dart';
import 'package:http/http.dart' as http;
import '../auth_jwt_project.dart';


class AuthJwtSignupController extends ResourceController {
  AuthJwtSignupController(this.context, this.configuration);

  final ManagedContext context;
  final AuthConfiguration configuration;

  @Operation.post()
  Future<Response> signup() async {
    
    //Obtem os dados do body
    final bodyMap = request.body.as();
    final password = bodyMap["input"]["password"].toString();
    final user = bodyMap["input"]["user"].toString();
    final idPhone = bodyMap["input"]["id_phone"].toString();

    //Criptografa a senha
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac(sha256),
      iterations: 100000,
      bits: 128,
    );
    final salt = Nonce.randomBytes(32);
    final hashPassword =
        await pbkdf2.deriveBits(utf8.encode(password), nonce: salt);

    //Gera o refresh_token
    final Random _random = Random.secure();
    final values = List<int>.generate(32, (i) => _random.nextInt(256));
    final refreshToken = await blake2s.hash(
      values,
    );

    //Gera o body do Hasura Graphql
    const hasuraOperation = '''
        mutation MyMutation(\$id_phone: String!, \$password: String!, \$user: String!, \$salt: String!, \$refresh_token: String!, \$creation_date: timestamptz!) {
          insert_user_one(object: {user: \$user, password: \$password, id_phone: \$id_phone, refresh_token: \$refresh_token, salt: \$salt, creation_date: \$creation_date}) {
            id
          }
        }       
        ''';
    final variables = {"user": user, "password": hashPassword.toString(), "id_phone": idPhone, "salt": salt.bytes.toString(), "creation_date": DateTime.now().toString(), "refresh_token": refreshToken.bytes.toString()};
    final bodyHasura =
        json.encode({"query": hasuraOperation, "variables": variables});

    //Enviar requisição para engine do hasura
    final response = await http.post(configuration.hasuraUrl,
        headers: {
          "content-type": "application/json",
          "x-hasura-admin-secret": configuration.hasuraAdminSecret
        },
        body: bodyHasura);

    final bodyResponse = json.decode(response.body);
    final id = bodyResponse["data"]["insert_user_one"]["id"];

    //Gera o token jwt
    final builder = JWTBuilder();
    builder
      //..subject = id.toString()
      ..expiresAt = DateTime.now().add(const Duration(days: 1))
      ..setClaim('https://hasura.io/jwt/claims', {
        "x-hasura-allowed-roles": ["user"],
        "x-hasura-user-id": id.toString(),
        "x-hasura-default-role": "user",
        "x-hasura-role": "user"
      })
      ..getToken(); // returns token without signature

    final signer = JWTHmacSha256Signer(
        configuration.jwtSecret);
    final signedToken = builder.getSignedToken(signer);
    
    //Retorna o token
    return Response.created("",body: {
        "id": id.toString(),
        "token": signedToken.toString(),
        "refreshtoken": refreshToken.bytes.toString()
      });
  }
}
