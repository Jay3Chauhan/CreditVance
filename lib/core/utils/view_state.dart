/// Standard lifecycle states for ViewModels / Providers.
enum ViewState {
  initial,
  loading,
  loaded,
  empty,
  error,
  refreshing;

  bool get isInitial => this == ViewState.initial;
  bool get isLoading => this == ViewState.loading;
  bool get isLoaded => this == ViewState.loaded;
  bool get isEmpty => this == ViewState.empty;
  bool get isError => this == ViewState.error;
  bool get isRefreshing => this == ViewState.refreshing;
}
