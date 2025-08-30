part of '../signin_screen.dart';

mixin SignInScreenFunctions on State<SignInScreen> {
  void _submitForm() async {
    if (!(this as _SignInScreenState)._formKey.currentState!.validate()) return;

    (this as _SignInScreenState).setState(() {
      (this as _SignInScreenState)._isLoading = true;
    });

    try {
      final String rawPhone = (this as _SignInScreenState)._phoneController.text
          .trim();

      // Normalize first so we accept local and international formats
      final String? normalized = PhoneUtils.normalizeKsaPhone(rawPhone);
      if (normalized == null || !normalized.startsWith('+966')) {
        (this as _SignInScreenState).setState(() {
          (this as _SignInScreenState)._isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('أدخل رقم سعودي صحيح'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Pass normalized phone to sign-in flow
      final bool? isMerchant = await AuthActions.signInAndSetSession(
        normalized,
      );
      print('SignInScreen - AuthActions returned: $isMerchant');
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
