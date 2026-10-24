import 'dart:async';

/// A value plus a stream that replays the latest value to each new listener.
class Live<T> {
  Live(this._value);

  T _value;
  final _changes = StreamController<T>.broadcast();

  T get value => _value;

  set value(T next) {
    _value = next;
    if (!_changes.isClosed) _changes.add(next);
  }

  Stream<T> get stream async* {
    yield _value;
    yield* _changes.stream;
  }

  Future<void> close() => _changes.close();
}
