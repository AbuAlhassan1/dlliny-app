part of 'follow_requests_bloc.dart';

sealed class FollowRequestsEvent {}

class GetFollowRequests extends FollowRequestsEvent {}

class AcceptFollowRequest extends FollowRequestsEvent {
  final String userId;
  AcceptFollowRequest(this.userId);
}

class RejectFollowRequest extends FollowRequestsEvent {
  final String userId;
  RejectFollowRequest(this.userId);
}
