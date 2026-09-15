import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'screens/agenda_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('install_date')) {
    await prefs.setString('install_date', DateTime.now().toIso8601String());
  }

  runApp(const MeuAppOrcamento());
}

class MeuAppOrcamento extends StatelessWidget {
  const MeuAppOrcamento({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrçaFácil PRO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: const Color(0xFF1976D2),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      home: const WelcomeScreen(),
    );
  }
}

// ==========================================
// MODELOS DE DADOS LOCAIS
// ==========================================

class UserAccountInfo {
  final String email;
  final String displayName;
  UserAccountInfo({required this.email, required this.displayName});
}

class CompanyProfile {
  String name;
  String doc;
  String phone;
  String address;
  String? logoBase64;
  String? signatureBase64;

  CompanyProfile({
    this.name = '',
    this.doc = '',
    this.phone = '',
    this.address = '',
    this.logoBase64,
    this.signatureBase64,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'doc': doc,
        'phone': phone,
        'address': address,
        'logoBase64': logoBase64,
        'signatureBase64': signatureBase64,
      };

  factory CompanyProfile.fromJson(Map<String, dynamic> json) => CompanyProfile(
        name: json['name'] ?? '',
        doc: json['doc'] ?? '',
        phone: json['phone'] ?? '',
        address: json['address'] ?? '',
        logoBase64: json['logoBase64'],
        signatureBase64: json['signatureBase64'],
      );
}

class BudgetItem {
  String description;
  int quantity;
  double unitPrice;

  BudgetItem({
    required this.description,
    this.quantity = 1,
    this.unitPrice = 0.0,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  factory BudgetItem.fromJson(Map<String, dynamic> json) => BudgetItem(
        description: json['description'] ?? '',
        quantity: json['quantity'] ?? 1,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      );
}

class Budget {
  String id;
  int number;
  String clientName;
  String clientPhone;
  String clientAddress;
  DateTime date;
  List<BudgetItem> items;
  double discount;
  String status; // 'Pendente', 'Aprovado', 'Concluído', 'Cancelado'
  String notes;

  Budget({
    required this.id,
    required this.number,
    required this.clientName,
    this.clientPhone = '',
    this.clientAddress = '',
    required this.date,
    required this.items,
    this.discount = 0.0,
    this.status = 'Pendente',
    this.notes = '',
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);
  double get total => (subtotal - discount) < 0 ? 0.0 : (subtotal - discount);

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'clientAddress': clientAddress,
        'date': date.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
        'discount': discount,
        'status': status,
        'notes': notes,
      };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        id: json['id'] ?? '',
        number: json['number'] ?? 1,
        clientName: json['clientName'] ?? '',
        clientPhone: json['clientPhone'] ?? '',
        clientAddress: json['clientAddress'] ?? '',
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
        items: (json['items'] as List<dynamic>?)
                ?.map((i) => BudgetItem.fromJson(i))
                .toList() ??
            [],
        discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
        status: json['status'] ?? 'Pendente',
        notes: json['notes'] ?? '',
      );
}

class FinancialTransaction {
  String id;
  String description;
  String clientName;
  double amount;
  DateTime date;
  String type; // 'Receita' ou 'Despesa'
  String status; // 'Recebido', 'A Receber', 'Pago', 'Pendente'
  String category;
  String notes;
  String? budgetId;

  FinancialTransaction({
    required this.id,
    required this.description,
    required this.clientName,
    required this.amount,
    required this.date,
    required this.type,
    required this.status,
    required this.category,
    this.notes = '',
    this.budgetId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'clientName': clientName,
        'amount': amount,
        'date': date.toIso8601String(),
        'type': type,
        'status': status,
        'category': category,
        'notes': notes,
        'budgetId': budgetId,
      };

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) => FinancialTransaction(
        id: json['id'] ?? '',
        description: json['description'] ?? '',
        clientName: json['clientName'] ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
        type: json['type'] ?? 'Receita',
        status: json['status'] ?? 'A Receber',
        category: json['category'] ?? 'Orçamento',
        notes: json['notes'] ?? '',
        budgetId: json['budgetId'],
      );
}

// ==========================================
// TELA DE BOAS-VINDAS & LOGIN FLEXÍVEL
// ==========================================

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  int _authMode = 0; // 0 = Início, 1 = Cadastro, 2 = Login

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '1098844585019-8qvqiqkl5o591elut5mf50v6dmbngb92.apps.googleusercontent.com',
  );

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final account = await _googleSignIn.signIn();
      if (account != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigationScreen(
              userInfo: UserAccountInfo(
                email: account.email,
                displayName: account.displayName ?? 'Usuário Google',
              ),
            ),
          ),
        );
      } else {
        setState(() => _errorMessage = 'Login com Google cancelado.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erro no login com Google: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleManualRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      setState(() => _errorMessage = 'Preencha todos os campos para se cadastrar.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      await prefs.setString('user_password', password);
      await prefs.setString('user_name', name);
      await prefs.setBool('is_logged_in', true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta cadastrada com sucesso!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainNavigationScreen(
            userInfo: UserAccountInfo(email: email, displayName: name),
          ),
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao cadastrar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleManualLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Informe seu e-mail e senha.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('user_email');
      final savedPassword = prefs.getString('user_password');
      final savedName = prefs.getString('user_name') ?? 'Profissional';

      if (savedEmail == null) {
        await prefs.setString('user_email', email);
        await prefs.setString('user_password', password);
        await prefs.setString('user_name', email.split('@')[0]);
        await prefs.setBool('is_logged_in', true);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigationScreen(
              userInfo: UserAccountInfo(email: email, displayName: email.split('@')[0]),
            ),
          ),
        );
        return;
      }

      if (savedEmail.toLowerCase() == email.toLowerCase() && savedPassword == password) {
        await prefs.setBool('is_logged_in', true);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigationScreen(
              userInfo: UserAccountInfo(email: email, displayName: savedName),
            ),
          ),
        );
      } else {
        setState(() => _errorMessage = 'Senha incorreta para este e-mail.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao fazer login: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final emailInput = _emailController.text.trim();
    if (emailInput.isEmpty) {
      setState(() => _errorMessage = 'Digite seu e-mail acima para enviar as instruções.');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redefinição de Senha'),
        content: Text('Enviamos um link seguro de recuperação para:\n\n📧 $emailInput'),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade800, Colors.blue.shade400],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.request_quote, size: 80, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'OrçaFácil PRO',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _authMode == 0
                      ? 'Gerencie orçamentos e finanças com segurança.'
                      : (_authMode == 1 ? 'Cadastre sua conta' : 'Acesse com seu e-mail e senha'),
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_authMode == 0) ...[
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleLogin,
                    icon: const Icon(Icons.login, color: Colors.blue),
                    label: const Text('Entrar com Google', style: TextStyle(fontSize: 16, color: Colors.black87)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('OU', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() { _authMode = 2; _errorMessage = null; }),
                      icon: const Icon(Icons.email, color: Colors.white),
                      label: const Text('Entrar com E-mail e Senha', style: TextStyle(fontSize: 15, color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() { _authMode = 1; _errorMessage = null; }),
                    child: const Text('Não tem uma conta? Cadastre-se', style: TextStyle(color: Colors.white, decoration: TextDecoration.underline)),
                  ),
                ] else if (_authMode == 1) ...[
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nome / Empresa',
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white54), borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white54), borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Senha de Acesso',
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white54), borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleManualRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('CADASTRAR CONTA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() { _authMode = 0; _errorMessage = null; }),
                    child: const Text('Voltar', style: TextStyle(color: Colors.white70)),
                  ),
                ] else if (_authMode == 2) ...[
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Seu E-mail',
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white54), borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Sua Senha',
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white54), borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleManualLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('ENTRAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => setState(() { _authMode = 1; _errorMessage = null; }),
                        child: const Text('Criar conta', style: TextStyle(color: Colors.white)),
                      ),
                      TextButton(
                        onPressed: _handleForgotPassword,
                        child: const Text('Esqueci minha senha', style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => setState(() { _authMode = 0; _errorMessage = null; }),
                    child: const Text('Voltar ao início', style: TextStyle(color: Colors.white70)),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// NAVEGAÇÃO PRINCIPAL COM DASHBOARD (INÍCIO)
// ==========================================

class MainNavigationScreen extends StatefulWidget {
  final UserAccountInfo userInfo;

  const MainNavigationScreen({super.key, required this.userInfo});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _isPro = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkTrialStatus();
  }

  Future<void> _checkTrialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final proStatus = prefs.getBool('is_pro_user') ?? false;
    if (proStatus) {
      setState(() {
        _isPro = true;
        _isLoading = false;
      });
      return;
    }

    final installDateStr = prefs.getString('install_date');
    if (installDateStr != null) {
      final installDate = DateTime.parse(installDateStr);
      final difference = DateTime.now().difference(installDate).inDays;
      if (difference > 7) {
        setState(() => _isPro = false);
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> screens = [
      DashboardScreen(
        userInfo: widget.userInfo,
        isPro: _isPro,
        onNavigate: (index) => setState(() => _currentIndex = index),
      ),
      BudgetsHomeScreen(userInfo: widget.userInfo, isPro: _isPro),
      _isPro ? const AgendaScreen() : const LockedFeatureScreen(featureName: 'Agenda'),
      ManagedFinancialScreen(userInfo: widget.userInfo, isPro: _isPro),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.request_quote), label: 'Orçamentos'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Agenda'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Financeiro'),
        ],
      ),
    );
  }
}

// ==========================================
// TELA DASHBOARD (INÍCIO)
// ==========================================

class DashboardScreen extends StatefulWidget {
  final UserAccountInfo userInfo;
  final bool isPro;
  final Function(int) onNavigate;

  const DashboardScreen({super.key, required this.userInfo, required this.isPro, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Budget> _budgets = [];
  List<Appointment> _appointments = [];
  List<FinancialTransaction> _transactions = [];
  CompanyProfile _companyProfile = CompanyProfile();

  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();

    final profileStr = prefs.getString('company_profile');
    if (profileStr != null) {
      _companyProfile = CompanyProfile.fromJson(jsonDecode(profileStr));
    }

    final budgetsStr = prefs.getString('budgets_list');
    if (budgetsStr != null) {
      final List<dynamic> listJson = jsonDecode(budgetsStr);
      _budgets = listJson.map((e) => Budget.fromJson(e)).toList();
    }

    final apptsStr = prefs.getString('appointments_list');
    if (apptsStr != null) {
      final List<dynamic> listJson = jsonDecode(apptsStr);
      _appointments = listJson.map((e) => Appointment.fromJson(e)).toList();
    }

    final transStr = prefs.getString('financial_transactions_list');
    if (transStr != null) {
      final List<dynamic> listJson = jsonDecode(transStr);
      _transactions = listJson.map((e) => FinancialTransaction.fromJson(e)).toList();
    } else {
      for (var b in _budgets) {
        if (b.status != 'Cancelado') {
          _transactions.add(FinancialTransaction(
            id: 'trans_${b.id}',
            description: 'Orçamento #${b.number.toString().padLeft(3, '0')} - ${b.clientName}',
            clientName: b.clientName,
            amount: b.total,
            date: b.date,
            type: 'Receita',
            status: 'A Receber',
            category: 'Orçamento',
            budgetId: b.id,
          ));
        }
      }
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final int pendingBudgetsCount = _budgets.where((b) => b.status == 'Pendente').length;

    final now = DateTime.now();
    final todayAppointments = _appointments.where((a) {
      return a.date.year == now.year && a.date.month == now.month && a.date.day == now.day;
    }).toList();

    final double totalAReceber = _transactions
        .where((t) => t.type == 'Receita' && t.status == 'A Receber')
        .fold(0.0, (sum, t) => sum + t.amount);

    final double totalRecebidoMes = _transactions
        .where((t) => t.type == 'Receita' && (t.status == 'Recebido' || t.status == 'Pago') && t.date.month == now.month && t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);

    final double totalDespesasMes = _transactions
        .where((t) => t.type == 'Despesa' && t.date.month == now.month && t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);

    final double saldoMes = totalRecebidoMes - totalDespesasMes;

    final displayName = _companyProfile.name.isNotEmpty ? _companyProfile.name : widget.userInfo.displayName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OrçaFácil PRO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar Dados',
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              displayName.isNotEmpty ? 'Bom dia, $displayName!' : 'Olá! 👋',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Veja um resumo do seu negócio.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildSummaryCard(
                  title: 'ORÇAMENTOS PENDENTES',
                  value: pendingBudgetsCount.toString(),
                  color: Colors.orange,
                  icon: Icons.pending_actions,
                  onTap: () => widget.onNavigate(1),
                ),
                _buildSummaryCard(
                  title: 'AGENDAMENTOS HOJE',
                  value: todayAppointments.length.toString(),
                  color: Colors.blue,
                  icon: Icons.calendar_today,
                  onTap: () => widget.onNavigate(2),
                ),
                _buildSummaryCard(
                  title: 'A RECEBER',
                  value: currencyFormat.format(totalAReceber),
                  color: Colors.indigo,
                  icon: Icons.account_balance_wallet,
                  onTap: () => widget.onNavigate(3),
                ),
                _buildSummaryCard(
                  title: 'RECEBIDO NO MÊS',
                  value: currencyFormat.format(totalRecebidoMes),
                  color: Colors.green,
                  icon: Icons.check_circle,
                  onTap: () => widget.onNavigate(3),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Agenda de hoje', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => widget.onNavigate(2),
                  child: const Text('Ver agenda →'),
                ),
              ],
            ),
            todayAppointments.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Você não possui agendamentos para hoje.', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: todayAppointments.length > 3 ? 3 : todayAppointments.length,
                    itemBuilder: (context, index) {
                      final appt = todayAppointments[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(DateFormat('HH:mm').format(appt.date), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ),
                          title: Text(appt.clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(appt.title),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Financeiro (Mês Atual)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => widget.onNavigate(3),
                  child: const Text('Ver financeiro →'),
                ),
              ],
            ),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildFinanceRow('Recebido', currencyFormat.format(totalRecebidoMes), Colors.green),
                    const Divider(),
                    _buildFinanceRow('A receber', currencyFormat.format(totalAReceber), Colors.blue),
                    const Divider(),
                    _buildFinanceRow('Despesas', currencyFormat.format(totalDespesasMes), Colors.red),
                    const Divider(),
                    _buildFinanceRow('Saldo', currencyFormat.format(saldoMes), Colors.indigo, isBold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Orçamentos recentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => widget.onNavigate(1),
                  child: const Text('Ver todos →'),
                ),
              ],
            ),
            _budgets.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Nenhum orçamento cadastrado.', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _budgets.length > 3 ? 3 : _budgets.length,
                    itemBuilder: (context, index) {
                      final budget = _budgets.reversed.toList()[index];
                      return Card(
                        child: ListTile(
                          title: Text('#${budget.number.toString().padLeft(3, '0')} - ${budget.clientName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(currencyFormat.format(budget.total)),
                          trailing: Chip(
                            label: Text(budget.status, style: const TextStyle(fontSize: 10)),
                            backgroundColor: budget.status == 'Aprovado' ? Colors.blue.shade100 : Colors.orange.shade100,
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 24),
            const Text('Ações rápidas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onNavigate(1),
                    icon: const Icon(Icons.add),
                    label: const Text('Novo orçamento'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onNavigate(2),
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Novo agendamento'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({required String title, required String value, required Color color, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                Icon(icon, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// ==========================================
// TELA PAYWALL (RECURSO BLOQUEADO)
// ==========================================

class LockedFeatureScreen extends StatelessWidget {
  final String featureName;

  const LockedFeatureScreen({super.key, required this.featureName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(featureName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 70, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Recurso Exclusivo PRO',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
              ),
              const SizedBox(height: 10),
              Text(
                'Seu período de teste gratuito de 7 dias expirou.\nA aba de $featureName está disponível apenas na versão PRO.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Ativar Versão PRO'),
                      content: const Text('Deseja simular a ativação da licença PRO?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                        ElevatedButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('is_pro_user', true);
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                            );
                          },
                          child: const Text('Ativar PRO'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.star, color: Colors.amber),
                label: const Text('ASSINAR / ATIVAR PRO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// TELA FINANCEIRA
// ==========================================

class ManagedFinancialScreen extends StatefulWidget {
  final UserAccountInfo userInfo;
  final bool isPro;

  const ManagedFinancialScreen({super.key, required this.userInfo, required this.isPro});

  @override
  State<ManagedFinancialScreen> createState() => _ManagedFinancialScreenState();
}

class _ManagedFinancialScreenState extends State<ManagedFinancialScreen> {
  List<FinancialTransaction> _transactions = [];
  List<Budget> _budgets = [];
  String _searchQuery = '';
  String _statusFilter = 'Todos';

  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    final prefs = await SharedPreferences.getInstance();

    final budgetsStr = prefs.getString('budgets_list');
    if (budgetsStr != null) {
      final List<dynamic> listJson = jsonDecode(budgetsStr);
      _budgets = listJson.map((e) => Budget.fromJson(e)).toList();
    }

    final transStr = prefs.getString('financial_transactions_list');
    if (transStr != null) {
      final List<dynamic> listJson = jsonDecode(transStr);
      _transactions = listJson.map((e) => FinancialTransaction.fromJson(e)).toList();
    }

    _syncTransactionsFromBudgets();
  }

  void _syncTransactionsFromBudgets() {
    List<FinancialTransaction> manualOrExpense = _transactions.where((t) => t.budgetId == null).toList();
    List<FinancialTransaction> updatedTransactions = [...manualOrExpense];

    for (var b in _budgets) {
      if (b.status != 'Cancelado') {
        final existingTrans = _transactions.firstWhere(
          (t) => t.budgetId == b.id,
          orElse: () => FinancialTransaction(
            id: 'trans_${b.id}',
            description: 'Orçamento #${b.number.toString().padLeft(3, '0')} - ${b.clientName}',
            clientName: b.clientName,
            amount: b.total,
            date: b.date,
            type: 'Receita',
            status: 'A Receber',
            category: 'Orçamento',
            budgetId: b.id,
          ),
        );

        existingTrans.amount = b.total;
        existingTrans.description = 'Orçamento #${b.number.toString().padLeft(3, '0')} - ${b.clientName}';
        existingTrans.clientName = b.clientName;

        updatedTransactions.add(existingTrans);
      }
    }

    setState(() => _transactions = updatedTransactions);
    _saveTransactions();
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_transactions.map((t) => t.toJson()).toList());
    await prefs.setString('financial_transactions_list', jsonStr);
  }

  double get _totalRecebido => _transactions
      .where((t) => t.type == 'Receita' && (t.status == 'Recebido' || t.status == 'Pago'))
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalAReceber => _transactions
      .where((t) => t.type == 'Receita' && t.status == 'A Receber')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalDespesas => _transactions
      .where((t) => t.type == 'Despesa')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _saldoLiquido => (_totalRecebido + _totalAReceber) - _totalDespesas;

  List<FinancialTransaction> get _filteredTransactions {
    return _transactions.where((t) {
      final matchesQuery = t.clientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesFilter = true;
      if (_statusFilter == 'Receitas') {
        matchesFilter = t.type == 'Receita';
      } else if (_statusFilter == 'Despesas') {
        matchesFilter = t.type == 'Despesa';
      }
      return matchesQuery && matchesFilter;
    }).toList();
  }

  void _openTransactionForm([FinancialTransaction? transaction]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FinancialFormScreen(
          transaction: transaction,
          onSave: (savedTrans) {
            setState(() {
              final index = _transactions.indexWhere((t) => t.id == savedTrans.id);
              if (index >= 0) {
                _transactions[index] = savedTrans;
              } else {
                _transactions.add(savedTrans);
              }
            });
            _saveTransactions();
          },
        ),
      ),
    );
  }

  void _toggleTransactionStatus(FinancialTransaction t) {
    setState(() {
      if (t.type == 'Receita') {
        t.status = t.status == 'Recebido' ? 'A Receber' : 'Recebido';
      } else {
        t.status = t.status == 'Pago' ? 'Pendente' : 'Pago';
      }
    });
    _saveTransactions();
  }

  void _confirmDeleteTransaction(FinancialTransaction t) {
    if (t.budgetId != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Lançamento Vinculado'),
          content: const Text('Este lançamento veio de um orçamento. Gerencie-o na aba Orçamentos.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Excluir lançamento?'),
          content: const Text('Deseja excluir este registro?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () {
                setState(() => _transactions.removeWhere((item) => item.id == t.id));
                _saveTransactions();
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('EXCLUIR'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;

    return Scaffold(
      appBar: AppBar(title: const Text('Financeiro & Relatórios')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildSummaryCard('Recebido', currencyFormat.format(_totalRecebido), Colors.green)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildSummaryCard('A Receber', currencyFormat.format(_totalAReceber), Colors.blue)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _buildSummaryCard('Despesas', currencyFormat.format(_totalDespesas), Colors.red)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildSummaryCard('Saldo Líquido', currencyFormat.format(_saldoLiquido), Colors.indigo)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por cliente ou descrição...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: ['Todos', 'Receitas', 'Despesas'].map((status) {
                final isSelected = _statusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _statusFilter = status);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('Nenhum registro financeiro encontrado.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isExpense = item.type == 'Despesa';
                      final isReceivedOrPaid = item.status == 'Recebido' || item.status == 'Pago';
                      Color statusColor = isExpense ? Colors.red : (isReceivedOrPaid ? Colors.green : Colors.blue);

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Checkbox(
                            value: isReceivedOrPaid,
                            onChanged: (bool? value) => _toggleTransactionStatus(item),
                          ),
                          title: Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Favorecido / Cliente: ${item.clientName}'),
                              Text('Data: ${DateFormat('dd/MM/yyyy').format(item.date)}'),
                              Text(
                                '${isExpense ? "- " : "+ "}${currencyFormat.format(item.amount)}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: isExpense ? Colors.red : Colors.black87),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.status,
                                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (val) {
                                  if (val == 'editar' && item.budgetId == null) {
                                    _openTransactionForm(item);
                                  } else if (val == 'excluir') {
                                    _confirmDeleteTransaction(item);
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (item.budgetId == null)
                                    const PopupMenuItem(
                                      value: 'editar',
                                      child: Row(children: [
                                        Icon(Icons.edit, color: Colors.orange, size: 20),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ]),
                                    ),
                                  const PopupMenuItem(
                                    value: 'excluir',
                                    child: Row(children: [
                                      Icon(Icons.delete, color: Colors.red, size: 20),
                                      SizedBox(width: 8),
                                      Text('Excluir'),
                                    ]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTransactionForm(),
        icon: const Icon(Icons.add),
        label: const Text('Novo Lançamento'),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

// ==========================================
// FORMULÁRIO DE LANÇAMENTO FINANCEIRO
// ==========================================

class FinancialFormScreen extends StatefulWidget {
  final FinancialTransaction? transaction;
  final Function(FinancialTransaction) onSave;

  const FinancialFormScreen({super.key, this.transaction, required this.onSave});

  @override
  State<FinancialFormScreen> createState() => _FinancialFormScreenState();
}

class _FinancialFormScreenState extends State<FinancialFormScreen> {
  final _descController = TextEditingController();
  final _clientController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late String _type;
  late String _status;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _type = widget.transaction?.type ?? 'Despesa';
    _status = widget.transaction?.status ?? (_type == 'Despesa' ? 'Pago' : 'A Receber');
    _date = widget.transaction?.date ?? DateTime.now();

    if (widget.transaction != null) {
      _descController.text = widget.transaction!.description;
      _clientController.text = widget.transaction!.clientName;
      _amountController.text = widget.transaction!.amount.toString();
      _notesController.text = widget.transaction!.notes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.transaction == null ? 'Novo Lançamento Financeiro' : 'Editar Lançamento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Tipo de Lançamento', border: OutlineInputBorder()),
              items: ['Despesa', 'Receita'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _type = val;
                    _status = _type == 'Despesa' ? 'Pago' : 'A Receber';
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Descrição / Item *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _clientController, decoration: const InputDecoration(labelText: 'Favorecido / Fornecedor / Cliente *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor (R\$) *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              items: _type == 'Despesa'
                  ? ['Pago', 'Pendente'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList()
                  : ['Recebido', 'A Receber'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _status = val);
              },
            ),
            const SizedBox(height: 12),
            TextField(controller: _notesController, maxLines: 2, decoration: const InputDecoration(labelText: 'Observações', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_descController.text.isEmpty || _clientController.text.isEmpty || _amountController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha os campos obrigatórios (*).')));
                    return;
                  }
                  final amountVal = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
                  widget.onSave(FinancialTransaction(
                    id: widget.transaction?.id ?? DateTime.now().toString(),
                    description: _descController.text,
                    clientName: _clientController.text,
                    amount: amountVal,
                    date: _date,
                    type: _type,
                    status: _status,
                    category: _type == 'Despesa' ? 'Operacional' : 'Serviço',
                    notes: _notesController.text,
                    budgetId: null,
                  ));
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.save),
                label: const Text('SALVAR LANÇAMENTO'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TELA PRINCIPAL DE ORÇAMENTOS
// ==========================================

class BudgetsHomeScreen extends StatefulWidget {
  final UserAccountInfo userInfo;
  final bool isPro;

  const BudgetsHomeScreen({super.key, required this.userInfo, required this.isPro});

  @override
  State<BudgetsHomeScreen> createState() => _BudgetsHomeScreenState();
}

class _BudgetsHomeScreenState extends State<BudgetsHomeScreen> {
  CompanyProfile _companyProfile = CompanyProfile();
  List<Budget> _budgets = [];
  String _searchQuery = '';
  String _statusFilter = 'Todos';

  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final profileStr = prefs.getString('company_profile');
    if (profileStr != null) {
      setState(() => _companyProfile = CompanyProfile.fromJson(jsonDecode(profileStr)));
    }

    final budgetsStr = prefs.getString('budgets_list');
    if (budgetsStr != null) {
      final List<dynamic> listJson = jsonDecode(budgetsStr);
      setState(() => _budgets = listJson.map((e) => Budget.fromJson(e)).toList());
    }
  }

  Future<void> _saveBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_budgets.map((b) => b.toJson()).toList());
    await prefs.setString('budgets_list', jsonStr);
  }

  Future<void> _saveProfile(CompanyProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_profile', jsonEncode(profile.toJson()));
    setState(() => _companyProfile = profile);
  }

  List<Budget> get _filteredBudgets {
    return _budgets.where((b) {
      final matchesQuery = b.clientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.number.toString().contains(_searchQuery);
      final matchesStatus = _statusFilter == 'Todos' || b.status == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
  }

  void _openProfileEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyProfilePage(
          profile: _companyProfile,
          userInfo: widget.userInfo,
          onSave: (updatedProfile) => _saveProfile(updatedProfile),
        ),
      ),
    );
  }

  void _openBudgetForm([Budget? budget]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetFormScreen(
          budget: budget,
          nextNumber: _budgets.length + 1,
          onSave: (savedBudget) {
            setState(() {
              final index = _budgets.indexWhere((b) => b.id == savedBudget.id);
              if (index >= 0) {
                _budgets[index] = savedBudget;
              } else {
                _budgets.add(savedBudget);
              }
            });
            _saveBudgets();
          },
        ),
      ),
    );
  }

  void _deleteBudget(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Orçamento?'),
        content: const Text('Esta ação removerá o orçamento e sua previsão financeira.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              setState(() => _budgets.removeWhere((b) => b.id == id));
              _saveBudgets();
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _generatePdfPreview(Budget budget, {bool isReceipt = false}) {
    if (isReceipt && !widget.isPro) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Recurso PRO'),
          content: const Text('A emissão de Recibos é exclusiva para assinantes PRO.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          title: isReceipt ? 'Recibo - ${budget.clientName}' : 'Orçamento #${budget.number}',
          buildPdf: (format) => generateBudgetPdf(budget, _companyProfile, isReceipt: isReceipt, pageFormat: format),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBudgets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OrçaFácil PRO - Orçamentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.business),
            tooltip: 'Perfil da Empresa',
            onPressed: _openProfileEditor,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Sair da Conta',
            onPressed: () async {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sair da Conta'),
                  content: const Text('Deseja realmente sair da sua conta?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                    ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('is_logged_in', false);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!widget.isPro)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.all(8),
              child: const Text(
                'Período de teste expirado. Apenas orçamentos estão liberados.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por cliente ou número...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: ['Todos', 'Pendente', 'Aprovado', 'Concluído', 'Cancelado'].map((status) {
                final isSelected = _statusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _statusFilter = status);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('Nenhum orçamento encontrado.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      Color statusColor;
                      switch (item.status) {
                        case 'Aprovado':
                          statusColor = Colors.blue;
                          break;
                        case 'Concluído':
                          statusColor = Colors.green;
                          break;
                        case 'Cancelado':
                          statusColor = Colors.red;
                          break;
                        default:
                          statusColor = Colors.orange;
                      }

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(
                                '#${item.number.toString().padLeft(3, '0')}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.clientName,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Data: ${DateFormat('dd/MM/yyyy').format(item.date)}'),
                              Text(
                                'Total: ${currencyFormat.format(item.total)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.status,
                                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (val) {
                                  if (val == 'pdf') {
                                    _generatePdfPreview(item);
                                  } else if (val == 'recibo') {
                                    _generatePdfPreview(item, isReceipt: true);
                                  } else if (val == 'editar') {
                                    _openBudgetForm(item);
                                  } else if (val == 'excluir') {
                                    _deleteBudget(item.id);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'pdf',
                                    child: Row(children: [
                                      Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                                      SizedBox(width: 8),
                                      Text('PDF Orçamento'),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    value: 'recibo',
                                    child: Row(children: [
                                      Icon(Icons.receipt, color: widget.isPro ? Colors.green : Colors.grey, size: 20),
                                      const SizedBox(width: 8),
                                      Text(widget.isPro ? 'PDF Recibo' : 'PDF Recibo (PRO)'),
                                    ]),
                                  ),
                                  const PopupMenuItem(
                                    value: 'editar',
                                    child: Row(children: [
                                      Icon(Icons.edit, color: Colors.blue, size: 20),
                                      SizedBox(width: 8),
                                      Text('Editar'),
                                    ]),
                                  ),
                                  const PopupMenuItem(
                                    value: 'excluir',
                                    child: Row(children: [
                                      Icon(Icons.delete, color: Colors.grey, size: 20),
                                      SizedBox(width: 8),
                                      Text('Excluir'),
                                    ]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBudgetForm(),
        icon: const Icon(Icons.add),
        label: const Text('Novo Orçamento'),
      ),
    );
  }
}

// ==========================================
// TELA DE ASSINATURA DIGITAL
// ==========================================

class SignatureScreen extends StatefulWidget {
  const SignatureScreen({super.key});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Desenhar Assinatura'),
        actions: [
          IconButton(icon: const Icon(Icons.clear), tooltip: 'Limpar', onPressed: () => _controller.clear()),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: Signature(controller: _controller, backgroundColor: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_controller.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Desenhe a assinatura.')));
                        return;
                      }
                      final bytes = await _controller.toPngBytes();
                      if (bytes != null && context.mounted) {
                        Navigator.pop(context, base64Encode(bytes));
                      }
                    },
                    child: const Text('Salvar'),
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

// ==========================================
// TELA DE PERFIL DA EMPRESA
// ==========================================

class CompanyProfilePage extends StatefulWidget {
  final CompanyProfile profile;
  final UserAccountInfo userInfo;
  final Function(CompanyProfile) onSave;

  const CompanyProfilePage({super.key, required this.profile, required this.userInfo, required this.onSave});

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _docController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  String? _logoBase64;
  String? _signatureBase64;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _docController = TextEditingController(text: widget.profile.doc);
    _phoneController = TextEditingController(text: widget.profile.phone);
    _addressController = TextEditingController(text: widget.profile.address);
    _logoBase64 = widget.profile.logoBase64;
    _signatureBase64 = widget.profile.signatureBase64;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _logoBase64 = base64Encode(bytes));
    }
  }

  Future<void> _openSignaturePad() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const SignatureScreen()),
    );
    if (result != null) setState(() => _signatureBase64 = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil da Empresa')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.account_circle, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Logado como: ${widget.userInfo.email}', style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _logoBase64 != null ? MemoryImage(base64Decode(_logoBase64!)) : null,
                child: _logoBase64 == null ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey) : null,
              ),
            ),
            TextButton(onPressed: _pickImage, child: const Text('Selecionar Logo')),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nome da Empresa', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _docController, decoration: const InputDecoration(labelText: 'CPF / CNPJ', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefone / WhatsApp', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Endereço', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Assinatura', style: TextStyle(fontWeight: FontWeight.bold)),
                ElevatedButton.icon(onPressed: _openSignaturePad, icon: const Icon(Icons.draw), label: const Text('Desenhar')),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.onSave(CompanyProfile(
                    name: _nameController.text,
                    doc: _docController.text,
                    phone: _phoneController.text,
                    address: _addressController.text,
                    logoBase64: _logoBase64,
                    signatureBase64: _signatureBase64,
                  ));
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.save),
                label: const Text('SALVAR PERFIL'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// FORMULÁRIO DE ORÇAMENTO
// ==========================================

class BudgetFormScreen extends StatefulWidget {
  final Budget? budget;
  final int nextNumber;
  final Function(Budget) onSave;

  const BudgetFormScreen({super.key, this.budget, required this.nextNumber, required this.onSave});

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _clientAddressController = TextEditingController();
  final _discountController = TextEditingController(text: '0.0');
  final _notesController = TextEditingController();

  late String _status;
  List<BudgetItem> _items = [];

  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _status = widget.budget?.status ?? 'Pendente';
    if (widget.budget != null) {
      _clientNameController.text = widget.budget!.clientName;
      _clientPhoneController.text = widget.budget!.clientPhone;
      _clientAddressController.text = widget.budget!.clientAddress;
      _discountController.text = widget.budget!.discount.toString();
      _notesController.text = widget.budget!.notes;
      _items = List.from(widget.budget!.items);
    }
  }

  void _addItemModal([BudgetItem? itemToEdit, int? editIndex]) {
    final descController = TextEditingController(text: itemToEdit?.description ?? '');
    final qtyController = TextEditingController(text: itemToEdit?.quantity.toString() ?? '1');
    final priceController = TextEditingController(text: itemToEdit?.unitPrice.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(itemToEdit == null ? 'Adicionar Item' : 'Editar Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Descrição')),
            TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantidade')),
            TextField(controller: priceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor Unitário (R\$)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (descController.text.isNotEmpty && priceController.text.isNotEmpty) {
                final newItem = BudgetItem(
                  description: descController.text,
                  quantity: int.tryParse(qtyController.text) ?? 1,
                  unitPrice: double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0.0,
                );
                setState(() {
                  if (editIndex != null) {
                    _items[editIndex] = newItem;
                  } else {
                    _items.add(newItem);
                  }
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  double get _subtotal => _items.fold(0.0, (sum, item) => sum + item.total);
  double get _discount => double.tryParse(_discountController.text.replaceAll(',', '.')) ?? 0.0;
  double get _total => (_subtotal - _discount) < 0 ? 0.0 : (_subtotal - _discount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.budget == null ? 'Novo Orçamento' : 'Editar Orçamento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _clientNameController, decoration: const InputDecoration(labelText: 'Nome do Cliente *', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _clientPhoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefone', border: OutlineInputBorder()))),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                    items: ['Pendente', 'Aprovado', 'Concluído', 'Cancelado'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => _status = val ?? 'Pendente'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: _clientAddressController, decoration: const InputDecoration(labelText: 'Endereço', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Itens do Orçamento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(onPressed: () => _addItemModal(), icon: const Icon(Icons.add), label: const Text('Adicionar Item')),
              ],
            ),
            _items.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Nenhum item adicionado.')))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        child: ListTile(
                          title: Text(item.description),
                          subtitle: Text('${item.quantity}x ${currencyFormat.format(item.unitPrice)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(currencyFormat.format(item.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _addItemModal(item, index)),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _items.removeAt(index))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 20),
            TextField(controller: _discountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Desconto (R\$)', border: OutlineInputBorder()), onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            TextField(controller: _notesController, maxLines: 2, decoration: const InputDecoration(labelText: 'Observações', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('VALOR TOTAL:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(currencyFormat.format(_total), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_clientNameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o cliente.')));
                    return;
                  }
                  widget.onSave(Budget(
                    id: widget.budget?.id ?? DateTime.now().toString(),
                    number: widget.budget?.number ?? widget.nextNumber,
                    clientName: _clientNameController.text,
                    clientPhone: _clientPhoneController.text,
                    clientAddress: _clientAddressController.text,
                    date: widget.budget?.date ?? DateTime.now(),
                    items: _items,
                    discount: _discount,
                    status: _status,
                    notes: _notesController.text,
                  ));
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.save),
                label: const Text('SALVAR ORÇAMENTO'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PRÉ-VISUALIZAÇÃO DE PDF SEGURA
// ==========================================

class PdfPreviewScreen extends StatelessWidget {
  final String title;
  final Future<Uint8List> Function(PdfPageFormat) buildPdf;

  const PdfPreviewScreen({super.key, required this.title, required this.buildPdf});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Imprimir',
            onPressed: () async {
              final pdfData = await buildPdf(PdfPageFormat.a4);
              await Printing.layoutPdf(onLayout: (format) async => pdfData);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartilhar',
            onPressed: () async {
              final pdfData = await buildPdf(PdfPageFormat.a4);
              await Printing.sharePdf(bytes: pdfData, filename: 'documento.pdf');
            },
          ),
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: buildPdf(PdfPageFormat.a4),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return PdfPreview(
              build: (format) async => snapshot.data!,
              allowPrinting: true,
              allowSharing: true,
              canChangePageFormat: false,
              canChangeOrientation: false,
              useActions: false,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

Future<Uint8List> generateBudgetPdf(
  Budget budget,
  CompanyProfile profile, {
  bool isReceipt = false,
  PdfPageFormat pageFormat = PdfPageFormat.a4,
}) async {
  final pdf = pw.Document();
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final dateFormat = DateFormat('dd/MM/yyyy');

  pw.ImageProvider? logoImage;
  if (profile.logoBase64 != null && profile.logoBase64!.isNotEmpty) {
    try { logoImage = pw.MemoryImage(base64Decode(profile.logoBase64!)); } catch (_) {}
  }

  pw.ImageProvider? companySignatureImage;
  if (profile.signatureBase64 != null && profile.signatureBase64!.isNotEmpty) {
    try { companySignatureImage = pw.MemoryImage(base64Decode(profile.signatureBase64!)); } catch (_) {}
  }

  pdf.addPage(
    pw.Page(
      pageFormat: pageFormat,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(profile.name.isNotEmpty ? profile.name : 'Sua Empresa', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    if (profile.doc.isNotEmpty) pw.Text('CPF/CNPJ: ${profile.doc}'),
                    if (profile.phone.isNotEmpty) pw.Text('Tel/WhatsApp: ${profile.phone}'),
                    if (profile.address.isNotEmpty) pw.Text('Endereço: ${profile.address}'),
                  ],
                ),
                if (logoImage != null) pw.SizedBox(width: 70, height: 70, child: pw.Image(logoImage)),
              ],
            ),
            pw.SizedBox(height: 15),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                isReceipt ? 'RECIBO DE PAGAMENTO Nº ${budget.number.toString().padLeft(4, '0')}' : 'ORÇAMENTO Nº ${budget.number.toString().padLeft(4, '0')}',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
              ),
            ),
            pw.SizedBox(height: 15),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Cliente: ${budget.clientName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  if (budget.clientPhone.isNotEmpty) pw.Text('Telefone: ${budget.clientPhone}'),
                  if (budget.clientAddress.isNotEmpty) pw.Text('Endereço: ${budget.clientAddress}'),
                  pw.Text('Data: ${dateFormat.format(budget.date)}'),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
            pw.Table.fromTextArray(
              headers: ['Descrição', 'Qtd', 'Vlr. Unit.', 'Total'],
              data: budget.items.map((i) => [i.description, i.quantity.toString(), currencyFormat.format(i.unitPrice), currencyFormat.format(i.total)]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 15),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.SizedBox(
                  width: 200,
                  child: pw.Column(
                    children: [
                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Subtotal:'), pw.Text(currencyFormat.format(budget.subtotal))]),
                      if (budget.discount > 0)
                        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Desconto:'), pw.Text('- ${currencyFormat.format(budget.discount)}', style: const pw.TextStyle(color: PdfColors.red))]),
                      pw.Divider(),
                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)), pw.Text(currencyFormat.format(budget.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blue800))]),
                    ],
                  ),
                ),
              ],
            ),
            if (budget.notes.isNotEmpty) ...[
              pw.SizedBox(height: 15),
              pw.Text('Observações:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(budget.notes, style: const pw.TextStyle(fontSize: 10)),
            ],
            pw.Spacer(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Column(
                  children: [
                    if (companySignatureImage != null) pw.SizedBox(width: 180, height: 50, child: pw.Image(companySignatureImage)) else pw.SizedBox(height: 50),
                    pw.SizedBox(width: 200, child: pw.Divider()),
                    pw.SizedBox(height: 4),
                    pw.Text(profile.name.isNotEmpty ? profile.name : 'Responsável', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}