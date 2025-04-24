import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/product.dart';
import '../widgets/product_form.dart';
import '../utils/receipt_pdf.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> _products = [];
  int _todayIncome = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadTodayIncome();
  }

  Future<void> _loadTodayIncome() async {
    final income = await DatabaseHelper().getTodayIncome();
    setState(() {
      _todayIncome = income;
    });
  }

  Future<void> _loadProducts() async {
    final products = await DatabaseHelper().getProducts();
    setState(() {
      _products = products;
    });
  }

  String formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  int _calculateTotal() {
    return _products.fold(0, (total, item) => total + item.quantity * item.price);
  }

  String getCurrentShift() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 6 && hour < 14) {
      return "Shift Pagi";
    } else if (hour >= 14 && hour < 22) {
      return "Shift Siang";
    } else {
      return "Shift Malam";
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _products.fold(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.teal[600],
        title: const Text("Mesin Kasir", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Laporan Pendapatan Hari Ini'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total: Rp ${formatRupiah(_todayIncome)}'),
                      const SizedBox(height: 20),
                      const Text('Apakah Anda ingin menghapus data pendapatan hari ini?'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await DatabaseHelper().clearTodayIncome();
                        await _loadTodayIncome();
                        Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Data pendapatan hari ini telah dihapus'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('Hapus Data', 
                        style: TextStyle(color: Colors.red)),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.teal[600],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Total Pendapatan Hari Ini:", 
                  style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text("Rp ${formatRupiah(_todayIncome)}",
                    style: const TextStyle(
                      fontSize: 26, 
                      color: Colors.white, 
                      fontWeight: FontWeight.bold
                    )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryBox(
                      Icons.shopping_cart, 
                      "Produk Terjual", 
                      "$totalItems"
                    ),
                    _summaryBox(
                      Icons.people,
                      "Mode Kasir",
                      getCurrentShift()
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _products.isEmpty
                ? const Center(child: Text("Belum ada produk"))
                : ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final item = _products[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12, 
                          vertical: 6
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.teal[100],
                                child: Text(item.name[0]),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Jumlah: ${item.quantity} barang',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Harga: Rp${formatRupiah(item.price)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Total: Rp${formatRupiah(item.quantity * item.price)}',
                                      style: const TextStyle(
                                        color: Colors.teal,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showForm(product: item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteProduct(item.id!),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal[50],
              border: Border(top: BorderSide(color: Colors.teal[100]!)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontSize: 18)),
                    Text(
                      'Rp${formatRupiah(_calculateTotal())}',
                      style: const TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _products.isEmpty || _isProcessing 
                      ? null 
                      : () async {
                          setState(() {
                            _isProcessing = true;
                          });
                          try {
                            final total = _calculateTotal();
                            await generateAndPrintReceipt(_products, total);
                            await DatabaseHelper().addDailyIncome(total);
                            await DatabaseHelper().clearAllProducts();
                            await _loadProducts();
                            await _loadTodayIncome();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("✅ Pembayaran berhasil"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("❌ Gagal memproses pembayaran: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isProcessing = false;
                              });
                            }
                          }
                        },
                  icon: _isProcessing 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.print),
                  label: Text(_isProcessing ? 'Memproses...' : 'Bayar & Cetak Struk'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _products.isEmpty || _isProcessing 
                        ? Colors.grey[300] 
                        : Colors.teal[400],
                    foregroundColor: _products.isEmpty || _isProcessing
                        ? Colors.grey[600]
                        : Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 130),
        child: FloatingActionButton(
          onPressed: () => _showForm(),
          backgroundColor: Colors.teal[400],
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Widget _summaryBox(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.teal[700]),
        const SizedBox(height: 6),
        Text(
          title, 
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)
        ),
        Text(
          value, 
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
        ),
      ],
    );
  }

  void _showForm({Product? product}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProductForm(
        product: product,
        onSubmit: (newProduct) async {
          if (product == null) {
            await DatabaseHelper().insertProduct(newProduct);
          } else {
            await DatabaseHelper().updateProduct(newProduct);
          }
          Navigator.pop(context);
          _loadProducts();
        },
      ),
    );
  }

  Future<void> _deleteProduct(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin menghapus produk ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper().deleteProduct(id);
      _loadProducts();
    }
  }
}