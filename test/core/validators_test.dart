import 'package:flutter_test/flutter_test.dart';
import 'package:imuka/core/utils/validators.dart';

void main() {
  group('Validators.phone', () {
    test('accepts MTN and Airtel numbers with or without spaces', () {
      expect(Validators.phone('788 123 456'), isNull);
      expect(Validators.phone('733123456'), isNull);
    });

    test('rejects empty, short and non-Rwandan numbers', () {
      expect(Validators.phone(''), contains('enter your phone'));
      expect(Validators.phone('78812'), contains('9 digits'));
      expect(Validators.phone('612345678'), contains('MTN or Airtel'));
    });
  });

  group('Validators.email', () {
    test('accepts normal addresses', () {
      expect(Validators.email('aline@imuka.rw'), isNull);
      expect(Validators.email(' a.b+move@alustudent.com '), isNull);
    });

    test('rejects empty and malformed addresses', () {
      expect(Validators.email(''), contains('enter your email'));
      expect(Validators.email('aline@'), contains('doesn\'t look right'));
      expect(
        Validators.email('aline.imuka.rw'),
        contains('doesn\'t look right'),
      );
    });
  });

  group('Validators.password', () {
    test('requires 8+ characters with letters and numbers', () {
      expect(Validators.password('kigali2026'), isNull);
      expect(Validators.password(''), contains('create a password'));
      expect(Validators.password('short1'), contains('8 characters'));
      expect(Validators.password('onlyletters'), contains('letters'));
      expect(Validators.password('12345678'), contains('letters'));
    });
  });

  group('Validators.fullName', () {
    test('needs a first and last name in letters', () {
      expect(Validators.fullName('Aline Uwase'), isNull);
      expect(Validators.fullName('Aline'), contains('last name'));
      expect(Validators.fullName('R2 D2'), contains('letters'));
      expect(Validators.fullName('  '), contains('full name'));
    });
  });
}
