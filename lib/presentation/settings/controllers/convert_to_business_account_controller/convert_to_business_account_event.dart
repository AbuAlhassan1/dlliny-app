part of 'convert_to_business_account_bloc.dart';

sealed class ConvertToBusinessAccountEvent {}

class SendConvertToBusinessAccountRequest extends ConvertToBusinessAccountEvent {
  final String companyName;
  final String description;

  SendConvertToBusinessAccountRequest({
    required this.companyName,
    required this.description,
  });
}

class CheckingIfUserHasBusinessAccountRequest extends ConvertToBusinessAccountEvent {}