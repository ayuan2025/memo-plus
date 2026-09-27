class MemosListLoadMoreController {
  MemosListLoadMoreController({
    required this.initialPageSize,
    required this.pageStep,
  }) : _pageSize = initialPageSize;

  final int initialPageSize;
  final int pageStep;

  int _pageSize;
  bool _reachedEnd = false;
  bool _loadingMore = false;
  String _paginationKey = '';
  int _lastResultCount = 0;
  int _currentResultCount = 0;
  bool _currentLoading = false;
  bool _currentShowSearchLanding = false;
  double _mobileBottomPullDistance = 0;
  bool _mobileBottomPullArmed = false;
  DateTime? _lastDesktopWheelLoadAt;
  int _loadMoreRequestSeq = 0;
  int? _activeLoadMoreRequestId;
  String? _activeLoadMoreSource;

  int get pageSize => _pageSize;
  bool get reachedEnd => _reachedEnd;
  bool get loadingMore => _loadingMore;
  String get paginationKey => _paginationKey;
  int get lastResultCount => _lastResultCount;
  int get currentResultCount => _currentResultCount;
  bool get currentLoading => _currentLoading;
  bool get currentShowSearchLanding => _currentShowSearchLanding;
  double get mobileBottomPullDistance => _mobileBottomPullDistance;
  bool get mobileBottomPullArmed => _mobileBottomPullArmed;
  int? get activeLoadMoreRequestId => _activeLoadMoreRequestId;
  String? get activeLoadMoreSource => _activeLoadMoreSource;

  bool syncQueryKey(String queryKey, {required int previousVisibleCount}) {
    if (_paginationKey == queryKey) return false;
    _paginationKey = queryKey;
    _pageSize = initialPageSize;
    _reachedEnd = false;
    _loadingMore = false;
    _lastResultCount = 0;
    resetTouchPull();
    _lastDesktopWheelLoadAt = null;
    _activeLoadMoreRequestId = null;
    _activeLoadMoreSource = null;
    return true;
  }

  void updateSnapshot({
    required bool hasProviderValue,
    required int resultCount,
    required bool providerLoading,
    required bool showSearchLanding,
  }) {
    _currentResultCount = resultCount;
    _currentLoading = providerLoading;
    _currentShowSearchLanding = showSearchLanding;
    if (hasProviderValue && _currentResultCount != _lastResultCount) {
      _lastResultCount = _currentResultCount;
      _loadingMore = false;
      _activeLoadMoreRequestId = null;
      _activeLoadMoreSource = null;
    }
    if (hasProviderValue) {
      _reachedEnd = _currentResultCount < _pageSize;
    }
  }

  bool canLoadMore() {
    if (_currentShowSearchLanding || _currentLoading) return false;
    if (_loadingMore || _reachedEnd) return false;
    if (_currentResultCount <= 0) return false;
    if (_currentResultCount < _pageSize) {
      _reachedEnd = true;
      return false;
    }
    return true;
  }

  int beginLoadMore({required String source}) {
    final requestId = ++_loadMoreRequestSeq;
    _activeLoadMoreRequestId = requestId;
    _activeLoadMoreSource = source;
    _loadingMore = true;
    _pageSize += pageStep;
    return requestId;
  }

  void finishLoadMore() {
    _loadingMore = false;
    _activeLoadMoreRequestId = null;
    _activeLoadMoreSource = null;
  }

  void cancelActiveLoadMore() {
    _loadingMore = false;
    _activeLoadMoreRequestId = null;
    _activeLoadMoreSource = null;
  }

  void resetTouchPull() {
    _mobileBottomPullDistance = 0;
    _mobileBottomPullArmed = false;
  }

  void updateTouchPullDistance(double nextDistance, {required double threshold}) {
    _mobileBottomPullDistance = nextDistance.clamp(0.0, threshold * 2);
    _mobileBottomPullArmed = _mobileBottomPullDistance >= threshold;
  }

  bool consumeTouchPullArm() {
    final armed = _mobileBottomPullArmed;
    resetTouchPull();
    return armed;
  }

  bool shouldThrottleDesktopWheel(DateTime now, Duration debounce) {
    final last = _lastDesktopWheelLoadAt;
    if (last != null && now.difference(last) < debounce) {
      return true;
    }
    _lastDesktopWheelLoadAt = now;
    return false;
  }

  String describeBlockReason() {
    if (_currentShowSearchLanding) return 'search_landing';
    if (_currentLoading) return 'provider_loading';
    if (_loadingMore) return 'already_loading_more';
    if (_reachedEnd) return 'reached_end';
    if (_currentResultCount <= 0) return 'empty_result';
    if (_currentResultCount < _pageSize) return 'result_less_than_page_size';
    return 'unknown';
  }
}
