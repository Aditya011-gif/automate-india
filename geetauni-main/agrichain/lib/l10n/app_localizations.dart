import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'AgriChain'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Empowering Agriculture with Blockchain & AI'**
  String get tagline;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @userType.
  ///
  /// In en, this message translates to:
  /// **'I am a'**
  String get userType;

  /// No description provided for @farmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmer;

  /// No description provided for @buyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer / Trader'**
  String get buyer;

  /// No description provided for @lender.
  ///
  /// In en, this message translates to:
  /// **'Lender / Financial Inst.'**
  String get lender;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get navMarketplace;

  /// No description provided for @navMyCrops.
  ///
  /// In en, this message translates to:
  /// **'My Crops'**
  String get navMyCrops;

  /// No description provided for @navLoans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get navLoans;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get navAnalytics;

  /// No description provided for @navDownloads.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get navDownloads;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search crops, farmers, locations...'**
  String get search;

  /// No description provided for @searchCrops.
  ///
  /// In en, this message translates to:
  /// **'Search crops...'**
  String get searchCrops;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @addCrop.
  ///
  /// In en, this message translates to:
  /// **'List New Crop'**
  String get addCrop;

  /// No description provided for @analyzeLand.
  ///
  /// In en, this message translates to:
  /// **'Land Analysis'**
  String get analyzeLand;

  /// No description provided for @applyForLoan.
  ///
  /// In en, this message translates to:
  /// **'Apply for Loan'**
  String get applyForLoan;

  /// No description provided for @marketplaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Direct farmer-to-buyer transparent trade'**
  String get marketplaceSubtitle;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @harvestDate.
  ///
  /// In en, this message translates to:
  /// **'Harvest Date'**
  String get harvestDate;

  /// No description provided for @qualityGrade.
  ///
  /// In en, this message translates to:
  /// **'Quality Grade'**
  String get qualityGrade;

  /// No description provided for @certifications.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get certifications;

  /// No description provided for @biddingType.
  ///
  /// In en, this message translates to:
  /// **'Trading Type'**
  String get biddingType;

  /// No description provided for @fixedPrice.
  ///
  /// In en, this message translates to:
  /// **'Fixed Price'**
  String get fixedPrice;

  /// No description provided for @auction.
  ///
  /// In en, this message translates to:
  /// **'Auction'**
  String get auction;

  /// No description provided for @startingBid.
  ///
  /// In en, this message translates to:
  /// **'Starting Bid'**
  String get startingBid;

  /// No description provided for @currentHighestBid.
  ///
  /// In en, this message translates to:
  /// **'Highest Bid'**
  String get currentHighestBid;

  /// No description provided for @bidNow.
  ///
  /// In en, this message translates to:
  /// **'Place Bid'**
  String get bidNow;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNow;

  /// No description provided for @sold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get sold;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @sellerDetails.
  ///
  /// In en, this message translates to:
  /// **'Seller Information'**
  String get sellerDetails;

  /// No description provided for @perQuintal.
  ///
  /// In en, this message translates to:
  /// **'/ Quintal'**
  String get perQuintal;

  /// No description provided for @verifiedNftSeal.
  ///
  /// In en, this message translates to:
  /// **'NFT Verified Seal'**
  String get verifiedNftSeal;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @browseCrops.
  ///
  /// In en, this message translates to:
  /// **'Browse Crops'**
  String get browseCrops;

  /// No description provided for @priceComparison.
  ///
  /// In en, this message translates to:
  /// **'Price Comparison'**
  String get priceComparison;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryNFT.
  ///
  /// In en, this message translates to:
  /// **'NFT'**
  String get categoryNFT;

  /// No description provided for @categoryRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get categoryRegular;

  /// No description provided for @categoryWheat.
  ///
  /// In en, this message translates to:
  /// **'Wheat'**
  String get categoryWheat;

  /// No description provided for @agriTrustScore.
  ///
  /// In en, this message translates to:
  /// **'Agri-Trust Score'**
  String get agriTrustScore;

  /// No description provided for @landAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Land & Soil Intelligence'**
  String get landAnalysisTitle;

  /// No description provided for @landAnalysisDesc.
  ///
  /// In en, this message translates to:
  /// **'Evaluate satellite vegetation, soil parameters, weather risks, and ML yield predictions'**
  String get landAnalysisDesc;

  /// No description provided for @enterCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Enter Land Coordinates'**
  String get enterCoordinates;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use Current GPS Location'**
  String get useCurrentLocation;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @runAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Analyze Land'**
  String get runAnalysis;

  /// No description provided for @analyzingLand.
  ///
  /// In en, this message translates to:
  /// **'Scanning satellite & environmental data...'**
  String get analyzingLand;

  /// No description provided for @scoreBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Score Breakdown'**
  String get scoreBreakdown;

  /// No description provided for @vegetationIndex.
  ///
  /// In en, this message translates to:
  /// **'Vegetation Index (NDVI)'**
  String get vegetationIndex;

  /// No description provided for @soilQuality.
  ///
  /// In en, this message translates to:
  /// **'Soil Quality'**
  String get soilQuality;

  /// No description provided for @landClassification.
  ///
  /// In en, this message translates to:
  /// **'Land Classification'**
  String get landClassification;

  /// No description provided for @weatherCondition.
  ///
  /// In en, this message translates to:
  /// **'Weather Condition'**
  String get weatherCondition;

  /// No description provided for @marketStability.
  ///
  /// In en, this message translates to:
  /// **'Market Stability'**
  String get marketStability;

  /// No description provided for @creditRiskTier.
  ///
  /// In en, this message translates to:
  /// **'Credit Risk Tier'**
  String get creditRiskTier;

  /// No description provided for @mlPredictionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Machine Learning Intelligence'**
  String get mlPredictionsTitle;

  /// No description provided for @cropQualityPrediction.
  ///
  /// In en, this message translates to:
  /// **'Predicted Crop Quality'**
  String get cropQualityPrediction;

  /// No description provided for @cropHealthScore.
  ///
  /// In en, this message translates to:
  /// **'Crop Health Score'**
  String get cropHealthScore;

  /// No description provided for @riskLevelPrediction.
  ///
  /// In en, this message translates to:
  /// **'Assessed Risk Level'**
  String get riskLevelPrediction;

  /// No description provided for @ndviTrendPrediction.
  ///
  /// In en, this message translates to:
  /// **'15-Day NDVI Trend'**
  String get ndviTrendPrediction;

  /// No description provided for @confidenceScore.
  ///
  /// In en, this message translates to:
  /// **'Model Confidence'**
  String get confidenceScore;

  /// No description provided for @scanNewLand.
  ///
  /// In en, this message translates to:
  /// **'Scan Another Land Parcel'**
  String get scanNewLand;

  /// No description provided for @tierPlatinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum Tier'**
  String get tierPlatinum;

  /// No description provided for @tierGold.
  ///
  /// In en, this message translates to:
  /// **'Gold Tier'**
  String get tierGold;

  /// No description provided for @tierSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver Tier'**
  String get tierSilver;

  /// No description provided for @tierBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze Tier'**
  String get tierBronze;

  /// No description provided for @lowRisk.
  ///
  /// In en, this message translates to:
  /// **'Low Risk'**
  String get lowRisk;

  /// No description provided for @mediumRisk.
  ///
  /// In en, this message translates to:
  /// **'Medium Risk'**
  String get mediumRisk;

  /// No description provided for @highRisk.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get highRisk;

  /// No description provided for @flaggedRisk.
  ///
  /// In en, this message translates to:
  /// **'Flagged for Review'**
  String get flaggedRisk;

  /// No description provided for @soilAlluvial.
  ///
  /// In en, this message translates to:
  /// **'Alluvial Soil (Highly Fertile)'**
  String get soilAlluvial;

  /// No description provided for @soilBlackCotton.
  ///
  /// In en, this message translates to:
  /// **'Black Cotton Soil'**
  String get soilBlackCotton;

  /// No description provided for @soilRed.
  ///
  /// In en, this message translates to:
  /// **'Red Loamy Soil'**
  String get soilRed;

  /// No description provided for @soilClayey.
  ///
  /// In en, this message translates to:
  /// **'Clayey Soil'**
  String get soilClayey;

  /// No description provided for @soilMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed Soil'**
  String get soilMixed;

  /// No description provided for @seasonKharif.
  ///
  /// In en, this message translates to:
  /// **'Kharif (Monsoon)'**
  String get seasonKharif;

  /// No description provided for @seasonRabi.
  ///
  /// In en, this message translates to:
  /// **'Rabi (Winter)'**
  String get seasonRabi;

  /// No description provided for @seasonZaid.
  ///
  /// In en, this message translates to:
  /// **'Zaid (Summer)'**
  String get seasonZaid;

  /// No description provided for @cropWheat.
  ///
  /// In en, this message translates to:
  /// **'Wheat'**
  String get cropWheat;

  /// No description provided for @cropRice.
  ///
  /// In en, this message translates to:
  /// **'Rice'**
  String get cropRice;

  /// No description provided for @cropMaize.
  ///
  /// In en, this message translates to:
  /// **'Maize'**
  String get cropMaize;

  /// No description provided for @cropPotato.
  ///
  /// In en, this message translates to:
  /// **'Potato'**
  String get cropPotato;

  /// No description provided for @cropTomato.
  ///
  /// In en, this message translates to:
  /// **'Tomato'**
  String get cropTomato;

  /// No description provided for @cropOnion.
  ///
  /// In en, this message translates to:
  /// **'Onion'**
  String get cropOnion;

  /// No description provided for @cropCotton.
  ///
  /// In en, this message translates to:
  /// **'Cotton'**
  String get cropCotton;

  /// No description provided for @cropSugarcane.
  ///
  /// In en, this message translates to:
  /// **'Sugarcane'**
  String get cropSugarcane;

  /// No description provided for @cropSoybean.
  ///
  /// In en, this message translates to:
  /// **'Soybean'**
  String get cropSoybean;

  /// No description provided for @cropMango.
  ///
  /// In en, this message translates to:
  /// **'Mango'**
  String get cropMango;

  /// No description provided for @cropApple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get cropApple;

  /// No description provided for @cropBanana.
  ///
  /// In en, this message translates to:
  /// **'Banana'**
  String get cropBanana;

  /// No description provided for @loanSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'DeFi Agricultural Micro-Loans'**
  String get loanSectionTitle;

  /// No description provided for @loanSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get instant loans backed by crop & land collateral'**
  String get loanSectionSubtitle;

  /// No description provided for @requestNewLoan.
  ///
  /// In en, this message translates to:
  /// **'Request Micro-Loan'**
  String get requestNewLoan;

  /// No description provided for @loanAmount.
  ///
  /// In en, this message translates to:
  /// **'Loan Amount'**
  String get loanAmount;

  /// No description provided for @interestRate.
  ///
  /// In en, this message translates to:
  /// **'Interest Rate'**
  String get interestRate;

  /// No description provided for @durationMonths.
  ///
  /// In en, this message translates to:
  /// **'Duration (Months)'**
  String get durationMonths;

  /// No description provided for @collateral.
  ///
  /// In en, this message translates to:
  /// **'Collateral NFT'**
  String get collateral;

  /// No description provided for @monthlyPayment.
  ///
  /// In en, this message translates to:
  /// **'Estimated Monthly Payment'**
  String get monthlyPayment;

  /// No description provided for @activeLoans.
  ///
  /// In en, this message translates to:
  /// **'Active Loans'**
  String get activeLoans;

  /// No description provided for @loanHistory.
  ///
  /// In en, this message translates to:
  /// **'Loan History'**
  String get loanHistory;

  /// No description provided for @loanStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get loanStatusPending;

  /// No description provided for @loanStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get loanStatusActive;

  /// No description provided for @loanStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed / Repaid'**
  String get loanStatusCompleted;

  /// No description provided for @loanStatusDefaulted.
  ///
  /// In en, this message translates to:
  /// **'Defaulted'**
  String get loanStatusDefaulted;

  /// No description provided for @makeOffer.
  ///
  /// In en, this message translates to:
  /// **'Make Offer'**
  String get makeOffer;

  /// No description provided for @loanContract.
  ///
  /// In en, this message translates to:
  /// **'Loan Contract'**
  String get loanContract;

  /// No description provided for @loanPurpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get loanPurpose;

  /// No description provided for @seedsFertilizers.
  ///
  /// In en, this message translates to:
  /// **'Seeds & Fertilizers'**
  String get seedsFertilizers;

  /// No description provided for @machineryEquipment.
  ///
  /// In en, this message translates to:
  /// **'Machinery & Equipment'**
  String get machineryEquipment;

  /// No description provided for @irrigation.
  ///
  /// In en, this message translates to:
  /// **'Irrigation'**
  String get irrigation;

  /// No description provided for @expectedRoi.
  ///
  /// In en, this message translates to:
  /// **'Expected ROI'**
  String get expectedRoi;

  /// No description provided for @repaymentPeriod.
  ///
  /// In en, this message translates to:
  /// **'Repayment'**
  String get repaymentPeriod;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;

  /// No description provided for @myLoanRequests.
  ///
  /// In en, this message translates to:
  /// **'My Loan Requests'**
  String get myLoanRequests;

  /// No description provided for @browseRequests.
  ///
  /// In en, this message translates to:
  /// **'Browse Requests'**
  String get browseRequests;

  /// No description provided for @loanOffers.
  ///
  /// In en, this message translates to:
  /// **'Loan Offers'**
  String get loanOffers;

  /// No description provided for @myOffers.
  ///
  /// In en, this message translates to:
  /// **'My Offers'**
  String get myOffers;

  /// No description provided for @addLoanRequest.
  ///
  /// In en, this message translates to:
  /// **'Add Loan Request'**
  String get addLoanRequest;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileTitle;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @kycStatus.
  ///
  /// In en, this message translates to:
  /// **'KYC Verification'**
  String get kycStatus;

  /// No description provided for @digiLockerVerified.
  ///
  /// In en, this message translates to:
  /// **'DigiLocker Verified'**
  String get digiLockerVerified;

  /// No description provided for @notVerified.
  ///
  /// In en, this message translates to:
  /// **'Not Verified'**
  String get notVerified;

  /// No description provided for @verifyNow.
  ///
  /// In en, this message translates to:
  /// **'Verify Now with DigiLocker'**
  String get verifyNow;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी (Hindi)'**
  String get hindi;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalance;

  /// No description provided for @addMoney.
  ///
  /// In en, this message translates to:
  /// **'Add Money'**
  String get addMoney;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @walletDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Wallet Disconnected'**
  String get walletDisconnected;

  /// No description provided for @connectWallet.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectWallet;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @personalInfoDesc.
  ///
  /// In en, this message translates to:
  /// **'Update your profile details'**
  String get personalInfoDesc;

  /// No description provided for @ratingsReviews.
  ///
  /// In en, this message translates to:
  /// **'Ratings & Reviews'**
  String get ratingsReviews;

  /// No description provided for @ratingsReviewsDesc.
  ///
  /// In en, this message translates to:
  /// **'View your ratings and feedback'**
  String get ratingsReviewsDesc;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @securityDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage password and authentication'**
  String get securityDesc;

  /// No description provided for @myWallet.
  ///
  /// In en, this message translates to:
  /// **'My Wallet'**
  String get myWallet;

  /// No description provided for @myWalletDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage balance and transactions'**
  String get myWalletDesc;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @termsService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @downloadAgreements.
  ///
  /// In en, this message translates to:
  /// **'Download Legal Agreements & Receipts'**
  String get downloadAgreements;

  /// No description provided for @contracts.
  ///
  /// In en, this message translates to:
  /// **'Contracts & Agreements'**
  String get contracts;

  /// No description provided for @contractCropSale.
  ///
  /// In en, this message translates to:
  /// **'Crop Sale Agreement'**
  String get contractCropSale;

  /// No description provided for @contractLoan.
  ///
  /// In en, this message translates to:
  /// **'Loan Agreement'**
  String get contractLoan;

  /// No description provided for @noContractsYet.
  ///
  /// In en, this message translates to:
  /// **'No contracts yet'**
  String get noContractsYet;

  /// No description provided for @noContractsDesc.
  ///
  /// In en, this message translates to:
  /// **'Your purchase contracts will appear here after placing orders'**
  String get noContractsDesc;

  /// No description provided for @contractManager.
  ///
  /// In en, this message translates to:
  /// **'Contract Manager'**
  String get contractManager;

  /// No description provided for @contractsAvailable.
  ///
  /// In en, this message translates to:
  /// **'contracts available'**
  String get contractsAvailable;

  /// No description provided for @aboutContracts.
  ///
  /// In en, this message translates to:
  /// **'About Contracts'**
  String get aboutContracts;

  /// No description provided for @aboutContractPoint1.
  ///
  /// In en, this message translates to:
  /// **'Contracts are generated automatically when you place orders'**
  String get aboutContractPoint1;

  /// No description provided for @aboutContractPoint2.
  ///
  /// In en, this message translates to:
  /// **'All contracts are securely stored in the cloud'**
  String get aboutContractPoint2;

  /// No description provided for @aboutContractPoint3.
  ///
  /// In en, this message translates to:
  /// **'Download or view your contracts anytime'**
  String get aboutContractPoint3;

  /// No description provided for @aboutContractPoint4.
  ///
  /// In en, this message translates to:
  /// **'Contracts serve as legal proof of transaction'**
  String get aboutContractPoint4;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @viewContract.
  ///
  /// In en, this message translates to:
  /// **'View Contract'**
  String get viewContract;

  /// No description provided for @marketTrends.
  ///
  /// In en, this message translates to:
  /// **'Market Trends'**
  String get marketTrends;

  /// No description provided for @priceTrends7Days.
  ///
  /// In en, this message translates to:
  /// **'Price Trends (Last 7 Days)'**
  String get priceTrends7Days;

  /// No description provided for @recentBidding.
  ///
  /// In en, this message translates to:
  /// **'Recent Bidding Activity'**
  String get recentBidding;

  /// No description provided for @totalBids.
  ///
  /// In en, this message translates to:
  /// **'Total Bids'**
  String get totalBids;

  /// No description provided for @wonAuctions.
  ///
  /// In en, this message translates to:
  /// **'Won Auctions'**
  String get wonAuctions;

  /// No description provided for @totalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get totalSpent;

  /// No description provided for @statusWon.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get statusWon;

  /// No description provided for @statusOutbid.
  ///
  /// In en, this message translates to:
  /// **'Outbid'**
  String get statusOutbid;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Direct Agricultural Marketplace'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Connect directly with verified buyers without middlemen, maximizing your harvest profits.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'AI Land Intelligence & Agri-Score'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Leverage satellite NDVI, soil data, and machine learning to build instant trust with buyers.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Instant DeFi Micro-Loans'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Unlock flexible financing against your listed crops with transparent smart contracts.'**
  String get onboardingDesc3;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
