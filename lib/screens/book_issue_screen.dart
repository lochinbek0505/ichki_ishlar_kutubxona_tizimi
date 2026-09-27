import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/book_issue_model.dart';
import '../models/book_model.dart';
import '../models/user_model.dart';
import '../providers/book_issue_provider.dart';
import '../providers/book_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';

class BookIssueScreen extends StatefulWidget {
  const BookIssueScreen({super.key});

  @override
  State<BookIssueScreen> createState() => _BookIssueScreenState();
}

class _BookIssueScreenState extends State<BookIssueScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final issueProv = context.watch<BookIssueProvider>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & New Issue Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KITOB BERISH VA QAYTARIB OLISH JURNALI',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Faol: ${issueProv.activeIssuedCount} ta | Kechikkan (Qarzdor): ${issueProv.overdueCount} ta',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showIssueBookDialog(context),
                icon: const Icon(Icons.add_to_photos, size: 18),
                label: const Text('O\'quvchiga Kitob Biriktirish'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldPrimary, foregroundColor: AppColors.backgroundDark),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filters Bar
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
                    onChanged: (val) => issueProv.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Kitob nomi, o\'quvchi ismi yoki guruh bo\'yicha qidiruv...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textMuted),
                              onPressed: () {
                                _searchCtrl.clear();
                                issueProv.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Status Filter Chips
                Wrap(
                  spacing: 8,
                  children: [
                    _buildStatusFilterChip(context, issueProv, 'ALL', 'Barchasi'),
                    _buildStatusFilterChip(context, issueProv, 'ISSUED', 'Olingan (Faol)'),
                    _buildStatusFilterChip(context, issueProv, 'OVERDUE', 'Kechikkan (Qarzdor)'),
                    _buildStatusFilterChip(context, issueProv, 'RETURNED', 'Qaytarilgan'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Issues Table
          Expanded(
            child: issueProv.issues.isEmpty
                ? const Center(
                    child: Text('Kitob berish yozuvlari topilmadi', style: TextStyle(color: AppColors.textMuted)),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: ListView.separated(
                      itemCount: issueProv.issues.length,
                      separatorBuilder: (_, index) => const Divider(color: AppColors.cardBorder, height: 1),
                      itemBuilder: (context, index) {
                        final item = issueProv.issues[index];
                        return _buildIssueRow(context, item, issueProv);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(BuildContext context, BookIssueProvider prov, String code, String label) {
    final bool isSelected = prov.selectedStatusFilter == code;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => prov.setStatusFilter(code),
      selectedColor: AppColors.goldPrimary,
      backgroundColor: AppColors.inputBackground,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.backgroundDark : AppColors.textMuted,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildIssueRow(BuildContext context, BookIssueModel item, BookIssueProvider issueProv) {
    Color statusColor = AppColors.emeraldAccent;
    String statusText = 'QAYTARILGAN';

    if (!item.isReturned) {
      if (item.isOverdue) {
        statusColor = AppColors.error;
        statusText = 'KECHIKKAN (QARZDOR)';
      } else {
        statusColor = AppColors.goldPrimary;
        statusText = 'OLINGAN (FAOL)';
      }
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.2),
        child: Icon(
          item.isReturned ? Icons.check_circle_outline : (item.isOverdue ? Icons.error_outline : Icons.menu_book),
          color: statusColor,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.bookTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor, width: 0.8),
            ),
            child: Text(
              statusText,
              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'O\'quvchi: ${item.userName} | Guruh: ${item.userGroup ?? '—'} | Bosqich: ${item.userStage ?? '—'}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            'Berilgan: ${item.issueDate} | Qaytarish muhlati: ${item.dueDate} ${item.returnDate != null ? '| Topshirilgan: ${item.returnDate}' : ''}',
            style: TextStyle(
              color: item.isOverdue ? AppColors.error : AppColors.textMuted,
              fontSize: 11,
              fontWeight: item.isOverdue ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (item.notes != null && item.notes!.isNotEmpty)
            Text(
              'Izoh: ${item.notes}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
            ),
        ],
      ),
      trailing: !item.isReturned
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _confirmReturnBook(context, item, issueProv),
                  icon: const Icon(Icons.assignment_turned_in, size: 16),
                  label: const Text('Qaytarib olish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.update, color: AppColors.goldPrimary, size: 20),
                  onPressed: () => _showExtendDueDateDialog(context, item, issueProv),
                  tooltip: 'Muddatni uzaytirish',
                ),
              ],
            )
          : null,
    );
  }

  void _showIssueBookDialog(BuildContext context) {
    final userProv = context.read<UserProvider>();
    final bookProv = context.read<BookProvider>();

    UserModel? selectedUser;
    BookModel? selectedBook;
    DateTime dueDate = DateTime.now().add(const Duration(days: 15));
    final notesCtrl = TextEditingController();
    final studentSearchCtrl = TextEditingController();

    final availableBooks = bookProv.books.where((b) => b.isAvailable).toList();
    // Sort all cadets strictly alphabetically
    final allUsersSorted = List<UserModel>.from(userProv.users)
      ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final searchQuery = studentSearchCtrl.text.toLowerCase();
            final filteredUsers = allUsersSorted.where((u) {
              return searchQuery.isEmpty ||
                  u.fullName.toLowerCase().contains(searchQuery) ||
                  (u.guruhName ?? '').toLowerCase().contains(searchQuery) ||
                  u.readerCardId.toLowerCase().contains(searchQuery);
            }).toList();

            return AlertDialog(
              backgroundColor: AppColors.cardDark,
              title: const Text(
                'O\'quvchiga Kitob Biriktirish (Issue)',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Live Student Search
                    TextField(
                      controller: studentSearchCtrl,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => setDialogState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Kursant F.I.O yoki guruhini izlash...',
                        prefixIcon: Icon(Icons.person_search, color: AppColors.goldPrimary),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // User Selection Dropdown
                    DropdownButtonFormField<UserModel>(
                      initialValue: selectedUser,
                      decoration: const InputDecoration(labelText: 'O\'quvchi / Kursantni Tanlang (Alifbo tartibida) *'),
                      items: filteredUsers.map((u) {
                        return DropdownMenuItem(
                          value: u,
                          child: Text('${u.fullName} (${u.guruhName ?? u.bosqichName ?? 'Kursant'})'),
                        );
                      }).toList(),
                      onChanged: (v) => setDialogState(() => selectedUser = v),
                    ),
                    const SizedBox(height: 12),

                    // Book selection
                    DropdownButtonFormField<BookModel>(
                      initialValue: selectedBook,
                      decoration: const InputDecoration(labelText: 'Mavjud Kitobni Tanlang *'),
                      items: availableBooks.map((b) {
                        return DropdownMenuItem(
                          value: b,
                          child: Text('${b.title} (Mavjud: ${b.availableCopies} ta)'),
                        );
                      }).toList(),
                      onChanged: (v) => setDialogState(() => selectedBook = v),
                    ),
                    const SizedBox(height: 12),

                    // Due date picker
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppColors.cardBorder),
                      ),
                      tileColor: AppColors.inputBackground,
                      title: const Text('Qaytarish Muhlati', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      subtitle: Text(
                        DateFormat('yyyy-MM-dd').format(dueDate),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                      ),
                      trailing: const Icon(Icons.calendar_month, color: AppColors.goldPrimary),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 180)),
                        );
                        if (picked != null) {
                          setDialogState(() => dueDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: notesCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Izoh / Maqsad'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Bekor qilish', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedUser == null || selectedBook == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Iltimos, o\'quvchi va kitobni tanlang!')),
                      );
                      return;
                    }

                    final dueDateStr = DateFormat('yyyy-MM-dd').format(dueDate);
                    final issueProv = context.read<BookIssueProvider>();

                    await issueProv.issueBook(
                      bookId: selectedBook!.id,
                      bookTitle: selectedBook!.title,
                      userId: selectedUser!.id,
                      userName: selectedUser!.fullName,
                      userGroup: selectedUser!.guruhName,
                      userStage: selectedUser!.bosqichName,
                      dueDate: dueDateStr,
                      notes: notesCtrl.text.trim(),
                    );

                    if (context.mounted) {
                      await context.read<BookProvider>().loadBooks();
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Kitobni Berish'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmReturnBook(BuildContext context, BookIssueModel item, BookIssueProvider issueProv) {
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Kitobni Qaytarib Olish', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kitob: "${item.bookTitle}"', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            Text('O\'quvchi: ${item.userName}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Topshirilgandagi holati / Izoh'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emeraldPrimary, foregroundColor: Colors.white),
            onPressed: () async {
              await issueProv.returnBook(item.id, notes: notesCtrl.text.trim());
              if (context.mounted) {
                await context.read<BookProvider>().loadBooks();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Qaytarildi deb belgilash'),
          ),
        ],
      ),
    );
  }

  void _showExtendDueDateDialog(BuildContext context, BookIssueModel item, BookIssueProvider issueProv) {
    DateTime newDate = DateTime.tryParse(item.dueDate) ?? DateTime.now().add(const Duration(days: 10));

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardDark,
              title: const Text('Qaytarish Muhlatini Uzaytirish', style: TextStyle(color: Colors.white)),
              content: ListTile(
                tileColor: AppColors.inputBackground,
                title: const Text('Yangi Qaytarish Muhlati'),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(newDate), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                trailing: const Icon(Icons.calendar_month, color: AppColors.goldPrimary),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: newDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 180)),
                  );
                  if (picked != null) {
                    setDialogState(() => newDate = picked);
                  }
                },
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish')),
                ElevatedButton(
                  onPressed: () async {
                    final dateStr = DateFormat('yyyy-MM-dd').format(newDate);
                    await issueProv.extendDueDate(item.id, dateStr);
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Uzaytirish'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
