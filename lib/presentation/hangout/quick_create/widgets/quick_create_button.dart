import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/my_profile/controller/create_hangout_controller/create_hangout_bloc.dart';

class QuickCreateButton extends StatelessWidget {
  final int count;
  final VoidCallback onSubmit;

  const QuickCreateButton({
    super.key,
    required this.count,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final submitting =
        context.watch<CreateHangoutBloc>().state is CreateHangoutLoading;
    return FilledButton.icon(
      onPressed: submitting ? null : onSubmit,
      icon: submitting
          ? const SizedBox(
              width: 18,
              height: 18,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(TablerIcons.send, size: 18),
      label: Text(
        context.pickBilingual(ar: 'أنشئ · $count', en: 'Create · $count'),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontFamily: 'IBMPlexSansArabic',
        ),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    );
  }
}
