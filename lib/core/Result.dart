class Result<T, E> {
  final String msg;
  final T? value;
  final E? error;

  Result.ok(this.value, [this.msg = "ok"]) : error = null;

  Result.err([this.error, this.msg = "err"]) : value = null;

  /// 只有错误消息，而不关心具体错误类型
  Result.eMsg([this.msg = "err"]) : error = null, value = null;

  bool get isOk => msg == 'ok';
  bool get isErr => msg == 'err';

  T unwrap() {
    if (isOk) return value as T;
    throw Exception('Attempted to unwrap an Err value');
  }

  T unwrapOr(T defaultValue) => isOk ? value as T : defaultValue;

  E unwrapErr() {
    if (isErr) return error as E;
    throw Exception('Attempted to unwrapErr an Ok value');
  }

  Result<U, E> map<U>(U Function(T) fn) {
    if (isOk) {
      return Result.ok(fn(value as T));
    } else {
      return Result.err(error as E, msg);
    }
  }

  Result<T, F> mapErr<F>(F Function(E) fn) {
    if (isErr) {
      return Result.err(fn(error as E), msg);
    } else {
      return Result.ok(value as T, msg);
    }
  }

  /// 类似模式匹配，但返回void，更适合做副作用操作
  void when({
    required void Function(T value) ok,
    required void Function(E? error, String msg) err,
  }) {
    if (isOk) {
      // 如果是ok分支，value不为null
      ok(value as T);
    } else {
      // 如果是err分支，可能是 err(...) 或 eMsg(...)
      // 有的情况下 error 为 null（eMsg 情况）
      err(error, msg);
    }
  }

  /// 类似 match，但将 T 映射为 U 并返回
  U match<U>(U Function(T) ok, U Function(E) err) {
    return isOk ? ok(value as T) : err(error as E);
  }

  @override
  String toString() {
    if (isOk) {
      return 'Result.ok(value: $value, msg: "$msg")';
    } else if (isErr) {
      return 'Result.err(error: $error, msg: "$msg")';
    }
    return 'Result(msg: "$msg")';
  }
}
