part of rewards_test_screen;

mixin RewardsTestScreenFunctions on State<RewardsTestScreen> {
  int points = 0;
  List<Map<String, dynamic>> vouchers = const [];
  String? lastMessage;

  Future<void> refreshRewards() async {
    final p = await RewardsService.instance.getPointsBalance();
    final v = await RewardsService.instance.getActiveVouchers();
    if (!mounted) return;
    setState(() {
      points = p;
      vouchers = v;
    });
  }

  Future<void> simulatePurchase(double amountSar) async {
    await RewardsService.instance.addPointsFromPurchase(amountSar);
    await refreshRewards();
    if (!mounted) return;
    setState(() {
      lastMessage = 'Purchase +${amountSar.toStringAsFixed(0)} pts';
    });
  }

  Future<void> addHealthyChange(String changeId) async {
    final ok = await RewardsService.instance.addPointsForHealthyChange(
      changeId,
    );
    await refreshRewards();
    if (!mounted) return;
    setState(() {
      lastMessage = ok ? 'Healthy change +30 pts' : 'Already awarded';
    });
  }
}




