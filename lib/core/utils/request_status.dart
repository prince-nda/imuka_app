/// Lifecycle of an async request driven by a Cubit.
enum RequestStatus {
  initial,
  loading,
  success,
  failure;

  bool get isLoading => this == loading;
}
