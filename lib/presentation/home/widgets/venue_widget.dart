// ignore_for_file: use_build_context_synchronously
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/base/controller/tabs_bloc.dart';
import 'package:hangout/presentation/explore/controller/explore_bloc.dart';
import 'package:hangout/presentation/shared/controller/video_controller/video_bloc_bloc.dart';
import 'package:hangout/presentation/shared/widgets/place/video_view.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VenueWidget extends StatefulWidget {
  final int index;
  final PlaceModel place;
  const VenueWidget({super.key, required this.index, required this.place});

  @override
  State<VenueWidget> createState() => _VenueWidgetState();
}

class _VenueWidgetState extends State<VenueWidget> {
  var formatter = NumberFormat.compact();

  late VideoPlayerController _controller;

  bool isLoading = true;
  bool pausedByUser = false;

  void listener() {
    if (_controller.value.isInitialized) {
      setState(() {});
    }

    if (!_controller.value.isPlaying) {
      setState(() {});
    }
  }

  @override
  void initState() {
    _controller = VideoPlayerController.asset(widget.place.url)
      ..initialize().then((_) {
        _controller.setVolume(context.read<VideoBloc>().state.isMuted ? 0 : 1);
        setState(() {});
        _controller.addListener(listener);
      });

    context.read<TabsBloc>().tabController.addListener(() {
      if (context.read<TabsBloc>().tabController.index != 1 ||
          _controller.value.isPlaying) {
        _controller.pause();
        pausedByUser = false;
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey(widget.place.name),
      onVisibilityChanged: onVisibilityChanged,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 15),
        padding: EdgeInsets.all(10),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: AppColors.darkBorder,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          children: [
            TweenAnimationBuilder(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              tween: Tween<double>(
                begin: 1,
                end: _controller.value.isInitialized
                    ? _controller.value.aspectRatio
                    : 1,
              ),
              builder: (context, value, child) {
                return AspectRatio(
                  aspectRatio: value,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: onTap,
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: VideoView(controller: _controller),
                          ),
                        ),

                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: true,
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors:
                                      [Colors.transparent, Colors.transparent] +
                                      (!_controller.value.isPlaying
                                          ? [Colors.black.withAlpha(220)]
                                          : [Colors.black.withAlpha(150)]),
                                ),
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ExpandableText(
                                  widget.place.description,
                                  expandText: LocaleKeys.common_show_more.tr(),
                                  collapseText: LocaleKeys.common_show_less.tr(),
                                  animationCurve: Curves.linearToEaseOut,
                                  animationDuration: const Duration(
                                    milliseconds: 300,
                                  ),
                                  animation: true,
                                  expandOnTextTap: true,
                                  collapseOnTextTap: true,
                                  style: TextStyle(
                                    color: AppColors.lighterGrey,
                                    fontSize: 16,
                                  ),
                                ),

                                !_controller.value.isPlaying
                                    ? Column(
                                        children: [
                                          SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: AspectRatio(
                                                  aspectRatio: 1,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      image: DecorationImage(
                                                        image: AssetImage(
                                                          widget.place.image,
                                                        ),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: AspectRatio(
                                                  aspectRatio: 1,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      image: DecorationImage(
                                                        image: AssetImage(
                                                          widget.place.image,
                                                        ),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: AspectRatio(
                                                  aspectRatio: 1,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      image: DecorationImage(
                                                        image: AssetImage(
                                                          widget.place.image,
                                                        ),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ).animate().slideY(
                                            begin: 1,
                                            end: 0,
                                            duration: Duration(
                                              milliseconds: 200,
                                            ),
                                            curve: Curves.easeOut,
                                          ),
                                        ],
                                      )
                                    : SizedBox(),

                                SizedBox(height: 10),

                                Container(
                                  height: 40,
                                  clipBehavior: Clip.hardEdge,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        LocaleKeys.venue_has_hangout_badge.tr(),
                                        style: TextStyle(
                                          color: AppColors.darkPurple,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: AssetImage(widget.place.image),
                  ),

                  SizedBox(width: 10),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.place.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text("@username", style: TextStyle(color: Colors.grey)),
                    ],
                  ),

                  SizedBox(width: 10),

                  Expanded(
                    child: Container(
                      height: 50,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.onSurfaceDarkPurple,
                        borderRadius: BorderRadius.circular(16),
                      ),

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: FittedBox(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        widget.place.rating.toString(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 2),
                                        child: Icon(
                                          TablerIcons.star_filled,
                                          color: Colors.orange,
                                          size: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                              
                                  Text(
                                    LocaleKeys.venue_metrics_rating.tr(),
                                    style: TextStyle(
                                      color: AppColors.lightGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Expanded(
                            child: FittedBox(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    formatter.format(widget.place.followers),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              
                                  Text(
                                    LocaleKeys.venue_metrics_followers.tr(),
                                    style: TextStyle(
                                      color: AppColors.lightGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Expanded(
                            child: FittedBox(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    formatter.format(widget.place.visits),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              
                                  Text(
                                    LocaleKeys.venue_metrics_visits.tr(),
                                    style: TextStyle(
                                      color: AppColors.lightGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onTap() {
    if (_controller.value.isPlaying) {
      _controller.pause();
      pausedByUser = true;
    } else {
      _controller.play();
    }
  }

  void toggleVideoSound() async {
    context.read<VideoBloc>().add(
      VideoToggleSoundEvent(controller: _controller),
    );
    setState(() {});
  }

  void onVisibilityChanged(VisibilityInfo info) {
    if (mounted && _controller.value.isInitialized) {
      if (info.visibleFraction < 0.5) {
        if (_controller.value.isPlaying) {
          _controller.pause();
          pausedByUser = false;
        }
      } else if (info.visibleFraction > 0.55) {
        if (!_controller.value.isPlaying) {
          if (pausedByUser) return;
          _controller.play();
        }
      }
    }
  }
}
