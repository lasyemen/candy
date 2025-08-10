part of signin_screen;

mixin SignInScreenFunctions on State<SignInScreen> {
  void _submitForm() async {
    if (!(this as _SignInScreenState)._formKey.currentState!.validate()) return;

    (this as _SignInScreenState).setState(() {
      (this as _SignInScreenState)._isLoading = true;
    });

    try {
      final String rawPhone = (this as _SignInScreenState)._phoneController.text
          .trim();
      final bool? isMerchant = await AuthActions.signInAndSetSession(rawPhone);
      if (isMerchant == false) {
        if (mounted) {
          (this as _SignInScreenState).setState(() {
            (this as _SignInScreenState)._isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('رقم الهاتف غير مسجل. يرجى إنشاء حساب جديد.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        (this as _SignInScreenState).setState(() {
          (this as _SignInScreenState)._isLoading = false;
        });

        if (CustomerSession.instance.isLoggedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم تسجيل الدخول بنجاح!'),
              backgroundColor: Colors.green,
            ),
          );
          final bool merchantFlag = CustomerSession.instance.isMerchant;
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.main,
            arguments: merchantFlag ? {'isMerchant': true} : null,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حدث خطأ في تسجيل الدخول. يرجى المحاولة مرة أخرى.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        (this as _SignInScreenState).setState(() {
          (this as _SignInScreenState)._isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
