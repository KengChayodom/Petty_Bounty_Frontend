// Unit tests for PromptPayPayload (pure functions — no widget tree).
//
// Feature #6 has no UTC numbers yet. They are issued in the Phase 6 test plan,
// and these cases will be filed under the method that the Phase 5 Method
// Specification gives PromptPayPayload.build.

import 'package:flutter_test/flutter_test.dart';
import 'package:petty_bounty/src/features/bounty_payment/domain/promptpay_payload.dart';

/// Splits a payload into its top-level `tag -> value` fields.
Map<String, String> _fields(String payload) {
  final out = <String, String>{};
  var i = 0;
  while (i < payload.length) {
    final tag = payload.substring(i, i + 2);
    final len = int.parse(payload.substring(i + 2, i + 4));
    out[tag] = payload.substring(i + 4, i + 4 + len);
    i += 4 + len;
  }
  return out;
}

void main() {
  group('PromptPayPayload.crc16', () {
    test('matches the CRC-16/CCITT-FALSE check value for "123456789"', () {
      expect(PromptPayPayload.crc16('123456789'), '29B1');
    });
    test('returns the initial value for empty input', () {
      expect(PromptPayPayload.crc16(''), 'FFFF');
    });
  });

  group('PromptPayPayload.isValidMobile', () {
    test('accepts 06, 08 and 09 numbers, ignoring spaces and dashes', () {
      expect(PromptPayPayload.isValidMobile('0812345678'), isTrue);
      expect(PromptPayPayload.isValidMobile('061-234-5678'), isTrue);
      expect(PromptPayPayload.isValidMobile('09 1234 5678'), isTrue);
    });
    test('refuses landlines, wrong lengths and national ID numbers', () {
      expect(PromptPayPayload.isValidMobile('021234567'), isFalse);
      expect(PromptPayPayload.isValidMobile('081234567'), isFalse);
      expect(PromptPayPayload.isValidMobile('08123456789'), isFalse);
      expect(PromptPayPayload.isValidMobile('1234567890123'), isFalse);
    });
  });

  group('PromptPayPayload.build', () {
    test('a fixed amount gives a dynamic code with the amount inside', () {
      final f = _fields(PromptPayPayload.build('0812345678', amount: 2000));
      expect(f['00'], '01');
      expect(f['01'], '12');
      expect(f['29'], '0016A000000677010111' '01130066812345678');
      expect(f['53'], '764');
      expect(f['54'], '2000.00');
      expect(f['58'], 'TH');
    });

    test('no amount gives a static code with no amount field', () {
      final f = _fields(PromptPayPayload.build('0812345678'));
      expect(f['01'], '11');
      expect(f.containsKey('54'), isFalse);
    });

    test('the checksum covers everything before it, its own header included', () {
      final p = PromptPayPayload.build('0912345678', amount: 29);
      final body = p.substring(0, p.length - 4);
      expect(body.endsWith('6304'), isTrue);
      expect(p.substring(p.length - 4), PromptPayPayload.crc16(body));
    });

    test('formats the number without spaces or dashes', () {
      expect(PromptPayPayload.build('081-234-5678', amount: 49),
          PromptPayPayload.build('0812345678', amount: 49));
    });

    test('keeps two decimals for fractional amounts', () {
      final f = _fields(PromptPayPayload.build('0812345678', amount: 1.5));
      expect(f['54'], '1.50');
    });

    test('refuses a number that is not a Thai mobile number', () {
      expect(() => PromptPayPayload.build('021234567', amount: 10),
          throwsArgumentError);
    });

    test('refuses a zero or negative amount', () {
      expect(() => PromptPayPayload.build('0812345678', amount: 0),
          throwsArgumentError);
      expect(() => PromptPayPayload.build('0812345678', amount: -5),
          throwsArgumentError);
    });
  });
}
