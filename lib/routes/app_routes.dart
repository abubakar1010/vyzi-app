import 'package:vyzi/core/middleware/auth_middleware.dart';
import 'package:vyzi/core/navbar/navbar_screen.dart';
import 'package:vyzi/features/auth/create_account.dart';
import 'package:vyzi/features/auth/create_account_otp_screen.dart';
import 'package:vyzi/features/auth/screen/forgot_email_screen.dart';
import 'package:vyzi/features/auth/screen/forgot_reset_screen.dart';
import 'package:vyzi/features/auth/signin_screen.dart';
import 'package:vyzi/features/bills/screen/bill_detail_screen.dart';
import 'package:vyzi/features/bills/screen/bill_verification_screen.dart';
import 'package:vyzi/features/notifications/screen/notification_screen.dart';
import 'package:vyzi/features/profile/invite_friends/invite_friends.dart';
import 'package:vyzi/features/home/sign_contract/sign_contract.dart';
import 'package:vyzi/features/support/ticket_info_screen.dart';
import 'package:vyzi/features/home/screen/home_screen.dart';
import 'package:vyzi/features/onboarding/warmup.dart';
import 'package:get/get.dart';

import '../features/onboarding/onboarding_screen.dart';
import '../features/splash/spalsh_screen.dart';

class AppRoutes {
  static String splashScreen = "/splash_screen";

  static String homeScreen = "/home_screen";
  static String categoriesScreen = "/categories_screen";
  static String calenderScreen = "/calender_screen";
  static String profileScreen = "/profile_screen";

  static String walletScreen = "/wallet_screen";
  static String onboardScreen = "/onboarding_screen";
  static String warmOnboardScreen = "/warm_onboarding_screen";
  static String onboardSecondScreen = "/onboard_second_screen";
  static String signInScreen = "/sign_in_screen";
  static String signUpScreen = "/sign_up_screen";
  static String createAccountScreen = "/create_account_screen";
  static String createAccountOtpScreen = "/create_account_otp_screen";  
  static String forgotPasswordScreen = "/forgot_password_screen";
  static String verificationCodeScreen = "/verification_code_screen";
  static String resetPasswordScreen = "/reset_password_screen";

  static String personalInformationScreen = "/personal_information_screen";
  static String editProfileScreen = "/edit_profile_screen";
  static String memberProfileScreen = "/member_profile_screen";
  static String settingsScreen = "/settings_screen";
  static String changePasswordScreen = "/change_password_screen";
  static String privacyPolicyScreen = "/privacy_policy_screen";
  static String termsConditionScreen = "/terms_condition_screen";
  static String aboutusScreen = "/aboutus_screen";
  static String upcomingEventScreen = "/upcoming_event_screen";
  static String eventDetailsScreen = "/details_event_screen";
  static String searchEventScreen = "/search_event_screen";
  static String notificationsScreen = "/notifications_screen";
  static String filterScreen = "/filter_screen";

  static String inviteEventScreen = "/invite_event_screen";
  static String ownershipScreen = "/ownership_screen";
  static String mapScreen = "/map_screen";
  static String createFamilyGroup = "/createFamilyGroup";
  static String updateFamilyGroup = "/updateFamilyGroup";

  //static String bottomMenu ="/bottom_menu";

  static String myFamilyScreen = "/my_family_screen";
  static String createMemberProfileScreen = "/CreateMemberProfileScreen";
  static String myEventScreen = "/myEventScreen";
  static String myTodayEventScreen = "/MyTodayEventScreen";
  static String myEventFilterScreen = "/myEventFilterScreen";
  static String myConnectionScreen = "/myConnectionScreen";
  static String myContributionScreen = "/myContributionScreen";
  static String contributionFilterScreen = "/contributionFilterScreen";
  static String myInvitationPage = "/MyInvitationPage";
  static String shareInvitationPage = "/share_Invitation_Page";
  static String errorScreen = "/errorScreen";
  static String memberProfileDetailsScreen = "/memberProfileDetailsScreen";
  static String ownerProfileDetailsScreen = "/OwnerProfileDetailsScreen";
  static String appliedSearchEventListScreen = "/appliedSearch_Screen";
  static String suggestionDonationPage = "/suggestion_donation_page";
  static String suggestionScreen = "/suggestion_screen";
  static String donationScreen = "/donation_screen";
  static String makePaymentScreen = "/makePayment_screen";
  static String paymentSuccessScreen = "/paymentSuccessScreen";
  static String donationMoodScreen = "/donationMoodScreen";

  static String categoriesFilterScreen = "/categoriesFilterScreen";
  static String categoriesSearchAppliedScreen =
      "/categories_search_applied_screen";
  static String forgetPasswordOtpScreen = "/forgetPasswordOtpScreen";
  static String signUpOtpVerificationScreen = "/signUpOtpVerificationScreen";

  //create event
  static String createEventOne = "/create_event_one";
  static String stepTwoContent = "/stepTwoContent";

  //==============Invitation page================

  static String invitationListPage = "/invitationPage";
  static String familyGroupScreen = "/familyGroupScreen";
  static String navbarScreen = "/navbarScreen";
  static String billDetailScreen = "/bill_detail_screen";
  static String billVerificationScreen = "/bill_verification_screen";
  static String signContractScreen = "/sign_contract_screen";
  static String inviteFriendsScreen = "/invite_friends_screen";
  static String ticketDetailScreen = "/ticket_detail_screen";

//======================>>>> List PAge
  static List<GetPage> page = [
    GetPage(name: splashScreen, page: () => const SplashScreen()),
    GetPage(
        name: homeScreen,
        page: () => HomeScreen(),
        middlewares: [AuthMiddleware()],
        transition: Transition.noTransition),
    // GetPage(
    //     name: categoriesScreen,
    //     page: () => CategoriesScreen(),
    //     transition: Transition.noTransition),
    // // GetPage(
    // //     name: createAccountScreen,
    // //     page: () => CreateAccountScreen(),
    // //     transition: Transition.noTransition),
    // GetPage(
    //     name: calenderScreen,
    //     page: () => const CalenderScreen(),
    //     transition: Transition.noTransition),
    // GetPage(
    //     name: profileScreen,
    //     page: () => ProfileScreen(),
    //     transition: Transition.noTransition),
    // GetPage(name: walletScreen, page: () => const WalletScreen()),
    GetPage(name: warmOnboardScreen, page: () =>  WarmupOnboarding()),
    GetPage(name: onboardScreen, page: () =>  OnboardingScreen()),
    GetPage(name: navbarScreen, page: () =>  CustomBottomNavBar(), middlewares: [AuthMiddleware()]),
    GetPage(name: billDetailScreen, page: () => BillDetailScreen(billId: Get.arguments as String), middlewares: [AuthMiddleware()]),
    GetPage(name: billVerificationScreen, page: () => const BillVerificationScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: signContractScreen, page: () => const SignContractScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: notificationsScreen, page: () => const NotificationScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: inviteFriendsScreen, page: () => InviteScreen(), middlewares: [AuthMiddleware()]),
    GetPage(name: ticketDetailScreen, page: () => TicketInfoScreen(ticketId: Get.arguments as String), middlewares: [AuthMiddleware()]),
    GetPage(name: signInScreen, page: () => const SignInScreen()),
    GetPage(name: signUpScreen, page: () => const RegisterScreen()),
    GetPage(
        name: createAccountOtpScreen, page: () =>  CreateAccountOtpScreen()),
    GetPage(
        name: forgotPasswordScreen, page: () =>  ForgotPasswordScreen()),
    GetPage(
        name: resetPasswordScreen, page: () => ResetPasswordScreen()),
    // GetPage(
    //     name: personalInformationScreen,
    //     page: () => PersonalInformationScreen()),
    // GetPage(name: editProfileScreen, page: () => const EditProfileScreen()),
    // GetPage(name: memberProfileScreen, page: () => const MemberProfileScreen()),
    // GetPage(name: settingsScreen, page: () => SettingsScreen()),
    // GetPage(
    //     name: changePasswordScreen, page: () => const ChangePasswordScreen()),
    // GetPage(name: privacyPolicyScreen, page: () => PrivacyPolicyScreen()),
    // GetPage(name: termsConditionScreen, page: () => TermsConditionScreen()),
    // GetPage(name: aboutusScreen, page: () => AboutusScreen()),
    // GetPage(name: upcomingEventScreen, page: () => UpcomingEventScreen()),
    // GetPage(name: eventDetailsScreen, page: () => EventDetailsScreen()),
    // GetPage(name: searchEventScreen, page: () => SearchEventScreen()),
    // GetPage(name: notificationsScreen, page: () => NotificationsScreen()),
    // GetPage(name: filterScreen, page: () => FilterScreen()),
    //
    // GetPage(name: createEventOne, page: () => CreateEventOne()),
    // GetPage(name: stepTwoContent, page: () => StepTwoForm()),
    // GetPage(name: inviteEventScreen, page: () => InviteEventScreen()),
    // GetPage(name: ownershipScreen, page: () => OwnershipScreen()),
    // GetPage(name: mapScreen, page: () => MapScreen()),
    // GetPage(name: familyGroupScreen, page: () => FamilyGroupScreen()),
    // GetPage(name: createFamilyGroup, page: () => CreateFamilyGroup()),
    // GetPage(name: updateFamilyGroup, page: () => UpdateFamilyGroup()),
    // //GetPage(name:bottomMenu, page: ()=> BottomMenu()),
    //
    // //==============================>>>> Profile section <<<<< ============
    // GetPage(name: myFamilyScreen, page: () => MyFamilyScreen()),
    // GetPage(
    //     name: createMemberProfileScreen,
    //     page: () => CreateMemberProfileScreen()),
    // GetPage(
    //     name: myEventScreen,
    //     page: () => MyEventScreen(),
    //     transition: Transition.noTransition),
    // GetPage(
    //     name: myTodayEventScreen,
    //     page: () => MyTodayEventScreen(),
    //     transition: Transition.noTransition),
    // GetPage(name: myEventFilterScreen, page: () => MyEventFilterScreen()),
    // GetPage(name: myConnectionScreen, page: () => MyConnectionScreen()),
    //
    // GetPage(name: myContributionScreen, page: () => MyContributionScreen()),
    // GetPage(
    //     name: contributionFilterScreen, page: () => ContributionFilterScreen()),
    // GetPage(name: myInvitationPage, page: () => MyInvitationPage()),
    // GetPage(name: shareInvitationPage, page: () => ShareInvitationPage()),
    // GetPage(name: errorScreen, page: () => ErrorScreen()),
    //
    // GetPage(
    //     name: memberProfileDetailsScreen,
    //     page: () => MemberProfileDetailsScreen()),
    // GetPage(
    //     name: ownerProfileDetailsScreen,
    //     page: () => OwnerProfileDetailsScreen()),
    // GetPage(
    //     name: appliedSearchEventListScreen,
    //     page: () => AppliedSearchEventListScreen()),
    //
    // //home
    // GetPage(name: suggestionDonationPage, page: () => SuggestionDonationPage()),
    // GetPage(name: suggestionScreen, page: () => SuggestionScreen()),
    // GetPage(name: donationScreen, page: () => DonationScreen()),
    // GetPage(name: donationMoodScreen, page: () => DonationMoodScreen()),
    //
    // GetPage(name: makePaymentScreen, page: () => MakePaymentScreen()),
    // GetPage(name: paymentSuccessScreen, page: () => PaymentSuccessScreen()),
    // GetPage(
    //     name: forgetPasswordOtpScreen, page: () => ForgetPasswordOtpScreen()),
    // GetPage(
    //     name: signUpOtpVerificationScreen,
    //     page: () => SignUpOtpVerificationScreen()),
    //
    // //category
    // GetPage(name: categoriesFilterScreen, page: () => CategoriesFilterScreen()),
    // GetPage(
    //     name: categoriesSearchAppliedScreen,
    //     page: () => CategoriesSearchAppliedScreen(category: Get.arguments),
    //     binding: BindingsBuilder(() {
    //       Get.lazyPut(() => ApiService(sharedPreferences: Get.find()));
    //     })),
    // //========Invitation page
    // GetPage(
    //     name: invitationListPage,
    //     page: () => const Invitationlist(),
    //     binding: BindingsBuilder(() {
    //       Get.lazyPut(() => InvitationListController());
    //     })),
  ];
}
