class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://zeron-3000.ssh.bd',
  );

  // General
  static const String config = '/api/v1/config';
  static const String banners = '/api/v1/banners';
  static const String categories = '/api/v1/categories';
  static const String popularFoods = '/api/v1/products/popular';
  static const String foodCampaigns = '/api/v1/campaigns/item';

  static String restaurants(int offset, int limit) =>
      '/api/v1/restaurants/get-restaurants/all?offset=$offset&limit=$limit';

  // Auth endpoints
  static const String authRegister = '/api/v1/auth/register';
  static const String authVerifyOtp = '/api/v1/auth/verify-otp';
  static const String authResendOtp = '/api/v1/auth/resend-otp';
  static const String authLogin = '/api/v1/auth/login';
  static const String authForgotPassword = '/api/v1/auth/forgot-password';
  static const String authResetPassword = '/api/v1/auth/reset-password';
  static const String authRefreshToken = '/api/v1/auth/refresh-token';
  static const String authLogout = '/api/v1/auth/logout';
  static const String authSocialLogin = '/api/v1/auth/social-login';


  //Get My Profile
  static const String getMyProfile = '/api/v1/auth/me';
  static const String updateProfile = '/api/v1/users/profile';

  // User activated services (utilities)
  static const String myServices = '/api/v1/meters/my-services';

  // Dashboard
  static const String userDashboard = '/api/v1/dashboard/user';





  //Referral
  static const String getMyReferralCode = '/api/v1/referrals/my-code';
  static const String getListMyReferral = '/api/v1/referrals/my-referrals?page=1&limit=20';
  static const String createReferral = '/api/v1/referrals/invite';

  // Referral reward display amounts (update when backend adds settings endpoint)
  static const String referralYouEarn = '€10';
  static const String referralFriendGets = '€10';
  static const double referralEarningsMilestone = 50.0;



  //Suppliers
  static const String getSuppliers = '/api/v1/suppliers?page=1&limit=20';
  static const String getSupplierDetails = '/api/v1/suppliers/{{supplierId}}';


  //Offers
  static const String getActiveOffers = '/api/v1/offers?page=1&limit=20';
  static const String getMyOffers = '/api/v1/offers/my-offers';
  static const String getOfferDetails = '/api/v1/offers/{{offerId}}'; 
  static const String getCompareOffers = '/api/v1/offers/compare?ids={{offerId}},o2b3c4d5-e6f7-8901-bcde-f23456789012';
  static String getRecommendedOffers(String billId) => '/api/v1/offers/recommended/$billId';
  
  //Agreements
  static const String getListMyAgreements = '/api/v1/agreements/my-agreements';
  static const String getMyAgreementDetails = '/api/v1/agreements/my-agreements/{{agreementId}}';




  // Support
  static const String supportTopics = '/api/v1/support/topics';
  static const String supportTickets = '/api/v1/support/tickets';
  static String supportTicketDetail(String id) => '/api/v1/support/tickets/$id';
  static String supportTicketMessages(String id) =>
      '/api/v1/support/tickets/$id/messages';

  // FAQ
  static const String faqs = '/api/v1/support/faqs';

  // Static Pages
  static String staticPage(String slug) => '/api/v1/static-pages/$slug';

  // Legal documents & consent
  static const String legalDocuments = '/api/v1/legal/documents';
  static const String legalPending = '/api/v1/legal/pending';
  static const String legalAccept = '/api/v1/legal/accept';
  static const String legalHistory = '/api/v1/legal/history';

  /// Slugs the backend treats as agreements the user has to accept.
  static const String slugPrivacyPolicy = 'privacy-policy';
  static const String slugTermsConditions = 'terms-conditions';

  //Bills
  static const String billsBase = '/api/v1/bills';
  static const String extractBill = '/api/v1/bills/extract';
  static const String uploadBills = '/api/v1/bills/upload';
  static String addFileToBill(String billId) => '/api/v1/bills/$billId/files';
  static const String createEmailBillRequest = '/api/v1/bills/email-request';
  static const String getMyBills = '/api/v1/bills?page=1&limit=20';
  static const String getMyBillDetails = '/api/v1/bills/{{billId}}';
  static String getBillVerification(String billId) =>
      '/api/v1/bills/$billId/verification';
  static String getBillVerificationHistory(String billId) =>
      '/api/v1/bills/$billId/verification/history';
  static String submitBillVerification(String billId) =>
      '/api/v1/bills/$billId/verification/submit';

  // Cases
  static const String casesBase = '/api/v1/cases';
  static String caseDocuments(String caseId) =>
      '/api/v1/cases/$caseId/documents';
  static String getCaseByBill(String billId) =>
      '/api/v1/cases/by-bill/$billId';
  static String getCaseDetails(String caseId) => '/api/v1/cases/$caseId';

  // Contracts are signed with the supplier, outside the app — there is no
  // contract endpoint to call. The sign-contract screen reads the case.

  // Notifications
  static const String notifications = '/api/v1/notifications';
  static const String notificationsUnreadCount = '/api/v1/notifications/unread-count';
  static String notificationMarkRead(String id) => '/api/v1/notifications/$id/read';
  static const String notificationsMarkAllRead = '/api/v1/notifications/read-all';
  static const String registerPushToken = '/api/v1/notifications/push-token';
  static String removePushToken(String token) => '/api/v1/notifications/push-token/$token';

  // General file upload
  static const String fileUpload = '/api/v1/upload';

  // Default headers (can be extended at request time)
  static Map<String, String> headers = {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  // Cache keys
  static const String cacheBanners = 'banners';
  static const String cacheCategories = 'categories';
  static const String cachePopularFoods = 'popularFoods';
  static const String cacheFoodCampaigns = 'foodCampaigns';
  static const String cacheRestaurants = 'restaurants';
  static const String cacheRestaurantsTotalSize = 'restaurantsTotalSize';
}

