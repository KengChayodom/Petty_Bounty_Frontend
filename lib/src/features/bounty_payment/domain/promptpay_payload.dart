/// Builds the text a PromptPay QR code carries (Feature #6, the bounty payment card).
///
/// The format is the Thai QR Payment standard, an EMVCo merchant-presented
/// payload. Every field is written as `tag + two-digit length + value`, and the
/// last field (tag 63) is a CRC16-CCITT checksum over everything before it,
/// including its own `6304` header. No bank API is involved: the owner's banking
/// app reads the code, shows the payee's account name, and makes the transfer.
/// This app never learns whether the transfer happened.
///
/// Only a Thai mobile number is accepted as the PromptPay identifier. A national
/// ID number is personal data that anyone scanning the code could read.
class PromptPayPayload {
  PromptPayPayload._();

  /// The PromptPay application identifier (merchant account information, tag 29).
  static const String _aid = 'A000000677010111';

  /// A Thai mobile number: ten digits starting 06, 08 or 09.
  static final RegExp mobilePattern = RegExp(r'^0[689]\d{8}$');

  /// Returns true when [number] is a Thai mobile number once spaces and dashes
  /// are removed.
  static bool isValidMobile(String number) =>
      mobilePattern.hasMatch(_digits(number));

  /// The payload for a transfer of [amount] baht to the PromptPay [mobile].
  ///
  /// A positive [amount] produces a dynamic code (point of initiation `12`)
  /// with the amount fixed inside it, so the payer cannot change it. A null
  /// [amount] produces a static code (`11`) that leaves the amount to the
  /// payer.
  ///
  /// Throws [ArgumentError] when [mobile] is not a Thai mobile number, or when
  /// [amount] is zero or negative.
  static String build(String mobile, {double? amount}) {
    final digits = _digits(mobile);
    if (!mobilePattern.hasMatch(digits)) {
      throw ArgumentError.value(mobile, 'mobile', 'not a Thai mobile number');
    }
    if (amount != null && amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'must be greater than zero');
    }

    // 0812345678 -> 0066812345678: the leading 0 becomes the 66 country code,
    // left-padded with zeros to the 13 characters the standard expects.
    final proxy = '66${digits.substring(1)}'.padLeft(13, '0');

    final body = StringBuffer()
      ..write(_field('00', '01'))
      ..write(_field('01', amount == null ? '11' : '12'))
      ..write(_field('29', _field('00', _aid) + _field('01', proxy)))
      ..write(_field('53', '764'))
      ..write(amount == null ? '' : _field('54', amount.toStringAsFixed(2)))
      ..write(_field('58', 'TH'))
      ..write('6304');
    final withoutCrc = body.toString();
    return withoutCrc + crc16(withoutCrc);
  }

  /// CRC-16/CCITT-FALSE (polynomial 0x1021, initial value 0xFFFF), as four
  /// upper-case hexadecimal digits.
  static String crc16(String data) {
    var crc = 0xFFFF;
    for (final byte in data.codeUnits) {
      crc ^= byte << 8;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1;
        crc &= 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  static String _field(String tag, String value) =>
      '$tag${value.length.toString().padLeft(2, '0')}$value';

  static String _digits(String s) => s.replaceAll(RegExp(r'[\s-]'), '');
}
