import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jose/jose.dart';
import 'package:pocket_hangar/app/config.dart';
import 'package:pocket_hangar/core/auth/jwt_verifier.dart';
import 'package:pocket_hangar/core/log.dart';

/// Public part of a generated key, as a JWKS would publish it.
Map<String, dynamic> publicJwk(JsonWebKey key, String kid) {
  final json = Map<String, dynamic>.of(key.toJson());
  for (final private in const ['d', 'p', 'q', 'dp', 'dq', 'qi']) {
    json.remove(private);
  }
  return json..['kid'] = kid;
}

String sign(Map<String, dynamic> claims, JsonWebKey key, String alg, String kid) {
  final builder = JsonWebSignatureBuilder()
    ..jsonContent = claims
    ..addRecipient(JsonWebKey.fromJson({...key.toJson(), 'kid': kid}), algorithm: alg);
  return builder.build().toCompactSerialization();
}

void main() {
  final now = DateTime.utc(2026, 11, 6, 12);
  const clientId = 'abc123';
  final rsa = JsonWebKey.generate('RS256');
  final ec = JsonWebKey.generate('ES256');
  final other = JsonWebKey.generate('RS256');

  Map<String, dynamic> claims({Object? iss = 'https://login.eveonline.com', Object? aud, int? exp, Object? sub}) => {
        'iss': iss,
        'aud': aud ?? [clientId, 'EVE Online'],
        'exp': exp ?? now.add(const Duration(minutes: 20)).millisecondsSinceEpoch ~/ 1000,
        'sub': sub ?? 'CHARACTER:EVE:2112625428',
        'name': 'Test Pilot',
        'scp': ['esi-skills.read_skills.v1', 'esi-skills.read_skillqueue.v1'],
        'owner': 'hash=',
      };

  late int loads;
  EveJwtVerifier verifier(List<Map<String, dynamic>> Function() keys) {
    loads = 0;
    return EveJwtVerifier(
      clientId: clientId,
      clock: () => now,
      loadJwks: () async {
        loads++;
        return {'keys': keys()};
      },
    );
  }

  test('RS256 and ES256 tokens from the published keys are accepted', () async {
    final v = verifier(() => [publicJwk(rsa, 'JWT-Signature-Key'), publicJwk(ec, 'ec-key')]);
    final a = await v.verify(sign(claims(), rsa, 'RS256', 'JWT-Signature-Key'));
    expect(a.characterId, 2112625428);
    expect(a.name, 'Test Pilot');
    expect(a.scopes, contains('esi-skills.read_skillqueue.v1'));
    final b = await v.verify(sign(claims(), ec, 'ES256', 'ec-key'));
    expect(b.characterId, 2112625428);
  });

  test('a token signed by an unknown key is rejected after reloading the key set once', () async {
    final v = verifier(() => [publicJwk(rsa, 'JWT-Signature-Key')]);
    await expectLater(v.verify(sign(claims(), other, 'RS256', 'JWT-Signature-Key')), throwsA(isA<JwtValidationException>()));
    expect(loads, 2);
  });

  test('a rotated key is picked up by the reload', () async {
    var rotated = false;
    final v = verifier(() => [publicJwk(rotated ? other : rsa, 'k')]);
    await v.verify(sign(claims(), rsa, 'RS256', 'k'));
    rotated = true;
    final c = await v.verify(sign(claims(), other, 'RS256', 'k'));
    expect(c.characterId, 2112625428);
  });

  group('claims', () {
    final v = EveJwtVerifier(clientId: clientId, clock: () => now, loadJwks: () async => {'keys': <Object>[]});

    test('all three issuer spellings are accepted', () {
      for (final iss in ['login.eveonline.com', 'https://login.eveonline.com', 'https://login.eveonline.com/']) {
        expect(v.checkClaims(claims(iss: iss)).characterId, 2112625428);
      }
    });

    test('rejects a wrong issuer, audience, subject or an expired token', () {
      Matcher fails(String reason) =>
          throwsA(isA<JwtValidationException>().having((e) => e.reason, 'reason', contains(reason)));
      expect(() => v.checkClaims(claims(iss: 'https://evil.example')), fails('issuer'));
      expect(() => v.checkClaims(claims(aud: [clientId])), fails('audience'));
      expect(() => v.checkClaims(claims(aud: ['someone-else', 'EVE Online'])), fails('audience'));
      expect(() => v.checkClaims(claims(sub: 'CORPORATION:EVE:1')), fails('subject'));
      final past = now.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000;
      expect(() => v.checkClaims(claims(exp: past)), fails('expired'));
    });
  });

  group('log redaction', () {
    test('bearer tokens, JWTs and token fields never reach a log line', () {
      const jwt = 'eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJDSEFSQUNURVI6RVZFOjEifQ.c2lnbmF0dXJl';
      final line = redact(
        'Authorization: Bearer $jwt refresh_token=abcDEF123 {"access_token": "xyz", "code_verifier":"v"} code=42',
      );
      expect(line, isNot(contains('abcDEF123')));
      expect(line, isNot(contains('xyz')));
      expect(line, isNot(contains('eyJ')));
      expect(line, isNot(contains('"v"')));
      expect(line, isNot(contains('code=42')));
      expect(line, contains('refresh_token=<redacted>'));
    });

    test('ordinary text is unchanged', () {
      expect(redact('ESI GET /markets/10000002/orders 200'), 'ESI GET /markets/10000002/orders 200');
    });
  });

  group('callback', () {
    test('the scheme passes the developer portal rule and is the same on Android and iOS', () {
      // developers.eveonline.com accepts custom schemes that start with "eveauth", continue with
      // lower-case letters, digits, "+", "." or "-", and end with a letter or digit.
      expect(AppConfig.ssoRedirectScheme, matches(RegExp(r'^eveauth([a-z0-9+.-]*[a-z0-9])?$')));
      expect(AppConfig.ssoRedirectUrl, startsWith('${AppConfig.ssoRedirectScheme}://'));

      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('"appAuthRedirectScheme" to "${AppConfig.ssoRedirectScheme}"'));

      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      final schemes = RegExp(r'<key>CFBundleURLSchemes</key>\s*<array>(.*?)</array>', dotAll: true)
          .firstMatch(plist)!
          .group(1)!;
      expect(
        [for (final m in RegExp(r'<string>([^<]*)</string>').allMatches(schemes)) m.group(1)],
        [AppConfig.ssoRedirectScheme],
      );
    });
  });
}
