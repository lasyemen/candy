part of otp_screen;

mixin OtpScreenFunctions on State<OtpScreen> {
  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && (this as _OtpScreenState)._remainingTime > 0) {
        (this as _OtpScreenState).setState(() {
          (this as _OtpScreenState)._remainingTime--;
        });
        _startCountdown();
      }
    });
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 3) {
      (this as _OtpScreenState)._focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      (this as _OtpScreenState)._focusNodes[index - 1].requestFocus();
    }
  }

  // helper removed as unused

  void _verifyOtp() {
    Navigator.pushReplacementNamed(context, AppRoutes.main);
  }

  void _resendOtp() {
    (this as _OtpScreenState).setState(() {
      (this as _OtpScreenState)._remainingTime = 60;
    });
    _startCountdown();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إرسال رمز التحقق الجديد'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
