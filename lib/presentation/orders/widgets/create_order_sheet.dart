import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/create_order_request.dart';
import 'package:hangout/presentation/orders/order_detail_page_wrapper.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';

Future<void> showCreateOrderSheet(
  BuildContext context, {
  required String postId,
  required double price,
  required String currency,
  String? venueName,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CreateOrderSheet(
      postId: postId,
      price: price,
      currency: currency,
      venueName: venueName,
    ),
  );
}

class _CreateOrderSheet extends StatefulWidget {
  final String postId;
  final double price;
  final String currency;
  final String? venueName;
  const _CreateOrderSheet({
    required this.postId,
    required this.price,
    required this.currency,
    this.venueName,
  });

  @override
  State<_CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends State<_CreateOrderSheet> {
  final TextEditingController _note = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final api = serviceLocator.get<ApiService>();
    try {
      final note = _note.text.trim();
      final res = await api.createOrder(
        CreateOrderRequest(
          postId: widget.postId,
          note: note.isEmpty ? null : note,
        ),
      );
      if (!mounted) return;
      if (!res.success || res.data == null) {
        appToast.error(res.error ?? 'تعذر إنشاء الطلب');
        setState(() => _submitting = false);
        return;
      }
      final orderId = res.data!.id;
      Navigator.of(context).pop();
      OrderDetailPageWrapper.push(context, orderId);
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      final msg = (data is Map && data['error'] is String)
          ? data['error'] as String
          : (e.response?.statusCode == 409
              ? 'لديك طلب مفتوح على هذا المنتج مسبقاً'
              : (e.message ?? 'تعذر إنشاء الطلب'));
      appToast.error(msg);
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'تأكيد الطلب',
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.venueName != null && widget.venueName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'من ${widget.venueName!}',
                      style: TextStyle(
                        color: c.onSurfaceSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'السعر',
                        style: TextStyle(
                          color: c.onSurfaceSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.price.toStringAsFixed(0),
                        style: TextStyle(
                          color: c.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.currency,
                        style: TextStyle(
                          color: c.onSurfaceSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _note,
                  label: 'ملاحظة (اختياري)',
                  hint: 'تفاصيل إضافية، توقيت الاستلام، ...',
                  maxLines: 4,
                  minLines: 2,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        TablerIcons.info_circle,
                        color: c.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'الدفع يتم خارج التطبيق — هذا الطلب رسالة تأكيد للمتجر',
                          style: TextStyle(
                            color: c.onSurfaceSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(color: c.onSurfaceSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: c.onSurface,
                          foregroundColor: c.surface,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _submitting
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: c.surface,
                                  strokeWidth: 1.5,
                                ),
                              )
                            : const Text('تأكيد الطلب'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
