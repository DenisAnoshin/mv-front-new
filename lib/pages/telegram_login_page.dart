import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../stores/user_store.dart';
import '../stores/chat_store.dart';
import '../theme/telegram_colors.dart';
import 'chat_list_page.dart';
import '../pages/home_shell.dart';

class TelegramLoginPage extends StatefulWidget {
  const TelegramLoginPage({super.key});

  @override
  State<TelegramLoginPage> createState() => _TelegramLoginPageState();
}

class _TelegramLoginPageState extends State<TelegramLoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _countryController = TextEditingController(text: '+7');
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final List<FocusNode> _codeFocus = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _codeCells = List.generate(6, (_) => TextEditingController());

  bool _isSubmitting = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _countryController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    for (final f in _codeFocus) f.dispose();
    for (final c in _codeCells) c.dispose();
    super.dispose();
  }

  String _fullPhone() {
    final cc = _countryController.text.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    final pn = _phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    return (cc.isEmpty ? '+7' : cc) + pn;
  }

  Future<void> _requestCode() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    setState(() => _isSubmitting = true);
    final userStore = context.read<UserStore>();
    final ok = await userStore.requestLoginCode(_fullPhone());
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _codeSent = ok;
      });
    }
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Код отправлен. Для мока введите: 000000')),
      );
    }
  }

  Future<void> _verifyCode() async {
    setState(() => _isSubmitting = true);
    final userStore = context.read<UserStore>();
    final chatStore = context.read<ChatStore>();
    final ok = await userStore.verifySmsCode(_gatherCode());
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
    if (ok && mounted) {
      await chatStore.loadMockChats(userStore.currentUser!);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный код. Для мока используйте 000000.')),
      );
    }
  }

  String _gatherCode() => _codeCells.map((c) => c.text).join();

  void _onCodeChanged(int idx, String value) {
    if (value.length > 1) {
      // if user pasted
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < 6 && i < digits.length; i++) {
        _codeCells[i].text = digits[i];
      }
      if (digits.length >= 6) {
        FocusScope.of(context).unfocus();
        _verifyCode();
      }
      return;
    }
    if (value.isNotEmpty) {
      if (idx < 5) {
        _codeFocus[idx + 1].requestFocus();
      } else {
        FocusScope.of(context).unfocus();
        if (_gatherCode().length == 6) _verifyCode();
      }
    } else {
      if (idx > 0) _codeFocus[idx - 1].requestFocus();
    }
  }

  Widget _codeBox(int idx) {
    final controller = _codeCells[idx];
    final focus = _codeFocus[idx];
    return SizedBox(
      width: 48,
      child: TextField(
        controller: controller,
        focusNode: focus,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.04),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        onChanged: (v) => _onCodeChanged(idx, v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _codeSent ? 'Введите код' : 'Вход по номеру телефона';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: TelegramColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: SvgPicture.asset('assets/svg/logo.svg'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: TelegramColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _codeSent
                        ? 'Мы отправили код подтверждения в SMS. Введите 000000 для мока.'
                        : 'Укажите код страны и номер телефона, чтобы получить код входа.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: TelegramColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_codeSent) ...[
                          Row(
                            children: [
                              SizedBox(
                                width: 92,
                                child: TextFormField(
                                  controller: _countryController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Код',
                                    hintText: '+7',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                  ),
                                  validator: (v) {
                                    final raw = (v ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
                                    if (raw.isEmpty || !raw.startsWith('+')) return 'Начните с +';
                                    if (raw.length < 2) return 'Коротко';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\s\-]')),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Номер телефона',
                                    hintText: '999 123-45-67',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                  ),
                                  validator: (value) {
                                    final raw = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                                    if (raw.isEmpty) return 'Введите номер';
                                    if (raw.length < 6) return 'Слишком короткий';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _isSubmitting ? null : _requestCode,
                            style: FilledButton.styleFrom(
                              backgroundColor: TelegramColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(TelegramColors.textOnPrimary),
                                    ),
                                  )
                                : const Text('Получить код', style: TextStyle(color: TelegramColors.textOnPrimary)),
                          ),
                        ]
                        else ...[
                          Center(
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: List.generate(6, (i) => _codeBox(i)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => setState(() {
                                            _codeSent = false;
                                          }),
                                  child: const Text('Изменить номер'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () {
                                          final form = _formKey.currentState;
                                          if (form == null) return;
                                          if (!form.validate()) return;
                                          _verifyCode();
                                        },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: TelegramColors.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(TelegramColors.textOnPrimary),
                                          ),
                                        )
                                      : const Text('Войти', style: TextStyle(color: TelegramColors.textOnPrimary)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'В целях мока: код всегда 000000. Профиль будет сохранён локально.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: TelegramColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 