import 'dart:async';

Stream<List<T>> gopLuong<T>(List<Stream<T>> sources) {
  if (sources.isEmpty) return Stream.value(<T>[]);
  late StreamController<List<T>> output;
  final subscriptions = <StreamSubscription<T>>[];
  final values = List<T?>.filled(sources.length, null);
  final ready = List<bool>.filled(sources.length, false);
  var closed = false;
  var ended = 0;
  output = StreamController<List<T>>(
    onListen: () {
      for (var i = 0; i < sources.length; i++) {
        final index = i;
        subscriptions.add(
          sources[i].listen(
            (value) {
              if (closed) return;
              values[index] = value;
              ready[index] = true;
              if (ready.every((value) => value)) {
                output.add([for (final value in values) value as T]);
              }
            },
            onError: (Object error, StackTrace stack) {
              if (closed) return;
              ready[index] = false;
              output.addError(error, stack);
            },
            onDone: () {
              if (++ended == sources.length && !closed) output.close();
            },
          ),
        );
      }
    },
    onCancel: () async {
      closed = true;
      await Future.wait(subscriptions.map((sub) => sub.cancel()));
    },
  );
  return output.stream;
}

Stream<R> chuyenLuong<T, R>(Stream<T> source, Stream<R> Function(T) next) {
  late StreamController<R> output;
  StreamSubscription<T>? outer;
  StreamSubscription<R>? inner;
  var generation = 0;
  var closed = false, sourceDone = false, innerDone = true;
  void finish() {
    if (!closed && sourceDone && innerDone) output.close();
  }

  output = StreamController<R>(
    onListen: () {
      outer = source.listen(
        (value) async {
          final token = ++generation;
          innerDone = false;
          final previous = inner;
          inner = null;
          await previous?.cancel();
          if (closed || token != generation) return;
          try {
            inner = next(value).listen(
              (data) {
                if (!closed && token == generation) output.add(data);
              },
              onError: (Object error, StackTrace stack) {
                if (!closed && token == generation) {
                  output.addError(error, stack);
                }
              },
              onDone: () {
                if (token != generation) return;
                innerDone = true;
                finish();
              },
            );
          } catch (error, stack) {
            if (!closed && token == generation) {
              innerDone = true;
              output.addError(error, stack);
              finish();
            }
          }
        },
        onError: (Object error, StackTrace stack) {
          generation++;
          inner?.cancel();
          inner = null;
          innerDone = true;
          if (!closed) output.addError(error, stack);
        },
        onDone: () {
          sourceDone = true;
          finish();
        },
      );
    },
    onCancel: () async {
      closed = true;
      generation++;
      await outer?.cancel();
      await inner?.cancel();
    },
  );
  return output.stream;
}

class PhienTheoDoi {
  final _subscriptions = <String, StreamSubscription<dynamic>>{};
  final _tokens = <String, Object>{};
  bool _disposed = false;
  bool contains(String key) => _tokens.containsKey(key);

  void listen<T>(
    String key,
    Stream<T> stream,
    void Function(T) onData,
    void Function(Object) onError,
  ) {
    if (_disposed) return;
    cancel(key);
    final token = Object();
    _tokens[key] = token;
    _subscriptions[key] = stream.listen(
      (value) {
        if (!_disposed && _tokens[key] == token) onData(value);
      },
      onError: (Object error) {
        if (!_disposed && _tokens[key] == token) onError(error);
      },
    );
  }

  void cancel(String key) {
    _tokens.remove(key);
    _subscriptions.remove(key)?.cancel();
  }

  void dispose() {
    _disposed = true;
    _tokens.clear();
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
  }
}
