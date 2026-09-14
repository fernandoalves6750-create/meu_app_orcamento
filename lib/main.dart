import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerador de Orçamentos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const SplashCheckScreen(),
    );
  }
}

// ==========================================
// TELA DE VERIFICAÇÃO INICIAL (SPLASH)
// ==========================================
class SplashCheckScreen extends StatefulWidget {
  const SplashCheckScreen({super.key});

  @override
  State<SplashCheckScreen> createState() => _SplashCheckScreenState();
}

class _SplashCheckScreenState extends State<SplashCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialFlow();
  }

  Future<void> _checkInitialFlow() async {
    final prefs = await SharedPreferences.getInstance();
    final String? segment = prefs.getString('company_segment');
    final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (!mounted) return;

    if (segment == null || segment.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SegmentSelectionPage()),
      );
    } else if (!isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// ==========================================
// TELA 1: SELEÇÃO DO SEGMENTO DA EMPRESA
// ==========================================
class SegmentSelectionPage extends StatefulWidget {
  const SegmentSelectionPage({super.key});

  @override
  State<SegmentSelectionPage> createState() => _SegmentSelectionPageState();
}

class _SegmentSelectionPageState extends State<SegmentSelectionPage> {
  String? _selectedSegment;

  final List<Map<String, dynamic>> _segments = const [
    {
      'title': 'Prestação de Serviços / Manutenção',
      'icon': Icons.build,
      'key': 'servicos'
    },
    {
      'title': 'Construção Civil & Reformas',
      'icon': Icons.home_repair_service,
      'key': 'construcao'
    },
    {
      'title': 'Comércio & Vendas',
      'icon': Icons.shopping_bag,
      'key': 'comercio'
    },
    {
      'title': 'Estética, Beleza & Saúde',
      'icon': Icons.content_cut,
      'key': 'estetica'
    },
    {
      'title': 'Tecnologia & Informática',
      'icon': Icons.computer,
      'key': 'tecnologia'
    },
    {
      'title': 'Outros Segmentos',
      'icon': Icons.category,
      'key': 'outros'
    },
  ];

  Future<void> _saveSegmentAndContinue() async {
    if (_selectedSegment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um segmento.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_segment', _selectedSegment!);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bem-vindo!')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Qual é o segmento do seu negócio?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Isso nos ajuda a personalizar o app e os orçamentos para você.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _segments.length,
                itemBuilder: (context, index) {
                  final item = _segments[index];
                  final isSelected = _selectedSegment == item['key'];

                  return Card(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: ListTile(
                      leading: Icon(item['icon'] as IconData),
                      title: Text(item['title'] as String),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.blue)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedSegment = item['key'] as String;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _saveSegmentAndContinue,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('CONTINUAR', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TELA 2: LOGIN COM GOOGLE & EMAIL
// ==========================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_email', account.email);
        await prefs.setString('user_name', account.displayName ?? '');

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const MainNavigationScreen()),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao fazer login: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_email', 'offline');

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.cloud_sync, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Conecte sua Conta',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Faça login com o Google para salvar seus orçamentos e backups diretamente no Google Drive.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              OutlinedButton.icon(
                onPressed: _handleGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.login, color: Colors.red),
                label: const Text(
                  'Entrar com Google (Backup no Drive)',
                  style: TextStyle(fontSize: 15),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _continueAsGuest,
                child: const Text('Continuar sem login (Apenas offline)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==========================================
// MODELOS DE DADOS
// ==========================================
class Product {
  final String id;
  final String name;
  final double price;

  Product({required this.id, required this.name, required this.price});
}

class OrderItem {
  final Product product;
  int quantity;

  OrderItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

// ==========================================
// TELA PRINCIPAL (NAVEGAÇÃO ABA)
// ==========================================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  String _companyName = '';
  String _companyDoc = '';
  String _companyPhone = '';
  String _companyAddress = '';
  String _userEmail = '';
  Uint8List? _companyLogoBytes;

  final List<Product> _products = [
    Product(id: '1', name: 'Serviço de Consultoria', price: 150.0),
    Product(id: '2', name: 'Manutenção de Equipamento', price: 250.0),
  ];

  @override
  void initState() {
    super.initState();
    _loadCompanyProfile();
  }

  Future<void> _loadCompanyProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _companyName = prefs.getString('company_name') ?? 'Minha Empresa Ltda';
      _companyDoc = prefs.getString('company_doc') ?? '00.000.000/0001-00';
      _companyPhone = prefs.getString('company_phone') ?? '(11) 99999-9999';
      _companyAddress =
          prefs.getString('company_address') ?? 'Rua Principal, 100';
      _userEmail = prefs.getString('user_email') ?? '';
    });
  }

  Future<void> _saveCompanyProfile(
    String name,
    String doc,
    String phone,
    String address,
    Uint8List? logoBytes,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_name', name);
    await prefs.setString('company_doc', doc);
    await prefs.setString('company_phone', phone);
    await prefs.setString('company_address', address);

    setState(() {
      _companyName = name;
      _companyDoc = doc;
      _companyPhone = phone;
      _companyAddress = address;
      if (logoBytes != null) {
        _companyLogoBytes = logoBytes;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil da empresa salvo com sucesso!')),
      );
    }
  }

  void _addProduct(Product product) {
    setState(() {
      _products.add(product);
    });
  }

  void _removeProduct(String id) {
    setState(() {
      _products.removeWhere((p) => p.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CreateQuotePage(
        products: _products,
        companyName: _companyName,
        companyDoc: _companyDoc,
        companyPhone: _companyPhone,
        companyAddress: _companyAddress,
        companyLogoBytes: _companyLogoBytes,
      ),
      ProductsPage(
        products: _products,
        onAddProduct: _addProduct,
        onRemoveProduct: _removeProduct,
      ),
      CompanyProfilePage(
        companyName: _companyName,
        companyDoc: _companyDoc,
        companyPhone: _companyPhone,
        companyAddress: _companyAddress,
        userEmail: _userEmail,
        companyLogoBytes: _companyLogoBytes,
        onSave: _saveCompanyProfile,
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Novo Orçamento',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Produtos',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business),
            label: 'Empresa',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// PÁGINA: CRIAR ORÇAMENTO / RECIBO & PDF
// ==========================================
class CreateQuotePage extends StatefulWidget {
  final List<Product> products;
  final String companyName;
  final String companyDoc;
  final String companyPhone;
  final String companyAddress;
  final Uint8List? companyLogoBytes;

  const CreateQuotePage({
    super.key,
    required this.products,
    required this.companyName,
    required this.companyDoc,
    required this.companyPhone,
    required this.companyAddress,
    this.companyLogoBytes,
  });

  @override
  State<CreateQuotePage> createState() => _CreateQuotePageState();
}

class _CreateQuotePageState extends State<CreateQuotePage> {
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final List<OrderItem> _selectedItems = [];

  double get _grandTotal =>
      _selectedItems.fold(0.0, (sum, item) => sum + item.total);

  void _addItem(Product product) {
    setState(() {
      final index =
          _selectedItems.indexWhere((i) => i.product.id == product.id);
      if (index >= 0) {
        _selectedItems[index].quantity++;
      } else {
        _selectedItems.add(OrderItem(product: product, quantity: 1));
      }
    });
  }

  void _generateAndShowPdf() async {
    if (_clientNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe o nome do cliente.')),
      );
      return;
    }

    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Adicione pelo menos um produto ao orçamento.')),
      );
      return;
    }

    final pdf = pw.Document();

    pw.ImageProvider? logoImage;
    if (widget.companyLogoBytes != null) {
      logoImage = pw.MemoryImage(widget.companyLogoBytes!);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        widget.companyName,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text('CNPJ/CPF: ${widget.companyDoc}'),
                      pw.Text('Telefone: ${widget.companyPhone}'),
                      pw.Text('Endereço: ${widget.companyAddress}'),
                    ],
                  ),
                  if (logoImage != null)
                    pw.SizedBox(
                      height: 60,
                      width: 60,
                      child: pw.Image(logoImage),
                    ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Text(
                'ORÇAMENTO / RECIBO',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Cliente: ${_clientNameController.text}'),
              if (_clientPhoneController.text.isNotEmpty)
                pw.Text('Telefone: ${_clientPhoneController.text}'),
              pw.Text(
                'Data: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              ),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: ['Item / Serviço', 'Qtd', 'Preço Unit.', 'Total'],
                data: _selectedItems.map((item) {
                  return [
                    item.product.name,
                    '${item.quantity}',
                    'R\$ ${item.product.price.toStringAsFixed(2)}',
                    'R\$ ${item.total.toStringAsFixed(2)}',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'TOTAL: R\$ ${_grandTotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  'Obrigado pela preferência!',
                  style: const pw.TextStyle(color: PdfColors.grey700),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Orcamento_${_clientNameController.text}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Orçamento / Recibo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dados do Cliente',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _clientNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Cliente',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _clientPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefone / WhatsApp',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Itens do Orçamento',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                PopupMenuButton<Product>(
                  icon: const Row(
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 4),
                      Text('Adicionar Item'),
                    ],
                  ),
                  onSelected: _addItem,
                  itemBuilder: (context) {
                    if (widget.products.isEmpty) {
                      return [
                        const PopupMenuItem(
                          enabled: false,
                          child: Text('Nenhum produto cadastrado'),
                        ),
                      ];
                    }
                    return widget.products.map((p) {
                      return PopupMenuItem(
                        value: p,
                        child: Text
                            ('${p.name} - R\$ ${p.price.toStringAsFixed(2)}'),
                      );
                    }).toList();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_selectedItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text('Nenhum produto adicionado ao orçamento.'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedItems.length,
                itemBuilder: (context, index) {
                  final item = _selectedItems[index];
                  return Card(
                    child: ListTile(
                      title: Text(item.product.name),
                      subtitle: Text(
                        'R\$ ${item.product.price.toStringAsFixed(2)} x ${item.quantity} = R\$ ${item.total.toStringAsFixed(2)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              setState(() {
                                if (item.quantity > 1) {
                                  item.quantity--;
                                } else {
                                  _selectedItems.removeAt(index);
                                }
                              });
                            },
                          ),
                          Text('${item.quantity}'),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              setState(() {
                                item.quantity++;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Valor Total:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'R\$ ${_grandTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateAndShowPdf,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text(
                'GERAR E IMPRIMIR PDF',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PÁGINA: GERENCIAMENTO DE PRODUTOS
// ==========================================
class ProductsPage extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onAddProduct;
  final Function(String) onRemoveProduct;

  const ProductsPage({
    super.key,
    required this.products,
    required this.onAddProduct,
    required this.onRemoveProduct,
  });

  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cadastrar Produto / Serviço'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome do Item'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Preço (R\$)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final price = double.tryParse(
                        priceController.text.replaceAll(',', '.')) ??
                    0.0;

                if (name.isNotEmpty && price > 0) {
                  onAddProduct(Product(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    price: price,
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Produtos / Serviços')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo Produto'),
      ),
      body: products.isEmpty
          ? const Center(child: Text('Nenhum produto cadastrado ainda.'))
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  title: Text(product.name),
                  subtitle: Text('R\$ ${product.price.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => onRemoveProduct(product.id),
                  ),
                );
              },
            ),
    );
  }
}

// ==========================================
// PÁGINA: PERFIL DA EMPRESA
// ==========================================
class CompanyProfilePage extends StatefulWidget {
  final String companyName;
  final String companyDoc;
  final String companyPhone;
  final String companyAddress;
  final String userEmail;
  final Uint8List? companyLogoBytes;
  final Function(String, String, String, String, Uint8List?) onSave;

  const CompanyProfilePage({
    super.key,
    required this.companyName,
    required this.companyDoc,
    required this.companyPhone,
    required this.companyAddress,
    required this.userEmail,
    this.companyLogoBytes,
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
  Uint8List? _logoBytes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.companyName);
    _docController = TextEditingController(text: widget.companyDoc);
    _phoneController = TextEditingController(text: widget.companyPhone);
    _addressController = TextEditingController(text: widget.companyAddress);
    _logoBytes = widget.companyLogoBytes;
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _logoBytes = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dados da Minha Empresa')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.userEmail.isNotEmpty)
              Chip(
                avatar: const Icon(Icons.account_circle),
                label: Text('Conectado como: ${widget.userEmail}'),
              ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickLogo,
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    _logoBytes != null ? MemoryImage(_logoBytes!) : null,
                child: _logoBytes == null
                    ? const Icon(Icons.add_a_photo,
                        size: 36, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('Clique para alterar a Logo')),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da Empresa / Razão Social',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _docController,
              decoration: const InputDecoration(
                labelText: 'CNPJ ou CPF',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                widget.onSave(
                  _nameController.text,
                  _docController.text,
                  _phoneController.text,
                  _addressController.text,
                  _logoBytes,
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.save),
              label: const Text('SALVAR PERFIL'),
            ),
          ],
        ),
      ),
    );
  }
}