import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ui_translations_ar.dart';
import 'models/institution.dart';
import 'services/institution_service.dart';

// Language selection: saved locally and applied to all app screens.
final ValueNotifier<bool> _englishMode = ValueNotifier<bool>(false);
bool get _isEnglish => _englishMode.value;

// UI text uses English source strings. Optional Arabic translations live
// separately in ui_translations_ar.dart to keep this file English-only.
String uiTr(String english) =>
    _isEnglish ? english : translateUiToArabic(english);


class AppColors {
  static const Color background = Color(0xFFF7F3E9);
  static const Color surface = Color(0xFFFFFCF4);
  static const Color sageDark = Color(0xFF485D70);
  static const Color sage = Color(0xFF8195A6);
  static const Color sageSoft = Color(0xFFE9EFF3);
  static const Color gold = Color(0xFFC7A96B);
  static const Color text = Color(0xFF303B46);
  static const Color mutedText = Color(0xFF7A8792);
  static const Color outline = Color(0xFFD8D4C6);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(InstitutionPlatformApp());
}

class InstitutionPlatformApp extends StatelessWidget {
  const InstitutionPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _englishMode,
      builder: (context, english, _) => MaterialApp(
        locale: Locale(english ? 'en' : 'ar'),
        debugShowCheckedModeBanner: false,
        title: uiTr('Institution Platform'),
        theme: ThemeData(
          brightness: Brightness.light,
          focusColor: Color(0x66C7A96B),
          hoverColor: Color(0x33405A3C),
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.sageDark,
            brightness: Brightness.light,
            surface: AppColors.surface,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.text,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surface,
            hintStyle: TextStyle(color: AppColors.mutedText),
            prefixIconColor: AppColors.sage,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.sage,
                width: 1.5,
              ),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.sageSoft,
            labelTextStyle: WidgetStatePropertyAll(
              TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: AppColors.text),
            bodyMedium: TextStyle(color: AppColors.text),
          ),
          useMaterial3: true,
        ),
        builder: (context, child) {
          return Shortcuts(
            shortcuts: <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.arrowUp):
              DirectionalFocusIntent(TraversalDirection.up),
              SingleActivator(LogicalKeyboardKey.arrowDown):
              DirectionalFocusIntent(TraversalDirection.down),
              SingleActivator(LogicalKeyboardKey.arrowLeft):
              DirectionalFocusIntent(TraversalDirection.left),
              SingleActivator(LogicalKeyboardKey.arrowRight):
              DirectionalFocusIntent(TraversalDirection.right),
            },
            child: FocusTraversalGroup(
              policy: ReadingOrderTraversalPolicy(),
              child: Directionality(
                textDirection: english ? TextDirection.ltr : TextDirection.rtl,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        },
        home: AppStart(),
      ),
    );
  }
}

// Language control lives inside page layouts (not a global Positioned
// overlay), so it cannot cover the notifications button or other actions.
class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFDF8EC),
      elevation: 1,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () async {
          _englishMode.value = !_englishMode.value;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('interface_english', _englishMode.value);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language, size: 18, color: AppColors.text),
              const SizedBox(width: 4),
              ValueListenableBuilder<bool>(
                valueListenable: _englishMode,
                builder: (context, isEnglish, _) => Text(
                  isEnglish ? 'Arabic' : 'English',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TvSearchField extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  const _TvSearchField({
    required this.hintText,
    required this.onChanged,
    this.autofocus = false,
  });

  @override
  State<_TvSearchField> createState() {
    return _TvSearchFieldState();
  }
}

class _TvSearchFieldState extends State<_TvSearchField> {
  late final FocusNode _remoteFocusNode;
  late final FocusNode _textFocusNode;
  late final TextEditingController _controller;
  bool _editing = false;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _remoteFocusNode = FocusNode(debugLabel: 'TV search control');
    _textFocusNode = FocusNode(debugLabel: 'TV search editor');
    _textFocusNode.addListener(_handleTextFocusChange);
    _controller = TextEditingController();
  }

  void _handleTextFocusChange() {
    if (!mounted || _textFocusNode.hasFocus || !_editing) {
      return;
    }

    setState(() {
      _editing = false;
    });
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  void _setFocusHighlight(bool value) {
    if (!mounted) {
      return;
    }

    setState(() {
      _hasFocus = value;
    });
  }

  void _startEditing() {
    if (_editing) {
      return;
    }

    setState(() {
      _editing = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _textFocusNode.requestFocus();
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    });
  }

  void _finishEditing() {
    if (!_editing) {
      return;
    }

    setState(() {
      _editing = false;
    });
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _remoteFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _textFocusNode.removeListener(_handleTextFocusChange);
    _remoteFocusNode.dispose();
    _textFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      focusNode: _remoteFocusNode,
      autofocus: widget.autofocus,
      onShowFocusHighlight: _setFocusHighlight,
      shortcuts: <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.arrowUp):
        DirectionalFocusIntent(TraversalDirection.up),
        SingleActivator(LogicalKeyboardKey.arrowDown):
        DirectionalFocusIntent(TraversalDirection.down),
        SingleActivator(LogicalKeyboardKey.arrowLeft):
        DirectionalFocusIntent(TraversalDirection.left),
        SingleActivator(LogicalKeyboardKey.arrowRight):
        DirectionalFocusIntent(TraversalDirection.right),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (_editing) {
              _finishEditing();
            } else {
              _startEditing();
            }
            return null;
          },
        ),
      },
      child: _editing
          ? TextField(
        controller: _controller,
        focusNode: _textFocusNode,
        showCursor: true,
        onChanged: widget.onChanged,
        onSubmitted: (_) {
          _finishEditing();
        },
        onTapOutside: (_) {
          _finishEditing();
        },
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: Icon(Icons.search),
        ),
      )
          : GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _startEditing,
        child: InputDecorator(
          isFocused: _hasFocus,
          isEmpty: _controller.text.isEmpty,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search),
            suffixIcon: _hasFocus
                ? Icon(Icons.keyboard_return)
                : null,
          ),
          child: Text(
            _controller.text.isEmpty
                ? widget.hintText
                : _controller.text,
            style: TextStyle(
              color: _controller.text.isEmpty
                  ? AppColors.mutedText
                  : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class AppStart extends StatefulWidget {
  const AppStart({super.key});

  @override
  State<AppStart> createState() {
    return _AppStartState();
  }
}

class _AppStartState extends State<AppStart> {
  final _AdminSessionStore _adminSessionStore =
  _AdminSessionStore();
  final _AdminAuthService _adminAuthService =
  _AdminAuthService();

  Institution? _selectedInstitution;
  _AdminSession? _adminSession;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppState();
  }

  Future<void> _loadAppState() async {
    final preferences = await SharedPreferences.getInstance();
    _englishMode.value = preferences.getBool('interface_english') ?? false;

    final id = preferences.getInt('selected_institution_id');
    final name = preferences.getString('selected_institution_name');
    final city = preferences.getString('selected_institution_city');
    final type = preferences.getString('selected_institution_type') ?? '';
    final description =
        preferences.getString('selected_institution_description') ?? '';
    final address =
        preferences.getString('selected_institution_address') ?? '';
    final phone = preferences.getString('selected_institution_phone') ?? '';
    final email = preferences.getString('selected_institution_email') ?? '';
    final websiteUrl =
        preferences.getString('selected_institution_website_url') ?? '';
    final logoUrl =
        preferences.getString('selected_institution_logo_url') ?? '';
    final latitude = preferences.getDouble('selected_institution_latitude');
    final longitude = preferences.getDouble('selected_institution_longitude');

    Institution? savedInstitution;

    if (id != null && name != null && city != null) {
      savedInstitution = Institution(
        id: id,
        name: name,
        city: city,
        type: type,
        description: description,
        address: address,
        phone: phone,
        email: email,
        websiteUrl: websiteUrl,
        logoUrl: logoUrl,
        latitude: latitude,
        longitude: longitude,
      );
    }

    _AdminSession? savedAdminSession;

    try {
      final storedSession = await _adminSessionStore.read();

      if (storedSession != null) {
        savedAdminSession = await _adminAuthService.verify(
          storedSession.authorizationHeader,
        );
        await _adminSessionStore.write(savedAdminSession);
      }
    } catch (_) {
      await _adminSessionStore.clear();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedInstitution = savedInstitution;
      _adminSession = savedAdminSession;
      _isLoading = false;
    });
  }

  Future<void> _saveAdminSession(_AdminSession session) async {
    await _adminSessionStore.write(session);

    if (!mounted) {
      return;
    }

    setState(() {
      _adminSession = session;
    });
  }

  Future<void> _logoutAdmin() async {
    await _adminSessionStore.clear();

    if (!mounted) {
      return;
    }

    setState(() {
      _adminSession = null;
    });
  }

  Future<void> _selectInstitution(Institution institution) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setInt('selected_institution_id', institution.id);
    await preferences.setString('selected_institution_name', institution.name);
    await preferences.setString(
      'selected_institution_city',
      institution.city,
    );
    await preferences.setString('selected_institution_type', institution.type);
    await preferences.setString(
      'selected_institution_description',
      institution.description,
    );
    await preferences.setString(
      'selected_institution_address',
      institution.address,
    );
    await preferences.setString('selected_institution_phone', institution.phone);
    await preferences.setString('selected_institution_email', institution.email);
    await preferences.setString(
      'selected_institution_website_url',
      institution.websiteUrl,
    );
    await preferences.setString(
      'selected_institution_logo_url',
      institution.logoUrl,
    );

    if (institution.latitude != null) {
      await preferences.setDouble(
        'selected_institution_latitude',
        institution.latitude!,
      );
    } else {
      await preferences.remove('selected_institution_latitude');
    }

    if (institution.longitude != null) {
      await preferences.setDouble(
        'selected_institution_longitude',
        institution.longitude!,
      );
    } else {
      await preferences.remove('selected_institution_longitude');
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedInstitution = institution;
    });
  }

  Future<void> _changeInstitution() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove('selected_institution_id');
    await preferences.remove('selected_institution_name');
    await preferences.remove('selected_institution_city');
    await preferences.remove('selected_institution_type');
    await preferences.remove('selected_institution_description');
    await preferences.remove('selected_institution_address');
    await preferences.remove('selected_institution_phone');
    await preferences.remove('selected_institution_email');
    await preferences.remove('selected_institution_website_url');
    await preferences.remove('selected_institution_logo_url');
    await preferences.remove('selected_institution_latitude');
    await preferences.remove('selected_institution_longitude');

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedInstitution = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final selectedInstitution = _selectedInstitution;

    if (selectedInstitution == null) {
      return InstitutionSetupScreen(
        onInstitutionSelected: _selectInstitution,
      );
    }

    return InstitutionHomeScreen(
      institution: selectedInstitution,
      onChangeInstitution: _changeInstitution,
      adminSession: _adminSession,
      onAdminLoggedIn: _saveAdminSession,
      onAdminLogout: _logoutAdmin,
    );
  }
}

class InstitutionSetupScreen extends StatefulWidget {
  final Future<void> Function(Institution institution) onInstitutionSelected;

  const InstitutionSetupScreen({
    super.key,
    required this.onInstitutionSelected,
  });

  @override
  State<InstitutionSetupScreen> createState() {
    return _InstitutionSetupScreenState();
  }
}

class _InstitutionSetupScreenState extends State<InstitutionSetupScreen> {
  final InstitutionService _institutionService = InstitutionService();

  late Future<List<Institution>> _institutionsFuture;

  String? _selectedCity;
  Institution? _selectedInstitution;
  String _citySearchText = '';
  String _institutionSearchText = '';

  @override
  void initState() {
    super.initState();
    _institutionsFuture = _institutionService.getAllInstitutions();
  }

  void _retry() {
    setState(() {
      _institutionsFuture = _institutionService.getAllInstitutions();
    });
  }

  void _selectCity(String city) {
    setState(() {
      _selectedCity = city;
      _selectedInstitution = null;
      _institutionSearchText = '';
    });
  }

  void _returnToCities() {
    setState(() {
      _selectedCity = null;
      _selectedInstitution = null;
      _citySearchText = '';
      _institutionSearchText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectingInstitution = _selectedCity != null;

    return PopScope<Object?>(
      canPop: !selectingInstitution,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && selectingInstitution) {
          _returnToCities();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: selectingInstitution
              ? IconButton(
            onPressed: _returnToCities,
            tooltip: uiTr('Back to cities'),
            icon: Icon(Icons.arrow_back),
          )
              : null,
          title: Text(
            selectingInstitution ? uiTr('Select Institution') : uiTr('Institution Platform'),
          ),
          actions: const [
            Padding(
              padding: EdgeInsetsDirectional.only(end: 12),
              child: Center(child: _LanguageToggle()),
            ),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<List<Institution>>(
            future: _institutionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorState();
              }

              final institutions = snapshot.data ?? [];

              if (institutions.isEmpty) {
                return Center(
                  child: Text(uiTr('No institutions available right now')),
                );
              }

              final cities = institutions
                  .map((institution) => institution.city)
                  .toSet()
                  .toList()
                ..sort();

              return Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildHeader(),
                    SizedBox(height: 20),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        child: selectingInstitution
                            ? _buildInstitutionStep(institutions)
                            : _buildCityStep(institutions, cities),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            size: 50,
          ),
          SizedBox(height: 12),
          Text(uiTr('Unable to load institutions')),
          SizedBox(height: 12),
          FilledButton(
            onPressed: _retry,
            child: Text(uiTr('Retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final selectingInstitution = _selectedCity != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.sageDark,
            AppColors.sage,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Icon(
              selectingInstitution
                  ? Icons.home_work_outlined
                  : Icons.location_city,
              size: 34,
              color: Color(0xFF485D70),
            ),
          ),
          SizedBox(height: 12),
          Text(
            selectingInstitution ? uiTr('Step 2 of 2') : uiTr('Step 1 of 2'),
            style: TextStyle(
              color: Color(0xFFE7E9DF),
              fontSize: 14,
            ),
          ),
          SizedBox(height: 6),
          Text(
            selectingInstitution
                ? uiTr('Choose your institution in $_selectedCity')
                : uiTr('Choose your city or town'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            selectingInstitution
                ? uiTr('Select an institution, then confirm to continue.')
                : uiTr('We\'ll show institutions in that location.'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFE7E9DF),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityStep(
      List<Institution> institutions,
      List<String> cities,
      ) {
    final search = _citySearchText.trim().toLowerCase();
    final filteredCities = cities.where((city) {
      return city.toLowerCase().contains(search);
    }).toList();

    return Column(
      key: ValueKey('city_step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TvSearchField(
          autofocus: true,
          onChanged: (value) {
            setState(() {
              _citySearchText = value;
            });
          },
          hintText: uiTr('Search cities or towns'),
        ),
        SizedBox(height: 14),
        Expanded(
          child: filteredCities.isEmpty
              ? Center(
            child: Text(uiTr('No matching city or town')),
          )
              : ListView.separated(
            itemCount: filteredCities.length,
            separatorBuilder: (context, index) {
              return SizedBox(height: 10);
            },
            itemBuilder: (context, index) {
              final city = filteredCities[index];
              final institutionCount = institutions.where((institution) {
                return institution.city == city;
              }).length;

              return Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    _selectCity(city);
                  },
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.sageSoft,
                          child: Icon(
                            Icons.place_outlined,
                            color: AppColors.sageDark,
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            city,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          uiTr('$institutionCount institutions'),
                          style: TextStyle(
                            color: AppColors.mutedText,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.sage,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInstitutionStep(List<Institution> institutions) {
    final search = _institutionSearchText.trim().toLowerCase();
    final availableInstitutions = institutions.where((institution) {
      final sameCity = institution.city == _selectedCity;
      final matchesSearch = institution.name.toLowerCase().contains(search);

      return sameCity && matchesSearch;
    }).toList();

    final selectedInstitution = _selectedInstitution;

    return Column(
      key: ValueKey(_selectedCity),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TvSearchField(
          autofocus: true,
          onChanged: (value) {
            setState(() {
              _institutionSearchText = value;
              _selectedInstitution = null;
            });
          },
          hintText: uiTr('Search by institution name'),
        ),
        SizedBox(height: 14),
        Expanded(
          child: availableInstitutions.isEmpty
              ? Center(
            child: Text(uiTr('No matching institution in this area')),
          )
              : ListView.separated(
            itemCount: availableInstitutions.length,
            separatorBuilder: (context, index) {
              return SizedBox(height: 10);
            },
            itemBuilder: (context, index) {
              final institution = availableInstitutions[index];
              final isSelected = selectedInstitution?.id == institution.id;

              return Material(
                color: isSelected
                    ? AppColors.sageSoft
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    setState(() {
                      _selectedInstitution = institution;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isSelected
                              ? AppColors.sageDark
                              : AppColors.sageSoft,
                          child: Icon(
                            Icons.home_work_outlined,
                            color: isSelected
                                ? Colors.white
                                : AppColors.sageDark,
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            institution.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: AppColors.sageDark,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 12),
        FilledButton.icon(
          onPressed: selectedInstitution == null
              ? null
              : () async {
            await widget.onInstitutionSelected(selectedInstitution);
          },
          icon: Icon(Icons.check),
          label: Text(uiTr('Confirm Institution')),
          style: FilledButton.styleFrom(
            padding: EdgeInsets.all(17),
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class InstitutionHomeScreen extends StatefulWidget {
  final Institution institution;
  final Future<void> Function() onChangeInstitution;
  final _AdminSession? adminSession;
  final Future<void> Function(_AdminSession session)
  onAdminLoggedIn;
  final Future<void> Function() onAdminLogout;

  const InstitutionHomeScreen({
    super.key,
    required this.institution,
    required this.onChangeInstitution,
    required this.adminSession,
    required this.onAdminLoggedIn,
    required this.onAdminLogout,
  });

  @override
  State<InstitutionHomeScreen> createState() {
    return _InstitutionHomeScreenState();
  }
}

class _InstitutionHomeScreenState extends State<InstitutionHomeScreen> {
  DateTime _now = DateTime.now();
  Timer? _clockTimer;
  late Future<List<_AdminAnnouncement>> _activeAnnouncementsFuture;
  late Future<List<_InstitutionEvent>> _eventsFuture;
  Institution? _currentInstitution;
  bool _coverRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentInstitution = widget.institution;
    _refreshInstitution();
    _activeAnnouncementsFuture = _loadActiveAnnouncements();
    _eventsFuture = _loadEvents();
    _clockTimer = Timer.periodic(Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InstitutionHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.institution.id != widget.institution.id) {
      setState(() {
        _activeAnnouncementsFuture = _loadActiveAnnouncements();
        _eventsFuture = _loadEvents();
        _currentInstitution = widget.institution;
        _refreshInstitution();
      });
    }
  }

  Future<void> _refreshInstitution() async {
    if (_coverRefreshing) return;
    _coverRefreshing = true;
    try {
      final response = await http.get(
        Uri.parse('${_ApiConfig.baseUrl}/api/institutions/${widget.institution.id}'),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 12));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic> && mounted) {
          setState(() => _currentInstitution = Institution.fromJson(data));
        }
      }
    } catch (_) {
      // Preserve the last available institution data while offline.
    } finally {
      _coverRefreshing = false;
    }
  }

  Future<List<_AdminAnnouncement>> _loadActiveAnnouncements() {
    return _PublicAnnouncementService()
        .getActiveAnnouncements(widget.institution.id);
  }

  Future<List<_InstitutionEvent>> _loadEvents() {
    return _PublicEventService()
        .getUpcomingEvents(widget.institution.id);
  }

  void _reloadActiveAnnouncements() {
    setState(() {
      _activeAnnouncementsFuture = _loadActiveAnnouncements();
      _eventsFuture = _loadEvents();

    });
  }

  Future<void> _openPage(Widget page) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  Future<void> _openAdminPanel(_AdminSession session) async {
    if (session.role == 'INSTITUTION_ADMIN') {
      await _openPage(
        _InstitutionAdminDashboardScreen(
          session: session,
          onLogout: _logoutAdminFromPanel,
        ),
      );
      if (mounted) {
        _reloadActiveAnnouncements();
        await _refreshInstitution();
      }
      return;
    }

    await _openPage(
      _SuperAdminDashboardScreen(
        session: session,
        onLogout: _logoutAdminFromPanel,
      ),
    );
  }

  Future<void> _handleAdminLogin(_AdminSession session) async {
    await widget.onAdminLoggedIn(session);
    if (mounted) await _openAdminPanel(session);
  }

  Future<void> _logoutAdminFromPanel() async {
    await widget.onAdminLogout();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String _formatDate(DateTime date) {
    final months = [
      uiTr('January'), uiTr('February'), uiTr('March'), uiTr('April'), uiTr('May'), uiTr('June'),
      uiTr('July'), uiTr('August'), uiTr('September'), uiTr('October'), uiTr('November'), uiTr('December'),
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _showMoreSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(16, 0, 16, 22),
          children: [
            ListTile(
              title: Text(uiTr('More'), style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(uiTr('Institution and app options')),
            ),
            ListTile(
              leading: Icon(Icons.tv_outlined),
              title: Text(uiTr('Display Screen')),
              subtitle: Text(uiTr('View institution details and announcements on TV')),
              onTap: () {
                Navigator.pop(sheetContext);
                _openPage(_InstitutionDisplayScreen(institution: widget.institution));
              },
            ),
            ListTile(
              leading: Icon(Icons.swap_horiz),
              title: Text(uiTr('Change Institution')),
              onTap: () async {
                Navigator.pop(sheetContext);
                await widget.onChangeInstitution();
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text(uiTr('About the Platform')),
              onTap: () {
                Navigator.pop(sheetContext);
                _openPage(
                  _AboutScreen(
                    onAdminLoggedIn: _handleAdminLogin,
                    adminSession: widget.adminSession,
                    onOpenAdminPanel: _openAdminPanel,
                  ),
                );
              },
            ),
            if (widget.adminSession != null)
              ListTile(
                leading: Icon(Icons.logout),
                title: Text(uiTr('Admin Sign Out')),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await widget.onAdminLogout();
                  if (mounted) setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }


  bool get _institutionAdmin =>
      widget.adminSession?.role == 'INSTITUTION_ADMIN' &&
          widget.adminSession?.institutionId == widget.institution.id;

  bool get _superAdmin => widget.adminSession?.role == 'SUPER_ADMIN';

  Widget _sectionHeader(String title, IconData icon, VoidCallback openAll) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 22),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
          TextButton(
            onPressed: openAll,
            child: Text(uiTr('View All')),
          ),
        ],
      ),
    );
  }

  Widget _upcomingEvents() => FutureBuilder<List<_InstitutionEvent>>(
    future: _eventsFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return SizedBox(
          height: 150,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        return _SoftInfoCard(
          icon: Icons.cloud_off_outlined,
          title: uiTr('Unable to load events'),
          subtitle: uiTr('Pull down to refresh.'),
        );
      }

      final events = snapshot.data ?? <_InstitutionEvent>[];
      if (events.isEmpty) {
        return _SoftInfoCard(
          icon: Icons.event_busy_outlined,
          title: uiTr('No upcoming events'),
          subtitle: uiTr('Institution events will appear here when added.'),
        );
      }

      return SizedBox(
        height: 268,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: events.length > 5 ? 5 : events.length,
          separatorBuilder: (_, __) => SizedBox(width: 12),
          itemBuilder: (context, index) {
            final event = events[index];
            return _HomeEventCard(
              event: event,
              onTap: () => _openPage(
                _EventsScreen(institution: widget.institution),
              ),
            );
          },
        ),
      );
    },
  );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _reloadActiveAnnouncements();
            await _refreshInstitution();
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              _FriendlyInstitutionHeader(
                institution: _currentInstitution ?? widget.institution,
                adminName: widget.adminSession?.name,
                onInstitutionPressed: widget.onChangeInstitution,
                onNotificationsPressed: () => _openPage(_NotificationsScreen()),
              ),
              SizedBox(height: 18),
              // Permanent institution identity cover, never an announcement.
              _InstitutionCoverCard(
                institution: _currentInstitution ?? widget.institution,
                isAdmin: _institutionAdmin,
                onAction: () async {
                  if (_institutionAdmin) {
                    await _openPage(_InstitutionCoverEditor(
                      session: widget.adminSession!,
                    ));
                    if (mounted) await _refreshInstitution();
                  } else {
                    await _openPage(_InstitutionInfoScreen(
                      institution: _currentInstitution ?? widget.institution,
                    ));
                  }
                },
              ),
              SizedBox(height: 15),
              _sectionHeader(uiTr('Important Announcements'), Icons.campaign_outlined,
                      () => _openPage(_NotificationsScreen())),
              FutureBuilder<List<_AdminAnnouncement>>(
                future: _activeAnnouncementsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(height: 180,
                        child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    return _SoftInfoCard(icon: Icons.cloud_off_outlined,
                        title: uiTr('Unable to load announcements'),
                        subtitle: uiTr('Pull down to refresh.'));
                  }
                  final announcements = snapshot.data ?? <_AdminAnnouncement>[];
                  if (announcements.isEmpty) {
                    return _SoftInfoCard(icon: Icons.campaign_outlined,
                        title: uiTr('No announcements right now'),
                        subtitle: uiTr('Announcements will appear when posted by an admin.'));
                  }
                  return _ImportantAnnouncementsCarousel(
                    announcements: announcements,
                    onPressed: (announcement) => _openPage(
                        _AnnouncementDetailsScreen(announcement: announcement)),
                  );
                },
              ),
              SizedBox(height: 8),
              _sectionHeader(uiTr('Upcoming Events'), Icons.event_outlined,
                      () => _openPage(_EventsScreen(institution: widget.institution))),
              _upcomingEvents(),
              SizedBox(height: 18),
              _HomeSimpleHeading(uiTr('Quick Services'), Icons.grid_view_rounded),
              SizedBox(height: 12),
              Row(children: [
                Expanded(child: _HomeShortcut(
                    icon: Icons.apartment_outlined, title: uiTr('Institution'),
                    onTap: () => _openPage(_InstitutionInfoScreen(
                        institution: widget.institution)))),
                SizedBox(width: 10),
                Expanded(child: _HomeShortcut(
                    icon: Icons.campaign_outlined, title: uiTr('Announcements'),
                    onTap: () => _openPage(_NotificationsScreen()))),
                SizedBox(width: 10),
                Expanded(child: _HomeShortcut(
                    icon: Icons.event_available_outlined, title: uiTr('Events'),
                    onTap: () => _openPage(_EventsScreen(
                        institution: widget.institution)))),
                SizedBox(width: 10),
                Expanded(child: _HomeShortcut(
                    icon: Icons.tv_outlined, title: uiTr('Display Screen'),
                    onTap: () => _openPage(_InstitutionDisplayScreen(
                        institution: widget.institution)))),
              ]),
              if (_institutionAdmin || _superAdmin) ...[
                SizedBox(height: 25),
                _HomeSimpleHeading(uiTr('Admin Tools'),
                    Icons.admin_panel_settings_outlined),
                SizedBox(height: 11),
                _HomeAdminAccess(
                  title: _superAdmin ? uiTr('Super Admin Dashboard') : uiTr('Institution Management'),
                  subtitle: _superAdmin
                      ? uiTr('Institutions and admin accounts')
                      : uiTr('Manage announcements and events'),
                  onTap: () => _openAdminPanel(widget.adminSession!),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) _openPage(_EventsScreen(institution: widget.institution));
          if (index == 2) _openPage(_NotificationsScreen());
          if (index == 3) _showMoreSheet();
        },
        destinations: [
          NavigationDestination(icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home), label: uiTr('Home')),
          NavigationDestination(icon: Icon(Icons.event_outlined), label: uiTr('Events')),
          NavigationDestination(icon: Icon(Icons.campaign_outlined), label: uiTr('Announcements')),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: uiTr('More')),
        ],
      ),
    );
  }

}

class _InstitutionPatternPainter extends CustomPainter {
  const _InstitutionPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0x14C7A96B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const cell = 34.0;

    for (double y = 0; y <= size.height + cell; y += cell) {
      for (double x = 0; x <= size.width + cell; x += cell) {
        final center = Offset(x, y);
        final diamond = Path()
          ..moveTo(center.dx, center.dy - cell * 0.45)
          ..lineTo(center.dx + cell * 0.45, center.dy)
          ..lineTo(center.dx, center.dy + cell * 0.45)
          ..lineTo(center.dx - cell * 0.45, center.dy)
          ..close();

        canvas.drawPath(diamond, paint);
        canvas.drawRect(
          Rect.fromCenter(
            center: center,
            width: cell * 0.64,
            height: cell * 0.64,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _HomeHeader extends StatelessWidget {
  final Institution institution;
  final VoidCallback onNotificationsPressed;
  final Future<void> Function() onChangeInstitution;

  const _HomeHeader({
    required this.institution,
    required this.onNotificationsPressed,
    required this.onChangeInstitution,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 48, height: 48),
        SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () async {
              await onChangeInstitution();
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Column(
                children: [
                  Text(
                    institution.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.sageDark,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 7),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 34,
                        child: Divider(
                          color: AppColors.gold,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 7),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: AppColors.gold,
                        ),
                      ),
                      SizedBox(
                        width: 34,
                        child: Divider(
                          color: AppColors.gold,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    institution.city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        _RoundIconButton(
          icon: Icons.notifications_none,
          tooltip: uiTr('Notifications'),
          onPressed: onNotificationsPressed,
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: CircleBorder(
        side: BorderSide(color: AppColors.outline),
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        color: AppColors.sageDark,
        icon: Icon(icon),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  final String gregorianDate;
  final String hijriDate;

  const _DatePill({
    required this.gregorianDate,
    required this.hijriDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 17,
            color: AppColors.sage,
          ),
          SizedBox(width: 7),
          Flexible(
            child: Text(
              hijriDate,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              height: 18,
              child: VerticalDivider(
                width: 1,
                color: AppColors.outline,
              ),
            ),
          ),
          Icon(
            Icons.calendar_today_outlined,
            size: 17,
            color: AppColors.sage,
          ),
          SizedBox(width: 7),
          Text(
            gregorianDate,
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Color(0xFFE8DFCB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 4),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.sageSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.sageDark,
                  size: 25,
                ),
              ),
              SizedBox(height: 11),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminHomeButton extends StatelessWidget {
  final String institutionName;
  final VoidCallback onPressed;

  const _AdminHomeButton({
    required this.institutionName,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.sageDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 15,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Color(0x26FFFFFF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.admin_panel_settings_outlined,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      uiTr('Institution Management'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      institutionName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementCarousel extends StatefulWidget {
  final String institutionName;
  final List<_AdminAnnouncement> announcements;
  final ValueChanged<_AdminAnnouncement> onAnnouncementPressed;
  final ValueChanged<int>? onPageChanged;

  const _AnnouncementCarousel({
    required this.institutionName,
    required this.announcements,
    required this.onAnnouncementPressed,
    this.onPageChanged,
  });

  @override
  State<_AnnouncementCarousel> createState() {
    return _AnnouncementCarouselState();
  }
}

class _AnnouncementCarouselState extends State<_AnnouncementCarousel> {
  static const Duration _switchInterval = Duration(seconds: 6);

  final PageController _pageController = PageController();
  Timer? _autoSwitchTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startAutoSwitch();
  }

  @override
  void didUpdateWidget(covariant _AnnouncementCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_sameAnnouncements(
      oldWidget.announcements,
      widget.announcements,
    )) {
      _currentIndex = 0;

      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }

      _startAutoSwitch();
    }
  }

  bool _sameAnnouncements(
      List<_AdminAnnouncement> first,
      List<_AdminAnnouncement> second,
      ) {
    if (first.length != second.length) {
      return false;
    }

    for (var index = 0; index < first.length; index++) {
      if (first[index].id != second[index].id) {
        return false;
      }
    }

    return true;
  }

  void _startAutoSwitch() {
    _autoSwitchTimer?.cancel();

    if (widget.announcements.length <= 1) {
      return;
    }

    _autoSwitchTimer = Timer.periodic(_switchInterval, (_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }

      final nextIndex =
          (_currentIndex + 1) % widget.announcements.length;

      _pageController.animateToPage(
        nextIndex,
        duration: Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoSwitchTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.announcements.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              widget.onPageChanged?.call(index);
            },
            itemBuilder: (context, index) {
              final announcement = widget.announcements[index];

              return _AnnouncementBanner(
                institutionName: widget.institutionName,
                announcement: announcement,
                onPressed: () {
                  widget.onAnnouncementPressed(announcement);
                },
              );
            },
          ),
        ),
        if (widget.announcements.length > 1) ...[
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.announcements.length,
                  (index) {
                final selected = index == _currentIndex;

                return AnimatedContainer(
                  duration: Duration(milliseconds: 250),
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: selected ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.sageDark
                        : AppColors.outline,
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _AnnouncementBanner extends StatelessWidget {
  final String institutionName;
  final _AdminAnnouncement announcement;
  final VoidCallback onPressed;

  const _AnnouncementBanner({
    required this.institutionName,
    required this.announcement,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = announcement.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 1),
      child: Material(
        color: AppColors.sageDark,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Color(0xFF485D70),
                          Color(0xFF8195A6),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: constraints.maxWidth * 0.50,
                    child: hasImage
                        ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _AnnouncementImageFallback();
                      },
                    )
                        : _AnnouncementImageFallback(),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: [0.05, 0.48, 0.72],
                        colors: [
                          Color(0x00485D70),
                          Color(0xB3485D70),
                          Color(0xFF485D70),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 18, 12),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: constraints.maxWidth * 0.63,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0x33FFFFFF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.campaign_outlined,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    uiTr('Institution announcement'),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Spacer(),
                            Text(
                              announcement.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                height: 1.25,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (announcement.content.trim().isNotEmpty) ...[
                              SizedBox(height: 7),
                              Text(
                                announcement.content,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color(0xFFE8EEE4),
                                  fontSize: 13,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            Spacer(),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    institutionName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.gold,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 21,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AnnouncementImageFallback extends StatelessWidget {
  const _AnnouncementImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF8195A6),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.apartment,
            color: Color(0x55FFFFFF),
            size: 112,
          ),
          Positioned(
            top: 28,
            left: 28,
            child: Icon(
              Icons.auto_awesome,
              color: AppColors.gold,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final String institutionName;
  final String title;
  final VoidCallback? onPressed;

  const _AnnouncementCard({
    required this.institutionName,
    required this.title,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.sageDark,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 180,
          child: Padding(
            padding: EdgeInsets.all(22),
            child: Row(
              children: [
                Icon(
                  Icons.campaign_outlined,
                  color: AppColors.gold,
                  size: 46,
                ),
                SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        uiTr('Institution announcement'),
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        institutionName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturePageScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FeaturePageScaffold({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.sageDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(18, 10, 18, 28),
          children: children,
        ),
      ),
    );
  }
}

class _PageHeroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PageHeroCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFF1EEDC),
            AppColors.sageSoft,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 34,
              color: AppColors.sageDark,
            ),
          ),
          SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 7),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SoftInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.sageSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.sageDark,
            ),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _NotificationsScreen extends StatelessWidget {
  const _NotificationsScreen();

  @override
  Widget build(BuildContext context) {
    return _FeaturePageScaffold(
      title: uiTr('Notifications'),
      children: [
        _PageHeroCard(
          icon: Icons.notifications_none,
          title: uiTr('Institution Notifications'),
          subtitle: uiTr('Important announcements and alerts from your institution will appear here.'),
        ),
        SizedBox(height: 18),
        _SoftInfoCard(
          icon: Icons.notifications_off_outlined,
          title: uiTr('No new notifications'),
          subtitle: uiTr('Notifications will be available here in a future update.'),
        ),
      ],
    );
  }
}


class _InstitutionDisplayScreen extends StatefulWidget {
  final Institution institution;

  const _InstitutionDisplayScreen({required this.institution});

  @override
  State<_InstitutionDisplayScreen> createState() => _InstitutionDisplayScreenState();
}

class _InstitutionDisplayScreenState extends State<_InstitutionDisplayScreen> {
  static const Duration _slideInterval = Duration(seconds: 15);

  DateTime _now = DateTime.now();
  List<_AdminAnnouncement> _announcements = const [];
  int _currentSlideIndex = 0;
  bool _isLoading = true;
  bool _loadFailed = false;
  Timer? _clockTimer;
  Timer? _slideTimer;
  Timer? _refreshTimer;

  int get _slideCount => _announcements.length + 1;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (mounted && _currentSlideIndex == 0) {
        setState(() => _now = DateTime.now());
      } else {
        _now = DateTime.now();
      }
    });
    _refreshTimer = Timer.periodic(
      Duration(minutes: 5),
          (_) => _loadAnnouncements(),
    );
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      final result = await _PublicAnnouncementService()
          .getDisplayAnnouncements(widget.institution.id);
      if (!mounted) return;
      setState(() {
        _announcements = result.where((item) {
          final image = item.imageUrl?.trim();
          return item.showOnDisplayScreen && image != null && image.isNotEmpty;
        }).toList(growable: false);
        _currentSlideIndex = 0;
        _isLoading = false;
        _loadFailed = false;
      });
      _startRotation();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
        _currentSlideIndex = 0;
      });
      _startRotation();
    }
  }

  void _startRotation() {
    _slideTimer?.cancel();
    if (_slideCount <= 1) return;
    _slideTimer = Timer.periodic(_slideInterval, (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
        _currentSlideIndex = (_currentSlideIndex + 1) % _slideCount;
      });
    });
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  String _clock() {
    var hour = _now.hour;
    final period = hour < 12 ? uiTr('AM') : uiTr('PM');
    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;
    return '$hour:${_two(_now.minute)} $period';
  }

  String _date() => '${_two(_now.day)}/${_two(_now.month)}/${_now.year}';

  Widget _welcomeSlide(BoxConstraints constraints) {
    final wide = constraints.maxWidth >= 700;
    return Container(
      key: ValueKey('institution-welcome'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF3E5940), Color(0xFF15261B)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(42),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.apartment_rounded, color: AppColors.gold, size: wide ? 92 : 62),
              SizedBox(height: 20),
              Text(
                widget.institution.name,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: wide ? 58 : 34, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 10),
              Text(
                widget.institution.city,
                style: TextStyle(color: Color(0xFFDCE6D8), fontSize: wide ? 28 : 18),
              ),
              SizedBox(height: 34),
              Text(
                _clock(),
                textDirection: TextDirection.ltr,
                style: TextStyle(color: AppColors.gold, fontSize: wide ? 64 : 38, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 6),
              Text(_date(), style: TextStyle(color: Colors.white70, fontSize: wide ? 24 : 16)),
              SizedBox(height: 28),
              Text(uiTr('Welcome'), style: TextStyle(color: Colors.white, fontSize: wide ? 32 : 21, fontWeight: FontWeight.w700)),
              if (_isLoading) ...[
                SizedBox(height: 24),
                CircularProgressIndicator(color: AppColors.gold),
              ] else if (_loadFailed) ...[
                SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _loadAnnouncements,
                  icon: Icon(Icons.refresh),
                  label: Text(uiTr('Refresh announcements')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _announcementSlide(_AdminAnnouncement item, BoxConstraints constraints) {
    final wide = constraints.maxWidth >= 700;
    return Container(
      key: ValueKey('display-announcement-${item.id}'),
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            item.imageUrl!,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : Center(child: CircularProgressIndicator(color: AppColors.gold)),
            errorBuilder: (_, __, ___) => Center(
              child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 74),
            ),
          ),
          if (item.title.trim().isNotEmpty || item.content.trim().isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: wide ? 48 : 24, vertical: wide ? 24 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xE6000000)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.title, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: wide ? 32 : 21, fontWeight: FontWeight.w900)),
                    if (item.content.trim().isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(item.content, maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: wide ? 20 : 14)),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _currentSlide(BoxConstraints constraints) {
    if (_currentSlideIndex == 0 || _announcements.isEmpty) {
      return _welcomeSlide(constraints);
    }
    final index = _currentSlideIndex - 1;
    if (index < 0 || index >= _announcements.length) return _welcomeSlide(constraints);
    return _announcementSlide(_announcements[index], constraints);
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _slideTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: Duration(milliseconds: 800),
                child: _currentSlide(constraints),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: IconButton.filledTonal(
                      tooltip: uiTr('Back'),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_forward),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventsScreen extends StatelessWidget {
  final Institution institution;

  const _EventsScreen({required this.institution});

  @override
  Widget build(BuildContext context) {
    return _FeaturePageScaffold(
      title: uiTr('Events'),
      children: [
        _PageHeroCard(
          icon: Icons.event_outlined,
          title: uiTr('Institution events'),
          subtitle: uiTr('Upcoming meetings, workshops and activities with dates and times.'),
        ),
        SizedBox(height: 18),
        FutureBuilder<List<_InstitutionEvent>>(
          future: _PublicEventService()
              .getUpcomingEvents(institution.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _SoftInfoCard(
                icon: Icons.cloud_off_outlined,
                title: uiTr('Unable to load events'),
                subtitle: uiTr('Check the server connection and try again.'),
              );
            }
            final events = snapshot.data ?? const [];
            if (events.isEmpty) {
              return _SoftInfoCard(
                icon: Icons.event_busy_outlined,
                title: uiTr('No events at the moment'),
                subtitle: uiTr('Events created by institution admins will appear here.'),
              );
            }
            return Column(
              children: events.map((event) {
                final location = event.location.trim();
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Card(
                    color: AppColors.surface,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 170,
                            child: (event.imageUrl ?? '').trim().isEmpty
                                ? _EventImagePlaceholder()
                                : Image.network(event.imageUrl!.trim(),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _EventImagePlaceholder())),
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(event.title, style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w800)),
                              SizedBox(height: 8),
                              Text([
                                _formatAdminDate(event.startAt),
                                if (location.isNotEmpty) location,
                                if (event.description.trim().isNotEmpty)
                                  event.description.trim(),
                              ].join(' • ')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _InstitutionInfoScreen extends StatelessWidget {
  final Institution institution;

  const _InstitutionInfoScreen({required this.institution});

  @override
  Widget build(BuildContext context) {
    final description = institution.description.trim();
    final address = institution.address.trim().isNotEmpty
        ? institution.address.trim()
        : institution.city;
    final contact = [
      institution.phone.trim(),
      institution.email.trim(),
      institution.websiteUrl.trim(),
    ].where((value) => value.isNotEmpty).join(' • ');

    return _FeaturePageScaffold(
      title: uiTr('Institution Information'),
      children: [
        _PageHeroCard(
          icon: Icons.apartment_outlined,
          title: institution.name,
          subtitle: institution.type.trim().isEmpty
              ? uiTr('Institution information and contact details.')
              : institution.type.trim(),
        ),
        SizedBox(height: 18),
        _SoftInfoCard(
          icon: Icons.info_outline,
          title: uiTr('About the institution'),
          subtitle: description.isEmpty
              ? uiTr('No institution description has been added.')
              : description,
        ),
        SizedBox(height: 10),
        _SoftInfoCard(
          icon: Icons.location_on_outlined,
          title: uiTr('Address'),
          subtitle: address.isEmpty ? uiTr('No address has been added.') : address,
        ),
        SizedBox(height: 10),
        _SoftInfoCard(
          icon: Icons.contact_phone_outlined,
          title: uiTr('Contact Information'),
          subtitle: contact.isEmpty
              ? uiTr('No contact information has been added.')
              : contact,
        ),
      ],
    );
  }
}

class _AnnouncementDetailsScreen extends StatelessWidget {
  final _AdminAnnouncement announcement;

  const _AnnouncementDetailsScreen({
    required this.announcement,
  });

  @override
  Widget build(BuildContext context) {
    return _FeaturePageScaffold(
      title: uiTr('Announcement Details'),
      children: [
        Text(
          announcement.title,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: AppColors.sageDark,
            fontSize: 26,
            height: 1.3,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (announcement.content.trim().isNotEmpty) ...[
          SizedBox(height: 12),
          Text(
            announcement.content,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 17,
              height: 1.7,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (announcement.imageUrl != null &&
            announcement.imageUrl!.trim().isNotEmpty) ...[
          SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.network(
              announcement.imageUrl!,
              width: double.infinity,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return child;
                }

                return SizedBox(
                  height: 260,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.sageDark,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _SoftInfoCard(
                  icon: Icons.broken_image_outlined,
                  title: uiTr('Cannot display announcement image'),
                  subtitle: uiTr('Check the image URL and internet connection.'),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _AboutScreen extends StatelessWidget {
  final _AdminSession? adminSession;
  final Future<void> Function(_AdminSession session)
  onAdminLoggedIn;
  final Future<void> Function(_AdminSession session)
  onOpenAdminPanel;

  const _AboutScreen({
    required this.adminSession,
    required this.onAdminLoggedIn,
    required this.onOpenAdminPanel,
  });

  Future<void> _handleLogoPressed(BuildContext context) async {
    final currentSession = adminSession;

    if (currentSession != null) {
      await onOpenAdminPanel(currentSession);
      return;
    }

    final session = await Navigator.of(context).push<_AdminSession>(
      MaterialPageRoute<_AdminSession>(
        builder: (context) {
          return _AdminLoginScreen();
        },
      ),
    );

    if (session != null) {
      await onAdminLoggedIn(session);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FeaturePageScaffold(
      title: uiTr('About the App'),
      children: [
        _PageHeroCard(
          icon: Icons.apartment_outlined,
          title: uiTr('Institution Platform'),
          subtitle: uiTr('A platform connecting people with institutions, announcements, events and services.'),
        ),
        SizedBox(height: 18),
        _SoftInfoCard(
          icon: Icons.info_outline,
          title: uiTr('Current Version'),
          subtitle: uiTr('Early version under development and testing.'),
        ),
        SizedBox(height: 30),
        Center(
          child: _DescendantsLogoButton(
            onPressed: () async {
              await _handleLogoPressed(context);
            },
          ),
        ),
        SizedBox(height: 10),
        Center(
          child: Text(
            uiTr('Version 1.0.0'),
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _DescendantsLogoButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DescendantsLogoButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: uiTr('Admin Login'),
      child: Material(
        color: AppColors.surface,
        shape: CircleBorder(
          side: BorderSide(
            color: AppColors.gold,
            width: 1.2,
          ),
        ),
        elevation: 1,
        shadowColor: AppColors.gold,
        child: InkWell(
          onTap: onPressed,
          customBorder: CircleBorder(),
          child: Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.surface,
                  AppColors.sageSoft,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 21,
                  color: AppColors.gold,
                ),
                SizedBox(height: 3),
                Text(
                  uiTr('Admin\nLogin'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.sageDark,
                    fontSize: 12,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminLoginScreen extends StatefulWidget {
  const _AdminLoginScreen();

  @override
  State<_AdminLoginScreen> createState() {
    return _AdminLoginScreenState();
  }
}

class _AdminLoginScreenState extends State<_AdminLoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _AdminAuthService _authService = _AdminAuthService();

  bool _isLoading = false;
  bool _hidePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(session);
    } on _AdminLoginException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          uiTr('Admin Sign In'),
          style: TextStyle(
            color: AppColors.sageDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 30),
          children: [
            _PageHeroCard(
              icon: Icons.admin_panel_settings_outlined,
              title: uiTr('Welcome'),
              subtitle: uiTr('This area is for institution and platform administrators.'),
            ),
            SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    decoration: InputDecoration(
                      labelText: uiTr('Email'),
                      hintText: 'admin@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';

                      if (email.isEmpty) {
                        return uiTr('Enter your email');
                      }

                      if (!email.contains('@')) {
                        return uiTr('Invalid email address');
                      }

                      return null;
                    },
                  ),
                  SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) {
                      if (!_isLoading) {
                        _login();
                      }
                    },
                    decoration: InputDecoration(
                      labelText: uiTr('Password'),
                      prefixIcon: Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _hidePassword = !_hidePassword;
                          });
                        },
                        tooltip: _hidePassword
                            ? uiTr('Show Password')
                            : uiTr('Hide Password'),
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return uiTr('Enter password');
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: 14),
              Container(
                padding: EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Color(0xFFFFE9E6),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Color(0xFFE7B8B0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Color(0xFF9A4036),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Color(0xFF7D3028),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isLoading ? null : _login,
              style: FilledButton.styleFrom(
                minimumSize: Size.fromHeight(54),
                backgroundColor: AppColors.sageDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              icon: _isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
                  : Icon(Icons.login),
              label: Text(
                _isLoading ? uiTr('Checking...') : uiTr('Sign In'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiConfig {
  // Android emulator default. Override it on a real phone with:
  // flutter run --dart-define=API_BASE_URL=http://YOUR_COMPUTER_IP:8080
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );
}

class _PublicAnnouncementService {
  const _PublicAnnouncementService();

  Future<List<_AdminAnnouncement>> getActiveAnnouncements(
      int institutionId,
      ) {
    return _load(institutionId, 'active');
  }

  Future<List<_AdminAnnouncement>> getDisplayAnnouncements(
      int institutionId,
      ) {
    return _load(institutionId, 'display');
  }

  Future<List<_AdminAnnouncement>> _load(
      int institutionId,
      String endpoint,
      ) async {
    final response = await http
        .get(
      Uri.parse(
        '${_ApiConfig.baseUrl}/api/announcements/'
            'institution/$institutionId/$endpoint',
      ),
      headers: const {'Accept': 'application/json'},
    )
        .timeout(Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Unable to load announcements (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    if (decoded is! List) {
      throw FormatException('Invalid announcement response');
    }

    final announcements = decoded
        .whereType<Map<String, dynamic>>()
        .map(_AdminAnnouncement.fromJson)
        .toList();

    announcements.sort(
          (first, second) => second.createdAt.compareTo(first.createdAt),
    );

    return announcements;
  }
}

class _PublicEventService {
  const _PublicEventService();

  Future<List<_InstitutionEvent>> getUpcomingEvents(
      int institutionId,
      ) async {
    final response = await http
        .get(
      Uri.parse(
        '${_ApiConfig.baseUrl}/api/events/'
            'institution/$institutionId/upcoming',
      ),
      headers: const {'Accept': 'application/json'},
    )
        .timeout(Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to load events (${response.statusCode})');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw FormatException('Invalid events response');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_InstitutionEvent.fromJson)
        .toList();
  }
}

class _AdminAuthService {
  const _AdminAuthService();

  Future<_AdminSession> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final credentials = base64Encode(
      utf8.encode('$normalizedEmail:$password'),
    );

    return verify('Basic $credentials');
  }

  Future<_AdminSession> verify(
      String authorizationHeader,
      ) async {
    try {
      final response = await http.get(
        Uri.parse('${_ApiConfig.baseUrl}/api/auth/me'),
        headers: {
          'Accept': 'application/json',
          'Authorization': authorizationHeader,
        },
      ).timeout(Duration(seconds: 12));

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw _AdminLoginException(
          uiTr('Incorrect username or password.'),
        );
      }

      if (response.statusCode != 200) {
        throw _AdminLoginException(
          uiTr('Sign-in failed. Error code: ${response.statusCode}'),
        );
      }

      final decoded = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (decoded is! Map<String, dynamic>) {
        throw _AdminLoginException(
          uiTr('Invalid server response.'),
        );
      }

      final role = decoded['role']?.toString().toUpperCase();

      if (role != 'INSTITUTION_ADMIN' && role != 'SUPER_ADMIN')  {
        throw _AdminLoginException(
          uiTr('This account does not have admin access.'),
        );
      }

      return _AdminSession(
        id: _readInt(decoded['id']),
        name: decoded['name']?.toString(),
        email: decoded['email']?.toString() ?? '',
        role: role!,
        institutionId: _readNullableInt(decoded['institutionId']),
        institutionName: decoded['institutionName']?.toString(),
        authorizationHeader: authorizationHeader,
      );
    } on _AdminLoginException {
      rethrow;
    } catch (_) {
      throw _AdminLoginException(
        uiTr('Cannot connect to the server. Check that it is running and try again.'),
      );
    }
  }

  int _readInt(Object? value) {
    final result = _readNullableInt(value);

    if (result == null) {
      throw _AdminLoginException(
        uiTr('Account ID is missing from the server response.'),
      );
    }

    return result;
  }

  int? _readNullableInt(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }
}

class _AdminSession {
  final int id;
  final String? name;
  final String email;
  final String role;
  final int? institutionId;
  final String? institutionName;
  final String authorizationHeader;

  const _AdminSession({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.institutionId,
    required this.institutionName,
    required this.authorizationHeader,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'institutionId': institutionId,
      'institutionName': institutionName,
      'authorizationHeader': authorizationHeader,
    };
  }

  factory _AdminSession.fromJson(Map<String, dynamic> json) {
    return _AdminSession(
      id: json['id'] as int,
      name: json['name']?.toString(),
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      institutionId: json['institutionId'] as int?,
      institutionName: json['institutionName']?.toString(),
      authorizationHeader:
      json['authorizationHeader']?.toString() ?? '',
    );
  }
}

class _AdminSessionStore {
  static const String _sessionKey = 'admin_session';

  final FlutterSecureStorage _storage;

  _AdminSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? FlutterSecureStorage();

  // WebCrypto-based secure storage is unavailable on HTTP LAN addresses.
  // For local web testing, do not persist Basic auth credentials insecurely.
  // The authenticated session remains in AppStartState memory until refresh.
  bool get _insecureLanWeb =>
      kIsWeb &&
          Uri.base.scheme == 'http' &&
          Uri.base.host != 'localhost' &&
          Uri.base.host != '127.0.0.1';

  Future<void> write(_AdminSession session) async {
    if (_insecureLanWeb) return;
    await _storage.write(
      key: _sessionKey,
      value: jsonEncode(session.toJson()),
    );
  }

  Future<_AdminSession?> read() async {
    if (_insecureLanWeb) return null;

    final value = await _storage.read(key: _sessionKey);

    if (value == null || value.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(value);

    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return _AdminSession.fromJson(decoded);
  }

  Future<void> clear() async {
    if (_insecureLanWeb) return;
    await _storage.delete(key: _sessionKey);
  }
}

class _AdminLoginException implements Exception {
  final String message;

  const _AdminLoginException(this.message);
}

class _InstitutionAdminDashboardScreen extends StatefulWidget {
  final _AdminSession session;
  final Future<void> Function() onLogout;

  const _InstitutionAdminDashboardScreen({
    required this.session,
    required this.onLogout,
  });

  @override
  State<_InstitutionAdminDashboardScreen> createState() {
    return _InstitutionAdminDashboardScreenState();
  }
}

class _InstitutionAdminDashboardScreenState
    extends State<_InstitutionAdminDashboardScreen> {
  late final _AdminApiService _api;
  late Future<List<_AdminAnnouncement>> _announcementsFuture;

  @override
  void initState() {
    super.initState();
    _api = _AdminApiService(widget.session);
    _reload();
  }

  void _reload() {
    _announcementsFuture = _api.getMyAnnouncements();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _announcementsFuture;
  }

  Future<void> _openForm([_AdminAnnouncement? announcement]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) {
          return _AnnouncementFormScreen(
            api: _api,
            announcement: announcement,
          );
        },
      ),
    );

    if (changed == true && mounted) {
      setState(_reload);
    }
  }

  Future<void> _openCoverEditor() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _InstitutionCoverEditor(session: widget.session),
      ),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiTr('Cover updated. Return home and refresh the page.'))),
      );
    }
  }

  Future<void> _openEvents() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _EventManagementScreen(api: _api),
      ),
    );
  }

  Future<void> _deleteAnnouncement(
      _AdminAnnouncement announcement,
      ) async {
    final confirmed = await _confirmAction(
      context,
      title: uiTr('Delete announcement?'),
      message: uiTr('“${announcement.title}” will be permanently deleted.'),
      confirmLabel: uiTr('Delete'),
    );

    if (!confirmed) {
      return;
    }

    try {
      await _api.deleteAnnouncement(announcement.id);

      if (!mounted) {
        return;
      }

      _showMessage(context, uiTr('Announcement deleted.'));
      setState(_reload);
    } on _AdminApiException catch (error) {
      if (mounted) {
        _showMessage(context, error.message, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          uiTr('Institution Management'),
          style: TextStyle(
            color: AppColors.sageDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openCoverEditor,
            tooltip: uiTr('Edit Institution Cover'),
            icon: Icon(Icons.image_outlined),
          ),
          IconButton(
            onPressed: _openEvents,
            tooltip: uiTr('Manage Events'),
            icon: Icon(Icons.event_note_outlined),
          ),
          IconButton(
            onPressed: widget.onLogout,
            tooltip: uiTr('Sign Out'),
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: _AdminDashboardHeader(
                icon: Icons.apartment_outlined,
                title: widget.session.institutionName ?? uiTr('My Institution'),
                subtitle: widget.session.email,
              ),
            ),
            Expanded(
              child: FutureBuilder<List<_AdminAnnouncement>>(
                future: _announcementsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return _AdminErrorState(
                      message: _errorText(snapshot.error),
                      onRetry: () {
                        setState(_reload);
                      },
                    );
                  }

                  final announcements = snapshot.data ?? [];

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(18, 4, 18, 100),
                      children: [
                        _AdminSectionTitle(
                          title: uiTr('Institution Announcements'),
                          subtitle: uiTr('Create and edit announcements and set their visibility dates.'),
                        ),
                        SizedBox(height: 12),
                        if (announcements.isEmpty)
                          _AdminEmptyCard(
                            icon: Icons.campaign_outlined,
                            title: uiTr('No announcements yet'),
                            subtitle: uiTr('Tap Add Announcement to create the first one.'),
                          )
                        else
                          ...announcements.map(
                                (announcement) => Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: _AdminAnnouncementCard(
                                announcement: announcement,
                                onEdit: () {
                                  _openForm(announcement);
                                },
                                onDelete: () {
                                  _deleteAnnouncement(announcement);
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _openForm();
        },
        backgroundColor: AppColors.sageDark,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text(
          uiTr('Add Announcement'),
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _EventManagementScreen extends StatefulWidget {
  final _AdminApiService api;

  const _EventManagementScreen({required this.api});

  @override
  State<_EventManagementScreen> createState() =>
      _EventManagementScreenState();
}

class _EventManagementScreenState extends State<_EventManagementScreen> {
  late Future<List<_InstitutionEvent>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _eventsFuture = widget.api.getMyEvents();
  }

  Future<void> _openForm([_InstitutionEvent? event]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _EventFormScreen(api: widget.api, event: event),
      ),
    );
    if (changed == true && mounted) setState(_reload);
  }

  Future<void> _delete(_InstitutionEvent event) async {
    final confirmed = await _confirmAction(
      context,
      title: uiTr('Delete event?'),
      message: uiTr('“${event.title}” will be permanently deleted.'),
      confirmLabel: uiTr('Delete'),
    );
    if (!confirmed) return;
    try {
      await widget.api.deleteEvent(event.id);
      if (mounted) setState(_reload);
    } on _AdminApiException catch (error) {
      if (mounted) _showMessage(context, error.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          uiTr('Manage Events'),
          style: TextStyle(
            color: AppColors.sageDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: FutureBuilder<List<_InstitutionEvent>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _AdminErrorState(
              message: _errorText(snapshot.error),
              onRetry: () => setState(_reload),
            );
          }
          final events = snapshot.data ?? const [];
          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _eventsFuture;
            },
            child: ListView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(18, 16, 18, 100),
              children: [
                _AdminSectionTitle(
                  title: uiTr('Institution events'),
                  subtitle: uiTr('Set the date, time and location.'),
                ),
                SizedBox(height: 12),
                if (events.isEmpty)
                  _AdminEmptyCard(
                    icon: Icons.event_busy_outlined,
                    title: uiTr('No events'),
                    subtitle: uiTr('Tap Add Event to create your first event.'),
                  )
                else
                  ...events.map(
                        (event) => Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: _AdminEventCard(
                        event: event,
                        onEdit: () => _openForm(event),
                        onDelete: () => _delete(event),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.sageDark,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text(uiTr('Add Event')),
      ),
    );
  }
}

class _AdminEventCard extends StatelessWidget {
  final _InstitutionEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminEventCard({
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if ((event.imageUrl ?? '').trim().isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(height: 150, width: double.infinity,
                    child: Image.network(event.imageUrl!.trim(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _EventImagePlaceholder())),
              ),
              SizedBox(height: 10),
            ],
            Text(
              event.title,
              style: TextStyle(
                color: AppColors.sageDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(uiTr('Starts ${_formatAdminDate(event.startAt)}')),
            Text(uiTr('Ends ${_formatAdminDate(event.endAt)}')),
            if (event.location.trim().isNotEmpty)
              Text(uiTr('Location: ${event.location.trim()}')),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined),
                  label: Text(uiTr('Edit')),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline),
                  label: Text(uiTr('Delete')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EventFormScreen extends StatefulWidget {
  final _AdminApiService api;
  final _InstitutionEvent? event;

  const _EventFormScreen({required this.api, required this.event});

  @override
  State<_EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<_EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _eventImageController;
  late DateTime _startAt;
  late DateTime _endAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    _locationController = TextEditingController(text: event?.location ?? '');
    _eventImageController = TextEditingController(text: event?.imageUrl ?? '');
    _startAt = event?.startAt ?? DateTime.now().add(Duration(days: 1));
    _endAt = event?.endAt ?? _startAt.add(Duration(hours: 2));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _eventImageController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 3650)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_endAt.isBefore(_startAt)) {
      _showMessage(context, uiTr('End time must be after start time.'), isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final event = widget.event;
      if (event == null) {
        await widget.api.addEvent(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          imageUrl: _eventImageController.text.trim(),
          startAt: _startAt,
          endAt: _endAt,
        );
      } else {
        await widget.api.updateEvent(
          id: event.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          imageUrl: _eventImageController.text.trim(),
          startAt: _startAt,
          endAt: _endAt,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on _AdminApiException catch (error) {
      if (mounted) _showMessage(context, error.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? uiTr('Add Event') : uiTr('Edit Event')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: uiTr('Event Title'),
                prefixIcon: Icon(Icons.event_outlined),
              ),
              validator: _requiredText,
            ),
            SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(labelText: uiTr('Event Description')),
            ),
            SizedBox(height: 14),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: uiTr('Location'),
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            SizedBox(height: 14),
            TextFormField(
              controller: _eventImageController,
              keyboardType: TextInputType.url,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: uiTr('Event Image URL (optional)'),
                hintText: 'https://example.com/event.jpg',
                prefixIcon: Icon(Icons.image_outlined),
              ),
              onChanged: (_) => setState(() {}),
              validator: (value) {
                final url = (value ?? '').trim();
                if (url.isEmpty) return null;
                if (url.length > 2048) return uiTr('URL is too long');
                final uri = Uri.tryParse(url);
                if (uri == null ||
                    (uri.scheme != 'http' && uri.scheme != 'https') ||
                    uri.host.isEmpty) {
                  return uiTr('Enter a valid image URL starting with https://');
                }
                return null;
              },
            ),
            if (_eventImageController.text.trim().isNotEmpty) ...[
              SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 155,
                  child: Image.network(
                    _eventImageController.text.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _EventImagePlaceholder(),
                  ),
                ),
              ),
            ],
            SizedBox(height: 14),
            _DateTimePickerCard(
              title: uiTr('Event Start'),
              value: _startAt,
              onPressed: () async {
                final value = await _pickDateTime(_startAt);
                if (value != null) setState(() => _startAt = value);
              },
            ),
            SizedBox(height: 12),
            _DateTimePickerCard(
              title: uiTr('Event End'),
              value: _endAt,
              onPressed: () async {
                final value = await _pickDateTime(_endAt);
                if (value != null) setState(() => _endAt = value);
              },
            ),
            SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: Icon(Icons.save_outlined),
              label: Text(_saving ? uiTr('Saving...') : uiTr('Save Event')),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminAnnouncementCard extends StatelessWidget {
  final _AdminAnnouncement announcement;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? institutionName;

  const _AdminAnnouncementCard({
    required this.announcement,
    this.onEdit,
    this.onDelete,
    this.institutionName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _AnnouncementStatusChip(status: announcement.status),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  announcement.title.isEmpty
                      ? uiTr('Untitled announcement')
                      : announcement.title,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'delete') {
                      onDelete?.call();
                    }
                  },
                  itemBuilder: (context) {
                    return [
                      if (onEdit != null)
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(uiTr('Edit')),
                        ),
                      if (onDelete != null)
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(uiTr('Delete')),
                        ),
                    ];
                  },
                ),
            ],
          ),
          if (institutionName != null) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.apartment_outlined,
                  size: 16,
                  color: AppColors.sage,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    institutionName!,
                    style: TextStyle(
                      color: AppColors.sageDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (announcement.content.isNotEmpty) ...[
            SizedBox(height: 10),
            Text(
              announcement.content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.mutedText,
                height: 1.5,
              ),
            ),
          ],
          SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 7,
            children: [
              _AdminMetaText(
                icon: Icons.play_circle_outline,
                text: uiTr('Starts ${_formatAdminDate(announcement.startAt)}'),
              ),
              _AdminMetaText(
                icon: Icons.stop_circle_outlined,
                text: uiTr('Ends ${_formatAdminDate(announcement.endAt)}'),
              ),
              _AdminMetaText(
                icon: announcement.showOnDisplayScreen
                    ? Icons.live_tv
                    : Icons.tv_off_outlined,
                text: announcement.showOnDisplayScreen
                    ? uiTr('Shown on display screen')
                    : uiTr('Not shown on display screen'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnnouncementStatusChip extends StatelessWidget {
  final String status;

  const _AnnouncementStatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color background;
    late final Color foreground;

    if (status == 'ACTIVE') {
      label = uiTr('Active');
      background = Color(0xFFE4F1E2);
      foreground = AppColors.sageDark;
    } else if (status == 'UPCOMING') {
      label = uiTr('Upcoming');
      background = Color(0xFFFFF1D6);
      foreground = Color(0xFF87611D);
    } else {
      label = uiTr('Ended');
      background = Color(0xFFF0ECE6);
      foreground = AppColors.mutedText;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AdminMetaText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _AdminMetaText({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.gold),
        SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _AnnouncementFormScreen extends StatefulWidget {
  final _AdminApiService api;
  final _AdminAnnouncement? announcement;

  const _AnnouncementFormScreen({
    required this.api,
    required this.announcement,
  });

  @override
  State<_AnnouncementFormScreen> createState() {
    return _AnnouncementFormScreenState();
  }
}

class _AnnouncementFormScreenState
    extends State<_AnnouncementFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _imageUrlController;
  late DateTime _startAt;
  late DateTime _endAt;
  late bool _showOnDisplayScreen;
  bool _isSaving = false;

  bool get _isEditing => widget.announcement != null;
  bool get _hasAnnouncementImage =>
      _imageUrlController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final announcement = widget.announcement;
    final now = DateTime.now();

    _titleController = TextEditingController(
      text: announcement?.title ?? '',
    );
    _contentController = TextEditingController(
      text: announcement?.content ?? '',
    );
    _imageUrlController = TextEditingController(
      text: announcement?.imageUrl ?? '',
    );
    _startAt = announcement?.startAt ?? now;
    _endAt = announcement?.endAt ?? now.add(Duration(days: 7));
    _showOnDisplayScreen =
        (announcement?.showOnDisplayScreen ?? false) &&
            (announcement?.imageUrl?.trim().isNotEmpty ?? false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date == null || !mounted) {
      return null;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (time == null) {
      return null;
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_startAt.isBefore(_endAt)) {
      _showMessage(
        context,
        uiTr('End time must be after start time.'),
        isError: true,
      );
      return;
    }

    final imageUrl = _imageUrlController.text.trim();

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEditing) {
        await widget.api.updateAnnouncement(
          id: widget.announcement!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
          startAt: _startAt,
          endAt: _endAt,
          showOnDisplayScreen: _showOnDisplayScreen,
        );
      } else {
        await widget.api.addAnnouncement(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
          startAt: _startAt,
          endAt: _endAt,
          showOnDisplayScreen: _showOnDisplayScreen,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on _AdminApiException catch (error) {
      if (mounted) {
        _showMessage(context, error.message, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          _isEditing ? uiTr('Edit Announcement') : uiTr('Add Announcement'),
          style: TextStyle(
            color: AppColors.sageDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(18, 10, 18, 30),
            children: [
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: uiTr('Announcement Title'),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return uiTr('Enter announcement title');
                  }

                  return null;
                },
              ),
              SizedBox(height: 14),
              TextFormField(
                controller: _contentController,
                minLines: 4,
                maxLines: 7,
                decoration: InputDecoration(
                  labelText: uiTr('Announcement Text'),
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes),
                ),
                validator: (value) {
                  final content = value?.trim() ?? '';
                  final imageUrl = _imageUrlController.text.trim();

                  if (content.isEmpty && imageUrl.isEmpty) {
                    return uiTr('Enter text or an image URL');
                  }

                  return null;
                },
              ),
              SizedBox(height: 14),
              TextFormField(
                controller: _imageUrlController,
                keyboardType: TextInputType.url,
                onChanged: (_) {
                  setState(() {
                    if (!_hasAnnouncementImage) {
                      _showOnDisplayScreen = false;
                    }
                  });
                },
                decoration: InputDecoration(
                  labelText: uiTr('Image URL (optional)'),
                  prefixIcon: Icon(Icons.image_outlined),
                ),
              ),
              SizedBox(height: 18),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.live_tv_outlined,
                          color: AppColors.sageDark,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            uiTr('Show on Display Screen'),
                            style: TextStyle(
                              color: AppColors.sageDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      _hasAnnouncementImage
                          ? uiTr('When enabled, this image appears on the display screen.')
                          : uiTr('Add an image URL to enable display screen visibility.'),
                      style: TextStyle(
                        color: AppColors.mutedText,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 14),
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment<bool>(
                          value: true,
                          enabled: _hasAnnouncementImage,
                          icon: Icon(Icons.check_circle_outline),
                          label: Text(uiTr('Yes')),
                        ),
                        ButtonSegment<bool>(
                          value: false,
                          icon: Icon(Icons.cancel_outlined),
                          label: Text(uiTr('No')),
                        ),
                      ],
                      selected: {_showOnDisplayScreen},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) {
                        setState(() {
                          _showOnDisplayScreen = selection.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18),
              _DateTimePickerCard(
                title: uiTr('Announcement Start'),
                value: _startAt,
                onPressed: () async {
                  final value = await _pickDateTime(_startAt);

                  if (value != null) {
                    setState(() {
                      _startAt = value;
                    });
                  }
                },
              ),
              SizedBox(height: 12),
              _DateTimePickerCard(
                title: uiTr('Announcement End'),
                value: _endAt,
                onPressed: () async {
                  final value = await _pickDateTime(_endAt);

                  if (value != null) {
                    setState(() {
                      _endAt = value;
                    });
                  }
                },
              ),
              SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: Size.fromHeight(54),
                  backgroundColor: AppColors.sageDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                icon: _isSaving
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Icon(Icons.save_outlined),
                label: Text(
                  _isSaving ? uiTr('Saving...') : uiTr('Save Announcement'),
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTimePickerCard extends StatelessWidget {
  final String title;
  final DateTime value;
  final VoidCallback onPressed;

  const _DateTimePickerCard({
    required this.title,
    required this.value,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.outline),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.sageSoft,
                child: Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.sageDark,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatAdminDate(value),
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit_calendar_outlined,
                color: AppColors.sage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuperAdminDashboardScreen extends StatelessWidget {
  final _AdminSession session;
  final Future<void> Function() onLogout;

  const _SuperAdminDashboardScreen({
    required this.session,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final api = _AdminApiService(session);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            uiTr('Manage Platform'),
            style: TextStyle(
              color: AppColors.sageDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            IconButton(
              onPressed: onLogout,
              tooltip: uiTr('Sign Out'),
              icon: Icon(Icons.logout),
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.sageDark,
            unselectedLabelColor: AppColors.mutedText,
            indicatorColor: AppColors.gold,
            tabs: [
              Tab(icon: Icon(Icons.apartment_outlined), text: uiTr('Institutions')),
              Tab(
                icon: Icon(Icons.manage_accounts_outlined),
                text: uiTr('Administrators'),
              ),
              Tab(
                icon: Icon(Icons.campaign_outlined),
                text: uiTr('Announcements'),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SuperAdminInstitutionsTab(api: api),
            _SuperAdminAccountsTab(
              api: api,
              currentAdminId: session.id,
            ),
            _SuperAdminAnnouncementsTab(api: api),
          ],
        ),
      ),
    );
  }
}

class _SuperAdminInstitutionsTab extends StatefulWidget {
  final _AdminApiService api;

  const _SuperAdminInstitutionsTab({required this.api});

  @override
  State<_SuperAdminInstitutionsTab> createState() {
    return _SuperAdminInstitutionsTabState();
  }
}

class _SuperAdminInstitutionsTabState
    extends State<_SuperAdminInstitutionsTab> {
  late Future<List<_ManagedInstitution>> _institutionsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _institutionsFuture = widget.api.getInstitutions();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _institutionsFuture;
  }

  Future<void> _openForm([_ManagedInstitution? institution]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) {
          return _InstitutionFormScreen(
            api: widget.api,
            institution: institution,
          );
        },
      ),
    );

    if (changed == true && mounted) {
      setState(_reload);
    }
  }

  Future<void> _delete(_ManagedInstitution institution) async {
    final confirmed = await _confirmAction(
      context,
      title: uiTr('Delete institution?'),
      message: uiTr('“${institution.name}” will be deleted if it has no related data.'),
      confirmLabel: uiTr('Delete'),
    );

    if (!confirmed) {
      return;
    }

    try {
      await widget.api.deleteInstitution(institution.id);

      if (mounted) {
        _showMessage(context, uiTr('Institution deleted.'));
        setState(_reload);
      }
    } on _AdminApiException catch (error) {
      if (mounted) {
        _showMessage(context, error.message, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_ManagedInstitution>>(
      future: _institutionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _AdminErrorState(
            message: _errorText(snapshot.error),
            onRetry: () {
              setState(_reload);
            },
          );
        }

        final institutions = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(18, 18, 18, 30),
            children: [
              _AdminSectionTitle(
                title: uiTr('Institutions'),
                subtitle: uiTr('${institutions.length} institutions'),
                actionLabel: uiTr('Add Institution'),
                onAction: () {
                  _openForm();
                },
              ),
              SizedBox(height: 14),
              if (institutions.isEmpty)
                _AdminEmptyCard(
                  icon: Icons.apartment_outlined,
                  title: uiTr('No institutions'),
                  subtitle: uiTr('Add the first institution.'),
                )
              else
                ...institutions.map(
                      (institution) => Padding(
                    padding: EdgeInsets.only(bottom: 11),
                    child: _ManagedInstitutionCard(
                      institution: institution,
                      onEdit: () {
                        _openForm(institution);
                      },
                      onDelete: () {
                        _delete(institution);
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ManagedInstitutionCard extends StatelessWidget {
  final _ManagedInstitution institution;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ManagedInstitutionCard({
    required this.institution,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.sageSoft,
            child: Icon(
              Icons.apartment_outlined,
              color: AppColors.sageDark,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  institution.name,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  institution.city,
                  style: TextStyle(color: AppColors.mutedText),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: uiTr('Edit Institution'),
            icon: Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: uiTr('Delete Institution'),
            color: Color(0xFF9A4036),
            icon: Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _InstitutionFormScreen extends StatefulWidget {
  final _AdminApiService api;
  final _ManagedInstitution? institution;

  const _InstitutionFormScreen({
    required this.api,
    required this.institution,
  });

  @override
  State<_InstitutionFormScreen> createState() {
    return _InstitutionFormScreenState();
  }
}

class _InstitutionFormScreenState extends State<_InstitutionFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _cityController;
  late final TextEditingController _typeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _websiteController;
  late final TextEditingController _logoController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.institution?.name ?? '');
    _cityController = TextEditingController(
      text: widget.institution?.city ?? '',
    );
    _typeController = TextEditingController(
      text: widget.institution?.type ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.institution?.description ?? '',
    );
    _addressController = TextEditingController(
      text: widget.institution?.address ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.institution?.phone ?? '',
    );
    _emailController = TextEditingController(
      text: widget.institution?.email ?? '',
    );
    _websiteController = TextEditingController(
      text: widget.institution?.websiteUrl ?? '',
    );
    _logoController = TextEditingController(
      text: widget.institution?.logoUrl ?? '',
    );
    _latitudeController = TextEditingController(
      text: widget.institution?.latitude?.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: widget.institution?.longitude?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _logoController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  double? _coordinateValue(TextEditingController controller) {
    final text = controller.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  String? _validateLatitude(String? value) {
    final latitude = double.tryParse(
      (value ?? '').trim().replaceAll(',', '.'),
    );

    if ((value ?? '').trim().isEmpty) return null;

    if (latitude == null) {
      return uiTr('Enter latitude');
    }

    if (latitude < -90 || latitude > 90) {
      return uiTr('Latitude must be between -90 and 90');
    }

    return null;
  }

  String? _validateLongitude(String? value) {
    final longitude = double.tryParse(
      (value ?? '').trim().replaceAll(',', '.'),
    );

    if ((value ?? '').trim().isEmpty) return null;

    if (longitude == null) {
      return uiTr('Enter longitude');
    }

    if (longitude < -180 || longitude > 180) {
      return uiTr('Longitude must be between -180 and 180');
    }

    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.institution == null) {
        await widget.api.addInstitution(
          name: _nameController.text.trim(),
          city: _cityController.text.trim(),
          type: _typeController.text.trim(),
          description: _descriptionController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          websiteUrl: _websiteController.text.trim(),
          logoUrl: _logoController.text.trim(),
          latitude: _coordinateValue(_latitudeController),
          longitude: _coordinateValue(_longitudeController),
        );
      } else {
        await widget.api.updateInstitution(
          id: widget.institution!.id,
          name: _nameController.text.trim(),
          city: _cityController.text.trim(),
          type: _typeController.text.trim(),
          description: _descriptionController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          websiteUrl: _websiteController.text.trim(),
          logoUrl: _logoController.text.trim(),
          latitude: _coordinateValue(_latitudeController),
          longitude: _coordinateValue(_longitudeController),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on _AdminApiException catch (error) {
      if (mounted) {
        _showMessage(context, error.message, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.institution != null;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          isEditing ? uiTr('Edit Institution') : uiTr('Add Institution'),
          style: TextStyle(
            color: AppColors.sageDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: uiTr('Institution Name'),
                  prefixIcon: Icon(Icons.apartment_outlined),
                ),
                validator: _requiredText,
              ),
              SizedBox(height: 14),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: uiTr('City or Town'),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: _requiredText,
              ),
              SizedBox(height: 14),
              TextFormField(
                controller: _typeController,
                decoration: InputDecoration(
                  labelText: uiTr('Institution Type'),
                  hintText: uiTr('School, association, center, club...'),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: uiTr('About the institution'),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              SizedBox(height: 14),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: uiTr('Address'),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: uiTr('Phone'),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: uiTr('Email'),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              SizedBox(height: 14),
              TextFormField(
                controller: _websiteController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: uiTr('Website URL'),
                  prefixIcon: Icon(Icons.language_outlined),
                ),
              ),
              SizedBox(height: 14),
              TextFormField(
                controller: _logoController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: uiTr('Institution Logo URL'),
                  prefixIcon: Icon(Icons.image_outlined),
                ),
              ),
              SizedBox(height: 14),
              TextFormField(
                controller: _latitudeController,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: uiTr('Latitude (optional)'),
                  hintText: uiTr('Example: 32.8070'),
                  prefixIcon: Icon(Icons.my_location_outlined),
                ),
                validator: _validateLatitude,
              ),
              SizedBox(height: 14),
              TextFormField(
                controller: _longitudeController,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: uiTr('Longitude (optional)'),
                  hintText: uiTr('Example: 35.2600'),
                  prefixIcon: Icon(Icons.public_outlined),
                ),
                validator: _validateLongitude,
              ),
              SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: Size.fromHeight(54),
                  backgroundColor: AppColors.sageDark,
                ),
                icon: Icon(Icons.save_outlined),
                label: Text(
                  _isSaving ? uiTr('Saving...') : uiTr('Save Institution'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuperAdminAccountsTab extends StatefulWidget {
  final _AdminApiService api;
  final int currentAdminId;

  const _SuperAdminAccountsTab({
    required this.api,
    required this.currentAdminId,
  });

  @override
  State<_SuperAdminAccountsTab> createState() {
    return _SuperAdminAccountsTabState();
  }
}

class _SuperAdminAccountsTabState
    extends State<_SuperAdminAccountsTab> {
  late Future<_AdminAccountsData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _dataFuture = _loadData();
  }

  Future<_AdminAccountsData> _loadData() async {
    final admins = await widget.api.getAdmins();
    final institutions = await widget.api.getInstitutions();

    return _AdminAccountsData(admins: admins, institutions: institutions);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _dataFuture;
  }

  Future<void> _openAddForm(_AdminAccountsData data) async {
    final usedInstitutionIds = data.admins
        .map((admin) => admin.institutionId)
        .whereType<int>()
        .toSet();
    final availableInstitutions = data.institutions
        .where((institution) => !usedInstitutionIds.contains(institution.id))
        .toList();

    if (availableInstitutions.isEmpty) {
      _showMessage(
        context,
        uiTr('All institutions already have an admin. Add a new institution first.'),
        isError: true,
      );
      return;
    }

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) {
          return _InstitutionAdminFormScreen(
            api: widget.api,
            institutions: availableInstitutions,
          );
        },
      ),
    );

    if (changed == true && mounted) {
      setState(_reload);
    }
  }

  Future<void> _delete(_AdminAccountInfo admin) async {
    final confirmed = await _confirmAction(
      context,
      title: uiTr('Delete admin account?'),
      message: uiTr('The account for ${admin.name} will be deleted if there are no related announcements.'),
      confirmLabel: uiTr('Delete'),
    );

    if (!confirmed) {
      return;
    }

    try {
      await widget.api.deleteAdmin(admin.id);

      if (mounted) {
        _showMessage(context, uiTr('Admin account deleted.'));
        setState(_reload);
      }
    } on _AdminApiException catch (error) {
      if (mounted) {
        _showMessage(context, error.message, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AdminAccountsData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _AdminErrorState(
            message: _errorText(snapshot.error),
            onRetry: () {
              setState(_reload);
            },
          );
        }

        final data = snapshot.data ?? _AdminAccountsData();
        final institutionNames = {
          for (final institution in data.institutions) institution.id: institution.name,
        };

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(18, 18, 18, 30),
            children: [
              _AdminSectionTitle(
                title: uiTr('Admin Accounts'),
                subtitle: uiTr('${data.admins.length} admin accounts'),
                actionLabel: uiTr('Add Admin'),
                onAction: () {
                  _openAddForm(data);
                },
              ),
              SizedBox(height: 14),
              if (data.admins.isEmpty)
                _AdminEmptyCard(
                  icon: Icons.manage_accounts_outlined,
                  title: uiTr('No accounts'),
                  subtitle: uiTr('Add an admin to an institution.'),
                )
              else
                ...data.admins.map(
                      (admin) => Padding(
                    padding: EdgeInsets.only(bottom: 11),
                    child: _AdminAccountCard(
                      admin: admin,
                      institutionName: admin.institutionId == null
                          ? null
                          : institutionNames[admin.institutionId],
                      onDelete: (admin.role == 'INSTITUTION_ADMIN') &&
                          admin.id != widget.currentAdminId
                          ? () {
                        _delete(admin);
                      }
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminAccountsData {
  final List<_AdminAccountInfo> admins;
  final List<_ManagedInstitution> institutions;

  const _AdminAccountsData({
    this.admins = const [],
    this.institutions = const [],
  });
}

class _AdminAccountCard extends StatelessWidget {
  final _AdminAccountInfo admin;
  final String? institutionName;
  final VoidCallback? onDelete;

  const _AdminAccountCard({
    required this.admin,
    required this.institutionName,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = admin.role == 'SUPER_ADMIN';

    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.sageSoft,
            child: Icon(
              isSuperAdmin
                  ? Icons.security_outlined
                  : Icons.person_outline,
              color: AppColors.sageDark,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin.name.isEmpty ? admin.email : admin.name,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  admin.email,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  isSuperAdmin
                      ? uiTr('Super Admin')
                      : institutionName ?? uiTr('Institution Admin'),
                  style: TextStyle(
                    color: AppColors.sageDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              tooltip: uiTr('Delete Account'),
              color: Color(0xFF9A4036),
              icon: Icon(Icons.delete_outline),
            ),
        ],
      ),
    );
  }
}

class _InstitutionAdminFormScreen extends StatefulWidget {
  final _AdminApiService api;
  final List<_ManagedInstitution> institutions;

  const _InstitutionAdminFormScreen({
    required this.api,
    required this.institutions,
  });

  @override
  State<_InstitutionAdminFormScreen> createState() {
    return _InstitutionAdminFormScreenState();
  }
}

class _InstitutionAdminFormScreenState
    extends State<_InstitutionAdminFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  int? _institutionId;
  bool _hidePassword = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.api.addInstitutionAdmin(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        institutionId: _institutionId!,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on _AdminApiException catch (error) {
      if (mounted) {
        _showMessage(context, error.message, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          uiTr('Add Institution Admin'),
          style: TextStyle(
            color: AppColors.sageDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: uiTr('Admin Name'),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: _requiredText,
              ),
              SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: uiTr('Email'),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';

                  if (email.isEmpty || !email.contains('@')) {
                    return uiTr('Enter a valid email address');
                  }

                  return null;
                },
              ),
              SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: _hidePassword,
                decoration: InputDecoration(
                  labelText: uiTr('Password'),
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _hidePassword = !_hidePassword;
                      });
                    },
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return uiTr('Password must be at least 6 characters');
                  }

                  return null;
                },
              ),
              SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: _institutionId,
                decoration: InputDecoration(
                  labelText: uiTr('Institution'),
                  prefixIcon: Icon(Icons.apartment_outlined),
                ),
                items: widget.institutions.map((institution) {
                  return DropdownMenuItem<int>(
                    value: institution.id,
                    child: Text('${institution.name} - ${institution.city}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _institutionId = value;
                  });
                },
                validator: (value) {
                  return value == null ? uiTr('Select institution') : null;
                },
              ),
              SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: Size.fromHeight(54),
                  backgroundColor: AppColors.sageDark,
                ),
                icon: Icon(Icons.person_add_alt_1_outlined),
                label: Text(
                  _isSaving ? uiTr('Creating...') : uiTr('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuperAdminAnnouncementsTab extends StatefulWidget {
  final _AdminApiService api;

  const _SuperAdminAnnouncementsTab({required this.api});

  @override
  State<_SuperAdminAnnouncementsTab> createState() {
    return _SuperAdminAnnouncementsTabState();
  }
}

class _SuperAdminAnnouncementsTabState
    extends State<_SuperAdminAnnouncementsTab> {
  late Future<_SuperAdminAnnouncementData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _dataFuture = _loadData();
  }

  Future<_SuperAdminAnnouncementData> _loadData() async {
    final announcements = await widget.api.getAllAnnouncements();
    final institutions = await widget.api.getInstitutions();

    return _SuperAdminAnnouncementData(
      announcements: announcements,
      institutions: institutions,
    );
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _dataFuture;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SuperAdminAnnouncementData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _AdminErrorState(
            message: _errorText(snapshot.error),
            onRetry: () {
              setState(_reload);
            },
          );
        }

        final data = snapshot.data ??
            _SuperAdminAnnouncementData();
        final institutionNames = {
          for (final institution in data.institutions) institution.id: institution.name,
        };

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(18, 18, 18, 30),
            children: [
              _AdminSectionTitle(
                title: uiTr('All Announcements'),
                subtitle: uiTr('${data.announcements.length} announcements'),
              ),
              SizedBox(height: 14),
              if (data.announcements.isEmpty)
                _AdminEmptyCard(
                  icon: Icons.campaign_outlined,
                  title: uiTr('No announcements'),
                  subtitle: uiTr('Announcements from all institutions will appear here.'),
                )
              else
                ...data.announcements.map(
                      (announcement) => Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _AdminAnnouncementCard(
                      announcement: announcement,
                      institutionName: institutionNames[announcement.institutionId] ??
                          uiTr('Institution #${announcement.institutionId}'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SuperAdminAnnouncementData {
  final List<_AdminAnnouncement> announcements;
  final List<_ManagedInstitution> institutions;

  const _SuperAdminAnnouncementData({
    this.announcements = const [],
    this.institutions = const [],
  });
}

class _AdminDashboardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AdminDashboardHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.sageDark,
            Color(0xFF698064),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Color(0x26FFFFFF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _AdminSectionTitle({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          FilledButton.tonalIcon(
            onPressed: onAction,
            icon: Icon(Icons.add, size: 18),
            label: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _AdminEmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AdminEmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppColors.sage),
          SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.mutedText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AdminErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.sage,
            ),
            SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText),
            ),
            SizedBox(height: 14),
            FilledButton.tonal(
              onPressed: onRetry,
              child: Text(uiTr('Retry')),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _confirmAction(
    BuildContext context, {
      required String title,
      required String message,
      required String confirmLabel,
    }) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text(uiTr('Cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Color(0xFF9A4036),
            ),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

void _showMessage(
    BuildContext context,
    String message, {
      bool isError = false,
    }) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Color(0xFF9A4036)
            : AppColors.sageDark,
      ),
    );
}

String _errorText(Object? error) {
  if (error is _AdminApiException) {
    return error.message;
  }

  return uiTr('An unexpected error occurred. Please try again.');
}

String? _requiredText(String? value) {
  if (value == null || value.trim().isEmpty) {
    return uiTr('This field is required');
  }

  return null;
}

String _formatAdminDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hourValue = date.hour > 12
      ? date.hour - 12
      : date.hour == 0
      ? 12
      : date.hour;
  final hour = hourValue.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour < 12 ? uiTr('AM') : uiTr('PM');

  return '$day/$month/${date.year}  $hour:$minute $period';
}

class _AdminApiException implements Exception {
  final String message;

  const _AdminApiException(this.message);
}

class _AdminApiService {
  final _AdminSession session;

  const _AdminApiService(this.session);

  Map<String, String> get _headers {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': session.authorizationHeader,
    };
  }

  Future<dynamic> _request(
      String method,
      String path, {
        Map<String, dynamic>? body,
      }) async {
    final uri = Uri.parse('${_ApiConfig.baseUrl}$path');
    late http.Response response;

    try {
      if (method == 'GET') {
        response = await http
            .get(uri, headers: _headers)
            .timeout(Duration(seconds: 15));
      } else if (method == 'POST') {
        response = await http
            .post(
          uri,
          headers: _headers,
          body: jsonEncode(body),
        )
            .timeout(Duration(seconds: 15));
      } else if (method == 'PUT') {
        response = await http
            .put(
          uri,
          headers: _headers,
          body: jsonEncode(body),
        )
            .timeout(Duration(seconds: 15));
      } else if (method == 'DELETE') {
        response = await http
            .delete(uri, headers: _headers)
            .timeout(Duration(seconds: 15));
      } else {
        throw _AdminApiException(uiTr('Unsupported request method.'));
      }
    } on _AdminApiException {
      rethrow;
    } catch (_) {
      throw _AdminApiException(
        uiTr('Cannot connect to the server. Check that it is running.'),
      );
    }

    if (response.statusCode == 401) {
      throw _AdminApiException(
        uiTr('Your session has expired. Please sign in again.'),
      );
    }

    if (response.statusCode == 403) {
      throw _AdminApiException(
        uiTr('You do not have permission to perform this action.'),
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _AdminApiException(
        _readErrorMessage(response),
      );
    }

    if (response.bodyBytes.isEmpty) {
      return null;
    }

    final text = utf8.decode(response.bodyBytes);

    if (text.trim().isEmpty) {
      return null;
    }

    return jsonDecode(text);
  }

  String _readErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString();

        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // The fallback below is used when the server has no JSON body.
    }

    if (response.statusCode == 404) {
      return uiTr('Requested item not found.');
    }

    if (response.statusCode == 409) {
      return uiTr('Cannot complete this action because related data exists.');
    }

    return uiTr('Action failed. Error code: ${response.statusCode}');
  }

  Future<List<_AdminAnnouncement>> getMyAnnouncements() async {
    final decoded = await _request(
      'GET',
      '/api/announcements/my',
    );

    return _parseAnnouncementList(decoded);
  }

  Future<List<_AdminAnnouncement>> getAllAnnouncements() async {
    final decoded = await _request(
      'GET',
      '/api/announcements',
    );

    return _parseAnnouncementList(decoded);
  }

  Future<_AdminAnnouncement> addAnnouncement({
    required String title,
    required String content,
    required String? imageUrl,
    required DateTime startAt,
    required DateTime endAt,
    required bool showOnDisplayScreen,
  }) async {
    final decoded = await _request(
      'POST',
      '/api/announcements',
      body: {
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        'showOnDisplayScreen': showOnDisplayScreen,
      },
    );

    return _AdminAnnouncement.fromJson(
      decoded as Map<String, dynamic>,
    );
  }

  Future<_AdminAnnouncement> updateAnnouncement({
    required int id,
    required String title,
    required String content,
    required String? imageUrl,
    required DateTime startAt,
    required DateTime endAt,
    required bool showOnDisplayScreen,
  }) async {
    final decoded = await _request(
      'PUT',
      '/api/announcements/$id',
      body: {
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        'showOnDisplayScreen': showOnDisplayScreen,
      },
    );

    return _AdminAnnouncement.fromJson(
      decoded as Map<String, dynamic>,
    );
  }

  Future<void> deleteAnnouncement(int id) async {
    await _request('DELETE', '/api/announcements/$id');
  }

  Future<List<_InstitutionEvent>> getMyEvents() async {
    final decoded = await _request('GET', '/api/events/my');
    if (decoded is! List) {
      throw _AdminApiException(uiTr('Invalid events response.'));
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_InstitutionEvent.fromJson)
        .toList();
  }

  Future<_InstitutionEvent> addEvent({
    required String title,
    required String description,
    required String location,
    required String imageUrl,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    final decoded = await _request(
      'POST',
      '/api/events',
      body: {
        'title': title,
        'description': description,
        'location': location,
        'imageUrl': imageUrl.isEmpty ? null : imageUrl,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
      },
    );
    return _InstitutionEvent.fromJson(decoded as Map<String, dynamic>);
  }

  Future<_InstitutionEvent> updateEvent({
    required int id,
    required String title,
    required String description,
    required String location,
    required String imageUrl,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    final decoded = await _request(
      'PUT',
      '/api/events/$id',
      body: {
        'title': title,
        'description': description,
        'location': location,
        'imageUrl': imageUrl.isEmpty ? null : imageUrl,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
      },
    );
    return _InstitutionEvent.fromJson(decoded as Map<String, dynamic>);
  }

  Future<void> deleteEvent(int id) async {
    await _request('DELETE', '/api/events/$id');
  }

  Future<List<_ManagedInstitution>> getInstitutions() async {
    final decoded = await _request('GET', '/api/institutions');

    if (decoded is! List) {
      throw _AdminApiException(uiTr('Invalid institutions response.'));
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_ManagedInstitution.fromJson)
        .toList();
  }

  Future<_ManagedInstitution> addInstitution({
    required String name,
    required String city,
    required String type,
    required String description,
    required String address,
    required String phone,
    required String email,
    required String websiteUrl,
    required String logoUrl,
    required double? latitude,
    required double? longitude,
  }) async {
    final decoded = await _request(
      'POST',
      '/api/institutions',
      body: {
        'name': name,
        'city': city,
        'type': type,
        'description': description,
        'address': address,
        'phone': phone,
        'email': email,
        'websiteUrl': websiteUrl,
        'logoUrl': logoUrl,
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    return _ManagedInstitution.fromJson(
      decoded as Map<String, dynamic>,
    );
  }

  Future<_ManagedInstitution> updateInstitution({
    required int id,
    required String name,
    required String city,
    required String type,
    required String description,
    required String address,
    required String phone,
    required String email,
    required String websiteUrl,
    required String logoUrl,
    required double? latitude,
    required double? longitude,
  }) async {
    final decoded = await _request(
      'PUT',
      '/api/institutions/$id',
      body: {
        'name': name,
        'city': city,
        'type': type,
        'description': description,
        'address': address,
        'phone': phone,
        'email': email,
        'websiteUrl': websiteUrl,
        'logoUrl': logoUrl,
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    return _ManagedInstitution.fromJson(
      decoded as Map<String, dynamic>,
    );
  }

  Future<void> deleteInstitution(int id) async {
    await _request('DELETE', '/api/institutions/$id');
  }

  Future<List<_AdminAccountInfo>> getAdmins() async {
    final decoded = await _request(
      'GET',
      '/api/super-admin/admins',
    );

    if (decoded is! List) {
      throw _AdminApiException(uiTr('Invalid administrators response.'));
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_AdminAccountInfo.fromJson)
        .toList();
  }

  Future<_AdminAccountInfo> addInstitutionAdmin({
    required String name,
    required String email,
    required String password,
    required int institutionId,
  }) async {
    final decoded = await _request(
      'POST',
      '/api/super-admin/institution-admins',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'institutionId': institutionId,
      },
    );

    return _AdminAccountInfo.fromJson(
      decoded as Map<String, dynamic>,
    );
  }

  Future<void> deleteAdmin(int id) async {
    await _request(
      'DELETE',
      '/api/super-admin/admins/$id',
    );
  }

  List<_AdminAnnouncement> _parseAnnouncementList(
      dynamic decoded,
      ) {
    if (decoded is! List) {
      throw _AdminApiException(uiTr('Invalid announcements response.'));
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_AdminAnnouncement.fromJson)
        .toList();
  }
}

class _AdminAnnouncement {
  final int id;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime startAt;
  final DateTime endAt;
  final String status;
  final int institutionId;
  final bool showOnDisplayScreen;

  const _AdminAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.createdAt,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.institutionId,
    required this.showOnDisplayScreen,
  });

  factory _AdminAnnouncement.fromJson(
      Map<String, dynamic> json,
      ) {
    return _AdminAnnouncement(
      id: _jsonInt(json['id']),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      createdAt: _jsonDate(json['createdAt']),
      startAt: _jsonDate(json['startAt']),
      endAt: _jsonDate(json['endAt']),
      status: json['status']?.toString() ?? '',
      institutionId: _jsonInt(json['institutionId']),
      showOnDisplayScreen: _jsonBool(json['showOnDisplayScreen']),
    );
  }
}

class _InstitutionEvent {
  final int id;
  final String title;
  final String description;
  final String location;
  final String? imageUrl;
  final DateTime startAt;
  final DateTime endAt;
  final String status;
  final int institutionId;

  const _InstitutionEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.imageUrl,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.institutionId,
  });

  factory _InstitutionEvent.fromJson(Map<String, dynamic> json) {
    return _InstitutionEvent(
      id: _jsonInt(json['id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      startAt: _jsonDate(json['startAt']),
      endAt: _jsonDate(json['endAt']),
      status: json['status']?.toString() ?? '',
      institutionId: _jsonInt(json['institutionId']),
    );
  }
}

class _ManagedInstitution {
  final int id;
  final String name;
  final String city;
  final String type;
  final String description;
  final String address;
  final String phone;
  final String email;
  final String websiteUrl;
  final String logoUrl;
  final double? latitude;
  final double? longitude;

  const _ManagedInstitution({
    required this.id,
    required this.name,
    required this.city,
    required this.type,
    required this.description,
    required this.address,
    required this.phone,
    required this.email,
    required this.websiteUrl,
    required this.logoUrl,
    required this.latitude,
    required this.longitude,
  });

  factory _ManagedInstitution.fromJson(Map<String, dynamic> json) {
    return _ManagedInstitution(
      id: _jsonInt(json['id']),
      name: json['name']?.toString() ?? '',
      city: (json['city'] ?? json['village'])?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      websiteUrl: json['websiteUrl']?.toString() ?? '',
      logoUrl: json['logoUrl']?.toString() ?? '',
      latitude: _jsonNullableDouble(json['latitude']),
      longitude: _jsonNullableDouble(json['longitude']),
    );
  }
}

class _AdminAccountInfo {
  final int id;
  final String name;
  final String email;
  final String role;
  final int? institutionId;

  const _AdminAccountInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.institutionId,
  });

  factory _AdminAccountInfo.fromJson(
      Map<String, dynamic> json,
      ) {
    return _AdminAccountInfo(
      id: _jsonInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      institutionId: _jsonNullableInt(json['institutionId']),
    );
  }
}

int _jsonInt(Object? value) {
  final result = _jsonNullableInt(value);

  if (result == null) {
    throw FormatException('Expected an integer value.');
  }

  return result;
}

int? _jsonNullableInt(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  return int.tryParse(value.toString());
}

double? _jsonNullableDouble(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

bool _jsonBool(Object? value) {
  if (value is bool) {
    return value;
  }

  final normalized = value?.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1';
}

DateTime _jsonDate(Object? value) {
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}


// Home-screen presentation widgets. They do not change the backend API.
class _FriendlyInstitutionHeader extends StatelessWidget {
  final Institution institution;
  final String? adminName;
  final Future<void> Function() onInstitutionPressed;
  final VoidCallback onNotificationsPressed;

  const _FriendlyInstitutionHeader({
    required this.institution,
    required this.adminName,
    required this.onInstitutionPressed,
    required this.onNotificationsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.sageSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.holiday_village_outlined,
                  color: AppColors.sageDark, size: 26),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: onInstitutionPressed,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adminName == null || adminName!.trim().isEmpty
                          ? uiTr('Welcome')
                          : uiTr('Welcome ${adminName!.trim()}'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: AppColors.sageDark,
                      ),
                    ),
                    Text(
                      institution.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.mutedText),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: onNotificationsPressed,
              icon: const Icon(Icons.notifications_none_rounded,
                  color: AppColors.sageDark),
              tooltip: uiTr('Announcements'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Align(
          alignment: _isEnglish ? Alignment.centerRight : Alignment.centerLeft,
          child: const _LanguageToggle(),
        ),
      ],
    );
  }
}

class _HomeSimpleHeading extends StatelessWidget {
  final String title;
  final IconData icon;
  const _HomeSimpleHeading(this.title, this.icon);
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: AppColors.gold, size: 23),
    SizedBox(width: 8),
    Text(title, style: TextStyle(color: AppColors.text,
        fontSize: 19, fontWeight: FontWeight.w800)),
  ]);
}

class _EventImagePlaceholder extends StatelessWidget {
  const _EventImagePlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    color: Color(0xFFEAEDE5),
    alignment: Alignment.center,
    child: Icon(Icons.landscape_outlined,
        size: 42, color: AppColors.sage),
  );
}

class _HomeEventCard extends StatelessWidget {
  final _InstitutionEvent event;
  final VoidCallback onTap;
  const _HomeEventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final url = event.imageUrl?.trim() ?? '';
    return SizedBox(
      width: 218,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 115,
                width: double.infinity,
                child: url.isEmpty
                    ? _EventImagePlaceholder()
                    : Image.network(url, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _EventImagePlaceholder()),
              ),
              Expanded(child: Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatAdminDate(event.startAt),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10.5,
                            color: AppColors.mutedText)),
                    SizedBox(height: 5),
                    Text(event.title, maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w800,
                            fontSize: 14, color: AppColors.text)),
                    Spacer(),
                    Row(children: [
                      Icon(Icons.place_outlined, size: 14,
                          color: AppColors.sage),
                      SizedBox(width: 3),
                      Expanded(child: Text(
                          event.location.trim().isEmpty
                              ? uiTr('Event Details') : event.location,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11,
                              color: AppColors.mutedText))),
                    ]),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeShortcut extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _HomeShortcut({required this.icon, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(color: AppColors.surface,
      borderRadius: BorderRadius.circular(18), clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 3),
          child: Column(children: [
            Icon(icon, color: AppColors.sageDark, size: 27),
            SizedBox(height: 9),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: AppColors.text,
                    fontWeight: FontWeight.w700)),
          ]))));
}

class _HomeAdminAccess extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _HomeAdminAccess({required this.title, required this.subtitle,
    required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.sageSoft, borderRadius: BorderRadius.circular(21),
    clipBehavior: Clip.antiAlias,
    child: InkWell(onTap: onTap, child: Padding(
        padding: EdgeInsets.all(16), child: Row(children: [
      Icon(Icons.admin_panel_settings_rounded,
          size: 35, color: AppColors.sageDark),
      SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 16,
                fontWeight: FontWeight.w800, color: AppColors.sageDark)),
            SizedBox(height: 3),
            Text(subtitle, style: TextStyle(fontSize: 12,
                color: AppColors.mutedText)),
          ])),
      Icon(Icons.arrow_back_ios_new, size: 17,
          color: AppColors.sageDark),
    ]))),
  );
}


// Responsive institution cover: text/buttons on the LEFT, picture on RIGHT.
// The source image may already contain printed lettering, so only its right
// photographic part is shown. The readable copy is rebuilt using Flutter.
class _InstitutionCoverCard extends StatelessWidget {
  final Institution institution;
  final bool isAdmin;
  final VoidCallback onAction;

  const _InstitutionCoverCard({
    required this.institution,
    required this.isAdmin,
    required this.onAction,
  });

  // Find the direction of the first strong letter, not the app's RTL layout.
  TextDirection _contentDirection(String value) {
    final firstLetter = RegExp(r'[A-Za-z\u0590-\u08FF]').firstMatch(value);
    if (firstLetter == null) return TextDirection.rtl;
    final character = firstLetter.group(0)!;
    return RegExp(r'[A-Za-z]').hasMatch(character)
        ? TextDirection.ltr
        : TextDirection.rtl;
  }

  @override
  Widget build(BuildContext context) {
    final title = institution.coverTitle.trim().isNotEmpty
        ? institution.coverTitle.trim() : institution.name;
    final description = institution.coverDescription.trim().isNotEmpty
        ? institution.coverDescription.trim() : institution.description.trim();
    final imageUrl = institution.coverImageUrl.trim();
    final titleDirection = _contentDirection(title);
    final descriptionDirection = _contentDirection(description);

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final compact = w < 370;
      final height = compact ? 260.0 : 265.0;
      final leftInset = compact ? 16.0 : 24.0;

      return ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: SizedBox(
          width: w,
          height: height,
          child: Stack(fit: StackFit.expand, children: [
            ColoredBox(color: Color(0xFFF7F0E0)),
            // Photo is confined to the RIGHT. Center-right crop removes
            // any headline printed on the original banner's left half.
            Positioned(
              right: 0, top: 0, bottom: 0, width: w * .72,
              child: imageUrl.isEmpty
                  ? ColoredBox(color: Color(0xFFE4E9DF),
                  child: Icon(Icons.apartment_rounded,
                      color: Color(0xFF809886), size: 58))
                  : Image.network(imageUrl, fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  errorBuilder: (_, __, ___) => ColoredBox(
                      color: Color(0xFFE4E9DF),
                      child: Icon(Icons.image_not_supported_outlined,
                          color: Color(0xFF809886), size: 48))),
            ),
            // Cream at left, soft transparent transition toward the photo.
            DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [0.0, .32, .55, .79],
                colors: [
                  Color(0xFFF7F0E0), Color(0xFFF7F0E0),
                  Color(0xEAF7F0E0), Color(0x00F7F0E0),
                ],
              ),
            )),
            // Pale botanical decoration in the bottom-left corner.
            Positioned(left: -7, bottom: -8, width: 100, height: 105,
              child: IgnorePointer(child: CustomPaint(
                painter: _CoverLeavesPainter(),
              )),
            ),
            Positioned(
              left: leftInset,
              top: compact ? 14 : 16,
              bottom: 74,
              width: w * (compact ? .56 : .54),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title,
                      textDirection: titleDirection,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: titleDirection == TextDirection.ltr
                          ? TextAlign.left : TextAlign.right,
                      style: TextStyle(
                        color: Color(0xFF155440),
                        fontSize: compact ? 21 : 25,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(description,
                        textDirection: descriptionDirection,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: descriptionDirection == TextDirection.ltr
                            ? TextAlign.left : TextAlign.right,
                        style: TextStyle(
                          color: Color(0xFF62655F),
                          fontSize: compact ? 14 : 15,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Keep the action anchored at the bottom BESIDE the leaves,
            // independently of the title and description's length.
            Positioned(
              left: compact ? 68 : 85,
              bottom: 15,
              child: Directionality(
                textDirection: _isEnglish ? TextDirection.ltr : TextDirection.rtl,
                child: FilledButton.icon(
                  onPressed: onAction,
                  icon: Icon(isAdmin ? Icons.add : Icons.info_outline,
                      size: compact ? 17 : 19),
                  label: Text(uiTr(isAdmin ? 'Add Content' : 'About the Institution'),
                      style: TextStyle(fontSize: compact ? 13 : 14,
                          fontWeight: FontWeight.w800)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Color(0xFFBE9848),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                        horizontal: compact ? 12 : 19, vertical: 11),
                    minimumSize: Size(0, 42),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: StadiumBorder(),
                  ),
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }
}

class _CoverLeavesPainter extends CustomPainter {
  const _CoverLeavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stem = Paint()
      ..color = Color(0xFFB3CEB5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final leaf = Paint()..color = Color(0xFFB7D0B9);
    final path = Path()
      ..moveTo(26, size.height)
      ..quadraticBezierTo(33, 58, 68, 18);
    canvas.drawPath(path, stem);
    void drawLeaf(double x, double y, double width, double height, double angle) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      final shape = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-width * .55, -height * .5, 0, -height)
        ..quadraticBezierTo(width * .55, -height * .5, 0, 0);
      canvas.drawPath(shape, leaf);
      canvas.restore();
    }
    drawLeaf(28, 100, 31, 59, -.45);
    drawLeaf(39, 81, 25, 51, .55);
    drawLeaf(53, 58, 22, 46, -.55);
    drawLeaf(67, 34, 20, 38, .35);
    drawLeaf(10, 81, 22, 43, -.6);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Auto-switching announcement card lives UNDER the important announcements heading.
class _ImportantAnnouncementsCarousel extends StatefulWidget {
  final List<_AdminAnnouncement> announcements;
  final ValueChanged<_AdminAnnouncement> onPressed;
  const _ImportantAnnouncementsCarousel({
    required this.announcements, required this.onPressed,
  });
  @override
  State<_ImportantAnnouncementsCarousel> createState() =>
      _ImportantAnnouncementsCarouselState();
}

class _ImportantAnnouncementsCarouselState
    extends State<_ImportantAnnouncementsCarousel> {
  final PageController _pages = PageController();
  Timer? _timer;
  int _index = 0;
  @override
  void initState() {
    super.initState();
    _startTimer();
  }
  void _startTimer() {
    _timer?.cancel();
    if (widget.announcements.length < 2) return;
    _timer = Timer.periodic(Duration(seconds: 6), (_) {
      if (!mounted || !_pages.hasClients) return;
      _pages.animateToPage((_index + 1) % widget.announcements.length,
          duration: Duration(milliseconds: 450),
          curve: Curves.easeInOut);
    });
  }
  @override
  void didUpdateWidget(covariant _ImportantAnnouncementsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.announcements.length != widget.announcements.length ||
        oldWidget.announcements.isNotEmpty && widget.announcements.isNotEmpty &&
            oldWidget.announcements.first.id != widget.announcements.first.id) {
      _index = 0;
      if (_pages.hasClients) _pages.jumpToPage(0);
      _startTimer();
    }
  }
  @override
  void dispose() { _timer?.cancel(); _pages.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Column(children: [
    SizedBox(height: 166, child: PageView.builder(
      controller: _pages,
      itemCount: widget.announcements.length,
      onPageChanged: (i) => setState(() => _index = i),
      itemBuilder: (context, i) {
        final ad = widget.announcements[i];
        final img = ad.imageUrl?.trim() ?? '';
        return Material(
          color: Color(0xFFFFFCF8),
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: () => widget.onPressed(ad),
            child: Row(children: [
              SizedBox(width: 126, height: double.infinity,
                child: img.isEmpty
                    ? ColoredBox(color: Color(0xFFE8DFD2),
                    child: Icon(Icons.campaign_outlined,
                        size: 48, color: Color(0xFFAC9F92)))
                    : Image.network(img, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                        color: Color(0xFFE8DFD2),
                        child: Icon(Icons.image_not_supported_outlined))),
              ),
              Expanded(child: Padding(
                padding: EdgeInsets.all(13),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ad.title, maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w800, color: AppColors.text)),
                    SizedBox(height: 7),
                    Expanded(child: Text(ad.content, maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12,
                            color: AppColors.mutedText, height: 1.35))),
                    Text(uiTr('Details  →'), style: TextStyle(
                        color: Color(0xFF9A783D),
                        fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
              )),
            ]),
          ),
        );
      },
    )),
    if (widget.announcements.length > 1) ...[
      SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.announcements.length, (i) =>
            AnimatedContainer(duration: Duration(milliseconds: 200),
              margin: EdgeInsets.symmetric(horizontal: 3),
              width: _index == i ? 19 : 7, height: 7,
              decoration: BoxDecoration(
                  color: _index == i ? AppColors.gold : AppColors.outline,
                  borderRadius: BorderRadius.circular(20)),
            ),
        ),
      ),
    ],
  ]);
}

class _InstitutionCoverEditor extends StatefulWidget {
  final _AdminSession session;
  const _InstitutionCoverEditor({required this.session});
  @override
  State<_InstitutionCoverEditor> createState() => _InstitutionCoverEditorState();
}

class _InstitutionCoverEditorState extends State<_InstitutionCoverEditor> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _image = TextEditingController();
  bool _saving = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final id = widget.session.institutionId;
    if (id == null) { setState(() { _error = uiTr('No institution is linked to this account.'); _loading = false; }); return; }
    try {
      final r = await http.get(Uri.parse('${_ApiConfig.baseUrl}/api/institutions/$id'))
          .timeout(Duration(seconds: 12));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final data = jsonDecode(utf8.decode(r.bodyBytes));
      final item = Institution.fromJson(data as Map<String, dynamic>);
      _title.text = item.coverTitle;
      _description.text = item.coverDescription;
      _image.text = item.coverImageUrl;
    } catch (_) { _error = uiTr('Could not load the cover. Check your connection.'); }
    if (mounted) setState(() => _loading = false);
  }
  Future<void> _save() async {
    final id = widget.session.institutionId;
    if (id == null || _saving) return;
    setState(() { _saving = true; _error = null; });
    try {
      final response = await http.put(
        Uri.parse('${_ApiConfig.baseUrl}/api/institutions/$id/cover'),
        headers: {
          'Authorization': widget.session.authorizationHeader,
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'coverTitle': _title.text.trim(),
          'coverDescription': _description.text.trim(),
          'coverImageUrl': _image.text.trim(),
        }),
      ).timeout(Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw Exception(uiTr('Save failed (${response.statusCode})'));
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = uiTr('Could not save cover: $e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  @override
  void dispose() {
    _title.dispose(); _description.dispose(); _image.dispose(); super.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(uiTr('Edit Institution Cover'))),
    body: _loading ? Center(child: CircularProgressIndicator()) :
    ListView(padding: EdgeInsets.all(20), children: [
      if (_error != null) ...[
        Text(_error!, style: TextStyle(color: Colors.red)),
        SizedBox(height: 14),
      ],
      TextField(controller: _title, maxLength: 255,
          decoration: InputDecoration(labelText: uiTr('Cover Title'))),
      SizedBox(height: 12),
      TextField(controller: _description, maxLength: 2000, maxLines: 3,
          decoration: InputDecoration(labelText: uiTr('Cover Description'))),
      SizedBox(height: 12),
      TextField(controller: _image, maxLength: 2048,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(labelText: uiTr('Cover Image URL'))),
      SizedBox(height: 20),
      FilledButton.icon(onPressed: _saving ? null : _save,
          icon: Icon(Icons.save_outlined),
          label: Text(_saving ? uiTr('Saving...') : uiTr('Save Cover'))),
    ]),
  );
}
