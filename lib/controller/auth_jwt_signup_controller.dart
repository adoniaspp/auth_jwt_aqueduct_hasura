import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:corsac_jwt/corsac_jwt.dart';
import 'package:http/http.dart' as http;
import '../auth_jwt_project.dart';

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
        body: bodyHasura);

    final bodyResponse = json.decode(response.body);
    final id = bodyResponse["data"]["insert_user_teste_one"]["id"];

    //Gera o token jwt
    final builder = JWTBuilder();
    builder
      ..subject = id.toString()
      ..expiresAt = DateTime.now().add(const Duration(days: 1))
      ..setClaim('https://hasura.io/jwt/claims', {
        "x-hasura-allowed-roles": ["user"],
        "x-hasura-user-id": id.toString(),
        "x-hasura-default-role": "user",
        "x-hasura-role": "user"
      })
      ..getToken(); // returns token without signature

    final signer = JWTHmacSha256Signer(
        'OANglItXIxleeSN_EyBnGmry-8Dmv04FMD6TC_Q9bRVn1RqI82BPaS3xPy4VGKiXBKVKhnXmF6aDyqHwlXIuuA');
    final signedToken = builder.getSignedToken(signer);
    print(signedToken); // prints encoded JWT

    //Retorna o token
    return Response.ok(bodyResponse["data"]["insert_user_teste_one"]);
  }
}
