import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';

class FriendsCompactAvatar extends StatelessWidget {
  const FriendsCompactAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.neonBlue,
          child: Text("A"),
        ),
        PositionedDirectional(
          start: 25,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue,
            child: Text("B"),
          ),
        ),
        PositionedDirectional(
          start: 50,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.red,
            child: Text("B"),
          ),
        ),
      ],
    );
  }
}