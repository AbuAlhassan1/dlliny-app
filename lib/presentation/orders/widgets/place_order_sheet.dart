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

Future<void> showPlaceOrderSheet(
  BuildContext context, {
  required String postId,
  required double price,
  required String currency,
  String? venueName,
  String? productCaption,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PlaceOrderSheet(
      postId: postId,
      price: price,
      currency: currency,
      venueName: venueName,
      productCaption: productCaption,
    ),
  );
}

class _PlaceOrderSheet extends StatefulWidget {
  final String postId;
  final double price;
  final String currency;
  final String? venueName;
  final String? productCaption;
  const _PlaceOrderSheet({
    required this.postId,
    required this.price,
    required this.currency,
    this.venueName,
    this.productCaption,
  });

  @override
  State<_PlaceOrderSheet> createState() => _PlaceOrderSheetState();
}

class _PlaceOrderSheetState extends State<_PlaceOrderSheet> {
  final TextEditingController _note = TextEditingController();
  final ApiService _api = serviceLocator.get<ApiService>();
  bool _submitting = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final res = await _api.createOrder(
        CreateOrderRequest(
          postId: widget.postId,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        ),
      );
      if (!mounted) return;
      if (!res.success || res.data == null) {
        appToast.error(res.error ?? 'تعذر إرسال الطلب');
        setState(() => _submitting = false);
        return;
      }
      final orderId = res.data!.id;
      Navigator.of(context).pop();
      OrderDetailPageWrapper.push(context, orderId);
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final data = e.response?.data;
      String message;
      if (code == 409) {
        message = 'عندك طلب مفتوح على هذا المنتج — افتح "طلباتي"';
      } else if (data is Map && data['error'] is String) {
        message = data['error'] as String;
      } else {
        message = e.message ?? 'تعذر إرسال الطلب';
      }
      appToast.error(message);
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
                const SizedBox(height: 14),
                Text(
                  'تأكيد الطلب',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.productCaption != null &&
                          widget.productCaption!.isNotEmpty)
                        Text(
                          widget.productCaption!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (widget.venueName != null &&
                          widget.venueName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            widget.venueName!,
                            style: TextStyle(
                              color: c.onSurfaceSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.price.toStringAsFixed(0),
                            style: TextStyle(
                              color: c.onSurface,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              widget.currency,
                              style: TextStyle(
                                color: c.onSurfaceSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _note,
                  label: 'ملاحظة (اختياري)',
                  hint: 'تفاصيل إضافية، وقت الاستلام…',
                  maxLines: 3,
                  minLines: 2,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        TablerIcons.info_circle,
                        color: c.onSurfaceSecondary,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'الدفع والتسليم يتم خارج التطبيق بالتنسيق مع المتجر',
                          style: TextStyle(
                            color: c.onSurfaceSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
                          backgroundColor: c.primary,
                          foregroundColor: c.onPrimary,
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
                                  color: c.onPrimary,
                                  strokeWidth: 1.5,
                                ),
                              )
                            : const Text(
                                'تأكيد الطلب',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
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
