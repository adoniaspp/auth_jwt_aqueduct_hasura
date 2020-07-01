import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:jose/jose.dart';
import 'package:http/http.dart' as http;
import 'auth_jwt_project.dart';

class AuthJwtSignupController extends ResourceController {
  AuthJwtSignupController(this.context);

  final ManagedContext context;

  @Operation.post()
  Future<Response> signup() async {
    //Obtem os dados do body
    final bodyMap = request.body.as();
    final password = bodyMap["input"]["senha"].toString();

    //Criptografa a senha
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac(sha256),
      iterations: 100000,
      bits: 128,
    );
    final nonce = Nonce.randomBytes(32);
    final hashPassword =
        await pbkdf2.deriveBits(utf8.encode(password), nonce: nonce);
    print(hashPassword);
    //Gera o body do Hasura Graphql
    const hasuraOperation =
        '''mutation MyMutation(\$senha: String!, \$usuario: String!) 
            {insert_user_teste_one(object: {senha: \$senha, usuario: \$usuario}) 
            {id}
        }''';
    final variables = {
      "usuario": bodyMap["input"]["usuario"].toString(),
      "senha": hashPassword.toString()
    };
    final bodyHasura =
        json.encode({"query": hasuraOperation, "variables": variables});

    //Enviar requisição para engine do hasura
    final response = await http.post("http://172.17.0.3:8080/v1/graphql",
        headers: {
          "content-type": "application/json",
          "x-hasura-admin-secret": "aliceadmin"
        },
        body: bodyHasura
        );
    final bodyResponse = json.decode(response.body);
    print(bodyResponse);
    final id = bodyResponse["data"]["insert_user_teste_one"]["id"];
    //Gera o token jwt
    var claims = new JsonWebTokenClaims.fromJson({
      "sub": id,
      "exp": new Duration(hours: 4).inSeconds,
      "https://hasura.io/jwt/claims": {
          "x-hasura-allowed-roles": ["user"],
          "x-hasura-user-id": '' + id.toString(),
          "x-hasura-default-role": "user",
          "x-hasura-role": "user"
        },
    });
    var builder = new JsonWebSignatureBuilder();
    builder.jsonContent = claims.toJson();
    builder.addRecipient(
      new JsonWebKey.fromJson({
        "kty": "oct",
        "k":
            "AyM1SysPpbyDfgZld3umj1qzKObwVMkoqQ-EstJQLr_T-1qS0gZH75aKtMN3Yj0iPS4hcgUuTwjAzZr1Z9CAow"
      }),
      algorithm: "HS256");
    var jws = builder.build();
    print("jwt compact serialization: ${jws.toCompactSerialization()}");
    //Retorna o token

    //print(bodyMap);

    return Response.ok(bodyResponse["data"]["insert_user_teste_one"]);
  }
}
