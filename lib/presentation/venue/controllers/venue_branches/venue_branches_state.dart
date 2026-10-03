part of 'venue_branches_bloc.dart';

sealed class VenueBranchesState {
  const VenueBranchesState();
}

final class VenueBranchesInitial extends VenueBranchesState {
  const VenueBranchesInitial();
}

final class VenueBranchesLoading extends VenueBranchesState {
  const VenueBranchesLoading();
}

final class VenueBranchesLoaded extends VenueBranchesState {
  const VenueBranchesLoaded();
}

final class VenueBranchesError extends VenueBranchesState {
  final String message;
  const VenueBranchesError(this.message);
}

final class VenueBranchOperating extends VenueBranchesState {
  const VenueBranchOperating();
}

final class VenueBranchOperated extends VenueBranchesState {
  const VenueBranchOperated();
}

final class VenueBranchOperationError extends VenueBranchesState {
  final String message;
  const VenueBranchOperationError(this.message);
}
