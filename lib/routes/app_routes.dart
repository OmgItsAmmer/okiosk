import 'package:get/get.dart';
import 'package:okiosk/features/pos/screens/pos_kiosk_screen.dart';
import '../features/login/screens/login.dart';
import 'routes.dart';

class AppRoutes {
  static final pages = [
    // POS Kiosk Routes
    GetPage(
      name: TRoutes.posKiosk,
      page: () => const PosKioskScreen(),
      binding: PosKioskBinding(),
    ),
    GetPage(
      name: TRoutes.posKioskDebug,
      page: () => const PosKioskScreenDebug(),
      binding: PosKioskBinding(),
    ),
    GetPage(
      name: TRoutes.signIn,
      page: () => const LoginScreen(),
     // binding: LoginBinding(),
    ),
    // GetPage(name: TRoutes.home, page: () => const HomeScreen()),
    // //  GetPage(name: TRoutes.store, page: () => const StoreScreen(initialCategoryIndex: 0,)),
    // GetPage(name: TRoutes.favourites, page: () => const FavoriteScreen()),
    // GetPage(name: TRoutes.settings, page: () => const SettingsScreen()),
    // GetPage(name: TRoutes.productReviews, page: () => const TProductReview()),
    // GetPage(name: TRoutes.order, page: () => const OrderScreen()),
    // GetPage(name: TRoutes.checkout, page: () => const CheckOutScreen()),
    // GetPage(name: TRoutes.cart, page: () => const CartScreen()),
    // GetPage(
    //   name: TRoutes.userProfile,
    //   page: () => const ProfileScreen(),
    // ),
    // GetPage(name: TRoutes.userAddress, page: () => UserAddressScreen()),
    // GetPage(name: TRoutes.signup, page: () => const SignUpScreen()),
    // GetPage(name: TRoutes.verifyEmail, page: () => const VerifyEmailScreen()),
    // GetPage(name: TRoutes.signIn, page: () => const LoginScreen()),
    // GetPage(name: TRoutes.forgetPassword, page: () => const ForgetPassword()),
    // GetPage(name: TRoutes.onBoarding, page: () => const OnBoardingScreen()),
    // GetPage(name: TRoutes.navigationMenu, page: () => const NavigationMenu()),
    // GetPage(name: TRoutes.allProducts, page: () => const AllProductsScreen()),
    // GetPage(
    //     name: TRoutes.productDetails, page: () => const ProductDetailScreen()),
    // GetPage(name: TRoutes.storeScreen, page: () => const StoreScreen()),
    // GetPage(
    //     name: TRoutes.addNewAddressScreen,
    //     page: () => const AddNewAddressScreen()),
    // GetPage(name: TRoutes.brandProducts, page: () => const BrandProducts()),
    // GetPage(name: TRoutes.allBrands, page: () => const AllBrandsScreen()),
    // GetPage(
    //     name: TRoutes.checkoutSuccess,
    //     page: () => const CheckoutSuccessScreen()),
    // GetPage(name: TRoutes.search, page: () => const SearchScreen()),
    // GetPage(
    //     name: TRoutes.searchResults, page: () => const SearchResultsScreen()),
    // GetPage(name: TRoutes.addExtraInfo, page: () => const AddExtraInfo()),
    // GetPage(name: TRoutes.support, page: () => const SupportScreen()),
    // GetPage(name: TRoutes.unkown, page: () => const UnknownScreen()),
  ];
}
