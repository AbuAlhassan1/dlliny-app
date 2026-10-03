import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/explore/utils/reel_item.dart';
import 'package:hangout/presentation/explore/widgets/hangout_reel_card.dart';
import 'package:hangout/presentation/explore/widgets/reel_card.dart';
import 'package:hangout/presentation/shared/widgets/scroll_snapy_physics.dart';

class DiscoverPostViewer extends StatefulWidget {
  final List<ReelItem> items;
  final int initialIndex;

  const DiscoverPostViewer({
    super.key,
    required this.items,
    required this.initialIndex,
  });

  @override
  State<DiscoverPostViewer> createState() => _DiscoverPostViewerState();
}

class _DiscoverPostViewerState extends State<DiscoverPostViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildReel(ReelItem item, bool isActive) {
    return switch (item) {
      PostReel(:final post) => ReelCard(
          key: ValueKey('discover-${item.id}'),
          post: post,
          isActive: isActive,
        ),
      HangoutReel(:final hangout) => HangoutReelCard(
          key: ValueKey('discover-${item.id}'),
          item: hangout,
          isActive: isActive,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.mediaSurface,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: const SnappyPageScrollPhysics(),
            allowImplicitScrolling: true,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) =>
                _buildReel(widget.items[index], index == _currentIndex),
          ),
          PositionedDirectional(
            top: MediaQuery.of(context).padding.top + 8,
            start: 8,
            child: _CircleButton(
              icon: TablerIcons.chevron_left,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
