import 'package:flutter/material.dart';

class LazyLoadList<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int pageSize) dataFetcher;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget Function()? loadingWidget;
  final Widget Function()? emptyWidget;
  final Widget Function(String error)? errorWidget;
  final int pageSize;
  final ScrollController? scrollController;
  final bool shrinkWrap;
  final EdgeInsets? padding;
  final double? itemExtent;
  final bool Function(T item)? isEqual;
  final VoidCallback? onRefresh;
  final bool enablePullToRefresh;

  const LazyLoadList({
    super.key,
    required this.dataFetcher,
    required this.itemBuilder,
    this.loadingWidget,
    this.emptyWidget,
    this.errorWidget,
    this.pageSize = 20,
    this.scrollController,
    this.shrinkWrap = false,
    this.padding,
    this.itemExtent,
    this.isEqual,
    this.onRefresh,
    this.enablePullToRefresh = false,
  });

  @override
  State<LazyLoadList<T>> createState() => _LazyLoadListState<T>();
}

class _LazyLoadListState<T> extends State<LazyLoadList<T>> {
  final List<T> _items = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_scrollListener);
    _loadMoreItems();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_scrollListener);
    }
    super.dispose();
  }

  void _scrollListener() {
    if (!_isLoading &&
        _hasMore &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newItems = await widget.dataFetcher(_currentPage, widget.pageSize);

      if (!mounted) return;

      setState(() {
        _items.addAll(newItems);
        _currentPage++;
        _hasMore = newItems.length == widget.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _currentPage = 0;
      _hasMore = true;
      _error = null;
    });
    await _loadMoreItems();
    widget.onRefresh?.call();
  }

  Widget _buildLoadingIndicator() {
    if (widget.loadingWidget != null) {
      return widget.loadingWidget!();
    }
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyWidget() {
    return widget.emptyWidget ??
        const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Aucun élément trouvé', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        );
  }

  Widget _buildErrorWidget() {
    return widget.errorWidget?.call(_error ?? 'Une erreur est survenue') ??
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Une erreur est survenue',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _refresh, child: const Text('Réessayer')),
              ],
            ),
          ),
        );
  }

  Widget _buildItem(BuildContext context, T item, int index) {
    if (widget.isEqual != null) {
      return KeyedSubtree(key: ValueKey(item), child: widget.itemBuilder(context, item, index));
    }
    return widget.itemBuilder(context, item, index);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items.isEmpty) {
      return _buildErrorWidget();
    }

    if (!_isLoading && _items.isEmpty) {
      return _buildEmptyWidget();
    }

    Widget listView = ListView.builder(
      controller: _scrollController,
      shrinkWrap: widget.shrinkWrap,
      padding: widget.padding,
      itemExtent: widget.itemExtent,
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _items.length) {
          return _buildItem(context, _items[index], index);
        } else {
          return _buildLoadingIndicator();
        }
      },
    );

    if (widget.enablePullToRefresh) {
      return RefreshIndicator(onRefresh: _refresh, child: listView);
    }

    return listView;
  }
}

class InfiniteScrollView<T> extends StatefulWidget {
  final Stream<List<T>> dataStream;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget Function()? loadingWidget;
  final Widget Function()? emptyWidget;
  final Widget Function(String error)? errorWidget;
  final bool shrinkWrap;
  final EdgeInsets? padding;
  final double? itemExtent;
  final bool Function(T item)? isEqual;

  const InfiniteScrollView({
    super.key,
    required this.dataStream,
    required this.itemBuilder,
    this.loadingWidget,
    this.emptyWidget,
    this.errorWidget,
    this.shrinkWrap = false,
    this.padding,
    this.itemExtent,
    this.isEqual,
  });

  @override
  State<InfiniteScrollView<T>> createState() => _InfiniteScrollViewState<T>();
}

class _InfiniteScrollViewState<T> extends State<InfiniteScrollView<T>> {
  final List<T> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.dataStream.listen(
      (data) {
        if (!mounted) return;
        setState(() {
          _items.clear();
          _items.addAll(data);
          _isLoading = false;
          _error = null;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      },
    );
  }

  Widget _buildLoadingIndicator() {
    if (widget.loadingWidget != null) {
      return widget.loadingWidget!();
    }
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyWidget() {
    if (widget.emptyWidget != null) {
      return widget.emptyWidget!();
    }
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun élément trouvé', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!(_error ?? 'Une erreur est survenue');
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Une erreur est survenue',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, T item, int index) {
    if (widget.isEqual != null) {
      return KeyedSubtree(key: ValueKey(item), child: widget.itemBuilder(context, item, index));
    }
    return widget.itemBuilder(context, item, index);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingIndicator();
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_items.isEmpty) {
      return _buildEmptyWidget();
    }

    return ListView.builder(
      shrinkWrap: widget.shrinkWrap,
      padding: widget.padding,
      itemExtent: widget.itemExtent,
      itemCount: _items.length,
      itemBuilder: (context, index) {
        return _buildItem(context, _items[index], index);
      },
    );
  }
}

class PaginatedDataTable<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int pageSize) dataFetcher;
  final List<DataColumn> columns;
  final List<DataCell> Function(T item) dataCellBuilder;
  final int pageSize;
  final Widget Function()? loadingWidget;
  final Widget Function()? emptyWidget;
  final Widget Function(String error)? errorWidget;
  final bool showFirstLastButtons;
  final Function(int)? onPageChanged;

  const PaginatedDataTable({
    super.key,
    required this.dataFetcher,
    required this.columns,
    required this.dataCellBuilder,
    this.pageSize = 20,
    this.loadingWidget,
    this.emptyWidget,
    this.errorWidget,
    this.showFirstLastButtons = false,
    this.onPageChanged,
  });

  @override
  State<PaginatedDataTable<T>> createState() => _PaginatedDataTableState<T>();
}

class _PaginatedDataTableState<T> extends State<PaginatedDataTable<T>> {
  List<T> _items = [];
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage(0);
  }

  Future<void> _loadPage(int page) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await widget.dataFetcher(page, widget.pageSize);

      if (!mounted) return;

      setState(() {
        _items = items;
        _currentPage = page;
        _totalPages = (items.length / widget.pageSize).ceil();
        _isLoading = false;
      });

      widget.onPageChanged?.call(page);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildLoadingIndicator() {
    if (widget.loadingWidget != null) {
      return widget.loadingWidget!();
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyWidget() {
    if (widget.emptyWidget != null) {
      return widget.emptyWidget!();
    }
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_chart, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucune donnée disponible', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!(_error ?? 'Une erreur est survenue');
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Une erreur est survenue',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadPage(_currentPage),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _items.isEmpty) {
      return _buildLoadingIndicator();
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (!_isLoading && _items.isEmpty) {
      return _buildEmptyWidget();
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              columns: widget.columns,
              rows: _items.map((item) {
                return DataRow(cells: widget.dataCellBuilder(item));
              }).toList(),
            ),
          ),
        ),
        if (_totalPages > 1)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _currentPage > 0 ? () => _loadPage(0) : null,
                  icon: const Icon(Icons.first_page),
                ),
                IconButton(
                  onPressed: _currentPage > 0 ? () => _loadPage(_currentPage - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('${_currentPage + 1} / $_totalPages', style: const TextStyle(fontSize: 16)),
                IconButton(
                  onPressed: _currentPage < _totalPages - 1
                      ? () => _loadPage(_currentPage + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
                IconButton(
                  onPressed: _currentPage < _totalPages - 1
                      ? () => _loadPage(_totalPages - 1)
                      : null,
                  icon: const Icon(Icons.last_page),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
