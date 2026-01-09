import 'package:flutter/material.dart';

class LoadingStates {
  static Widget shimmer({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }

  static Widget circular({Color? color, double size = 24.0, double strokeWidth = 3.0}) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: color,
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.blue),
      ),
    );
  }

  static Widget linear({Color? color, double height = 4.0}) {
    return LinearProgressIndicator(
      color: color,
      minHeight: height,
      backgroundColor: color?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
    );
  }

  static Widget skeletonCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                shimmer(width: 60, height: 60),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      shimmer(height: 16),
                      const SizedBox(height: 8),
                      shimmer(height: 12, width: 100),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            shimmer(height: 12),
            const SizedBox(height: 8),
            shimmer(height: 12, width: 200),
          ],
        ),
      ),
    );
  }

  static Widget skeletonList({int itemCount = 5}) {
    return ListView.builder(itemCount: itemCount, itemBuilder: (context, index) => skeletonCard());
  }

  static Widget profileCardSkeleton() {
    return Container(
      height: 500,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.grey[100]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: [Colors.grey[300]!, Colors.grey[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  shimmer(height: 20, width: 120),
                  const SizedBox(height: 8),
                  shimmer(height: 14, width: 80),
                  const SizedBox(height: 12),
                  shimmer(height: 12),
                  const SizedBox(height: 8),
                  shimmer(height: 12, width: 180),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget messageBubbleSkeleton({bool isMe = false}) {
    return Builder(
      builder: (context) {
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? Colors.grey[300] : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                shimmer(height: 14, width: 120),
                const SizedBox(height: 4),
                shimmer(height: 12, width: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget fullScreen({String? message, Widget? child, Color? backgroundColor}) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child:
            child ??
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                circular(size: 48),
                if (message != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
      ),
    );
  }

  static Widget overlay({required Widget child, bool isLoading = false, String? message}) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      circular(size: 32),
                      if (message != null) ...[const SizedBox(height: 16), Text(message)],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static Widget pullToRefresh({
    required RefreshCallback onRefresh,
    required Widget child,
    Color? color,
  }) {
    return RefreshIndicator(onRefresh: onRefresh, color: color, child: child);
  }

  static Widget custom({required Widget child, bool isLoading = false, Widget? loadingWidget}) {
    if (isLoading) {
      return loadingWidget ?? circular();
    }
    return child;
  }
}

class Get {
  static BuildContext? _context;

  static void setContext(BuildContext context) {
    _context = context;
  }

  static BuildContext get context {
    if (_context == null) {
      throw Exception('Context not set. Call Get.setContext(context) first.');
    }
    return _context!;
  }
}

class LoadingBuilder extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const LoadingBuilder({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingWidget,
    this.errorWidget,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget ?? LoadingStates.circular();
    }

    if (errorMessage != null) {
      return errorWidget ?? _buildErrorWidget();
    }

    return child;
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(errorMessage!, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          ],
        ),
      ),
    );
  }
}
