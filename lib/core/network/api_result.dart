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
    final self = this;
    return switch (self) {
      ApiSuccess<T>() => success(self.data),
      ApiFailure<T>() => failure(self.message, self.statusCode),
    };
  }
}

class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  final String? message;

  /// Raw `meta` object from the backend envelope (pagination etc.).
  final Map<String, dynamic>? meta;

  const ApiSuccess(this.data, {this.message, this.meta});
}

class ApiFailure<T> extends ApiResult<T> {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  /// True when the request never reached the server (offline / timeout).
  final bool isNetworkError;

  const ApiFailure(
    this.message, {
    this.statusCode,
    this.originalError,
    this.isNetworkError = false,
  });
}

/// One page of results from a paginated endpoint.
class PagedResult<T> {
  final List<T> items;
  final int page;
  final int total;
  final bool hasNext;
  final bool fromCache;

  const PagedResult({
    required this.items,
    required this.page,
    required this.total,
    required this.hasNext,
    this.fromCache = false,
  });

  factory PagedResult.fromMeta(List<T> items, Map<String, dynamic>? meta, {required int page, required int limit}) {
    return PagedResult(
      items: items,
      page: (meta?['page'] as num?)?.toInt() ?? page,
      total: (meta?['total'] as num?)?.toInt() ?? items.length,
      hasNext: meta?['has_next'] as bool? ?? items.length >= limit,
    );
  }
}
