import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book_model.dart';
import '../providers/book_provider.dart';
import '../services/excel_import_service.dart';
import '../theme/app_colors.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookProv = context.watch<BookProvider>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Actions Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KITOB FOND KUTUBXONASI',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Jami ${bookProv.books.length} turdagi kitoblar ko\'rsatilmoqda',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
              Row(
                children: [
                  // Manage Genres CRUD button
                  OutlinedButton.icon(
                    onPressed: () => _showManageGenresDialog(context, bookProv),
                    icon: const Icon(Icons.category, size: 16, color: AppColors.goldPrimary),
                    label: const Text('Janrlarni Boshqarish', style: TextStyle(color: AppColors.goldPrimary)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.goldPrimary)),
                  ),
                  const SizedBox(width: 10),

                  // Manage Types CRUD button
                  OutlinedButton.icon(
                    onPressed: () => _showManageTypesDialog(context, bookProv),
                    icon: const Icon(Icons.class_outlined, size: 16, color: AppColors.emeraldAccent),
                    label: const Text('Turlarni Boshqarish', style: TextStyle(color: AppColors.emeraldAccent)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.emeraldAccent)),
                  ),
                  const SizedBox(width: 10),

                  // Import from Excel button
                  OutlinedButton.icon(
                    onPressed: () => _importFromExcel(context, bookProv),
                    icon: const Icon(Icons.upload_file, size: 16, color: Colors.lightBlueAccent),
                    label: const Text('Excel\'dan Yuklash', style: TextStyle(color: Colors.lightBlueAccent)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.lightBlueAccent)),
                  ),
                  const SizedBox(width: 10),

                  // Add Book button
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditBookDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Yangi Kitob Qo\'shish'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldPrimary, foregroundColor: AppColors.backgroundDark),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search and Filters Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                // Search Input
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (val) => bookProv.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Kitob nomi, muallifi yoki ISBN kodi bo\'yicha qidiruv...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textMuted),
                              onPressed: () {
                                _searchCtrl.clear();
                                bookProv.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Category Filter
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: bookProv.selectedCategoryFilter,
                    decoration: const InputDecoration(
                      labelText: 'Janr / Soha',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Barcha janrlar', overflow: TextOverflow.ellipsis)),
                      ...bookProv.availableCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (val) => bookProv.setCategoryFilter(val),
                  ),
                ),
                const SizedBox(width: 12),

                // Type Filter
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: bookProv.selectedTypeFilter,
                    decoration: const InputDecoration(
                      labelText: 'Kitob Turi',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Barcha turlari', overflow: TextOverflow.ellipsis)),
                      ...bookProv.availableTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (val) => bookProv.setTypeFilter(val),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Books List / Cards (Clean layout without cover image)
          Expanded(
            child: bookProv.books.isEmpty
                ? const Center(
                    child: Text(
                      'Kitoblar topilmadi',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: bookProv.books.length,
                    itemBuilder: (context, index) {
                      final book = bookProv.books[index];
                      return _buildBookCard(context, book, bookProv);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, BookModel book, BookProvider bookProv) {
    final bool isAvailable = book.isAvailable;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.bookmark_border, color: AppColors.goldPrimary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      book.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Muallif: ${book.author}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildChip(book.category, AppColors.goldPrimary),
                  _buildChip(book.type, AppColors.emeraldAccent),
                  if (book.locationRack != null && book.locationRack!.isNotEmpty)
                    _buildChip('Javon: ${book.locationRack}', AppColors.info),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAvailable ? AppColors.emeraldAccent.withValues(alpha: 0.2) : AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Mavjud: ${book.availableCopies} / ${book.totalCopies}',
                  style: TextStyle(
                    color: isAvailable ? AppColors.emeraldAccent : AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: AppColors.textMuted),
                    onPressed: () => _showAddEditBookDialog(context, book: book),
                    tooltip: 'Tahrirlash',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    onPressed: () => _confirmDeleteBook(context, book, bookProv),
                    tooltip: 'O\'chirish',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showAddEditBookDialog(BuildContext context, {BookModel? book}) {
    final isEditing = book != null;
    final titleCtrl = TextEditingController(text: book?.title ?? '');
    final authorCtrl = TextEditingController(text: book?.author ?? '');
    final isbnCtrl = TextEditingController(text: book?.isbn ?? '');
    final categoryCtrl = TextEditingController(text: book?.category ?? 'Huquqshunoslik');
    final typeCtrl = TextEditingController(text: book?.type ?? 'Darslik');
    final copiesCtrl = TextEditingController(text: book?.totalCopies.toString() ?? '10');
    final yearCtrl = TextEditingController(text: book?.publishedYear.toString() ?? '2024');
    final publisherCtrl = TextEditingController(text: book?.publisher ?? '');
    final rackCtrl = TextEditingController(text: book?.locationRack ?? 'A-1');

    final bookProv = context.read<BookProvider>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Text(
            isEditing ? 'Kitobni Tahrirlash' : 'Yangi Kitob Qo\'shish',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Kitob Nomi *')),
                  const SizedBox(height: 10),
                  TextField(controller: authorCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Muallif *')),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: isbnCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'ISBN / Inventar Kodi *'))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: rackCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Javon Kodi (Rack)'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: bookProv.availableCategories.contains(categoryCtrl.text) ? categoryCtrl.text : (bookProv.availableCategories.isNotEmpty ? bookProv.availableCategories.first : 'Huquqshunoslik'),
                          decoration: const InputDecoration(labelText: 'Janr / Soha'),
                          items: bookProv.availableCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) => categoryCtrl.text = v ?? '',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: bookProv.availableTypes.contains(typeCtrl.text) ? typeCtrl.text : (bookProv.availableTypes.isNotEmpty ? bookProv.availableTypes.first : 'Darslik'),
                          decoration: const InputDecoration(labelText: 'Kitob Turi'),
                          items: bookProv.availableTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) => typeCtrl.text = v ?? '',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: copiesCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Jami Nusxalar Soni *'))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: yearCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Nashr Yili'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: publisherCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Nashriyot')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Bekor qilish', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || authorCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Iltimos, kitob nomi va muallifini kiriting!')),
                  );
                  return;
                }

                final totalCopies = int.tryParse(copiesCtrl.text) ?? 1;
                final year = int.tryParse(yearCtrl.text) ?? 2024;

                final newBook = BookModel(
                  id: isEditing ? book.id : 'bk_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleCtrl.text.trim(),
                  author: authorCtrl.text.trim(),
                  isbn: isbnCtrl.text.trim().isEmpty ? 'ISBN-${DateTime.now().millisecondsSinceEpoch}' : isbnCtrl.text.trim(),
                  category: categoryCtrl.text.trim().isEmpty ? 'Huquqshunoslik' : categoryCtrl.text.trim(),
                  type: typeCtrl.text.trim().isEmpty ? 'Darslik' : typeCtrl.text.trim(),
                  totalCopies: totalCopies,
                  availableCopies: isEditing ? (book.availableCopies + (totalCopies - book.totalCopies)).clamp(0, totalCopies) : totalCopies,
                  publishedYear: year,
                  publisher: publisherCtrl.text.trim(),
                  locationRack: rackCtrl.text.trim(),
                );

                if (isEditing) {
                  await bookProv.updateBook(newBook);
                } else {
                  await bookProv.addBook(newBook);
                }

                if (context.mounted) Navigator.pop(ctx);
              },
              child: Text(isEditing ? 'Saqlash' : 'Qo\'shish'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importFromExcel(BuildContext context, BookProvider prov) async {
    final messenger = ScaffoldMessenger.of(context);
    ExcelImportResult? result;
    try {
      result = await ExcelImportService.instance.pickAndParse();
    } catch (e) {
      final msg = e is FormatException ? e.message : e.toString();
      messenger.showSnackBar(SnackBar(content: Text('Excel faylni o\'qishda xatolik: $msg')));
      return;
    }
    if (result == null || !context.mounted) return;

    final data = result;
    final authorCtrl = TextEditingController(text: 'Noma\'lum');
    String category = prov.availableCategories.isNotEmpty ? prov.availableCategories.first : 'Umumiy';
    String type = prov.availableTypes.isNotEmpty ? prov.availableTypes.first : 'Darslik';
    bool importing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardDark,
              title: const Text('Excel\'dan Kitoblarni Yuklash', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 620,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.fileName, style: const TextStyle(color: AppColors.goldPrimary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${data.rows.length} turdagi kitob, jami ${data.totalCopies} nusxa topildi',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.cardBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        itemCount: data.rows.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.cardBorder),
                        itemBuilder: (_, i) {
                          final row = data.rows[i];
                          return ListTile(
                            dense: true,
                            leading: Text('${row.rowNumber}', style: const TextStyle(color: AppColors.textMuted)),
                            title: Text(row.title, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
                            trailing: Text(
                              '${row.publishedYear == 0 ? '—' : row.publishedYear}  •  ${row.copies} dona',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Excel faylda muallif, janr va tur ko\'rsatilmagan — yangi kitoblarga quyidagi qiymatlar beriladi. '
                      'Fondda nomi va yili bir xil kitob bo\'lsa, faqat nusxalar soni yangilanadi.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: category,
                            decoration: const InputDecoration(labelText: 'Janr / Soha'),
                            items: {...prov.availableCategories, category}
                                .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: importing ? null : (v) => category = v ?? category,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: type,
                            decoration: const InputDecoration(labelText: 'Kitob Turi'),
                            items: {...prov.availableTypes, type}
                                .map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: importing ? null : (v) => type = v ?? type,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: authorCtrl,
                            enabled: !importing,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Muallif'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: importing ? null : () => Navigator.pop(ctx),
                  child: const Text('Bekor qilish', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton.icon(
                  onPressed: importing
                      ? null
                      : () async {
                          setDialogState(() => importing = true);
                          try {
                            final (added, updated) = await prov.importBooksFromExcel(
                              data.rows,
                              category: category,
                              type: type,
                              author: authorCtrl.text.trim().isEmpty ? 'Noma\'lum' : authorCtrl.text.trim(),
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            messenger.showSnackBar(SnackBar(
                              content: Text('Import yakunlandi: $added ta yangi kitob qo\'shildi, $updated ta yangilandi.'),
                            ));
                          } catch (e) {
                            setDialogState(() => importing = false);
                            messenger.showSnackBar(SnackBar(content: Text('Import xatoligi: $e')));
                          }
                        },
                  icon: importing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.download_done, size: 18),
                  label: Text(importing ? 'Yuklanmoqda...' : 'Import qilish'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showManageGenresDialog(BuildContext context, BookProvider prov) {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardDark,
              title: const Text('Janrlarni Boshqarish (CRUD)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Yangi Janr Nomi'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            if (nameCtrl.text.trim().isNotEmpty) {
                              await prov.addGenre(nameCtrl.text.trim());
                              nameCtrl.clear();
                              setDialogState(() {});
                            }
                          },
                          child: const Text('Qo\'shish'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.cardBorder),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: prov.genres.isEmpty
                          ? const Center(child: Text('Janrlar mavjud emas', style: TextStyle(color: AppColors.textMuted)))
                          : ListView.builder(
                              itemCount: prov.genres.length,
                              itemBuilder: (context, index) {
                                final g = prov.genres[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(g.name, style: const TextStyle(color: Colors.white)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                    onPressed: () async {
                                      await prov.deleteGenre(g.id);
                                      setDialogState(() {});
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Yopish', style: TextStyle(color: AppColors.textMuted))),
              ],
            );
          },
        );
      },
    );
  }

  void _showManageTypesDialog(BuildContext context, BookProvider prov) {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardDark,
              title: const Text('Kitob Turlarini Boshqarish (CRUD)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Yangi Kitob Turi Nomi'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            if (nameCtrl.text.trim().isNotEmpty) {
                              await prov.addBookType(nameCtrl.text.trim());
                              nameCtrl.clear();
                              setDialogState(() {});
                            }
                          },
                          child: const Text('Qo\'shish'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.cardBorder),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: prov.types.isEmpty
                          ? const Center(child: Text('Kitob turlari mavjud emas', style: TextStyle(color: AppColors.textMuted)))
                          : ListView.builder(
                              itemCount: prov.types.length,
                              itemBuilder: (context, index) {
                                final t = prov.types[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(t.name, style: const TextStyle(color: Colors.white)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                    onPressed: () async {
                                      await prov.deleteBookType(t.id);
                                      setDialogState(() {});
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Yopish', style: TextStyle(color: AppColors.textMuted))),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteBook(BuildContext context, BookModel book, BookProvider bookProv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Kitobni o\'chirish', style: TextStyle(color: Colors.white)),
        content: Text('Siz rostdan ham "${book.title}" kitobini katalogdan o\'chirmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await bookProv.deleteBook(book.id);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
  }
}
