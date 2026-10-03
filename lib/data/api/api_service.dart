import 'package:dio/dio.dart';
import 'package:hangout/domain/dto/dto.dart';
import 'package:hangout/domain/dto/response/staff_response.dart';
import 'package:retrofit/retrofit.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: 'https://api.dlliny.com')
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @POST('/api/v1/auth/otp/send')
  Future<ApiResponse<dynamic>> sendOtp(@Body() SendOtpRequest request);

  @POST('/api/v1/auth/otp/verify')
  Future<ApiResponse<AuthResponse>> verifyOtp(@Body() VerifyOtpRequest request);

  @POST('/api/v1/auth/google')
  Future<ApiResponse<AuthResponse>> signInWithGoogle(
    @Body() GoogleSignInRequest request,
  );

  @POST('/api/v1/auth/apple')
  Future<ApiResponse<AuthResponse>> signInWithApple(
    @Body() AppleSignInRequest request,
  );

  @POST('/api/v1/auth/token/refresh')
  Future<ApiResponse<AuthResponse>> refreshToken(
    @Header('X-Refresh-Token') String refreshToken,
  );

  @POST('/api/v1/auth/logout')
  Future<ApiResponse<dynamic>> logout(
    @Header('X-Refresh-Token') String refreshToken,
  );

  @GET('/api/v1/users/me')
  Future<ApiResponse<UserDto>> getMyProfile();

  @GET('/api/v1/users/me/access')
  Future<ApiResponse<UserAccessResponse>> getMyAccess();

  @GET('/api/v1/users/{username}')
  Future<ApiResponse<UserDto>> getUserProfile(
    @Path('username') String username,
  );

  @GET('/api/v1/users/username/{username}/available')
  Future<ApiResponse<bool>> checkUsernameAvailable(
    @Path('username') String username,
  );

  @GET('/api/v1/users/username/{username}/availability')
  Future<ApiResponse<UsernameAvailabilityResponse>> checkUsernameAvailability(
    @Path('username') String username,
  );

  @POST('/api/v1/users/me/complete-profile')
  Future<ApiResponse<UserDto>> completeProfile(
    @Body() CompleteProfileRequest request,
  );

  @PATCH('/api/v1/users/me')
  Future<ApiResponse<UserDto>> updateProfile(
    @Body() UpdateProfileRequest request,
  );

  @PATCH('/api/v1/users/me/username')
  Future<ApiResponse<UserDto>> changeMyUsername(
    @Body() UpdateUsernameRequest request,
  );

  @GET('/api/v1/users/me/avatar/upload-url')
  Future<ApiResponse<UploadUrlResponse>> getAvatarUploadUrl(
    @Query('contentType') String contentType,
  );

  @PUT('/api/v1/users/me/avatar')
  Future<ApiResponse<dynamic>> confirmAvatarUpload(@Query('key') String key);

  @GET('/api/v1/users/me/cover/upload-url')
  Future<ApiResponse<UploadUrlResponse>> getCoverUploadUrl(
    @Query('contentType') String contentType,
  );

  @PUT('/api/v1/users/me/cover')
  Future<ApiResponse<dynamic>> confirmCoverUpload(@Query('key') String key);

  @POST('/api/v1/users/{userId}/follow')
  Future<ApiResponse<FollowActionResponse>> followUser(
    @Path('userId') String userId,
  );

  @DELETE('/api/v1/users/{userId}/follow')
  Future<ApiResponse<dynamic>> unfollowUser(@Path('userId') String userId);

  @GET('/api/v1/users/me/follow-requests')
  Future<ApiResponse<PagedResponse<UserSummaryResponse>>> getMyFollowRequests({
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @POST('/api/v1/users/me/follow-requests/{userId}/accept')
  Future<ApiResponse<dynamic>> acceptFollowRequest(
    @Path('userId') String userId,
  );

  @POST('/api/v1/users/me/follow-requests/{userId}/reject')
  Future<ApiResponse<dynamic>> rejectFollowRequest(
    @Path('userId') String userId,
  );

  @GET('/api/v1/users/me/followers')
  Future<ApiResponse<PagedResponse<UserSummaryResponse>>> getMyFollowers({
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @GET('/api/v1/users/me/following')
  Future<ApiResponse<PagedResponse<UserSummaryResponse>>> getMyFollowing({
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @POST('/api/v1/users/{userId}/block')
  Future<ApiResponse<dynamic>> blockUser(@Path('userId') String userId);

  @DELETE('/api/v1/users/{userId}/block')
  Future<ApiResponse<dynamic>> unblockUser(@Path('userId') String userId);

  @GET('/api/v1/users/blocked')
  Future<ApiResponse<List<UserDto>>> getBlockedUsers();

  @GET('/api/v1/posts/media/upload-url')
  Future<ApiResponse<PostMediaUploadResponse>> getPostMediaUploadUrl(
    @Query('contentType') String contentType,
  );

  @POST('/api/v1/posts')
  Future<ApiResponse<PostResponse>> createPost(
    @Body() CreatePostRequest request,
  );

  @GET('/api/v1/posts/{postId}')
  Future<ApiResponse<PostResponse>> getPost(@Path('postId') String postId);

  @DELETE('/api/v1/posts/{postId}')
  Future<ApiResponse<dynamic>> deletePost(@Path('postId') String postId);

  @GET('/api/v1/posts/me')
  Future<ApiResponse<PagedResponse<PostResponse>>> getMyPosts({
    @Query('page') int? page,
    @Query('size') int? size,
  });

  @GET('/api/v1/posts/users/{userId}')
  Future<ApiResponse<PagedResponse<PostResponse>>> getUserPosts(
    @Path('userId') String userId, {
    @Query('page') int? page,
    @Query('size') int? size,
  });

  @POST('/api/v1/posts/{postId}/likes')
  Future<ApiResponse<dynamic>> likePost(@Path('postId') String postId);

  @DELETE('/api/v1/posts/{postId}/likes')
  Future<ApiResponse<dynamic>> unlikePost(@Path('postId') String postId);

  @GET('/api/v1/posts/{postId}/comments')
  Future<ApiResponse<PagedResponse<CommentResponse>>> getComments(
    @Path('postId') String postId, {
    @Query('page') int? page,
    @Query('size') int? size,
  });

  @GET('/api/v1/posts/{postId}/comments/{commentId}/replies')
  Future<ApiResponse<PagedResponse<CommentResponse>>> getCommentReplies(
    @Path('postId') String postId,
    @Path('commentId') String commentId, {
    @Query('page') int? page,
    @Query('size') int? size,
  });

  @POST('/api/v1/posts/{postId}/comments')
  Future<ApiResponse<CommentResponse>> addComment(
    @Path('postId') String postId,
    @Body() CreateCommentRequest request,
  );

  @DELETE('/api/v1/posts/{postId}/comments/{commentId}')
  Future<ApiResponse<dynamic>> deleteComment(
    @Path('postId') String postId,
    @Path('commentId') String commentId,
  );

  @POST('/api/v1/posts/{postId}/reports')
  Future<ApiResponse<dynamic>> reportPost(
    @Path('postId') String postId,
    @Body() ReportPostRequest request,
  );

  @GET('/api/v1/posts/reports/categories')
  Future<ApiResponse<List<ReportCategoryResponse>>> getPostReportCategories();

  @GET('/api/v1/locations/cities')
  Future<ApiResponse<List<CityDto>>> getCities();

  @GET('/api/v1/locations/cities/{cityId}/districts')
  Future<ApiResponse<List<DistrictDto>>> getCityDistricts(
    @Path('cityId') int cityId,
  );

  @GET('/api/v1/locations/cities-with-districts')
  Future<ApiResponse<List<CityWithDistrictsDto>>> getCitiesWithDistricts();

  @GET('/api/v1/venues/{venueId}')
  Future<ApiResponse<VenueResponse>> getVenue(@Path('venueId') String venueId);

  @GET('/api/v1/venues/handle/{handle}')
  Future<ApiResponse<VenueResponse>> getVenueByHandle(
    @Path('handle') String handle,
  );

  @GET('/api/v1/venues/handle/{handle}/availability')
  Future<ApiResponse<HandleAvailabilityResponse>> checkVenueHandleAvailability(
    @Path('handle') String handle,
  );

  @GET('/api/v1/venues')
  Future<ApiResponse<PagedResponse<VenueSummaryResponse>>> getVenues({
    @Query('q') String? q,
    @Query('categoryId') int? categoryId,
    @Query('cityId') int? cityId,
    @Query('districtId') int? districtId,
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @GET('/api/v1/venues/nearby')
  Future<ApiResponse<List<VenueSummaryResponse>>> getNearbyVenues(
    @Query('lat') double lat,
    @Query('lng') double lng, {
    @Query('radiusMeters') int? radiusMeters,
    @Query('limit') int? limit,
  });

  @GET('/api/v1/venues/district/{district}')
  Future<ApiResponse<List<VenueSummaryResponse>>> getVenuesByDistrict(
    @Path('district') String district,
  );

  @GET('/api/v1/venues/categories')
  Future<ApiResponse<List<VenueCategoryDto>>> getVenueCategories();

  @POST('/api/v1/venues/{venueId}/follow')
  Future<ApiResponse<dynamic>> followVenue(@Path('venueId') String venueId);

  @DELETE('/api/v1/venues/{venueId}/follow')
  Future<ApiResponse<dynamic>> unfollowVenue(@Path('venueId') String venueId);

  @GET('/api/v1/venues/followed')
  Future<ApiResponse<List<VenueSummaryResponse>>> getFollowedVenues();

  @GET('/api/v1/venues/service-types')
  Future<ApiResponse<List<VenueServiceTypeDto>>> getVenueServiceTypes();

  @GET('/api/v1/venues/{venueId}/services')
  Future<ApiResponse<List<VenueServiceItemDto>>> getVenueServices(
    @Path('venueId') String venueId,
  );

  @GET('/api/v1/venues/{venueId}/announcements')
  Future<ApiResponse<PagedResponse<VenueAnnouncementDto>>> getVenueAnnouncements(
    @Path('venueId') String venueId, {
    @Query('page') int? page,
    @Query('size') int? size,
  });

  @GET('/api/v1/venues/{venueId}/menu')
  Future<ApiResponse<List<MenuSectionDto>>> getVenueMenu(
    @Path('venueId') String venueId,
  );

  @GET('/api/v1/venues/{venueId}/hours')
  Future<ApiResponse<VenueOpeningHoursDto>> getVenueOpeningHours(
    @Path('venueId') String venueId,
  );

  @GET('/api/v1/venues/{venueId}/gallery')
  Future<ApiResponse<List<GalleryPhotoDto>>> listVenueGallery(
    @Path('venueId') String venueId, {
    @Query('tag') String? tag,
    @Query('locationId') String? locationId,
  });

  @GET('/api/v1/venues/{venueId}/locations')
  Future<ApiResponse<List<VenueLocationResponse>>> getVenueLocations(
    @Path('venueId') String venueId,
  );

  @GET('/api/v1/business/venues/{venueId}/locations')
  Future<ApiResponse<List<VenueLocationResponse>>>
      getBusinessVenueLocations(
    @Path('venueId') String venueId,
  );

  @POST('/api/v1/business/venues/{venueId}/locations')
  Future<ApiResponse<VenueLocationResponse>> addVenueLocation(
    @Path('venueId') String venueId,
    @Body() CreateVenueLocationRequest request,
  );

  @PUT('/api/v1/business/venues/{venueId}/locations/{locationId}')
  Future<ApiResponse<VenueLocationResponse>> updateVenueLocation(
    @Path('venueId') String venueId,
    @Path('locationId') String locationId,
    @Body() UpdateVenueLocationRequest request,
  );

  @DELETE('/api/v1/business/venues/{venueId}/locations/{locationId}')
  Future<ApiResponse<dynamic>> deleteVenueLocation(
    @Path('venueId') String venueId,
    @Path('locationId') String locationId,
  );

  @POST('/api/v1/hangouts')
  Future<ApiResponse<HangoutResponse>> createHangout(
    @Body() CreateHangoutRequest request,
  );

  @GET('/api/v1/hangouts/{hangoutId}')
  Future<ApiResponse<HangoutResponse>> getHangout(
    @Path('hangoutId') String hangoutId,
  );

  @GET('/api/v1/hangouts/invite/{inviteLink}')
  Future<ApiResponse<HangoutResponse>> getHangoutByInviteLink(
    @Path('inviteLink') String inviteLink,
  );

  @GET('/api/v1/hangouts/me')
  Future<ApiResponse<List<HangoutResponse>>> getMyHangouts();

  @GET('/api/v1/hangouts/me/cancelled')
  Future<ApiResponse<List<HangoutResponse>>> getMyCancelledHangouts();

  @GET('/api/v1/hangouts/me/awaiting-review')
  Future<ApiResponse<PendingVenueReviewResponse?>> getAwaitingVenueReview();

  @GET('/api/v1/hangouts/me/recent-attended')
  Future<ApiResponse<List<HangoutResponse>>> getMyRecentAttendedHangouts();

  @GET('/api/v1/hangouts/me/hub')
  Future<ApiResponse<PagedHangoutFeedResponse>> getMyHangoutsHub({
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @GET('/api/v1/hangouts/me/upcoming')
  Future<ApiResponse<PagedHangoutFeedResponse>> getMyUpcomingHangouts({
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @GET('/api/v1/hangouts/users/{userId}')
  Future<ApiResponse<PagedResponse<HangoutResponse>>> getUserHangouts(
    @Path('userId') String userId, {
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @PATCH('/api/v1/hangouts/{hangoutId}/cancel')
  Future<ApiResponse<dynamic>> cancelHangout(
    @Path('hangoutId') String hangoutId,
  );

  @DELETE('/api/v1/hangouts/{hangoutId}')
  Future<ApiResponse<dynamic>> softDeleteHangout(
    @Path('hangoutId') String hangoutId,
  );

  @POST('/api/v1/hangouts/{hangoutId}/invite')
  Future<ApiResponse<dynamic>> inviteUsers(
    @Path('hangoutId') String hangoutId,
    @Body() InviteRequest request,
  );

  @GET('/api/v1/hangouts/invitations')
  Future<ApiResponse<List<InvitationResponse>>> getMyInvitations();

  @PATCH('/api/v1/hangouts/invitations/{invitationId}/respond')
  Future<ApiResponse<dynamic>> respondToInvitation(
    @Path('invitationId') String invitationId,
    @Body() RespondInvitationRequest request,
  );

  @POST('/api/v1/hangouts/{hangoutId}/join')
  Future<ApiResponse<dynamic>> joinHangout(
    @Path('hangoutId') String hangoutId,
  );

  @POST('/api/v1/hangouts/{hangoutId}/leave')
  Future<ApiResponse<dynamic>> leaveHangout(
    @Path('hangoutId') String hangoutId,
  );

  @GET('/api/v1/hangouts/{hangoutId}/media')
  Future<ApiResponse<List<HangoutMediaResponse>>> getHangoutMedia(
    @Path('hangoutId') String hangoutId,
  );

  @GET('/api/v1/hangouts/{hangoutId}/media/upload-url')
  Future<ApiResponse<MediaUploadUrlResponse>> getHangoutMediaUploadUrl(
    @Path('hangoutId') String hangoutId,
    @Query('contentType') String contentType,
  );

  @POST('/api/v1/hangouts/{hangoutId}/media/confirm')
  Future<ApiResponse<HangoutMediaResponse>> confirmHangoutMedia(
    @Path('hangoutId') String hangoutId,
    @Body() ConfirmHangoutMediaRequest request,
  );

  @DELETE('/api/v1/hangouts/{hangoutId}/media/{mediaId}')
  Future<ApiResponse<dynamic>> deleteHangoutMedia(
    @Path('hangoutId') String hangoutId,
    @Path('mediaId') String mediaId,
  );

  @POST('/api/v1/hangouts/{hangoutId}/likes')
  Future<ApiResponse<dynamic>> likeHangout(
    @Path('hangoutId') String hangoutId,
  );

  @DELETE('/api/v1/hangouts/{hangoutId}/likes')
  Future<ApiResponse<dynamic>> unlikeHangout(
    @Path('hangoutId') String hangoutId,
  );

  @POST('/api/v1/hangouts/{hangoutId}/reports')
  Future<ApiResponse<dynamic>> reportHangout(
    @Path('hangoutId') String hangoutId,
    @Body() ReportHangoutRequest request,
  );

  @GET('/api/v1/hangouts/{hangoutId}/comments')
  Future<ApiResponse<PagedResponse<HangoutCommentResponse>>>
      getHangoutComments(
    @Path('hangoutId') String hangoutId, {
    @Query('page') int? page,
    @Query('size') int? size,
  });

  @GET('/api/v1/hangouts/{hangoutId}/comments/{commentId}/replies')
  Future<ApiResponse<PagedResponse<HangoutCommentResponse>>>
      getHangoutCommentReplies(
    @Path('hangoutId') String hangoutId,
    @Path('commentId') String commentId, {
    @Query('page') int? page,
    @Query('size') int? size,
  });

  @POST('/api/v1/hangouts/{hangoutId}/comments')
  Future<ApiResponse<HangoutCommentResponse>> addHangoutComment(
    @Path('hangoutId') String hangoutId,
    @Body() CreateCommentRequest request,
  );

  @DELETE('/api/v1/hangouts/{hangoutId}/comments/{commentId}')
  Future<ApiResponse<dynamic>> deleteHangoutComment(
    @Path('hangoutId') String hangoutId,
    @Path('commentId') String commentId,
  );

  @POST('/api/v1/reviews')
  Future<ApiResponse<ReviewResponse>> createReview(
    @Body() CreateReviewRequest request,
  );

  @GET('/api/v1/reviews/venue/{venueId}')
  Future<ApiResponse<List<ReviewResponse>>> getVenueReviews(
    @Path('venueId') String venueId,
  );

  @GET('/api/v1/reviews/venue/{venueId}/me')
  Future<ApiResponse<ReviewResponse>> getMyReviewForVenue(
    @Path('venueId') String venueId,
  );

  @DELETE('/api/v1/reviews/{reviewId}')
  Future<ApiResponse<dynamic>> deleteReview(@Path('reviewId') String reviewId);

  @GET('/api/v1/feed/following')
  Future<ApiResponse<FollowingFeedResponse>> getFollowingFeed({
    @Query('cursor') String? cursor,
    @Query('page') int? page,
    @Query('size') int? size,
  });

  @GET('/api/v1/feed/for-you')
  Future<ApiResponse<PagedFeedResponse>> getForYouFeed({
    @Query('cursor') String? cursor,
    @Query('page') int? page,
    @Query('size') int? size,
  });

  @GET('/api/v1/feed/reels')
  Future<ApiResponse<PagedFeedResponse>> getReels({
    @Query('cursor') String? cursor,
    @Query('page') int? page,
    @Query('size') int? size,
  });

  @GET('/api/v1/feed/explore')
  Future<ApiResponse<PagedFeedResponse>> getExplore({
    @Query('cursor') String? cursor,
    @Query('page') int? page,
    @Query('size') int? size,
  });

  @GET('/api/v1/vibe-tags')
  Future<ApiResponse<List<VibeTagDto>>> getVibeTagCatalog();

  @GET('/api/v1/users/me/vibe-affinities')
  Future<ApiResponse<MyVibeProfileResponse>> getMyVibeProfile();

  @POST('/api/v1/users/me/vibe-affinities/onboarding')
  Future<ApiResponse<MyVibeProfileResponse>> setOnboardingVibes(
    @Body() OnboardingVibesRequest request,
  );

  @POST('/api/v1/users/me/vibe-affinities/recompute')
  Future<ApiResponse<MyVibeProfileResponse>> recomputeMyVibeAffinities();

  @GET('/api/v1/map/venues')
  Future<ApiResponse<List<MapVenuePinResponse>>> getMapVenuePins(
    @Query('lat') double lat,
    @Query('lng') double lng, {
    @Query('radiusMeters') int? radiusMeters,
    @Query('categoryId') int? categoryId,
    @Query('cityId') int? cityId,
    @Query('districtId') int? districtId,
    @Query('hasUpcomingHangouts') bool? hasUpcomingHangouts,
  });

  @GET('/api/v1/map/hangouts')
  Future<ApiResponse<List<MapHangoutPinResponse>>> getMapHangoutPins(
    @Query('lat') double lat,
    @Query('lng') double lng, {
    @Query('radiusMeters') int? radiusMeters,
  });

  @GET('/api/v1/recommendations/shake')
  Future<ApiResponse<ShakeRecommendationResponse>> getShakeRecommendations(
    @Query('mode') String mode,
    @Query('lat') double lat,
    @Query('lng') double lng, {
    @Query('includeFar') bool includeFar = false,
    @Query('excludeIds') List<String>? excludeIds,
  });

  @GET('/api/v1/recommendations/shake/random')
  Future<ApiResponse<ShakeRecommendationResponse>> getShakeRandomRecommendations(
    @Query('lat') double lat,
    @Query('lng') double lng, {
    @Query('includeFar') bool includeFar = false,
    @Query('excludeIds') List<String>? excludeIds,
  });

  @GET('/api/v1/venues/featured')
  Future<ApiResponse<List<FeaturedCollectionResponse>>> getFeaturedCollections({
    @Query('cityId') int? cityId,
  });

  @GET('/api/v1/venues/trending')
  Future<ApiResponse<List<TrendingVenueResponse>>> getTrendingVenues({
    @Query('cityId') int? cityId,
    @Query('limit') int limit = 20,
  });

  @GET('/api/v1/users/me/recommendations/weekly')
  Future<ApiResponse<WeeklyRecommendationsResponse>> getMyWeeklyRecommendations();

  @POST('/api/v1/users/me/recommendations/weekly/recompute')
  Future<ApiResponse<WeeklyRecommendationsResponse>> recomputeMyWeeklyRecommendations();

  @GET('/api/v1/intents')
  Future<ApiResponse<List<IntentResponse>>> getIntents();

  @GET('/api/v1/intents/{code}/venues')
  Future<ApiResponse<IntentVenuesResponse>> getVenuesForIntent(
    @Path('code') String code, {
    @Query('cityId') int? cityId,
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @GET('/api/v1/search')
  Future<ApiResponse<SearchResultResponse>> search(
    @Query('q') String q, {
    @Query('limit') int? limit,
  });

  @GET('/api/v1/notifications')
  Future<ApiResponse<PagedResponse<NotificationResponse>>> getNotifications({
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @GET('/api/v1/notifications/unread-count')
  Future<ApiResponse<UnreadCountResponse>> getUnreadCount();

  @POST('/api/v1/notifications/{notificationId}/read')
  Future<ApiResponse<dynamic>> markNotificationRead(
    @Path('notificationId') String notificationId,
  );

  @POST('/api/v1/notifications/mark-all-read')
  Future<ApiResponse<dynamic>> markAllNotificationsRead();

  @PUT('/api/v1/notifications/fcm-token')
  Future<ApiResponse<dynamic>> registerFcmToken(
    @Body() RegisterFcmTokenRequest request,
  );

  @POST('/api/v1/notifications/topics/{topic}/subscribe')
  Future<ApiResponse<dynamic>> subscribeToTopic(@Path('topic') String topic);

  @DELETE('/api/v1/notifications/topics/{topic}/unsubscribe')
  Future<ApiResponse<dynamic>> unsubscribeFromTopic(
    @Path('topic') String topic,
  );

  @POST('/api/v1/users/me/business-request')
  Future<ApiResponse<BusinessRequestResponse>> submitBusinessRequest(
    @Body() SubmitBusinessRequest request,
  );

  @GET('/api/v1/users/me/business-request')
  Future<ApiResponse<BusinessRequestResponse>> getMyBusinessRequest();

  @GET('/api/v1/business/accounts')
  Future<ApiResponse<List<BusinessAccountResponse>>> getMyBusinessAccounts();

  @GET('/api/v1/business/accounts/{businessId}/venues')
  Future<ApiResponse<List<BusinessVenueResponse>>> getBusinessVenues(
    @Path('businessId') String businessId,
  );

  @POST('/api/v1/business/accounts/{businessId}/venues')
  Future<ApiResponse<BusinessVenueResponse>> createBusinessVenue(
    @Path('businessId') String businessId,
    @Body() CreateBusinessVenueRequest request,
  );

  @PUT('/api/v1/business/accounts/{businessId}/venues/{venueId}')
  Future<ApiResponse<BusinessVenueResponse>> updateBusinessVenue(
    @Path('businessId') String businessId,
    @Path('venueId') String venueId,
    @Body() UpdateBusinessVenueRequest request,
  );

  @GET('/api/v1/subscriptions/tiers')
  Future<ApiResponse<List<SubscriptionTierResponse>>> getSubscriptionTiers();

  @GET('/api/v1/subscriptions/me')
  Future<ApiResponse<List<MySubscriptionResponse>>> getMySubscriptions();

  @GET('/api/v1/permissions/catalog')
  Future<ApiResponse<List<PermissionCatalogEntry>>> getPermissionsCatalog();

  @GET('/api/v1/business/venues')
  Future<ApiResponse<List<BusinessVenueResponse>>> getMyBusinessVenues();

  @POST('/api/v1/business/venues')
  Future<ApiResponse<BusinessVenueResponse>> createMyBusinessVenue(
    @Body() CreateBusinessVenueRequest request,
  );

  @PUT('/api/v1/business/venues/{venueId}')
  Future<ApiResponse<BusinessVenueResponse>> updateMyBusinessVenue(
    @Path('venueId') String venueId,
    @Body() UpdateBusinessVenueRequest request,
  );

  @PATCH('/api/v1/business/venues/{venueId}/handle')
  Future<ApiResponse<BusinessVenueResponse>> changeVenueHandle(
    @Path('venueId') String venueId,
    @Body() UpdateVenueHandleRequest request,
  );

  @GET('/api/v1/business/venues/{venueId}/conversion-impact')
  Future<ApiResponse<VenueConversionImpactResponse>>
      getBusinessVenueConversionImpact(@Path('venueId') String venueId);

  @GET('/api/v1/business/venues/{venueId}/hours')
  Future<ApiResponse<BusinessVenueHoursResponse>> businessGetVenueHours(
    @Path('venueId') String venueId,
  );

  @PUT('/api/v1/business/venues/{venueId}/hours')
  Future<ApiResponse<BusinessVenueHoursResponse>> businessUpdateVenueHours(
    @Path('venueId') String venueId,
    @Body() UpdateVenueHoursRequest body,
  );

  @DELETE('/api/v1/business/venues/{venueId}/hours')
  Future<ApiResponse<BusinessVenueHoursResponse>> businessClearVenueHours(
    @Path('venueId') String venueId,
  );

  @PUT('/api/v1/business/venues/{venueId}/locations/{locationId}/hours')
  Future<ApiResponse<BusinessVenueHoursResponse>> businessUpdateBranchHours(
    @Path('venueId') String venueId,
    @Path('locationId') String locationId,
    @Body() UpdateBranchHoursRequest body,
  );

  @PUT('/api/v1/business/venues/{venueId}/operating-status')
  Future<ApiResponse<BusinessVenueHoursResponse>>
      businessUpdateVenueOperatingStatus(
    @Path('venueId') String venueId,
    @Body() UpdateOperatingStatusRequest body,
  );

  @PUT(
    '/api/v1/business/venues/{venueId}/locations/{locationId}/operating-status',
  )
  Future<ApiResponse<BusinessVenueHoursResponse>>
      businessUpdateBranchOperatingStatus(
    @Path('venueId') String venueId,
    @Path('locationId') String locationId,
    @Body() UpdateBranchOperatingStatusRequest body,
  );

  @GET('/api/v1/business/venues/{venueId}/gallery')
  Future<ApiResponse<BusinessGalleryResponse>> businessListGallery(
    @Path('venueId') String venueId,
  );

  @GET('/api/v1/business/venues/{venueId}/gallery/upload-url')
  Future<ApiResponse<GalleryUploadUrlResponse>> businessGetGalleryUploadUrl(
    @Path('venueId') String venueId,
    @Query('contentType') String contentType,
    @Query('contentLength') int contentLength,
  );

  @POST('/api/v1/business/venues/{venueId}/gallery')
  Future<ApiResponse<GalleryPhotoDto>> businessAttachGalleryPhoto(
    @Path('venueId') String venueId,
    @Body() AttachGalleryPhotoRequest body,
  );

  @PATCH('/api/v1/business/venues/{venueId}/gallery/{photoId}')
  Future<ApiResponse<GalleryPhotoDto>> businessUpdateGalleryPhoto(
    @Path('venueId') String venueId,
    @Path('photoId') String photoId,
    @Body() UpdateGalleryPhotoRequest body,
  );

  @PUT('/api/v1/business/venues/{venueId}/gallery/order')
  Future<ApiResponse<BusinessGalleryResponse>> businessReorderGallery(
    @Path('venueId') String venueId,
    @Body() ReorderGalleryRequest body,
  );

  @DELETE('/api/v1/business/venues/{venueId}/gallery/{photoId}')
  Future<ApiResponse<dynamic>> businessDeleteGalleryPhoto(
    @Path('venueId') String venueId,
    @Path('photoId') String photoId,
  );

  @GET('/api/v1/business/venues/{venueId}/logo/upload-url')
  Future<ApiResponse<VenueMediaUploadResponse>> getVenueLogoUploadUrl(
    @Path('venueId') String venueId,
    @Query('contentType') String contentType,
  );

  @POST('/api/v1/business/venues/{venueId}/logo')
  Future<ApiResponse<BusinessVenueResponse>> confirmVenueLogo(
    @Path('venueId') String venueId,
    @Query('key') String key,
  );

  @DELETE('/api/v1/business/venues/{venueId}/logo')
  Future<ApiResponse<BusinessVenueResponse>> deleteVenueLogo(
    @Path('venueId') String venueId,
  );

  @GET('/api/v1/business/venues/{venueId}/cover/upload-url')
  Future<ApiResponse<VenueMediaUploadResponse>> getVenueCoverUploadUrl(
    @Path('venueId') String venueId,
    @Query('contentType') String contentType,
  );

  @POST('/api/v1/business/venues/{venueId}/cover')
  Future<ApiResponse<BusinessVenueResponse>> confirmVenueCover(
    @Path('venueId') String venueId,
    @Query('key') String key,
    @Query('contentType') String contentType,
  );

  @DELETE('/api/v1/business/venues/{venueId}/cover')
  Future<ApiResponse<BusinessVenueResponse>> deleteVenueCover(
    @Path('venueId') String venueId,
  );

  @GET('/api/v1/business/venues/{venueId}/services')
  Future<ApiResponse<List<VenueServiceResponse>>> getMyVenueServices(
    @Path('venueId') String venueId,
  );

  @POST('/api/v1/business/venues/{venueId}/services')
  Future<ApiResponse<VenueServiceResponse>> addVenueService(
    @Path('venueId') String venueId,
    @Body() AddVenueServiceRequest request,
  );

  @PUT('/api/v1/business/venues/{venueId}/services/{serviceId}')
  Future<ApiResponse<VenueServiceResponse>> updateVenueService(
    @Path('venueId') String venueId,
    @Path('serviceId') String serviceId,
    @Body() UpdateVenueServiceRequest request,
  );

  @DELETE('/api/v1/business/venues/{venueId}/services/{serviceId}')
  Future<ApiResponse<dynamic>> deleteVenueService(
    @Path('venueId') String venueId,
    @Path('serviceId') String serviceId,
  );

  @GET('/api/v1/business/venues/{venueId}/services/image-upload-url')
  Future<ApiResponse<ServiceImageUploadResponse>> getVenueServiceImageUploadUrl(
    @Path('venueId') String venueId,
    @Query('contentType') String contentType,
  );

  @POST('/api/v1/orders')
  Future<ApiResponse<OrderResponse>> createOrder(
    @Body() CreateOrderRequest request,
  );

  @GET('/api/v1/orders/me')
  Future<ApiResponse<PagedResponse<OrderSummaryResponse>>> getMyOrders({
    @Query('status') String? status,
    @Query('page') int? page,
    @Query('size') int? size,
  });

  @GET('/api/v1/orders/{orderId}')
  Future<ApiResponse<OrderResponse>> getOrder(
    @Path('orderId') String orderId,
  );

  @POST('/api/v1/orders/{orderId}/cancel')
  Future<ApiResponse<OrderResponse>> cancelOrder(
    @Path('orderId') String orderId,
  );

  @POST('/api/v1/orders/{orderId}/messages')
  Future<ApiResponse<OrderMessageResponse>> sendOrderMessage(
    @Path('orderId') String orderId,
    @Body() SendOrderMessageRequest request,
  );

  @POST('/api/v1/orders/{orderId}/messages/read')
  Future<void> markOrderMessagesRead(@Path('orderId') String orderId);

  @GET('/api/v1/business/venues/{venueId}/orders')
  Future<ApiResponse<PagedResponse<OrderSummaryResponse>>> listVenueOrders(
    @Path('venueId') String venueId, {
    @Query('status') String? status,
    @Query('page') int? page,
    @Query('size') int? size,
  });

  @GET('/api/v1/business/venues/{venueId}/orders/{orderId}')
  Future<ApiResponse<OrderResponse>> getVenueOrder(
    @Path('venueId') String venueId,
    @Path('orderId') String orderId,
  );

  @POST('/api/v1/business/venues/{venueId}/orders/{orderId}/accept')
  Future<ApiResponse<OrderResponse>> acceptOrder(
    @Path('venueId') String venueId,
    @Path('orderId') String orderId,
  );

  @POST('/api/v1/business/venues/{venueId}/orders/{orderId}/reject')
  Future<ApiResponse<OrderResponse>> rejectOrder(
    @Path('venueId') String venueId,
    @Path('orderId') String orderId,
  );

  @POST('/api/v1/business/venues/{venueId}/orders/{orderId}/deliver')
  Future<ApiResponse<OrderResponse>> deliverOrder(
    @Path('venueId') String venueId,
    @Path('orderId') String orderId,
  );

  @POST('/api/v1/business/venues/{venueId}/orders/{orderId}/cancel')
  Future<ApiResponse<OrderResponse>> cancelVenueOrder(
    @Path('venueId') String venueId,
    @Path('orderId') String orderId,
  );

  @POST('/api/v1/business/venues/{venueId}/orders/{orderId}/messages')
  Future<ApiResponse<OrderMessageResponse>> sendVenueOrderMessage(
    @Path('venueId') String venueId,
    @Path('orderId') String orderId,
    @Body() SendOrderMessageRequest request,
  );

  @POST('/api/v1/business/venues/{venueId}/orders/{orderId}/messages/read')
  Future<void> markVenueOrderMessagesRead(
    @Path('venueId') String venueId,
    @Path('orderId') String orderId,
  );

  @GET('/api/v1/business/venues/{venueId}/menu')
  Future<ApiResponse<List<MenuSectionResponse>>> getMyVenueMenu(
    @Path('venueId') String venueId,
  );

  @POST('/api/v1/business/venues/{venueId}/menu/sections')
  Future<ApiResponse<MenuSectionResponse>> createMenuSection(
    @Path('venueId') String venueId,
    @Body() CreateMenuSectionRequest request,
  );

  @PUT('/api/v1/business/venues/{venueId}/menu/sections/{sectionId}')
  Future<ApiResponse<MenuSectionResponse>> updateMenuSection(
    @Path('venueId') String venueId,
    @Path('sectionId') String sectionId,
    @Body() UpdateMenuSectionRequest request,
  );

  @DELETE('/api/v1/business/venues/{venueId}/menu/sections/{sectionId}')
  Future<ApiResponse<void>> deleteMenuSection(
    @Path('venueId') String venueId,
    @Path('sectionId') String sectionId,
  );

  @POST('/api/v1/business/venues/{venueId}/menu/items')
  Future<ApiResponse<MenuItemResponse>> createMenuItem(
    @Path('venueId') String venueId,
    @Body() CreateMenuItemRequest request,
  );

  @PUT('/api/v1/business/venues/{venueId}/menu/items/{itemId}')
  Future<ApiResponse<MenuItemResponse>> updateMenuItem(
    @Path('venueId') String venueId,
    @Path('itemId') String itemId,
    @Body() UpdateMenuItemRequest request,
  );

  @DELETE('/api/v1/business/venues/{venueId}/menu/items/{itemId}')
  Future<ApiResponse<void>> deleteMenuItem(
    @Path('venueId') String venueId,
    @Path('itemId') String itemId,
  );

  @GET('/api/v1/business/venues/{venueId}/menu/items/image-upload-url')
  Future<ApiResponse<MenuItemImageUploadResponse>> getMenuItemImageUploadUrl(
    @Path('venueId') String venueId,
    @Query('contentType') String contentType,
  );

  @GET('/api/v1/business/venues/{venueId}/announcements')
  Future<ApiResponse<PagedResponse<AnnouncementResponse>>> listMyVenueAnnouncements(
    @Path('venueId') String venueId, {
    @Query('page') int? page,
    @Query('size') int? size,
  });

  @POST('/api/v1/business/venues/{venueId}/announcements')
  Future<ApiResponse<AnnouncementResponse>> createAnnouncement(
    @Path('venueId') String venueId,
    @Body() CreateAnnouncementRequest request,
  );

  @PUT('/api/v1/business/venues/{venueId}/announcements/{announcementId}')
  Future<ApiResponse<AnnouncementResponse>> updateAnnouncement(
    @Path('venueId') String venueId,
    @Path('announcementId') String announcementId,
    @Body() UpdateAnnouncementRequest request,
  );

  @DELETE('/api/v1/business/venues/{venueId}/announcements/{announcementId}')
  Future<ApiResponse<void>> deleteAnnouncement(
    @Path('venueId') String venueId,
    @Path('announcementId') String announcementId,
  );

  @GET('/api/v1/business/venue-roles')
  Future<ApiResponse<List<AssignableVenueRole>>> listVenueRoles();

  @GET('/api/v1/business/venues/{venueId}/staff')
  Future<ApiResponse<List<VenueStaffResponse>>> listVenueStaff(
    @Path('venueId') String venueId,
  );

  @PUT('/api/v1/business/venues/{venueId}/staff/{staffUserId}')
  Future<ApiResponse<VenueStaffResponse>> assignVenueStaff(
    @Path('venueId') String venueId,
    @Path('staffUserId') String staffUserId,
    @Body() AssignVenueStaffRequest request,
  );

  @DELETE('/api/v1/business/venues/{venueId}/staff/{staffUserId}')
  Future<ApiResponse<dynamic>> revokeVenueStaff(
    @Path('venueId') String venueId,
    @Path('staffUserId') String staffUserId,
  );

  @GET('/api/v1/business/business-roles')
  Future<ApiResponse<List<BusinessRoleSummary>>> listBusinessRoles();

  @GET('/api/v1/business/businesses/{businessId}/staff')
  Future<ApiResponse<List<BusinessStaffResponse>>> listBusinessStaff(
    @Path('businessId') String businessId,
  );

  @PUT('/api/v1/business/businesses/{businessId}/staff/{staffUserId}')
  Future<ApiResponse<BusinessStaffResponse>> assignBusinessStaff(
    @Path('businessId') String businessId,
    @Path('staffUserId') String staffUserId,
    @Body() AssignBusinessStaffRequest request,
  );

  @DELETE('/api/v1/business/businesses/{businessId}/staff/{staffUserId}')
  Future<ApiResponse<dynamic>> revokeBusinessStaff(
    @Path('businessId') String businessId,
    @Path('staffUserId') String staffUserId,
  );

  @GET('/api/v1/business/venues/{venueId}/posts/media/upload-url')
  Future<ApiResponse<PostMediaUploadResponse>> getVenuePostMediaUploadUrl(
    @Path('venueId') String venueId,
    @Query('contentType') String contentType,
  );

  @POST('/api/v1/business/venues/{venueId}/posts')
  Future<ApiResponse<PostResponse>> createVenuePost(
    @Path('venueId') String venueId,
    @Body() CreatePostRequest request,
  );

  @GET('/api/v1/business/venues/{venueId}/posts')
  Future<ApiResponse<PagedResponse<PostResponse>>> listVenuePosts(
    @Path('venueId') String venueId, {
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @DELETE('/api/v1/business/venues/{venueId}/posts/{postId}')
  Future<ApiResponse<dynamic>> deleteVenuePost(
    @Path('venueId') String venueId,
    @Path('postId') String postId,
  );

  @POST('/api/v1/business/venues/{venueId}/hangouts')
  Future<ApiResponse<HangoutResponse>> createVenueHangout(
    @Path('venueId') String venueId,
    @Body() CreateHangoutRequest request,
  );

  @GET('/api/v1/business/venues/{venueId}/hangouts')
  Future<ApiResponse<List<HangoutResponse>>> listVenueHangouts(
    @Path('venueId') String venueId,
  );

  @DELETE('/api/v1/business/venues/{venueId}/hangouts/{hangoutId}')
  Future<ApiResponse<dynamic>> cancelVenueHangout(
    @Path('venueId') String venueId,
    @Path('hangoutId') String hangoutId,
  );

  @GET('/api/v1/venues/{venueId}/posts')
  Future<ApiResponse<PagedResponse<PostResponse>>> listPublicVenuePosts(
    @Path('venueId') String venueId, {
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @GET('/api/v1/venues/{venueId}/products')
  Future<ApiResponse<PagedResponse<PostResponse>>> listVenueProducts(
    @Path('venueId') String venueId, {
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @GET('/api/v1/venues/{venueId}/hangouts')
  Future<ApiResponse<PagedResponse<HangoutResponse>>> listPublicVenueHangouts(
    @Path('venueId') String venueId, {
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @GET('/api/v1/venues/{venueId}/community')
  Future<ApiResponse<PagedFeedResponse>> getVenueCommunityFeed(
    @Path('venueId') String venueId, {
    @Query('cursor') String? cursor,
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @POST('/api/v1/business/venues/{venueId}/verify')
  Future<ApiResponse<VerificationRequestResponse>> submitVerificationRequest(
    @Path('venueId') String venueId, {
    @Query('documents') String? documents,
  });

  @GET('/api/v1/business/venues/verification-requests')
  Future<ApiResponse<List<VerificationRequestResponse>>>
  getVerificationRequests();

  @POST('/api/v1/business/campaigns')
  Future<ApiResponse<CampaignResponse>> createCampaign(
    @Body() CreateCampaignRequest request,
  );

  @GET('/api/v1/business/campaigns')
  Future<ApiResponse<List<CampaignResponse>>> getMyCampaigns();

  @GET('/api/v1/business/campaigns/media/upload-url')
  Future<ApiResponse<CampaignMediaUploadResponse>> getCampaignMediaUploadUrl(
    @Query('contentType') String contentType,
  );

  @GET('/api/v1/ads')
  Future<ApiResponse<ServedAdResponse>> getAds(
    @Query('placement') String placement, {
    @Query('limit') int limit = 5,
  });

  @POST('/api/v1/ads/{adId}/click')
  Future<ApiResponse<bool>> recordAdClick(
    @Path('adId') String adId,
  );

  @GET('/api/v1/admin/campaigns')
  Future<ApiResponse<PagedResponse<CampaignResponse>>> adminListCampaigns({
    @Query('status') String? status,
    @Query('businessId') String? businessId,
    @Query('venueId') String? venueId,
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @GET('/api/v1/admin/campaigns/pending')
  Future<ApiResponse<List<CampaignResponse>>> adminGetPendingCampaigns();

  @GET('/api/v1/admin/campaigns/{id}')
  Future<ApiResponse<CampaignResponse>> adminGetCampaign(
    @Path('id') String id,
  );

  @POST('/api/v1/admin/campaigns/{id}/approve')
  Future<ApiResponse<dynamic>> adminApproveCampaign(
    @Path('id') String id,
  );

  @POST('/api/v1/admin/campaigns/{id}/reject')
  Future<ApiResponse<dynamic>> adminRejectCampaign(
    @Path('id') String id,
    @Body() Map<String, String> body,
  );

  @POST('/api/v1/admin/campaigns/{id}/pause')
  Future<ApiResponse<CampaignResponse>> adminPauseCampaign(
    @Path('id') String id,
  );

  @POST('/api/v1/admin/campaigns/{id}/resume')
  Future<ApiResponse<CampaignResponse>> adminResumeCampaign(
    @Path('id') String id,
  );

  @POST('/api/v1/admin/campaigns/{id}/force-complete')
  Future<ApiResponse<CampaignResponse>> adminForceCompleteCampaign(
    @Path('id') String id,
  );

  @GET('/api/v1/admin/campaigns/{id}/stats')
  Future<ApiResponse<CampaignStatsResponse>> adminGetCampaignStats(
    @Path('id') String id, {
    @Query('days') int days = 30,
  });

  @POST('/api/v1/admin/featured-collections')
  Future<ApiResponse<FeaturedCollectionResponse>> adminCreateFeaturedCollection(
    @Body() CreateFeaturedCollectionRequest request,
  );

  @GET('/api/v1/admin/featured-collections')
  Future<ApiResponse<PagedResponse<FeaturedCollectionResponse>>>
      adminListFeaturedCollections({
    @Query('cityId') int? cityId,
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @GET('/api/v1/admin/featured-collections/{id}')
  Future<ApiResponse<FeaturedCollectionResponse>> adminGetFeaturedCollection(
    @Path('id') String id,
  );

  @PATCH('/api/v1/admin/featured-collections/{id}')
  Future<ApiResponse<FeaturedCollectionResponse>> adminUpdateFeaturedCollection(
    @Path('id') String id,
    @Body() UpdateFeaturedCollectionRequest request,
  );

  @DELETE('/api/v1/admin/featured-collections/{id}')
  Future<ApiResponse<dynamic>> adminDeleteFeaturedCollection(
    @Path('id') String id,
  );

  @POST('/api/v1/admin/users/{userId}/recommendations/weekly/recompute')
  Future<ApiResponse<WeeklyRecommendationsResponse>>
      adminRecomputeUserWeeklyRecommendations(
    @Path('userId') String userId,
  );

  @GET('/api/v1/admin/notifications/audience/preview')
  Future<ApiResponse<AudiencePreviewResponse>> adminPreviewBroadcastAudience({
    @Query('audienceType') required String audienceType,
    @Query('targetId') required String targetId,
  });

  @POST('/api/v1/admin/notifications/broadcasts')
  Future<ApiResponse<AdminBroadcastResponse>> adminSendBroadcast(
    @Body() BroadcastRequest request,
  );

  @GET('/api/v1/admin/notifications/broadcasts')
  Future<ApiResponse<PagedResponse<AdminBroadcastResponse>>>
      adminListBroadcasts({
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @GET('/api/v1/admin/notifications/broadcasts/{id}')
  Future<ApiResponse<AdminBroadcastResponse>> adminGetBroadcast(
    @Path('id') String id,
  );

  @GET('/api/v1/admin/intents')
  Future<ApiResponse<List<IntentResponse>>> adminListIntents();

  @GET('/api/v1/admin/intents/{code}')
  Future<ApiResponse<IntentResponse>> adminGetIntent(
    @Path('code') String code,
  );

  @POST('/api/v1/admin/intents')
  Future<ApiResponse<IntentResponse>> adminCreateIntent(
    @Body() CreateIntentRequest request,
  );

  @PATCH('/api/v1/admin/intents/{code}')
  Future<ApiResponse<IntentResponse>> adminUpdateIntent(
    @Path('code') String code,
    @Body() UpdateIntentRequest request,
  );

  @DELETE('/api/v1/admin/intents/{code}')
  Future<ApiResponse<dynamic>> adminDeleteIntent(
    @Path('code') String code,
  );

  @PUT('/api/v1/admin/intents/{code}/vibe-tags')
  Future<ApiResponse<IntentResponse>> adminSetIntentVibeTags(
    @Path('code') String code,
    @Body() SetIntentVibeTagsRequest request,
  );

  @GET('/api/v1/admin/vibe-tags/catalog')
  Future<ApiResponse<List<VibeTagCatalogResponse>>> adminListVibeTagCatalog({
    @Query('includeInactive') bool includeInactive = false,
  });

  @POST('/api/v1/admin/vibe-tags/catalog')
  Future<ApiResponse<VibeTagCatalogResponse>> adminCreateVibeTag(
    @Body() CreateVibeTagRequest request,
  );

  @PATCH('/api/v1/admin/vibe-tags/catalog/{code}')
  Future<ApiResponse<VibeTagCatalogResponse>> adminUpdateVibeTag(
    @Path('code') String code,
    @Body() UpdateVibeTagRequest request,
  );

  @DELETE('/api/v1/admin/vibe-tags/catalog/{code}')
  Future<ApiResponse<dynamic>> adminDeleteVibeTag(
    @Path('code') String code,
  );

  @POST('/api/v1/admin/users/ghost')
  Future<ApiResponse<AdminGhostUserResponse>> adminCreateGhostUser(
    @Body() CreateGhostUserRequest request,
  );

  @GET('/api/v1/admin/users/ghost')
  Future<ApiResponse<PagedResponse<AdminGhostUserResponse>>> adminListGhostUsers({
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @GET('/api/v1/admin/users/ghost/{id}')
  Future<ApiResponse<AdminGhostUserResponse>> adminGetGhostUser(
    @Path('id') String id,
  );

  @PATCH('/api/v1/admin/users/ghost/{id}')
  Future<ApiResponse<AdminGhostUserResponse>> adminUpdateGhostUser(
    @Path('id') String id,
    @Body() UpdateGhostUserRequest request,
  );

  @DELETE('/api/v1/admin/users/ghost/{id}')
  Future<ApiResponse<dynamic>> adminDeleteGhostUser(
    @Path('id') String id,
  );

  @GET('/api/v1/admin/users/ghost/media/upload-url')
  Future<ApiResponse<AdminMediaUploadResponse>> mintGhostMediaUploadUrl(
    @Query('contentType') String contentType,
  );

  @POST('/api/v1/admin/users/ghost/{id}/posts')
  Future<ApiResponse<String>> adminCreateGhostPost(
    @Path('id') String id,
    @Body() CreateGhostPostRequest request,
  );

  @POST('/api/v1/admin/users/ghost/{id}/hangouts')
  Future<ApiResponse<String>> adminCreateGhostHangout(
    @Path('id') String id,
    @Body() CreateGhostHangoutRequest request,
  );

  @POST('/api/v1/admin/users/ghost/posts/{postId}/media')
  Future<ApiResponse<GhostPostMediaResponse>> adminAddGhostPostMedia(
    @Path('postId') String postId,
    @Body() AddGhostPostMediaRequest request,
  );

  @DELETE('/api/v1/admin/users/ghost/posts/{postId}/media/{mediaId}')
  Future<ApiResponse<void>> adminDeleteGhostPostMedia(
    @Path('postId') String postId,
    @Path('mediaId') String mediaId,
  );

  @POST('/api/v1/admin/users/ghost/hangouts/{hangoutId}/media')
  Future<ApiResponse<GhostHangoutMediaResponse>> adminAddGhostHangoutMedia(
    @Path('hangoutId') String hangoutId,
    @Body() AddGhostHangoutMediaRequest request,
  );

  @DELETE('/api/v1/admin/users/ghost/hangouts/{hangoutId}/media/{mediaId}')
  Future<ApiResponse<void>> adminDeleteGhostHangoutMedia(
    @Path('hangoutId') String hangoutId,
    @Path('mediaId') String mediaId,
  );

  @PATCH('/api/v1/admin/posts/{postId}')
  Future<ApiResponse<AdminPostResponse>> adminEditPost(
    @Path('postId') String postId,
    @Body() AdminEditPostRequest request,
  );

  @POST('/api/v1/admin/posts/{postId}/soft-delete')
  Future<ApiResponse<void>> adminSoftDeletePost(@Path('postId') String postId);

  @POST('/api/v1/admin/posts/{postId}/restore')
  Future<ApiResponse<void>> adminRestorePost(@Path('postId') String postId);

  @PATCH('/api/v1/admin/hangouts/{hangoutId}')
  Future<ApiResponse<AdminHangoutResponse>> adminEditHangout(
    @Path('hangoutId') String hangoutId,
    @Body() AdminEditHangoutRequest request,
  );

  @POST('/api/v1/admin/hangouts/{hangoutId}/soft-delete')
  Future<ApiResponse<void>> adminSoftDeleteHangout(
      @Path('hangoutId') String hangoutId);

  @POST('/api/v1/admin/hangouts/{hangoutId}/restore')
  Future<ApiResponse<void>> adminRestoreHangout(
      @Path('hangoutId') String hangoutId);

  @GET('/api/v1/admin/users/ghost/{ghostId}/merge-preview/{realUserId}')
  Future<ApiResponse<MergePreviewResponse>> adminGhostMergePreview(
    @Path('ghostId') String ghostId,
    @Path('realUserId') String realUserId,
  );

  @POST('/api/v1/admin/users/ghost/{ghostId}/merge-into/{realUserId}')
  Future<ApiResponse<AdminGhostUserResponse>> adminGhostMerge(
    @Path('ghostId') String ghostId,
    @Path('realUserId') String realUserId,
    @Body() MergeGhostUserRequest request,
  );

  @POST('/api/v1/chat/conversations')
  Future<ApiResponse<ConversationResponse>> createConversation(
    @Body() CreateConversationRequest request,
  );

  @GET('/api/v1/chat/conversations')
  Future<ApiResponse<PagedResponse<ConversationResponse>>> getChatInbox({
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @GET('/api/v1/chat/message-requests')
  Future<ApiResponse<PagedResponse<ConversationResponse>>> getMessageRequests({
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @GET('/api/v1/chat/conversations/{id}')
  Future<ApiResponse<ConversationResponse>> getConversation(
    @Path('id') String conversationId,
  );

  @POST('/api/v1/chat/conversations/{id}/accept-request')
  Future<ApiResponse<dynamic>> acceptMessageRequest(
    @Path('id') String conversationId,
  );

  @POST('/api/v1/chat/conversations/{id}/reject-request')
  Future<ApiResponse<dynamic>> rejectMessageRequest(
    @Path('id') String conversationId,
  );

  @POST('/api/v1/chat/conversations/{id}/leave')
  Future<ApiResponse<dynamic>> leaveConversation(
    @Path('id') String conversationId,
  );

  @GET('/api/v1/chat/conversations/{id}/messages')
  Future<ApiResponse<PagedResponse<MessageResponse>>> getMessages(
    @Path('id') String conversationId, {
    @Query('page') int page = 0,
    @Query('size') int size = 50,
  });

  @POST('/api/v1/chat/conversations/{id}/messages')
  Future<ApiResponse<MessageResponse>> sendMessage(
    @Path('id') String conversationId,
    @Body() SendMessageRequest request,
  );

  @POST('/api/v1/chat/conversations/{id}/read')
  Future<ApiResponse<dynamic>> markConversationRead(
    @Path('id') String conversationId,
    @Body() MarkReadRequest request,
  );

  @PATCH('/api/v1/chat/messages/{messageId}')
  Future<ApiResponse<MessageResponse>> editMessage(
    @Path('messageId') String messageId,
    @Body() EditMessageRequest request,
  );

  @DELETE('/api/v1/chat/messages/{messageId}')
  Future<ApiResponse<dynamic>> deleteMessage(
    @Path('messageId') String messageId, {
    @Query('scope') String scope = 'me',
  });

  @GET('/api/v1/chat/voice/upload-url')
  Future<ApiResponse<VoiceUploadUrlResponse>> getVoiceUploadUrl(
    @Query('contentType') String contentType,
  );

  @PATCH('/api/v1/chat/conversations/{id}')
  Future<ApiResponse<ConversationResponse>> updateConversation(
    @Path('id') String conversationId,
    @Body() UpdateConversationRequest request,
  );

  @PATCH('/api/v1/chat/conversations/{id}/mute')
  Future<ApiResponse<dynamic>> muteConversation(
    @Path('id') String conversationId,
    @Body() MuteConversationRequest request,
  );

  @POST('/api/v1/chat/conversations/{id}/members')
  Future<ApiResponse<ConversationResponse>> addMembers(
    @Path('id') String conversationId,
    @Body() AddMembersRequest request,
  );

  @DELETE('/api/v1/chat/conversations/{id}/members/{userId}')
  Future<ApiResponse<dynamic>> removeMember(
    @Path('id') String conversationId,
    @Path('userId') String userId,
  );

  @PATCH('/api/v1/chat/conversations/{id}/members/{userId}/role')
  Future<ApiResponse<dynamic>> updateMemberRole(
    @Path('id') String conversationId,
    @Path('userId') String userId,
    @Body() UpdateMemberRoleRequest request,
  );

  @GET('/api/v1/chat/presence')
  Future<ApiResponse<PresenceMapResponse>> getPresence(
    @Query('userIds') String userIds,
  );

  @POST('/api/v1/memories')
  Future<ApiResponse<MemoryResponse>> createMemory(
    @Body() CreateMemoryRequest request,
  );

  @DELETE('/api/v1/memories/{id}')
  Future<ApiResponse<dynamic>> deleteMemory(@Path('id') String memoryId);

  @GET('/api/v1/memories/upload-url/image')
  Future<ApiResponse<MediaUploadUrlResponse>> getMemoryImageUploadUrl(
    @Query('contentType') String contentType,
  );

  @GET('/api/v1/memories/upload-url/video')
  Future<ApiResponse<MediaUploadUrlResponse>> getMemoryVideoUploadUrl(
    @Query('contentType') String contentType,
  );

  @GET('/api/v1/memories/upload-url/audio')
  Future<ApiResponse<MediaUploadUrlResponse>> getMemoryAudioUploadUrl(
    @Query('contentType') String contentType,
  );

  @GET('/api/v1/memories/tray')
  Future<ApiResponse<List<MemoryTrayBucket>>> getMemoriesTray();

  @GET('/api/v1/memories/users/{userId}')
  Future<ApiResponse<List<MemoryResponse>>> getUserMemories(
    @Path('userId') String userId,
  );

  @GET('/api/v1/memories/venues/{venueId}')
  Future<ApiResponse<List<MemoryResponse>>> getVenueMemories(
    @Path('venueId') String venueId,
  );

  @GET('/api/v1/memories/{id}')
  Future<ApiResponse<MemoryResponse>> getMemory(@Path('id') String memoryId);

  @POST('/api/v1/memories/{id}/view')
  Future<ApiResponse<dynamic>> recordMemoryView(@Path('id') String memoryId);

  @GET('/api/v1/memories/{id}/viewers')
  Future<ApiResponse<PagedResponse<MemoryViewerEntry>>> getMemoryViewers(
    @Path('id') String memoryId, {
    @Query('page') int page = 0,
    @Query('size') int size = 50,
  });

  @POST('/api/v1/memories/{id}/react')
  Future<ApiResponse<dynamic>> reactToMemory(
    @Path('id') String memoryId,
    @Body() ReactToMemoryRequest request,
  );

  @DELETE('/api/v1/memories/{id}/react')
  Future<ApiResponse<dynamic>> removeMemoryReaction(
    @Path('id') String memoryId,
  );

  @POST('/api/v1/memories/{id}/respond')
  Future<ApiResponse<dynamic>> respondToMemoryEngagement(
    @Path('id') String memoryId,
    @Body() EngagementResponseRequest request,
  );

  @GET('/api/v1/memories/{id}/engagement/results')
  Future<ApiResponse<EngagementResultsResponse>> getMemoryEngagementResults(
    @Path('id') String memoryId, {
    @Query('page') int page = 0,
    @Query('size') int size = 50,
  });

  @GET('/api/v1/memories/me/mentions')
  Future<ApiResponse<PagedResponse<MemoryResponse>>> getMyMemoryMentions({
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @POST('/api/v1/business/venues/{venueId}/memories')
  Future<ApiResponse<MemoryResponse>> createVenueMemory(
    @Path('venueId') String venueId,
    @Body() CreateMemoryRequest request,
  );

  @DELETE('/api/v1/business/venues/{venueId}/memories/{memoryId}')
  Future<ApiResponse<dynamic>> deleteVenueMemory(
    @Path('venueId') String venueId,
    @Path('memoryId') String memoryId,
  );

  @GET('/api/v1/business/venues/{venueId}/memories/upload-url/image')
  Future<ApiResponse<MediaUploadUrlResponse>> getVenueMemoryImageUploadUrl(
    @Path('venueId') String venueId,
    @Query('contentType') String contentType,
  );

  @GET('/api/v1/business/venues/{venueId}/memories/upload-url/video')
  Future<ApiResponse<MediaUploadUrlResponse>> getVenueMemoryVideoUploadUrl(
    @Path('venueId') String venueId,
    @Query('contentType') String contentType,
  );

  @GET('/api/v1/business/venues/{venueId}/memories/upload-url/audio')
  Future<ApiResponse<MediaUploadUrlResponse>> getVenueMemoryAudioUploadUrl(
    @Path('venueId') String venueId,
    @Query('contentType') String contentType,
  );

  @GET('/api/v1/business/venues/{venueId}/memories/{memoryId}/metrics')
  Future<ApiResponse<MemoryMetricsResponse>> getVenueMemoryMetrics(
    @Path('venueId') String venueId,
    @Path('memoryId') String memoryId,
  );

  @POST('/api/v1/business/transfers')
  Future<ApiResponse<BusinessTransferResponse>> createBusinessTransfer(
    @Body() CreateBusinessTransferRequest body,
  );

  @GET('/api/v1/business/transfers/incoming')
  Future<ApiResponse<PagedResponse<BusinessTransferResponse>>>
      getIncomingBusinessTransfers({
    @Query('status') String status = 'pending',
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @GET('/api/v1/business/transfers/outgoing')
  Future<ApiResponse<PagedResponse<BusinessTransferResponse>>>
      getOutgoingBusinessTransfers({
    @Query('status') String status = 'pending',
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @POST('/api/v1/business/transfers/{transferId}/accept')
  Future<ApiResponse<BusinessTransferResponse>> acceptBusinessTransfer(
    @Path('transferId') String transferId,
    @Body() AcceptBusinessTransferRequest body,
  );

  @POST('/api/v1/business/transfers/{transferId}/decline')
  Future<ApiResponse<BusinessTransferResponse>> declineBusinessTransfer(
    @Path('transferId') String transferId,
  );

  @DELETE('/api/v1/business/transfers/{transferId}')
  Future<ApiResponse<BusinessTransferResponse>> cancelBusinessTransfer(
    @Path('transferId') String transferId,
  );

  @GET('/api/v1/business/venues/{venueId}/analytics/buzz')
  Future<ApiResponse<BuzzAnalyticsResponse>> getVenueBuzzAnalytics(
    @Path('venueId') String venueId,
  );

  @GET('/api/v1/business/venues/{venueId}/analytics/footfall')
  Future<ApiResponse<FootfallHeatmapResponse>> getVenueFootfallHeatmap(
    @Path('venueId') String venueId,
  );

  @GET('/api/v1/business/venues/{venueId}/analytics/daily')
  Future<ApiResponse<DailySeriesResponse>> getVenueDailyAnalytics(
    @Path('venueId') String venueId, {
    @Query('from') String? from,
    @Query('to') String? to,
  });

  @GET('/api/v1/business/venues/{venueId}/analytics/hangout-funnel')
  Future<ApiResponse<HangoutFunnelResponse>> getVenueHangoutFunnel(
    @Path('venueId') String venueId, {
    @Query('from') String? from,
    @Query('to') String? to,
  });

  @GET('/api/v1/business/venues/{venueId}/analytics/leaderboard')
  Future<ApiResponse<CategoryLeaderboardResponse>> getVenueLeaderboard(
    @Path('venueId') String venueId, {
    @Query('size') int size = 10,
  });

  @GET('/api/v1/business/venues/{venueId}/analytics/movers')
  Future<ApiResponse<MoversResponse>> getVenueMovers(
    @Path('venueId') String venueId, {
    @Query('direction') String direction = 'risers',
    @Query('size') int size = 5,
  });

  @GET('/api/v1/business/venues/{venueId}/analytics/peer-benchmark')
  Future<ApiResponse<PeerBenchmarkResponse>> getVenuePeerBenchmark(
    @Path('venueId') String venueId, {
    @Query('weeks') int weeks = 4,
  });

  @GET('/api/v1/business/venues/{venueId}/analytics/audience/demographics')
  Future<ApiResponse<AudienceDemographicsResponse>> getVenueAudienceDemographics(
    @Path('venueId') String venueId,
  );

  @GET('/api/v1/business/venues/{venueId}/analytics/audience/activity')
  Future<ApiResponse<AudienceActivityResponse>> getVenueAudienceActivity(
    @Path('venueId') String venueId,
  );

  @GET('/api/v1/business/venues/{venueId}/analytics/audience/loyalists')
  Future<ApiResponse<LoyalistsResponse>> getVenueLoyalists(
    @Path('venueId') String venueId, {
    @Query('days') int days = 30,
    @Query('minMentions') int minMentions = 3,
    @Query('page') int page = 0,
    @Query('size') int size = 20,
  });

  @GET('/api/v1/business/venues/{venueId}/analytics/funnel')
  Future<ApiResponse<ConversionFunnelResponse>> getVenueConversionFunnel(
    @Path('venueId') String venueId, {
    @Query('from') String? from,
    @Query('to') String? to,
  });

  @GET('/api/v1/business/venues/{venueId}/analytics/content/top-posts')
  Future<ApiResponse<TopPostsResponse>> getVenueTopPosts(
    @Path('venueId') String venueId, {
    @Query('days') int days = 30,
    @Query('size') int size = 5,
  });

  @GET('/api/v1/business/venues/{venueId}/analytics/content/top-memories')
  Future<ApiResponse<TopMemoriesResponse>> getVenueTopMemories(
    @Path('venueId') String venueId, {
    @Query('size') int size = 5,
  });

  @GET('/api/v1/business/venues/{venueId}/analytics/content/review-trend')
  Future<ApiResponse<ReviewTrendResponse>> getVenueReviewTrend(
    @Path('venueId') String venueId, {
    @Query('days') int days = 30,
  });

  @GET('/api/v1/users/me/points')
  Future<ApiResponse<UserPointsResponse>> getMyPoints();

  @POST('/api/v1/users/me/influencer/enable')
  Future<ApiResponse<UserDto>> enableInfluencer();

  @POST('/api/v1/users/me/influencer/disable')
  Future<ApiResponse<UserDto>> disableInfluencer();

  @GET('/api/v1/challenges')
  Future<ApiResponse<List<ChallengeListItemResponse>>> getChallenges({
    @Query('cadence') String? cadence,
  });

  @GET('/api/v1/challenges/me/joined')
  Future<ApiResponse<List<ChallengeListItemResponse>>>
      getMyJoinedChallenges();

  @GET('/api/v1/challenges/{challengeId}')
  Future<ApiResponse<ChallengeDetailResponse>> getChallengeDetail(
    @Path('challengeId') String challengeId,
  );

  @POST('/api/v1/challenges/{challengeId}/join')
  Future<ApiResponse<ChallengeDetailResponse>> joinChallenge(
    @Path('challengeId') String challengeId,
  );

  @POST('/api/v1/venue-locations/{branchId}/check-in')
  Future<ApiResponse<CheckInResponse>> checkInAtBranch(
    @Path('branchId') String branchId,
    @Body() CheckInRequest request,
  );

  @GET('/api/v1/events')
  Future<ApiResponse<PagedResponse<PublicEventResponse>>> listPublicEvents({
    @Query('status') String? status,
    @Query('page') int? page,
    @Query('size') int? size,
  });

  @GET('/api/v1/events/{eventId}')
  Future<ApiResponse<PublicEventResponse>> getPublicEvent(
    @Path('eventId') String eventId,
  );

  @POST('/api/v1/events/{eventId}/interest')
  Future<ApiResponse<PublicEventResponse>> markEventInterested(
    @Path('eventId') String eventId,
  );

  @DELETE('/api/v1/events/{eventId}/interest')
  Future<ApiResponse<PublicEventResponse>> unmarkEventInterested(
    @Path('eventId') String eventId,
  );

  @GET('/api/v1/events/me/interested')
  Future<ApiResponse<PagedResponse<PublicEventResponse>>> listMyInterestedEvents({
    @Query('page') int? page,
    @Query('size') int? size,
  });

  @GET('/api/v1/admin/events')
  Future<ApiResponse<PagedResponse<PublicEventResponse>>> adminListEvents({
    @Query('page') int? page,
    @Query('size') int? size,
  });

  @GET('/api/v1/admin/events/{eventId}')
  Future<ApiResponse<PublicEventResponse>> adminGetEvent(
    @Path('eventId') String eventId,
  );

  @POST('/api/v1/admin/events')
  Future<ApiResponse<PublicEventResponse>> adminCreateEvent(
    @Body() CreateEventRequest request,
  );

  @PATCH('/api/v1/admin/events/{eventId}')
  Future<ApiResponse<PublicEventResponse>> adminUpdateEvent(
    @Path('eventId') String eventId,
    @Body() UpdateEventRequest request,
  );

  @DELETE('/api/v1/admin/events/{eventId}')
  Future<ApiResponse<dynamic>> adminDeleteEvent(
    @Path('eventId') String eventId,
  );

  @POST('/api/v1/admin/events/{eventId}/hide')
  Future<ApiResponse<dynamic>> adminHideEvent(
    @Path('eventId') String eventId,
  );

  @POST('/api/v1/admin/events/{eventId}/unhide')
  Future<ApiResponse<dynamic>> adminUnhideEvent(
    @Path('eventId') String eventId,
  );

  @GET('/api/v1/admin/events/media/upload-url')
  Future<ApiResponse<EventMediaUploadUrlResponse>> adminGetEventMediaUploadUrl(
    @Query('contentType') String contentType,
  );

  @POST('/api/v1/admin/events/{eventId}/media')
  Future<ApiResponse<PublicEventMediaResponse>> adminAttachEventMedia(
    @Path('eventId') String eventId,
    @Body() AttachEventMediaRequest request,
  );

  @DELETE('/api/v1/admin/events/{eventId}/media/{mediaId}')
  Future<ApiResponse<dynamic>> adminRemoveEventMedia(
    @Path('eventId') String eventId,
    @Path('mediaId') String mediaId,
  );

  @GET('/api/v1/business/venues/{venueId}/events')
  Future<ApiResponse<PagedResponse<PublicEventResponse>>> businessListEvents(
    @Path('venueId') String venueId, {
    @Query('page') int? page,
    @Query('size') int? size,
  });

  @GET('/api/v1/business/venues/{venueId}/events/{eventId}')
  Future<ApiResponse<PublicEventResponse>> businessGetEvent(
    @Path('venueId') String venueId,
    @Path('eventId') String eventId,
  );

  @POST('/api/v1/business/venues/{venueId}/events')
  Future<ApiResponse<PublicEventResponse>> businessCreateEvent(
    @Path('venueId') String venueId,
    @Body() CreateEventRequest request,
  );

  @PATCH('/api/v1/business/venues/{venueId}/events/{eventId}')
  Future<ApiResponse<PublicEventResponse>> businessUpdateEvent(
    @Path('venueId') String venueId,
    @Path('eventId') String eventId,
    @Body() UpdateEventRequest request,
  );

  @DELETE('/api/v1/business/venues/{venueId}/events/{eventId}')
  Future<ApiResponse<dynamic>> businessDeleteEvent(
    @Path('venueId') String venueId,
    @Path('eventId') String eventId,
  );

  @GET('/api/v1/business/venues/{venueId}/events/media/upload-url')
  Future<ApiResponse<EventMediaUploadUrlResponse>> businessGetEventMediaUploadUrl(
    @Path('venueId') String venueId,
    @Query('contentType') String contentType,
  );

  @POST('/api/v1/business/venues/{venueId}/events/{eventId}/media')
  Future<ApiResponse<PublicEventMediaResponse>> businessAttachEventMedia(
    @Path('venueId') String venueId,
    @Path('eventId') String eventId,
    @Body() AttachEventMediaRequest request,
  );

  @DELETE('/api/v1/business/venues/{venueId}/events/{eventId}/media/{mediaId}')
  Future<ApiResponse<dynamic>> businessRemoveEventMedia(
    @Path('venueId') String venueId,
    @Path('eventId') String eventId,
    @Path('mediaId') String mediaId,
  );

  @POST('/api/v1/users/me/proximity/ping')
  Future<ApiResponse<ProximityPingResponse>> reportProximityPing(
    @Body() ProximityPingRequest request,
  );

  @GET('/api/v1/users/me/proximity/suggestions')
  Future<ApiResponse<NearbySuggestionsResponse>> getNearbySuggestions({
    @Query('limit') int? limit,
  });

  @POST('/api/v1/users/me/proximity/suggestions/{userId}/dismiss')
  Future<ApiResponse<void>> dismissNearbySuggestion(
    @Path('userId') String userId,
  );

  @PUT('/api/v1/users/me/proximity/settings')
  Future<ApiResponse<void>> updateProximitySettings(
    @Body() ProximitySettingsRequest request,
  );
}
