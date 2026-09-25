/// Typed Result wrapper for API and Repository operations.
sealed class ApiResult<T> {
  const ApiResult();

  bool get isSuccess => this is ApiSuccess<T>;
  bool get isFailure => this is ApiFailure<T>;

  T? get dataOrNull => this is ApiSuccess<T> ? (this as ApiSuccess<T>).data : null;
  String? get errorOrNull => this is ApiFailure<T> ? (this as ApiFailure<T>).message : null;

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, int? statusCode) failure,
  }) {
    if (this is ApiSuccess<T>) {
      return success((this as ApiSuccess<T>).data);
    } else {
      final f = this as ApiFailure<T>;
      return failure(f.message, f.statusCode);
    }
  }
}

class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  final String? message;
  const ApiSuccess(this.data, {this.message});
}

class ApiFailure<T> extends ApiResult<T> {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const ApiFailure(
    this.message, {
    this.statusCode,
    this.originalError,
  });
}
