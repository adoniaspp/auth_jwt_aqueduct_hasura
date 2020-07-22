import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:cryptography/cryptography.dart';
import 'package:corsac_jwt/corsac_jwt.dart';
import '../auth_jwt_project.dart';

class AuthJwtSigninController extends ResourceController {
  AuthJwtSigninController(this.context, this.configuration);

  final ManagedContext context;
  final AuthConfiguration configuration;

  @Operation.post()
  Future<Response> sigin() async {
    //Obtem os dados do body
    final bodyMap = request.body.as();
    final user = bodyMap["input"]["user"].toString();
    final passwordUser = bodyMap["input"]["password"].toString();

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
    final responseQuery = await http.post(configuration.hasuraUrl,
        headers: {
          "content-type": "application/json",
          "x-hasura-admin-secret": configuration.hasuraAdminSecret
        },
        body: bodyHasura);

    final bodyResponseQuery = json.decode(responseQuery.body);
    
    if(bodyResponseQuery["data"]["user"].toString() != "[]")
    {
      final idUser = bodyResponseQuery["data"]["user"][0]["id"];
      final passwordBD = bodyResponseQuery["data"]["user"][0]["password"];
      final salt = bodyResponseQuery["data"]["user"][0]["salt"].toString();

    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac(sha256),
      iterations: 100000,
      bits: 128,
    );

    final hashPassword = await pbkdf2.deriveBits(utf8.encode(passwordUser),
        nonce: Nonce(_convertSaltToListInt(salt)));

    if (passwordBD.toString() == hashPassword.toString()) {  
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

      //Gera o refresh_token
      final Random _random = Random.secure();
      final values = List<int>.generate(32, (i) => _random.nextInt(256));
      final refreshToken = await blake2s.hash(
        values,
      );
      //update do refresh token
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

      //final bodyResponseUpdate = json.decode(responseUpdate.body);

      return Response.ok(
      {
        "id": idUser.toString(),
        "token": signedToken.toString(),
        "refreshtoken": refreshToken.bytes.toString()
      }
    );
    } else {
      return Response.unauthorized(body: {
        "message": "password is invalid.",
        "code": "401"
      });
    }
    }else{
      return Response.unauthorized(body: {
        "message": "username is invalid.",
        "code": "401"
      });
    }
  }

  List<int> _convertSaltToListInt(String argSalt) {
    String saltClean = argSalt.substring(1, argSalt.length - 1);
    List<String> saltList = saltClean.split(",");
    List<int> saltInt = [];
    saltList.forEach((value) {
      saltInt.add(int.parse(value));
    });
    return saltInt;
  }
}
