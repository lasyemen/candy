part of test_checkout_screen;

mixin TestCheckoutScreenFunctions on State<TestCheckoutScreen> {
  List<Map<String, dynamic>> vouchers = const [];

  Future<void> _loadVouchers() async {
    vouchers = await RewardsService.instance.getActiveVouchers();
    if (mounted) setState(() {});
  }
}


