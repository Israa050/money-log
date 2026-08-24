import 'package:flutter_test/flutter_test.dart';
import 'package:stockflow/features/transactions/presentation/format.dart';

void main() {
  group('formatAmountMinor', () {
    test('whole dollar amount', () {
      expect(formatAmountMinor(500), r'$5.00');
    });

    test('amount with cents', () {
      expect(formatAmountMinor(1234), r'$12.34');
    });

    test('single-digit cents are zero-padded', () {
      expect(formatAmountMinor(105), r'$1.05');
    });

    test('zero', () {
      expect(formatAmountMinor(0), r'$0.00');
    });

    test('negative amount keeps the sign in front of the dollar sign', () {
      expect(formatAmountMinor(-1234), r'-$12.34');
    });
  });

  group('parseAmountToMinor', () {
    test('whole number -> minor units', () {
      expect(parseAmountToMinor('5'), 500);
    });

    test('two decimal places -> exact minor units', () {
      expect(parseAmountToMinor('12.34'), 1234);
    });

    test('one decimal place -> exact minor units', () {
      expect(parseAmountToMinor('3.5'), 350);
    });

    test('rounds three-plus decimal places to the nearest cent', () {
      expect(parseAmountToMinor('19.999'), 2000);
      expect(parseAmountToMinor('0.001'), 0);
      expect(parseAmountToMinor('0.005'), 1);
    });

    test('leading/trailing whitespace is trimmed', () {
      expect(parseAmountToMinor('  7.5  '), 750);
    });

    test('zero is not a valid amount', () {
      expect(parseAmountToMinor('0'), null);
    });

    test('negative amounts are rejected', () {
      expect(parseAmountToMinor('-5'), null);
    });

    test('empty string is rejected', () {
      expect(parseAmountToMinor(''), null);
    });

    test('non-numeric text is rejected', () {
      expect(parseAmountToMinor('abc'), null);
    });

    test('NaN and infinity are rejected', () {
      expect(parseAmountToMinor('NaN'), null);
      expect(parseAmountToMinor('Infinity'), null);
    });

    test('round-trips back through formatAmountMinor for typical values', () {
      for (final input in ['0.01', '1.00', '19.99', '1234.56']) {
        final minor = parseAmountToMinor(input);
        expect(minor, isNotNull);
        expect(formatAmountMinor(minor!), '\$$input');
      }
    });
  });
}
