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
      final String digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length != 9 || !digits.startsWith('5')) {
        (this as _SignInScreenState).setState(() {
          (this as _SignInScreenState)._isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('أدخل رقم سعودي صحيح (9 أرقام ويبدأ بـ 5)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final bool? isMerchant = await AuthActions.signInAndSetSession(rawPhone);
      if (isMerchant == false) {
        if (mounted) {
          (this as _SignInScreenState).setState(() {
            (this as _SignInScreenState)._isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Phone number not registered. Please create a new account.',
              ),
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
            const SnackBar(
              content: Text('Signed in successfully!'),
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
              content: Text('Login failed. Please try again.'),
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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
