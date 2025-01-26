import 'package:flutter/material.dart';

class CustomLoader extends StatefulWidget {
  final double width;
  final double height;

  const CustomLoader({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  CustomLoaderState createState() => CustomLoaderState();
}

class CustomLoaderState extends State<CustomLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      },
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Image.asset(
          'assets/images/logo_app.png',
          width: widget.width,
          height: widget.height,
        ),
      ),
    );
  }
}
