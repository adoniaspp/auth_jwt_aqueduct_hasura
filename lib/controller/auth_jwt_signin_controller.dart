import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cryptography/cryptography.dart';
import '../auth_jwt_project.dart';

class AuthJwtSigninController extends ResourceController {
  AuthJwtSigninController(this.context);

  final ManagedContext context;

  @Operation.post()
  Future<Response> sigin() async {
    //Obtem os dados do body
    final bodyMap = request.body.as();
    final user = bodyMap["input"]["user"].toString();
    final passwordUser = bodyMap["input"]["senha"].toString();

    //Obtem o usuário para recuperar a senha do banco via graphql
    const hasuraOperation = '''
        query MyQuery(\$user: String!) {
          user(where: {user: {_eq: \$user}}) {
            id
            password
            salt
          }
        }       
        ''';
    final variables = {"user": user};
    final bodyHasura =
        json.encode({"query": hasuraOperation, "variables": variables});
    final response = await http.post("http://172.17.0.3:8080/v1/graphql",
        headers: {
          "content-type": "application/json",
          "x-hasura-admin-secret": "aliceadmin"
        },
        body: bodyHasura);

    final bodyResponse = json.decode(response.body);
    final passwordBD = bodyResponse["data"]["user"]["id"];
    final salt = bodyResponse["data"]["user"]["salt"].toString();

    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac(sha256),
      iterations: 100000,
      bits: 128,
    );

    final hashPassword =
        await pbkdf2.deriveBits(utf8.encode(passwordUser), nonce: Nonce(_convertSaltToListInt(salt)));

    //Decodifica a senha do banco

    //Compara com a senha fornecida pelo usuário

    //Gera o token jwt

    //Retorna o token

    //print(bodyMap);
  }

  List<int> _convertSaltToListInt(String argSalt) {
    String saltClean = argSalt.substring(1, argSalt.length - 2);
    List<String> saltList = saltClean.split(",");
    List<int> saltInt = [];
    saltList.forEach((value) {
      saltInt.add(int.parse(value));
    });
    return saltInt;
  }
}
