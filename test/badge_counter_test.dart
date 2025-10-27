import 'package:flutter_test/flutter_test.dart';
import 'package:wizi_learn/core/services/badge_counter.dart';

void main() {
  group('BadgeCounter', () {
    test('initially zero', () {
      final b = BadgeCounter();
      expect(b.count, 0);
    });

    test('increment increments and notifies', () {
      final b = BadgeCounter();
      int? observed;
      b.onChanged = (c) => observed = c;
      b.increment();
      expect(b.count, 1);
      expect(observed, 1);
    });

    test('decrement does not go below zero', () {
      final b = BadgeCounter();
      b.decrement();
      expect(b.count, 0);
      b.setCount(2);
      b.decrement();
      expect(b.count, 1);
    });

    test('reset sets to zero and notifies', () {
      final b = BadgeCounter();
      int? observed;
      b.onChanged = (c) => observed = c;
      b.setCount(3);
      b.reset();
      expect(b.count, 0);
      expect(observed, 0);
    });
  });
}
