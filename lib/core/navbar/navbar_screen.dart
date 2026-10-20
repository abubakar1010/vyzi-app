import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/layout/adaptive.dart';
import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:vyzi/core/navbar/navbar_controller.dart';
import 'package:vyzi/core/services/system_ui_service.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/features/home/screen/home_screen.dart';
import 'package:vyzi/features/legal/legal_gate.dart';
import 'package:vyzi/features/my_utility/my_utiliets.dart';
import 'package:vyzi/features/profile/profile_screen.dart';
import 'package:vyzi/features/request/request_screen.dart';
import 'package:vyzi/features/utility/select_utility_screen.dart';

class CustomBottomNavBar extends StatefulWidget {
  const CustomBottomNavBar({super.key});

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  final NavbarController _controller = Get.put(NavbarController());

  final List<Widget> _tabRoots = [
    HomeScreen(),
    RequestScreen(),
    MyUtilitiesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // Every signed-in path lands here — login, splash restore, deep link — so
    // this is where an outstanding terms acceptance gets asked for, before the
    // user can do anything else in the app.
    LegalGate.enforceAfterFrame();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        // 1. Pop within the current tab if possible
        if (_controller.canPopCurrentTab()) {
          _controller.popCurrentTab();
          return;
        }

        // 2. If not on Home tab, switch to Home
        if (_controller.selectedIndex != 0) {
          _controller.changeIndex(0);
          return;
        }

        // 3. Already at Home root — exit app
        SystemNavigator.pop();
      },
      child: Obx(() {
        if (Adaptive.isWide(context)) return _buildWideLayout();

        final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: IndexedStack(
            index: _controller.selectedIndex,
            children: List.generate(4, (i) => _buildTabNavigator(i)),
          ),
          bottomNavigationBar: isKeyboardOpen
              ? null
              : _buildBottomNavigationBar(),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: isKeyboardOpen
              ? null
              : _buildFloatingActionButton(),
        );
      }),
    );
  }

  /// A wide window keeps the tabs in a rail down the leading edge, as iPad
  /// apps do, with the upload action at its head.
  ///
  /// The status bar sits on a strip of its own: one status bar style spans the
  /// rail and the tab's header, and only a plain background suits both.
  Widget _buildWideLayout() {
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiService.styleForBackground(AppColors.background),
            child: SizedBox(height: statusBarHeight, width: double.infinity),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: _buildRailAndTabs(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRailAndTabs() {
    return Row(
      children: [
        SafeArea(
          right: false,
          child: NavigationRail(
            backgroundColor: AppColors.background,
            selectedIndex: _controller.selectedIndex,
            onDestinationSelected: _controller.changeIndex,
            labelType: NavigationRailLabelType.all,
            minWidth: 96,
            groupAlignment: -0.85,
            indicatorColor: AppColors.primaryAlpha10,
            selectedIconTheme: const IconThemeData(
              color: AppColors.primaryColor,
            ),
            unselectedIconTheme: const IconThemeData(color: Colors.grey),
            selectedLabelTextStyle: TextStyle(
              fontSize: 12.sp,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelTextStyle: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey,
            ),
            leading: Padding(
              padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
              child: _buildFloatingActionButton(),
            ),
            destinations: [
              for (final (icon, label) in _tabs)
                NavigationRailDestination(
                  icon: Icon(icon),
                  label: Text(label.tr),
                ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        // The tabs measure the window to lay themselves out, so tell them
        // the window is the pane beside the rail — whose leading safe area
        // the rail has already taken.
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  size: constraints.biggest,
                  padding: media.padding.copyWith(left: 0),
                  viewPadding: media.viewPadding.copyWith(left: 0),
                ),
                child: IndexedStack(
                  index: _controller.selectedIndex,
                  children: List.generate(4, (i) => _buildTabNavigator(i)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// The tabs, in [NavTabs] order: icon and translation key.
  static const _tabs = [
    (Icons.home_outlined, 'navbar.home'),
    (Icons.description_outlined, 'navbar.request'),
    (Icons.flash_on_outlined, 'navbar.utilities'),
    (Icons.person_outline, 'navbar.profile'),
  ];

  /// Each tab gets its own Navigator so pushes stay within the tab body.
  Widget _buildTabNavigator(int index) {
    return Navigator(
      key: _controller.navigatorKeys[index],
      onGenerateRoute: (_) =>
          MaterialPageRoute(builder: (_) => _tabRoots[index]),
    );
  }

  /// Floating Action Button
  Widget _buildFloatingActionButton() {
    return SizedBox(
      height: 64.h,
      width: 64.w,
      child: FloatingActionButton(
        backgroundColor: AppColors.lightPurple,
        elevation: 2,
        onPressed: () => NavHelper.push(SelectUtilityScreen()),
        shape: const CircleBorder(),
        child: ClipOval(
          child: Image.asset(
            "assets/images/VYZI.png",
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }

  /// Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      color: AppColors.background,
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      height: 60,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          Expanded(
            child: _buildNavItem(
              index: 0,
              icon: Icons.home_outlined,
              label: 'navbar.home',
            ),
          ),
          Expanded(
            child: _buildNavItem(
              index: 1,
              icon: Icons.description_outlined,
              label: 'navbar.request',
            ),
          ),
          SizedBox(width: 72.w), // Space for FAB notch
          Expanded(
            child: _buildNavItem(
              index: 2,
              icon: Icons.flash_on_outlined,
              label: 'navbar.utilities',
            ),
          ),
          Expanded(
            child: _buildNavItem(
              index: 3,
              icon: Icons.person_outline,
              label: 'navbar.profile',
            ),
          ),
        ],
      ),
    );
  }

  /// Navigation Item with Icon and Translated Label
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    return Obx(() {
      final bool isSelected = _controller.selectedIndex == index;
      final color = isSelected ? AppColors.primaryColor : Colors.grey;
      return InkResponse(
        onTap: () => _controller.changeIndex(index),
        child: SizedBox(
          height: 56.h,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24.w, color: color),
              SizedBox(height: 2.h),
              Text(
                label.tr,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
