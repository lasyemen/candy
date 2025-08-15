import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_settings.dart';
import '../../core/services/auto_translator.dart';

class AutoTranslateText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AutoTranslateText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  State<AutoTranslateText> createState() => _AutoTranslateTextState();
}

class _AutoTranslateTextState extends State<AutoTranslateText> {
  String? _translated;
  String _lastText = '';
  String _lastLang = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeTranslate();
  }

  @override
  void didUpdateWidget(covariant AutoTranslateText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeTranslate();
  }

  Future<void> _maybeTranslate() async {
    final language = context.read<AppSettings>().currentLanguage;
    final text = widget.text;
    if (_lastLang == language && _lastText == text) return;
    _lastLang = language;
    _lastText = text;

    if (!mounted) return;
    final result = await AutoTranslator.instance.translate(text, to: language);
    if (!mounted) return;
    setState(() => _translated = result);
  }

  @override
  Widget build(BuildContext context) {
    // Language not needed since Rubik is enforced globally here
    final baseStyle = widget.style ?? const TextStyle();
    final style = baseStyle.copyWith(
      fontFamily: 'Rubik',
      fontWeight: FontWeight.w700,
    );
    return Text(
      _translated ?? widget.text,
      style: style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
