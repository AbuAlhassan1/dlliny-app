import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/permissions_catalog.dart';
import 'package:hangout/core/services/subscription_permissions.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/auth/controller/access_controller/access_bloc.dart';
import 'package:hangout/presentation/settings/controllers/convert_to_business_account_controller/convert_to_business_account_bloc.dart';
import 'package:hangout/presentation/subscriptions/controllers/subscription_bloc.dart';

class BusinessButton extends StatefulWidget {
  const BusinessButton({super.key});

  @override
  State<BusinessButton> createState() => _BusinessButtonState();
}

class _BusinessButtonState extends State<BusinessButton> {
  final AudioPlayer player = AudioPlayer();

  void playSound() async {
    await player.play(AssetSource('/audio/boy.MP3'));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          barrierColor: c.scrim,
          builder: (_) => BlocProvider.value(
            value: context.read<ConvertToBusinessAccountBloc>(),
            child: ConvertToBusinessAccountRequestFormBottomSheet(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: .center,
          children: [
            Text(
              LocaleKeys.settings_business_cta_convert.tr(),
              style: TextStyle(
                color: c.onPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 10),
            Icon(TablerIcons.tie, color: c.onPrimary),
          ],
        ),
      ),
    );
  }
}

class ConvertToBusinessAccountRequestFormBottomSheet extends StatefulWidget {
  const ConvertToBusinessAccountRequestFormBottomSheet({super.key});

  @override
  State<ConvertToBusinessAccountRequestFormBottomSheet> createState() =>
      _ConvertToBusinessAccountRequestFormBottomSheetState();
}

class _ConvertToBusinessAccountRequestFormBottomSheetState
    extends State<ConvertToBusinessAccountRequestFormBottomSheet> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  void dispose() {
    companyNameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.55,
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 74, 10, 101),
              const Color.fromARGB(255, 58, 3, 82),
              const Color.fromARGB(255, 41, 10, 54),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: .start,
                children: [
                  Text(
                    LocaleKeys.settings_business_cta_convert.tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(TablerIcons.tie, color: Colors.white, size: 30),
                ],
              ),
              SizedBox(height: 10),

              Text(
                LocaleKeys.settings_business_form_intro.tr(),
                style: TextStyle(color: Color(0xFFCFCFCF), fontSize: 16),
              ),

              SizedBox(height: 20),

              Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: companyNameController,
                      validator: (value) => value == null || value.isEmpty
                          ? LocaleKeys.common_field_required.tr()
                          : null,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: LocaleKeys.settings_business_form_company_name_hint.tr(),
                        hintStyle: TextStyle(color: Color(0xFFCFCFCF)),
                        filled: true,
                        fillColor: const Color(0x6814121B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: const Color(0x14FFFFFF),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: const Color(0x51FFFFFF),
                            width: 1,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 15),

                    TextFormField(
                      controller: descriptionController,
                      maxLines: 4,
                      validator: (value) => value == null || value.isEmpty
                          ? LocaleKeys.common_field_required.tr()
                          : null,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: LocaleKeys.settings_business_form_description_hint.tr(),
                        hintStyle: TextStyle(color: Color(0xFFCFCFCF)),
                        filled: true,
                        fillColor: const Color(0x6814121B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: const Color(0x14FFFFFF),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: const Color(0x51FFFFFF),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              BlocConsumer<
                ConvertToBusinessAccountBloc,
                ConvertToBusinessAccountState
              >(
                listener: (context, state) {
                  if (state is RequestSent) {
                    appToast.success(
                      LocaleKeys.settings_business_request_sent_toast.tr(),
                    );
                    Navigator.of(context).pop();
                  }
                },
                builder: (context, state) {
                  return GestureDetector(
                    onTap: () {
                      if (!(formKey.currentState!.validate() &&
                          companyNameController.text.isNotEmpty &&
                          descriptionController.text.isNotEmpty &&
                          state is! RequestLoading)) {
                        return;
                      }
                      final access = context
                          .read<AccessBloc>()
                          .myAccess
                          ?.data;
                      final alreadyHasBusiness =
                          access != null && access.businesses.isNotEmpty;
                      final canCreateMultiple = context
                          .read<SubscriptionBloc>()
                          .has(
                            PermissionsCatalog.validated(
                              SubscriptionPermissions.businessCreateMultiple,
                            ),
                          );
                      if (alreadyHasBusiness && !canCreateMultiple) {
                        appToast.info(
                          LocaleKeys.settings_business_multiple_required_toast.tr(),
                        );
                        return;
                      }
                      context.read<ConvertToBusinessAccountBloc>().add(
                        SendConvertToBusinessAccountRequest(
                          companyName: companyNameController.text,
                          description: descriptionController.text,
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: c.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: state is RequestLoading
                          ? Center(
                              child: SizedBox(
                                height: 25,
                                width: 25,
                                child: CircularProgressIndicator(
                                  color: c.onPrimary,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: .center,
                              children: [
                                Text(
                                  LocaleKeys.settings_business_form_submit.tr(),
                                  style: TextStyle(
                                    color: c.onPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward, color: c.onPrimary),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
