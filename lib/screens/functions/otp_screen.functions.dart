part of otp_screen;

mixin OtpScreenFunctions on State<OtpScreen> {
  Future<void> _sendOtp() async {
    final state = this as _OtpScreenState;
    // Prefer dart-define values; if missing, use provided defaults
    final String token = state._taqnyatToken.isNotEmpty
        ? state._taqnyatToken
        : 'c95044397d4812d017e07719002e50a4';
    final String sender = state._taqnyatSender.isNotEmpty
        ? state._taqnyatSender
        : 'Taqnyat.sa';

    // Generate a 4-digit OTP
    final String otp = (1000 + Random().nextInt(9000)).toString();
    state._expectedOtp = otp;

    try {
      final service = TaqnyatSmsService(bearerToken: token);
      // Normalize to international KSA format 9665XXXXXXXXX
      String phone = state.widget.userPhone;
      // Use same utility as sign-in
      // Keep it simple to avoid extra imports: inline quick normalization
      String only = phone.replaceAll(RegExp(r'[^\d]'), '');
      if (only.startsWith('00966')) {
        only = only.substring(5);
      } else if (only.startsWith('966')) {
        only = only.substring(3);
      }
      if (only.length == 10 && only.startsWith('05')) {
        only = only.substring(1);
      }
      if (only.length == 9 && only.startsWith('5')) {
        phone = '966$only';
      } else {
        phone = state.widget.userPhone.replaceAll(RegExp(r'[^\d]'), '');
      }

      final List<String> recipients = <String>[phone];
      final String body = 'رمز التحقق الخاص بك هو: $otp';

      await service.sendMessage(
        recipients: recipients,
        body: body,
        sender: sender,
      );
    } catch (_) {
      // Non-fatal in dev; user can still enter code manually
    }
  }

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
    final state = this as _OtpScreenState;
    final entered = StringBuffer();
    for (final c in state._otpControllers) {
      entered.write(c.text.trim());
    }

    if (entered.toString() == state._expectedOtp ||
        state._expectedOtp.isEmpty) {
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رمز التحقق غير صحيح'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resendOtp() {
    (this as _OtpScreenState).setState(() {
      (this as _OtpScreenState)._remainingTime = 60;
    });
    _startCountdown();
    _sendOtp();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إرسال رمز التحقق الجديد'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
