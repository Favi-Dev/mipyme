class ClientData {
  static bool hasActiveSubscription = true;
  static bool isMonthlyCouponRedeemed = false;
  static double couponAmount = 10000;
  static DateTime expirationDate = DateTime.now().add(const Duration(days: 30));
}
