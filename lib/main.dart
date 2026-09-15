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
import 'screens/financial_screen.dart';

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
  String status;
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

// ==========================================
// TELA DE BOAS-VINDAS & LOGIN OBRIGATÓRIO (SIMPLIFICADO)
// ==========================================

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;

  // GoogleSignIn limpo e sem parâmetros para evitar o erro 401: invalid_client
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final account = await _googleSignIn.signIn();
      if (account != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigationScreen(googleAccount: account),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no login com Google: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 90,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.request_quote,
                    size: 90,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'OrçaFácil PRO',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Faça login com sua conta Google para gerenciar seus orçamentos com total segurança.',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton.icon(
                        onPressed: _handleGoogleLogin,
                        icon: const Icon(Icons.login, color: Colors.blue),
                        label: const Text(
                          'Entrar com Google',
                          style: TextStyle(
                              fontSize: 16, color: Colors.black87),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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

// ==========================================
// NAVEGAÇÃO PRINCIPAL & CONTROLE DE DIAS PRO
// ==========================================

class MainNavigationScreen extends StatefulWidget {
  final GoogleSignInAccount googleAccount;

  const MainNavigationScreen({super.key, required this.googleAccount});

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
        setState(() {
          _isPro = false;
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> screens = [
      BudgetsHomeScreen(googleAccount: widget.googleAccount, isPro: _isPro),
      _isPro ? const AgendaScreen() : const LockedFeatureScreen(featureName: 'Agenda'),
      _isPro ? const FinancialScreen() : const LockedFeatureScreen(featureName: 'Financeiro'),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.request_quote),
            label: 'Orçamentos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Financeiro',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TELA DE RECURSO BLOQUEADO (PAYWALL)
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
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Seu período de teste gratuito de 7 dias expirou.\nA aba de $featureName e a emissão de Recibos estão disponíveis apenas na versão PRO.',
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
                      content: const Text(
                          'Deseja simular a ativação da licença PRO para desbloquear todas as funções do OrçaFácil PRO?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('is_pro_user', true);
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WelcomeScreen(),
                              ),
                            );
                          },
                          child: const Text('Ativar PRO (Simular)'),
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
// TELA PRINCIPAL DE ORÇAMENTOS
// ==========================================

class BudgetsHomeScreen extends StatefulWidget {
  final GoogleSignInAccount googleAccount;
  final bool isPro;

  const BudgetsHomeScreen({
    super.key,
    required this.googleAccount,
    required this.isPro,
  });

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
      setState(() {
        _companyProfile = CompanyProfile.fromJson(jsonDecode(profileStr));
      });
    }

    final budgetsStr = prefs.getString('budgets_list');
    if (budgetsStr != null) {
      final List<dynamic> listJson = jsonDecode(budgetsStr);
      setState(() {
        _budgets = listJson.map((e) => Budget.fromJson(e)).toList();
      });
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
    setState(() {
      _companyProfile = profile;
    });
  }

  List<Budget> get _filteredBudgets {
    return _budgets.where((b) {
      final matchesQuery = b.clientName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          b.number.toString().contains(_searchQuery);
      final matchesStatus =
          _statusFilter == 'Todos' || b.status == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
  }

  void _openProfileEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyProfilePage(
          profile: _companyProfile,
          googleAccount: widget.googleAccount,
          onSave: (updatedProfile) {
            _saveProfile(updatedProfile);
          },
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
        content: const Text('Esta ação não poderá ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _budgets.removeWhere((b) => b.id == id);
              });
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
          content: const Text('A emissão de Recibos é exclusiva para assinantes PRO ou durante o período de teste de 7 dias.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          title: isReceipt
              ? 'Recibo - ${budget.clientName}'
              : 'Orçamento #${budget.number}',
          buildPdf: (format) => generateBudgetPdf(
            budget,
            _companyProfile,
            isReceipt: isReceipt,
            pageFormat: format,
          ),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: ['Todos', 'Pendente', 'Aprovado', 'Concluído', 'Cancelado']
                  .map((status) {
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
                        Icon(Icons.description_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Nenhum orçamento encontrado.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.clientName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                  'Data: ${DateFormat('dd/MM/yyyy').format(item.date)}'),
                              Text(
                                'Total: ${currencyFormat.format(item.total)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                    child: Row(
                                      children: [
                                        Icon(Icons.picture_as_pdf,
                                            color: Colors.red, size: 20),
                                        SizedBox(width: 8),
                                        Text('PDF Orçamento'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'recibo',
                                    child: Row(
                                      children: [
                                        Icon(Icons.receipt,
                                            color: widget.isPro ? Colors.green : Colors.grey, size: 20),
                                        const SizedBox(width: 8),
                                        Text(widget.isPro ? 'PDF Recibo' : 'PDF Recibo (PRO)'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'editar',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit,
                                            color: Colors.blue, size: 20),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'excluir',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete,
                                            color: Colors.grey, size: 20),
                                        SizedBox(width: 8),
                                        Text('Excluir'),
                                      ],
                                    ),
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
// TELA DE ASSINATURA DIGITAL (LOUSA)
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
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Limpar',
            onPressed: () => _controller.clear(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: Signature(
                controller: _controller,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_controller.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Por favor, faça a assinatura.')),
                        );
                        return;
                      }
                      final signatureBytes = await _controller.toPngBytes();
                      if (signatureBytes != null && context.mounted) {
                        Navigator.pop(context, base64Encode(signatureBytes));
                      }
                    },
                    child: const Text('Salvar Assinatura'),
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
  final GoogleSignInAccount googleAccount;
  final Function(CompanyProfile) onSave;

  const CompanyProfilePage({
    super.key,
    required this.profile,
    required this.googleAccount,
    required this.onSave,
  });

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
      setState(() {
        _logoBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _openSignaturePad() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const SignatureScreen()),
    );
    if (result != null) {
      setState(() {
        _signatureBase64 = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil da Empresa'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_circle, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Logado como: ${widget.googleAccount.email}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _logoBase64 != null
                    ? MemoryImage(base64Decode(_logoBase64!))
                    : null,
                child: _logoBase64 == null
                    ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _pickImage,
              child: const Text('Selecionar Logo da Empresa'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da Empresa / Profissional',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _docController,
              decoration: const InputDecoration(
                labelText: 'CPF / CNPJ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone / WhatsApp',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Endereço Completo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Assinatura Padrão (Profissional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _openSignaturePad,
                  icon: const Icon(Icons.draw),
                  label: Text(_signatureBase64 == null
                      ? 'Desenhar Assinatura'
                      : 'Alterar Assinatura'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_signatureBase64 != null)
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(_signatureBase64!),
                    fit: BoxFit.contain,
                  ),
                ),
              )
            else
              const Text(
                'Nenhuma assinatura do profissional cadastrada.',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  final updated = CompanyProfile(
                    name: _nameController.text,
                    doc: _docController.text,
                    phone: _phoneController.text,
                    address: _addressController.text,
                    logoBase64: _logoBase64,
                    signatureBase64: _signatureBase64,
                  );
                  widget.onSave(updated);
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
// FORMULÁRIO DE CRIAR / EDITAR ORÇAMENTO
// ==========================================

class BudgetFormScreen extends StatefulWidget {
  final Budget? budget;
  final int nextNumber;
  final Function(Budget) onSave;

  const BudgetFormScreen({
    super.key,
    this.budget,
    required this.nextNumber,
    required this.onSave,
  });

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

  void _addItemModal() {
    final descController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar Item / Serviço'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantidade'),
            ),
            TextField(
              controller: priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Valor Unitário (R\$)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (descController.text.isNotEmpty &&
                  priceController.text.isNotEmpty) {
                setState(() {
                  _items.add(
                    BudgetItem(
                      description: descController.text,
                      quantity: int.tryParse(qtyController.text) ?? 1,
                      unitPrice: double.tryParse(
                            priceController.text.replaceAll(',', '.')) ??
                          0.0,
                    ),
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  double get _subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.total);
  double get _discount =>
      double.tryParse(_discountController.text.replaceAll(',', '.')) ?? 0.0;
  double get _total => (_subtotal - _discount) < 0 ? 0.0 : (_subtotal - _discount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budget == null ? 'Novo Orçamento' : 'Editar Orçamento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _clientNameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Cliente *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _clientPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Pendente', 'Aprovado', 'Concluído', 'Cancelado']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _status = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _clientAddressController,
              decoration: const InputDecoration(
                labelText: 'Endereço do Cliente',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Itens do Orçamento',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _addItemModal,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar Item'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _items.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Nenhum item adicionado.'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        child: ListTile(
                          title: Text(item.description),
                          subtitle: Text(
                              '${item.quantity}x ${currencyFormat.format(item.unitPrice)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currencyFormat.format(item.total),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _items.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 20),
            TextField(
              controller: _discountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Desconto Total (R\$)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observações / Condições de Pagamento',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'VALOR TOTAL:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    currencyFormat.format(_total),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Informe o nome do cliente.')),
                    );
                    return;
                  }

                  final budgetToSave = Budget(
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
                  );

                  widget.onSave(budgetToSave);
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
// TELA DE PRÉ-VISUALIZAÇÃO DE PDF
// ==========================================

class PdfPreviewScreen extends StatelessWidget {
  final String title;
  final Future<Uint8List> Function(PdfPageFormat) buildPdf;

  const PdfPreviewScreen({
    super.key,
    required this.title,
    required this.buildPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: PdfPreview(
        build: buildPdf,
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
      ),
    );
  }
}

// ==========================================
// GERADOR DE DOCUMENTO PDF COM ASSINATURA DA EMPRESA
// ==========================================

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
    try {
      final bytes = base64Decode(profile.logoBase64!);
      logoImage = pw.MemoryImage(bytes);
    } catch (_) {}
  }

  pw.ImageProvider? companySignatureImage;
  if (profile.signatureBase64 != null && profile.signatureBase64!.isNotEmpty) {
    try {
      final bytes = base64Decode(profile.signatureBase64!);
      companySignatureImage = pw.MemoryImage(bytes);
    } catch (_) {}
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
                    pw.Text(
                      profile.name.isNotEmpty ? profile.name : 'Sua Empresa',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (profile.doc.isNotEmpty)
                      pw.Text('CPF/CNPJ: ${profile.doc}'),
                    if (profile.phone.isNotEmpty)
                      pw.Text('Tel/WhatsApp: ${profile.phone}'),
                    if (profile.address.isNotEmpty)
                      pw.Text('Endereço: ${profile.address}'),
                  ],
                ),
                if (logoImage != null)
                  pw.SizedBox(
                    width: 70,
                    height: 70,
                    child: pw.Image(logoImage),
                  ),
              ],
            ),
            pw.SizedBox(height: 15),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                isReceipt
                    ? 'RECIBO DE PAGAMENTO Nº ${budget.number.toString().padLeft(4, '0')}'
                    : 'ORÇAMENTO Nº ${budget.number.toString().padLeft(4, '0')}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
            ),
            pw.SizedBox(height: 15),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Cliente: ${budget.clientName}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  if (budget.clientPhone.isNotEmpty)
                    pw.Text('Telefone: ${budget.clientPhone}'),
                  if (budget.clientAddress.isNotEmpty)
                    pw.Text('Endereço: ${budget.clientAddress}'),
                  pw.Text('Data: ${dateFormat.format(budget.date)}'),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
            pw.Table.fromTextArray(
              headers: ['Descrição', 'Qtd', 'Vlr. Unit.', 'Total'],
              data: budget.items
                  .map((item) => [
                        item.description,
                        item.quantity.toString(),
                        currencyFormat.format(item.unitPrice),
                        currencyFormat.format(item.total),
                      ])
                  .toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blue800),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
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
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Subtotal:'),
                          pw.Text(currencyFormat.format(budget.subtotal)),
                        ],
                      ),
                      if (budget.discount > 0)
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Desconto:'),
                            pw.Text(
                              '- ${currencyFormat.format(budget.discount)}',
                              style: const pw.TextStyle(color: PdfColors.red),
                            ),
                          ],
                        ),
                      pw.Divider(),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('TOTAL:',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 14)),
                          pw.Text(
                            currencyFormat.format(budget.total),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14,
                              color: PdfColors.blue800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (budget.notes.isNotEmpty) ...[
              pw.SizedBox(height: 15),
              pw.Text('Observações / Condições:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(budget.notes, style: const pw.TextStyle(fontSize: 10)),
            ],
            pw.Spacer(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Column(
                  children: [
                    if (companySignatureImage != null)
                      pw.SizedBox(
                        width: 180,
                        height: 50,
                        child: pw.Image(companySignatureImage),
                      )
                    else
                      pw.SizedBox(height: 50),
                    pw.SizedBox(width: 200, child: pw.Divider()),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      profile.name.isNotEmpty
                          ? profile.name
                          : 'Assinatura do Responsável',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
          ],
        );
      },
    ),
  );

  return pdf.save();
}