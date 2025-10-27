class BadgeCounter {
  int _count = 0;

  /// Callback called whenever the count changes.
  Function(int)? onChanged;

  int get count => _count;

  void setCount(int value) {
    _count = value < 0 ? 0 : value;
    onChanged?.call(_count);
  }

  void increment() {
    _count++;
    onChanged?.call(_count);
  }

  void decrement() {
    if (_count > 0) _count--;
    onChanged?.call(_count);
  }

  void reset() {
    _count = 0;
    onChanged?.call(_count);
  }
}
