import 'harness/app.dart';

Future main() async {
  final harness = Harness()..install();

  test("POST /auth/signup returns 200 {'key': 'signup'}", () async {
    expectResponse(await harness.agent.post("/auth/signup",body: {
      "user": "adoniaspp",
      "password": "latpar69"
    }), 200);
  });
}
