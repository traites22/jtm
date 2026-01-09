import 'package:flutter/material.dart';

class AppAnimations {
  // Durées d'animation
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration extraSlow = Duration(milliseconds: 800);

  // Courbes d'animation
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve elasticCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeOutCubic;

  // Animations de transition
  static Widget slideTransition({
    required Widget child,
    required Animation<double> animation,
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
    Curve curve = defaultCurve,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(parent: animation, curve: curve)),
      child: child,
    );
  }

  static Widget fadeTransition({
    required Widget child,
    required Animation<double> animation,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = defaultCurve,
  }) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(parent: animation, curve: curve)),
      child: child,
    );
  }

  static Widget scaleTransition({
    required Widget child,
    required Animation<double> animation,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = defaultCurve,
  }) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(parent: animation, curve: curve)),
      child: child,
    );
  }

  // Animations de page
  static Widget slideInFromRight({
    required Widget child,
    required Animation<double> animation,
    Curve curve = smoothCurve,
  }) {
    return slideTransition(
      child: child,
      animation: animation,
      begin: const Offset(1.0, 0.0),
      curve: curve,
    );
  }

  static Widget slideInFromLeft({
    required Widget child,
    required Animation<double> animation,
    Curve curve = smoothCurve,
  }) {
    return slideTransition(
      child: child,
      animation: animation,
      begin: const Offset(-1.0, 0.0),
      curve: curve,
    );
  }

  static Widget slideInFromTop({
    required Widget child,
    required Animation<double> animation,
    Curve curve = smoothCurve,
  }) {
    return slideTransition(
      child: child,
      animation: animation,
      begin: const Offset(0.0, -1.0),
      curve: curve,
    );
  }

  static Widget slideInFromBottom({
    required Widget child,
    required Animation<double> animation,
    Curve curve = smoothCurve,
  }) {
    return slideTransition(
      child: child,
      animation: animation,
      begin: const Offset(0.0, 1.0),
      curve: curve,
    );
  }

  static Widget fadeIn({
    required Widget child,
    required Animation<double> animation,
    Curve curve = defaultCurve,
  }) {
    return fadeTransition(child: child, animation: animation, curve: curve);
  }

  static Widget scaleIn({
    required Widget child,
    required Animation<double> animation,
    Curve curve = elasticCurve,
  }) {
    return scaleTransition(child: child, animation: animation, curve: curve);
  }

  // Animation de message
  static Widget messageSlideIn({
    required Widget child,
    required Animation<double> animation,
    bool isFromCurrentUser = false,
  }) {
    return slideTransition(
      child: child,
      animation: animation,
      begin: isFromCurrentUser ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0),
      curve: smoothCurve,
    );
  }

  // Animation de réaction
  static Widget reactionBounce({required Widget child, required Animation<double> animation}) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: bounceCurve)),
      child: child,
    );
  }

  // Animation de like/dislike
  static Widget heartBeat({required Widget child, required Animation<double> animation}) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        ),
      ),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.2, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
          ),
        ),
        child: child,
      ),
    );
  }

  // Animation de swipe
  static Widget swipeCard({
    required Widget child,
    required Animation<double> animation,
    double angle = 0.0,
  }) {
    return Transform.rotate(
      angle: angle * animation.value,
      child: Transform.translate(offset: Offset(300 * animation.value, 0), child: child),
    );
  }

  // Animation de chargement
  static Widget loadingAnimation({required Widget child, required Animation<double> animation}) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: smoothCurve)),
        child: child,
      ),
    );
  }

  // Animation de shimmer
  static Widget shimmer({
    required Widget child,
    required Animation<double> animation,
    Color baseColor = Colors.grey,
    Color highlightColor = Colors.white,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + animation.value * 2.0, 0.0),
              end: Alignment(1.0 + animation.value * 2.0, 0.0),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }

  // Animation de pulse
  static Widget pulse({required Widget child, required Animation<double> animation}) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (0.1 * animation.value),
          child: Opacity(opacity: 1.0 - (0.3 * animation.value), child: child),
        );
      },
      child: child,
    );
  }

  // Animation de shake
  static Widget shake({
    required Widget child,
    required Animation<double> animation,
    double displacement = 10.0,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(displacement * (animation.value - 0.5).abs(), 0),
          child: child,
        );
      },
      child: child,
    );
  }

  // Animation de rotation
  static Widget rotation({
    required Widget child,
    required Animation<double> animation,
    double turns = 1.0,
  }) {
    return Transform.rotate(angle: turns * 2 * 3.14159 * animation.value, child: child);
  }

  // Animation de flip
  static Widget flip({required Widget child, required Animation<double> animation}) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(animation.value * 3.14159),
          child: child,
        );
      },
      child: child,
    );
  }

  // Animation de fade entre deux widgets
  static Widget crossFade({
    required Widget child,
    Widget? secondChild,
    required Animation<double> animation,
  }) {
    return Stack(
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.0).animate(animation),
          child: child,
        ),
        if (secondChild != null)
          FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
            child: secondChild,
          ),
      ],
    );
  }

  // Animation de morphing
  static Widget morphing({
    required Widget child,
    required Animation<double> animation,
    double borderRadius = 0.0,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius * animation.value),
          child: child,
        );
      },
      child: child,
    );
  }

  // Animation de ripple
  static Widget ripple({
    required Widget child,
    required Animation<double> animation,
    Color color = Colors.blue,
  }) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: ClipRRect(
            child: Container(
              decoration: BoxDecoration(color: color.withOpacity(0.3 * (1.0 - animation.value))),
            ),
          ),
        ),
      ],
    );
  }

  // Animation de typing indicator
  static Widget typingIndicator({
    required Animation<double> animation,
    Color color = Colors.blue,
    double dotSize = 8.0,
    double spacing = 4.0,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final delay = index * 0.2;
            final progress = (animation.value - delay).clamp(0.0, 1.0);

            return Transform.scale(
              scale: 0.5 + (0.5 * progress),
              child: Container(
                width: dotSize,
                height: dotSize,
                margin: EdgeInsets.only(right: spacing),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            );
          },
        );
      }),
    );
  }

  // Animation de badge
  static Widget badgeAnimation({
    required Widget child,
    required Animation<double> animation,
    Color badgeColor = Colors.red,
  }) {
    return Stack(
      children: [
        child,
        Positioned(
          top: -8,
          right: -8,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(parent: animation, curve: elasticCurve)),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
            ),
          ),
        ),
      ],
    );
  }
}

// Extension pour faciliter l'utilisation des animations
extension AnimationExtensions on Widget {
  Widget animateWith({
    Duration duration = AppAnimations.medium,
    Curve curve = AppAnimations.defaultCurve,
    VoidCallback? onComplete,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: 1.0),
      curve: curve,
      builder: (context, animationValue, child) {
        final animation = AlwaysStoppedAnimation(animationValue.toDouble());
        return AppAnimations.fadeIn(
          child: child ?? Container(),
          animation: animation,
          curve: curve,
        );
      },
      onEnd: onComplete,
      child: this,
    );
  }

  Widget slideInFromRight({
    Duration duration = AppAnimations.medium,
    Curve curve = AppAnimations.smoothCurve,
    VoidCallback? onComplete,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: 1.0),
      curve: curve,
      builder: (context, animationValue, child) {
        final animation = AlwaysStoppedAnimation(animationValue.toDouble());
        return AppAnimations.slideInFromRight(
          child: child ?? Container(),
          animation: animation,
          curve: curve,
        );
      },
      onEnd: onComplete,
      child: this,
    );
  }

  Widget slideInFromLeft({
    Duration duration = AppAnimations.medium,
    Curve curve = AppAnimations.smoothCurve,
    VoidCallback? onComplete,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: 1.0),
      curve: curve,
      builder: (context, animationValue, child) {
        final animation = AlwaysStoppedAnimation(animationValue.toDouble());
        return AppAnimations.slideInFromLeft(
          child: child ?? Container(),
          animation: animation,
          curve: curve,
        );
      },
      onEnd: onComplete,
      child: this,
    );
  }

  Widget scaleIn({
    Duration duration = AppAnimations.medium,
    Curve curve = AppAnimations.elasticCurve,
    VoidCallback? onComplete,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: 1.0),
      curve: curve,
      builder: (context, animationValue, child) {
        final animation = AlwaysStoppedAnimation(animationValue.toDouble());
        return AppAnimations.scaleIn(
          child: child ?? Container(),
          animation: animation,
          curve: curve,
        );
      },
      onEnd: onComplete,
      child: this,
    );
  }

  Widget pulse({Duration duration = AppAnimations.slow, VoidCallback? onComplete}) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: 1.0),
      curve: AppAnimations.defaultCurve,
      builder: (context, animationValue, child) {
        final animation = AlwaysStoppedAnimation(animationValue.toDouble());
        return AppAnimations.pulse(child: child ?? Container(), animation: animation);
      },
      onEnd: onComplete,
      child: this,
    );
  }

  Widget shimmer({
    Duration duration = AppAnimations.extraSlow,
    Color baseColor = Colors.grey,
    Color highlightColor = Colors.white,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        final animation = AlwaysStoppedAnimation(animationValue);
        return AppAnimations.shimmer(
          child: child ?? Container(),
          animation: animation,
          baseColor: baseColor,
          highlightColor: highlightColor,
        );
      },
      child: this,
    );
  }
}
