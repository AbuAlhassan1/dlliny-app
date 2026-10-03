import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/request/create_post_request.dart';
import 'package:hangout/domain/dto/response/post_response.dart';
import 'package:hangout/domain/dto/response/search_response.dart';
import 'package:hangout/helper/get_mime_type_from_file.dart';
import 'package:hangout/presentation/shared/utils/file_media_aspect.dart';

part 'create_post_event.dart';
part 'create_post_state.dart';

class CreatePostBloc extends Bloc<CreatePostEvent, CreatePostState> {
  final ApiService apiService = serviceLocator.get<ApiService>();

  CreatePostBloc() : super(CreatePostInitial()) {
    on<CreatePostEvent>((event, emit) {});

    on<AddNewPost>((event, emit) async {
      log('AddNewPost: start. files=${event.files?.length ?? 0} '
          'caption.len=${event.body.caption?.length ?? 0} '
          'mentionedUsers=${event.body.mentionedUserIds} '
          'mentionedVenues=${event.body.mentionedVenueIds} '
          'asVenueId=${event.asVenueId}');
      emit(CreatePostLoading());

      final venueId = event.asVenueId;

      List<PostMediaItem> media = [];

      if (event.files != null) {
        try {
          for (int i = 0; i < event.files!.length; i++) {
            final file = event.files![i];
            log('AddNewPost: file[$i] path=${file.path}');
            final String contentType = contentTypeFromFile(file);
            log('AddNewPost: file[$i] contentType=$contentType');

            log('AddNewPost: file[$i] requesting upload URL…');
            final urlResp = venueId != null
                ? await apiService.getVenuePostMediaUploadUrl(venueId, contentType)
                : await apiService.getPostMediaUploadUrl(contentType);
            final uploadUrl = urlResp.data!.uploadUrl;
            final key = urlResp.data!.key;
            log('AddNewPost: file[$i] got key=$key');

            final mediaType = mediaTypeFromContentType(contentType);
            final aspectRatio = await readFileMediaAspect(file, mediaType);

            media.add(
              PostMediaItem(
                key: key,
                mediaType: mediaType,
                sortOrder: i,
                aspectRatio: aspectRatio,
              ),
            );

            final length = await file.length();
            log('AddNewPost: file[$i] length=$length → streaming PUT to S3');

            await Dio().put(
              uploadUrl,
              data: file.openRead(),
              options: Options(
                headers: {
                  'Content-Type': contentType,
                  'Content-Length': length,
                },
              ),
            );
            log('AddNewPost: file[$i] S3 PUT done');
          }
        } on DioException catch (e) {
          log('AddNewPost: DioException during media upload: ${e.message} '
              'response=${e.response?.statusCode} ${e.response?.data}');
          if (emit.isDone) return;
          emit(CreatePostError('Failed to upload media: ${e.message}'));
          return;
        } catch (e, st) {
          log('AddNewPost: unexpected exception during media upload: $e\n$st');
          if (emit.isDone) return;
          emit(CreatePostError('Failed to upload media: $e'));
          return;
        }
        if (emit.isDone) return;
      }

      log('AddNewPost: building CreatePostRequest. media.length=${media.length}');
      final body = CreatePostRequest(
        caption: event.body.caption,
        media: media.isEmpty ? null : media,
        mentionedUserIds: event.body.mentionedUserIds,
        mentionedVenueIds: event.body.mentionedVenueIds,
        isProduct: event.body.isProduct,
        price: event.body.price,
      );

      ApiResponse<PostResponse>? createPostResponse;

      log('AddNewPost: calling createPost…');
      try{
        createPostResponse = venueId != null
            ? await apiService.createVenuePost(venueId, body)
            : await apiService.createPost(body);
      } on DioException catch (e) {
        log('AddNewPost: DioException on createPost: ${e.message} '
            'response=${e.response?.statusCode} ${e.response?.data}');
        if (emit.isDone) return;
        emit(CreatePostError('Failed to create post: ${e.message}'));
        return;
      } catch (e, st) {
        log('AddNewPost: unexpected exception on createPost: $e\n$st');
        if (emit.isDone) return;
        emit(CreatePostError('Failed to create post: $e'));
        return;
      }
      if (emit.isDone) return;

      log('AddNewPost: createPost returned. success=${createPostResponse.success} '
          'error=${createPostResponse.error} hasData=${createPostResponse.data != null}');

      if (createPostResponse.success && createPostResponse.data != null) {
        emit(CreatePostSuccess());
        return;
      } else {
        emit(CreatePostError('Failed to create post: ${createPostResponse.error}'));
        return;
      }
    });
  
    on<SearchToMention> ((event, emit) async {
      emit(SearchToMentionLoading());
      ApiResponse<SearchResultResponse> response;

      try{
        response = await apiService.search(event.query);
      } on DioException catch (e) {
        if (emit.isDone) return;
        emit(SearchToMentionError('Search failed: ${e.message}'));
        return;
      }
      if (emit.isDone) return;

      if (response.success && response.data != null) {
        emit(SearchToMentionSuccess(response.data!));
        return;
      } else {
        emit(SearchToMentionError('Search failed: ${response.error}'));
        return;
      }

    });
  }
}
