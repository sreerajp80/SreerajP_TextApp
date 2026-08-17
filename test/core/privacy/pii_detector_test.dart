import 'package:flutter_test/flutter_test.dart';
import 'package:sreerajp_textapp/core/privacy/pii_detector.dart';
import 'package:sreerajp_textapp/core/privacy/pii_type.dart';

void main() {
  const detector = PiiDetector();

  group('PiiDetector - Emails', () {
    test('detects single and multiple email addresses', () {
      const text =
          'Contact alice@example.com or bob.smith+dev@company.co.uk for support.';
      final result = detector.scan(text);

      expect(result.totalCount, 2);
      expect(result.matches[0].type, PiiType.email);
      expect(result.matches[0].rawValue, 'alice@example.com');
      expect(result.matches[0].line, 1);
      expect(result.matches[1].type, PiiType.email);
      expect(result.matches[1].rawValue, 'bob.smith+dev@company.co.uk');
    });
  });

  group('PiiDetector - Phone Numbers', () {
    test('detects international and formatted phone numbers', () {
      const text = 'Call +1-555-0199 or (555) 234-5678 or +91 98765 43210.';
      final result = detector.scan(text);

      expect(result.totalCount, greaterThanOrEqualTo(2));
      final phones = result.matches
          .where((m) => m.type == PiiType.phone)
          .toList();
      expect(phones.isNotEmpty, true);
    });

    test('ignores short regular numbers', () {
      const text = 'Quantity is 42, total items: 12345, year is 2026.';
      final result = detector.scan(text);

      final phones = result.matches
          .where((m) => m.type == PiiType.phone)
          .toList();
      expect(phones.isEmpty, true);
    });
  });

  group('PiiDetector - Credit Cards with Luhn Checksum', () {
    test('detects valid credit card numbers with Luhn check', () {
      // Valid Luhn test card numbers
      const text = 'Pay with Visa: 4532-0150-1234-5674 or 4916-0150-0000-0003.';
      final result = detector.scan(text);

      final cards = result.matches
          .where((m) => m.type == PiiType.creditCard)
          .toList();
      expect(cards.isNotEmpty, true);
      expect(cards.first.type, PiiType.creditCard);
    });

    test('ignores invalid credit card numbers failing Luhn check', () {
      const text = 'Serial number is 4532-0150-1234-5679 (fails luhn).';
      final result = detector.scan(text);

      final cards = result.matches
          .where((m) => m.type == PiiType.creditCard)
          .toList();
      expect(cards.isEmpty, true);
    });
  });

  group('PiiDetector - IP Addresses', () {
    test('detects valid IPv4 addresses', () {
      const text = 'Server listening at 192.168.1.1 and 10.0.0.254.';
      final result = detector.scan(text);

      final ips = result.matches
          .where((m) => m.type == PiiType.ipAddress)
          .toList();
      expect(ips.length, 2);
      expect(ips[0].rawValue, '192.168.1.1');
      expect(ips[1].rawValue, '10.0.0.254');
    });

    test('rejects invalid IPv4 octets', () {
      const text = 'Invalid: 999.888.777.666 and 300.1.2.3.';
      final result = detector.scan(text);

      final ips = result.matches
          .where((m) => m.type == PiiType.ipAddress)
          .toList();
      expect(ips.isEmpty, true);
    });

    test('detects IPv6 addresses', () {
      const text = 'Host: 2001:0db8:85a3:0000:0000:8a2e:0370:7334';
      final result = detector.scan(text);

      final ips = result.matches
          .where((m) => m.type == PiiType.ipAddress)
          .toList();
      expect(ips.length, 1);
    });
  });

  group('PiiDetector - JWT & AWS & Private Keys', () {
    test('detects JWT tokens', () {
      const text =
          'Auth: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozG4m1e_pQ2m1e_pQ2m1e_pQ2m1e_pQ';
      final result = detector.scan(text);

      final jwts = result.matches
          .where((m) => m.type == PiiType.jwtToken)
          .toList();
      expect(jwts.length, 1);
    });

    test('detects AWS Access Keys', () {
      const text = 'export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE';
      final result = detector.scan(text);

      final aws = result.matches
          .where((m) => m.type == PiiType.awsKey)
          .toList();
      expect(aws.length, 1);
      expect(aws[0].rawValue, 'AKIAIOSFODNN7EXAMPLE');
    });

    test('detects multi-line RSA Private Keys', () {
      const text = '''
Config header
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA0Y1+example+key+material+data+here
more+key+lines+here
-----END RSA PRIVATE KEY-----
Footer text
''';
      final result = detector.scan(text);

      final keys = result.matches
          .where((m) => m.type == PiiType.privateKey)
          .toList();
      expect(keys.length, 1);
      expect(keys[0].line, 2);
    });
  });

  group('PiiDetector - API Secrets & Known Tokens', () {
    test('detects GitHub and Stripe tokens', () {
      const text = '''
github_token = ghp_1234567890abcdefghijklmnopqrstuvwxyz12
stripe_key = sk_test_1234567890abcdefghijklmnopqr
''';
      final result = detector.scan(text);

      final secrets = result.matches
          .where((m) => m.type == PiiType.apiKeySecret)
          .toList();
      expect(secrets.length, greaterThanOrEqualTo(2));
    });
  });

  group('PiiDetector - Empty & Clean Text', () {
    test('returns empty scan result for clean text', () {
      const text =
          'Hello world! This is a simple document without any secrets or sensitive data.';
      final result = detector.scan(text);

      expect(result.isEmpty, true);
      expect(result.totalCount, 0);
      expect(result.countsByType.isEmpty, true);
    });

    test('returns empty scan result for empty string', () {
      final result = detector.scan('');
      expect(result.isEmpty, true);
    });
  });
}
