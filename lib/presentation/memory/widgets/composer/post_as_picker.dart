import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/presentation/memory/bloc/memory_composer/memory_composer_bloc.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';
import 'package:hangout/presentation/my_profile/widgets/author_picker.dart';

class PostAsPicker extends StatefulWidget {
  const PostAsPicker({super.key});

  @override
  State<PostAsPicker> createState() => _PostAsPickerState();
}

class _PostAsPickerState extends State<PostAsPicker> {
  late AuthorIdentity _author = _buildMeFromProfile();

  AuthorIdentity _buildMeFromProfile() {
    final me = context.read<MyProfileBloc>().user;
    return MeAuthor(
      userId: me?.id ?? '',
      displayName: me?.displayName?.isNotEmpty == true
          ? me!.displayName!
          : (me?.username ?? 'أنا'),
      imageUrl: me?.avatarUrl,
    );
  }

  void _onChanged(AuthorIdentity next) {
    setState(() => _author = next);
    final venueId = switch (next) {
      VenueAuthor(:final venueId) => venueId,
      MeAuthor() => null,
    };
    context.read<MemoryComposerBloc>().add(PostAsChanged(venueId));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 4),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: AuthorPickerSwitcher(
          current: _author,
          onChanged: _onChanged,
        ),
      ),
    );
  }
}
