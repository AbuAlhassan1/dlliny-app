import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/report_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/post/controllers/post_interactions_bloc.dart';

Future<void> showReportPostSheet({
  required BuildContext context,
  required String postId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => BlocProvider.value(
      value: context.read<PostInteractionsBloc>(),
      child: _ReportSheet(postId: postId),
    ),
  );
}

class _ReportSheet extends StatefulWidget {
  final String postId;
  const _ReportSheet({required this.postId});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final ApiService _api = serviceLocator.get<ApiService>();
  final TextEditingController _description = TextEditingController();

  late final Future<List<ReportCategoryResponse>> _categoriesFuture =
      _loadCategories();
  String? _selectedId;

  Future<List<ReportCategoryResponse>> _loadCategories() async {
    final res = await _api.getPostReportCategories();
    if (!res.success || res.data == null) {
      throw Exception(res.error ?? 'Failed to load categories');
    }
    return res.data!;
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final id = _selectedId;
    if (id == null) return;
    context.read<PostInteractionsBloc>().add(SubmitPostReport(
          postId: widget.postId,
          categoryId: id,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<PostInteractionsBloc, PostInteractionsState>(
      listenWhen: (_, s) => s is ReportSubmitted || s is ReportFailed,
      listener: (context, state) {
        if (state is ReportSubmitted) {
          Navigator.of(context).pop();
          appToast.success(LocaleKeys.post_report_sent_toast.tr());
        } else if (state is ReportFailed) {
          appToast.error(state.message);
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, _) {
          final t = context.c;
          return Container(
            decoration: BoxDecoration(
              color: t.surfaceElevated,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(bottom: viewInsets),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: t.onSurfaceDisabled,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  LocaleKeys.post_report_title.tr(),
                  style: TextStyle(
                    color: t.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Divider(height: 16, color: t.divider),
                Expanded(
                  child: FutureBuilder<List<ReportCategoryResponse>>(
                    future: _categoriesFuture,
                    builder: (context, snap) {
                      final t = context.c;
                      if (snap.connectionState != ConnectionState.done) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: t.onSurface,
                            strokeWidth: 1,
                          ),
                        );
                      }
                      if (snap.hasError) {
                        return Center(
                          child: Text(
                            LocaleKeys.post_report_categories_load_failed.tr(),
                            style: TextStyle(color: t.onSurfaceSecondary),
                          ),
                        );
                      }
                      final categories = snap.data!;
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: categories.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: t.divider,
                        ),
                        itemBuilder: (context, i) {
                          final c = categories[i];
                          final selected = _selectedId == c.id;
                          return InkWell(
                            onTap: () => setState(() => _selectedId = c.id),
                            child: Container(
                              color: selected ? t.primary : t.surfaceMuted,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selected
                                        ? TablerIcons.circle_check_filled
                                        : TablerIcons.circle,
                                    color: selected
                                        ? t.onPrimary
                                        : t.onSurfaceMuted,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      isAr ? c.nameAr : c.nameEn,
                                      style: TextStyle(
                                        color: selected
                                            ? t.onPrimary
                                            : t.onSurface,
                                        fontWeight: selected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Divider(height: 1, color: t.divider),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _description,
                    style: TextStyle(color: t.onSurface),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: LocaleKeys.post_report_description_hint.tr(),
                      hintStyle: TextStyle(color: t.onSurfaceMuted),
                      filled: true,
                      fillColor: t.surfaceMuted,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: BlocBuilder<PostInteractionsBloc,
                        PostInteractionsState>(
                      buildWhen: (_, s) =>
                          s is ReportSubmitting ||
                          s is ReportSubmitted ||
                          s is ReportFailed,
                      builder: (context, state) {
                        final t = context.c;
                        final busy = state is ReportSubmitting;
                        return ElevatedButton(
                          onPressed: (_selectedId == null || busy) ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: t.primary,
                            foregroundColor: t.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: busy
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: t.onPrimary,
                                  ),
                                )
                              : Text(
                                  LocaleKeys.post_report_submit.tr(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
