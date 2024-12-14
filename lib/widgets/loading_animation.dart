import 'package:flutter/material.dart';

class LoadingAnimation extends StatefulWidget {
  final String logoPath;
  final Color? backgroundColor;
  final double size;

  const LoadingAnimation({
    Key? key,
    required this.logoPath,
    this.backgroundColor,
    this.size = 150.0,
  }) : super(key: key);

  @override
  _LoadingAnimationState createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation> 
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _zoomAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Create a zoom effect that makes the logo appear to come towards the viewer
    _zoomAnimation = Tween<double>(
      begin: 0.5,
      end: 1.8,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    // Add slight rotation for 3D effect
    _rotateAnimation = Tween<double>(
      begin: -0.2,
      end: 0.2,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Pulsing effect at the end of zoom
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.7, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective
                ..scale(_zoomAnimation.value * _scaleAnimation.value)
                ..rotateX(_rotateAnimation.value)
                ..rotateY(_rotateAnimation.value),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20 * _zoomAnimation.value,
                      spreadRadius: 5 * _zoomAnimation.value,
                    ),
                  ],
                ),
                child: Image.asset(
                  widget.logoPath,
                  width: widget.size,
                  height: widget.size,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 