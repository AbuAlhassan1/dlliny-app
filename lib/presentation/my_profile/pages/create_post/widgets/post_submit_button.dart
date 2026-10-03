import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/my_profile/controller/create_post_controller/create_post_bloc.dart';
import 'package:hangout/presentation/my_profile/controller/posts/my_posts_bloc.dart';

class PostSubmitButton extends StatelessWidget {
  final VoidCallback onTap;
  const PostSubmitButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BlocConsumer<CreatePostBloc, CreatePostState>(
        listener: (context, state) async {
          if (state is CreatePostSuccess) {
            try {
              context.read<MyPostsBloc>().add(GetMyPosts());
            } on ProviderNotFoundException catch (_) {
            }
            await Future.delayed(const Duration(seconds: 1));
            if (context.mounted) Navigator.pop(context, true);
          }
        },
        builder: (context, state) {
          final c = context.c;
          return Container(
            width: double.infinity,
            height: 45,
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: state is CreatePostSuccess
                  ? Icon(TablerIcons.check, color: c.onPrimary)
                  : state is CreatePostLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: c.onPrimary,
                            strokeWidth: 1,
                          ),
                        )
                      : state is CreatePostError
                          ? Icon(TablerIcons.x, color: c.onPrimary)
                          : Icon(TablerIcons.check, color: c.onPrimary),
            ),
          );
        },
      ),
    );
  }
}
