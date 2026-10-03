import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/settings/controllers/convert_to_business_account_controller/convert_to_business_account_bloc.dart';
import 'package:hangout/presentation/settings/widgets/business_button.dart';

class BusinessAccountCard extends StatefulWidget {
  const BusinessAccountCard({super.key});

  @override
  State<BusinessAccountCard> createState() => _BusinessAccountCardState();
}

class _BusinessAccountCardState extends State<BusinessAccountCard> {
  @override
  void initState() {
    context.read<ConvertToBusinessAccountBloc>().add(
      CheckingIfUserHasBusinessAccountRequest(),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<
      ConvertToBusinessAccountBloc,
      ConvertToBusinessAccountState
    >(
      builder: (context, state) {
        if (state is CheckingRequestLoading || state is ConvertToBusinessAccountInitial) {
          return SizedBox();
        }
        return Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade900, Colors.purple.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: c.border, width: 1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PositionedDirectional(
                top: -30,
                end: -40,
                child: Image.asset(
                  "assets/images/business.png",
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),

              Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: .start,
                            children: [
                              Builder(
                                builder: (context) {
                                  String text =
                                      LocaleKeys.settings_business_convert_title.tr();
                                  String subText =
                                      LocaleKeys.settings_business_convert_description.tr();
                                  if (state is CheckingRequestLoaded) {
                                    if (state.requestResponse != null) {
                                      if (state.requestResponse!.status ==
                                          "pending") {
                                        text =
                                            LocaleKeys.settings_business_pending_title.tr();
                                        subText =
                                            LocaleKeys.settings_business_pending_description.tr();
                                      } else if (state
                                              .requestResponse!
                                              .status ==
                                          "rejected") {
                                        text =
                                            LocaleKeys.settings_business_rejected_title.tr();
                                        subText =
                                            LocaleKeys.settings_business_rejected_description.tr();
                                      }
                                    }
                                  }
                                  return Column(
                                    crossAxisAlignment: .start,
                                    children: [
                                      Text(
                                        text,
                                        style: TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      SizedBox(height: 10),

                                      Text(
                                        subText,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFFCFCFCF),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        Expanded(flex: 2, child: SizedBox()),
                      ],
                    ),

                    Spacer(),

                    SizedBox(height: 10),

                    Builder(
                      builder: (context) {
                        if (state is CheckingRequestLoaded &&
                            state.requestResponse != null &&
                            (state.requestResponse!.status == "pending" ||
                                state.requestResponse!.status == "rejected")) {
                          return Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: state.requestResponse!.status == "pending"
                                  ? c.warning
                                  : c.danger,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: .center,
                              children: [
                                Text(
                                  state.requestResponse!.status == "pending"
                                      ? LocaleKeys.settings_business_pending_title.tr()
                                      : state.requestResponse!.status ==
                                            "rejected"
                                      ? LocaleKeys.settings_business_rejected_title.tr()
                                      : LocaleKeys.settings_business_cta_convert.tr(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(TablerIcons.tie, color: Colors.white),
                              ],
                            ),
                          );
                        }
                        return BusinessButton();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
