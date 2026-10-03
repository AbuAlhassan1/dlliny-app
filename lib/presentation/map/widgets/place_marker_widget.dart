import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:zo_animated_border/zo_animated_border.dart';

class PlaceMarkerWidget extends StatefulWidget {
  final ValueNotifier<double> tiltRotation;
  final MapVenuePinResponse pin;
  final VoidCallback? onTap;
  const PlaceMarkerWidget({
    super.key,
    required this.tiltRotation,
    required this.pin,
    this.onTap,
  });

  @override
  State<PlaceMarkerWidget> createState() => _PlaceMarkerWidgetState();
}

class _PlaceMarkerWidgetState extends State<PlaceMarkerWidget>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _controller2;
  late final Animation<double> _animation;
  late final Animation<double> _animation2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _controller2 = AnimationController(
      duration: const Duration(seconds: 9),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: -10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _animation2 = Tween<double>(
      begin: 0,
      end: -15,
    ).animate(CurvedAnimation(parent: _controller2, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.pin.labelAr;
    final showChip = label != null && label.isNotEmpty;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Transform.translate(
        offset: Offset(_animation2.value, _animation.value),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned.fill(child: _Marker(logoUrl: widget.pin.logoUrl)),
              if (showChip)
                Positioned(
                  top: -22,
                  child: _BranchLabelChip(label: label),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  final String? logoUrl;
  const _Marker({this.logoUrl});

  @override
  Widget build(BuildContext context) {
    return ZoAnimatedGradientBorder(
      borderRadius: 100,
      animationCurve: Curves.easeInOutCubic,
      borderThickness: 4,
      gradientColor: const [
        Colors.purpleAccent,
        Colors.yellow,
        Colors.orange,
      ],
      glowOpacity: 0.25,
      animationDuration: const Duration(seconds: 10),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(100),
        ),
        child: ClipOval(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF14121b),
            child: logoUrl != null && logoUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: logoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: const Color(0xFF14121b)),
                    errorWidget: (_, _, _) => const Icon(
                      TablerIcons.map_pin,
                      color: Colors.white70,
                      size: 18,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _BranchLabelChip extends StatelessWidget {
  final String label;
  const _BranchLabelChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
