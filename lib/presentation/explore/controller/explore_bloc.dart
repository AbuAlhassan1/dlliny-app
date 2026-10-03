import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'explore_event.dart';
part 'explore_state.dart';

class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  ExploreBloc() : super(ExploreInitial()) {
    on<ExploreEvent>((event, emit) {});
  } 
}

class PlaceModel {
  final String name;
  final String description;
  final double rating;
  final int followers;
  final int visits;
  final bool isFollowed;
  final bool isVisited;
  final String url;
  final String image;
  final double lat;
  final double lng;

  PlaceModel({
    required this.name,
    required this.description,
    required this.rating,
    required this.followers,
    required this.visits,
    required this.isFollowed,
    required this.isVisited,
    required this.url,
    required this.image,
    required this.lat,
    required this.lng,
  });
}