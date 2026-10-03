import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/utils/format_relative_time.dart';
import 'package:hangout/domain/dto/response/order_response.dart';
import 'package:hangout/presentation/orders/controllers/order_detail/order_detail_bloc.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';

class OrderInquiryThread extends StatefulWidget {
  final OrderResponse order;
  final OrderViewerSide viewerSide;

  final bool isSending;
  final ValueChanged<String> onSend;

  const OrderInquiryThread({
    super.key,
    required this.order,
    required this.viewerSide,
    required this.isSending,
    required this.onSend,
  });

  @override
  State<OrderInquiryThread> createState() => _OrderInquiryThreadState();
}

class _OrderInquiryThreadState extends State<OrderInquiryThread> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || widget.isSending) return;
    widget.onSend(text);
    _ctrl.clear();
  }

  bool _mineByRole(OrderMessageResponse m) {
    final viewerIsCustomer = widget.viewerSide == OrderViewerSide.customer;
    return (viewerIsCustomer && m.senderRole == OrderSenderRole.customer) ||
        (!viewerIsCustomer && m.senderRole == OrderSenderRole.venue);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final messages = widget.order.messages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (messages.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                widget.order.inquiryLocked
                    ? 'لا توجد رسائل في هذا الطلب'
                    : 'ابدأ المحادثة — اسأل عن التفاصيل أو نسّق الاستلام',
                style: TextStyle(
                  color: c.onSurfaceSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              for (final m in messages)
                _Bubble(
                  message: m,
                  mine: _mineByRole(m),
                ),
            ],
          ),
        const SizedBox(height: 12),
        if (widget.order.inquiryLocked)
          _LockedComposer(c: c)
        else
          _Composer(
            controller: _ctrl,
            focusNode: _focus,
            onSubmit: _submit,
            isSending: widget.isSending,
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final OrderMessageResponse message;
  final bool mine;
  const _Bubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: mine ? c.onSurface : c.surfaceMuted,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: mine
                      ? const Radius.circular(14)
                      : const Radius.circular(2),
                  bottomRight: mine
                      ? const Radius.circular(2)
                      : const Radius.circular(14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.body,
                    style: TextStyle(
                      color: mine ? c.surface : c.onSurface,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatRelativeTime(message.createdAt),
                    style: TextStyle(
                      color: mine
                          ? c.surface.withValues(alpha: 0.7)
                          : c.onSurfaceMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;
  final bool isSending;
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.isSending,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: AppTextField(
            controller: controller,
            focusNode: focusNode,
            hint: 'اكتب رسالة…',
            maxLines: 4,
            minLines: 1,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: c.onSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            onPressed: isSending ? null : onSubmit,
            icon: isSending
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: c.surface,
                      strokeWidth: 1.5,
                    ),
                  )
                : Icon(TablerIcons.send, color: c.surface, size: 18),
          ),
        ),
      ],
    );
  }
}

class _LockedComposer extends StatelessWidget {
  final AppColors c;
  const _LockedComposer({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(TablerIcons.lock, color: c.onSurfaceMuted, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'المحادثة مقفلة — الطلب في حالة نهائية',
              style: TextStyle(color: c.onSurfaceSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
