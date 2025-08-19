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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final List<FocusNode> _codeFocus = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _codeCells = List.generate(6, (_) => TextEditingController());

  // Simple country model and data
  static const List<_Country> _allCountries = <_Country>[
    _Country(name: 'Russia', dialCode: '+7', flag: '🇷🇺'),
    _Country(name: 'Netherlands', dialCode: '+31', flag: '🇳🇱'),
    _Country(name: 'United States', dialCode: '+1', flag: '🇺🇸'),
    _Country(name: 'United Kingdom', dialCode: '+44', flag: '🇬🇧'),
    _Country(name: 'Germany', dialCode: '+49', flag: '🇩🇪'),
    _Country(name: 'France', dialCode: '+33', flag: '🇫🇷'),
    _Country(name: 'Spain', dialCode: '+34', flag: '🇪🇸'),
    _Country(name: 'Italy', dialCode: '+39', flag: '🇮🇹'),
    _Country(name: 'Ukraine', dialCode: '+380', flag: '🇺🇦'),
    _Country(name: 'Belarus', dialCode: '+375', flag: '🇧🇾'),
    _Country(name: 'Kazakhstan', dialCode: '+7', flag: '🇰🇿'),
    _Country(name: 'Armenia', dialCode: '+374', flag: '🇦🇲'),
    _Country(name: 'Georgia', dialCode: '+995', flag: '🇬🇪'),
    _Country(name: 'China', dialCode: '+86', flag: '🇨🇳'),
    _Country(name: 'Japan', dialCode: '+81', flag: '🇯🇵'),
    _Country(name: 'India', dialCode: '+91', flag: '🇮🇳'),
    _Country(name: 'Brazil', dialCode: '+55', flag: '🇧🇷'),
    _Country(name: 'Canada', dialCode: '+1', flag: '🇨🇦'),
    _Country(name: 'Australia', dialCode: '+61', flag: '🇦🇺'),
    _Country(name: 'Turkey', dialCode: '+90', flag: '🇹🇷'),
  ];
  _Country _selectedCountry = const _Country(name: 'Russia', dialCode: '+7', flag: '🇷🇺');
  final TextEditingController _countrySearchController = TextEditingController();
  bool _countryListOpen = false;

  bool _isSubmitting = false;
  bool _codeSent = false;

  @override
  void initState() {
    super.initState();
    // Prefill phone input with default country's dial code
    _applySelectedCountryPrefix();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _countrySearchController.dispose();
    for (final f in _codeFocus) f.dispose();
    for (final c in _codeCells) c.dispose();
    super.dispose();
  }

  String _fullPhone() {
    final raw = _phoneController.text.trim();
    // If user removed prefix, restore selected country code
    if (!raw.startsWith('+')) {
      return _selectedCountry.dialCode + raw.replaceAll(RegExp(r'[^0-9]'), '');
    }
    final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    return digits;
  }

  void _applySelectedCountryPrefix() {
    final text = _phoneController.text;
    final rest = text.startsWith('+')
        ? text.replaceFirst(RegExp(r'^\+\d+\s*'), '')
        : text;
    final next = '${_selectedCountry.dialCode} ${rest.trim()}'.trimRight();
    _phoneController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
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
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDFE1E5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDFE1E5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDFE1E5)),
          ),
        ),
        onChanged: (v) => _onCodeChanged(idx, v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _codeSent ? 'Enter code' : 'Sign in to Words';

    return Scaffold(
      backgroundColor: Colors.white,
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
                        ? 'We sent a confirmation code via SMS. Enter 000000 for mock.'
                        : 'Please confirm your country code and enter your phone number.',
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
                          // Country dropdown with inline search
                          _CountrySelector(
                            selected: _selectedCountry,
                            onChanged: (c) {
                              setState(() => _selectedCountry = c);
                              _applySelectedCountryPrefix();
                            },
                          ),
                          const SizedBox(height: 12),
                          // Single phone input with auto prefix
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9\s\-+()]')),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              hintText: '${_selectedCountry.dialCode} 999 123 45 67',
                              filled: true,
                              fillColor: Colors.white,
                              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                              enabledBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(color: Color(0xFFDFE1E5)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(color: Color(0xFFDFE1E5)),
                              ),
                            ),
                            onTap: () {
                              if (!_phoneController.text.startsWith('+')) {
                                _applySelectedCountryPrefix();
                              }
                            },
                            validator: (value) {
                              final raw = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                              if (raw.isEmpty) return 'Enter phone';
                              if (raw.length < 6) return 'Too short';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _isSubmitting ? null : _requestCode,
                            style: FilledButton.styleFrom(
                              backgroundColor: TelegramColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 21),
                              minimumSize: const Size.fromHeight(48),
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
                                : const Text('NEXT', style: TextStyle(color: TelegramColors.textOnPrimary)),
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
                          // Single full-width login button
                          FilledButton(
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
                              padding: const EdgeInsets.symmetric(vertical: 21),
                              minimumSize: const Size.fromHeight(48),
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
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => setState(() {
                                        _codeSent = false;
                                      }),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF0A84FF),
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              ),
                              child: const Text('Изменить номер'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'For mock purposes: the code is always 000000. Profile is saved locally.',
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

class _CountrySelector extends StatefulWidget {
  final _Country selected;
  final ValueChanged<_Country> onChanged;
  const _CountrySelector({required this.selected, required this.onChanged});

  @override
  State<_CountrySelector> createState() => _CountrySelectorState();
}

class _CountrySelectorState extends State<_CountrySelector> {
  final TextEditingController _search = TextEditingController();
  bool _open = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Iterable<_Country> _filtered() {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _TelegramLoginPageState._allCountries;
    return _TelegramLoginPageState._allCountries.where((c) =>
        c.name.toLowerCase().contains(q) || c.dialCode.contains(q));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _open = !_open),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Country',
              filled: true,
              fillColor: Colors.white,
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Color(0xFFDFE1E5)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Color(0xFFDFE1E5)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Text(widget.selected.flag, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(widget.selected.name, style: const TextStyle(fontSize: 16)),
                ]),
                const Icon(Icons.expand_more, color: Color(0xFF8E8E93)),
              ],
            ),
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            constraints: const BoxConstraints(maxHeight: 320),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search country',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDFE1E5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDFE1E5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDFE1E5)),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: _filtered().map((c) {
                      final selected = c.name == widget.selected.name && c.dialCode == widget.selected.dialCode;
                      return ListTile(
                        dense: true,
                        leading: Text(c.flag, style: const TextStyle(fontSize: 20)),
                        title: Text(c.name),
                        trailing: Text(c.dialCode, style: const TextStyle(color: Color(0xFF8E8E93))),
                        selected: selected,
                        onTap: () {
                          widget.onChanged(c);
                          setState(() => _open = false);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Country {
  final String name;
  final String dialCode;
  final String flag;
  const _Country({required this.name, required this.dialCode, required this.flag});
}