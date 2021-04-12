import 'dart:convert';

import 'package:functions_framework/functions_framework.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

@CloudFunction()
Future<Response> function(Request request) async {
  final router = Router();

  router.get('/', (Request request) {
    return Response.ok(
      jsonEncode(
        {'hello': 'world'},
      ),
    );
  });

  router.post(
    '/jwt',
    (Request request) async {
      try {
        final data = jsonDecode(await request.readAsString());
        final email = data['email'];

        final jwt = JWT({'user_email': email, 'app': 'test'},
            issuer: 'vinicius-amelio');

        final token = jwt.sign(
          SecretKey('Otorrinolaringologista'),
          expiresIn: Duration(seconds: 30),
        );

        return Response.ok(
          jsonEncode(
            {'token': token},
          ),
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode(
            {'error': e},
          ),
        );
      }
    },
  );

  router.get('/jwt/validate', (Request request) {
    final token = request.headers['Authorization'];
    if (token == null) {
      return Response.internalServerError(
        body: jsonEncode(
          {'error': 'Token não encontrado no header "Authorization" '},
        ),
      );
    }
    try {
      final jwt = JWT.verify(
        token,
        SecretKey('Otorrinolaringologista'),
      );

      return Response.ok(
        jsonEncode(
          {'valid': true},
        ),
      );
    } on JWTExpiredError catch (_) {
      return Response.forbidden(
        jsonEncode({'valid': false, 'error': 'Token expirado'}),
      );
    } on JWTError catch (ex) {
      return Response.internalServerError(
        body: jsonEncode({'error': ex.message}),
      );
    }
  });
  return router(request);
}
