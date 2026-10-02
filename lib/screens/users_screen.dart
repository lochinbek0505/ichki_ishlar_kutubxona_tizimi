import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../services/local_file_service.dart';
import '../theme/app_colors.dart';
import 'reader_card_dialog.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KURSANTLAR RO\'YXATI',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Jami ${userProv.users.length} nafar kursant (Alifbo tartibida saralangan)',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditUserDialog(context),
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Yangi Kursant Qo\'shish'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldPrimary, foregroundColor: AppColors.backgroundDark),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search and Filters Bar (Bosqich & Guruh Kesimida)
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
                    onChanged: (val) => userProv.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Kursant F.I.O yoki Karta ID bo\'yicha qidiruv...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textMuted),
                              onPressed: () {
                                _searchCtrl.clear();
                                userProv.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Bosqich Filter
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: userProv.selectedBosqichIdFilter,
                    decoration: const InputDecoration(
                      labelText: 'Bosqich (Kurs)',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Barcha bosqichlar', overflow: TextOverflow.ellipsis)),
                      ...userProv.bosqichlar.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (val) => userProv.setBosqichFilter(val),
                  ),
                ),
                const SizedBox(width: 12),

                // Guruh Filter
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: userProv.selectedGuruhIdFilter,
                    decoration: const InputDecoration(
                      labelText: 'Guruh',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Barcha guruhlar', overflow: TextOverflow.ellipsis)),
                      ...userProv.guruhlar
                          .where((g) => userProv.selectedBosqichIdFilter == null || g.bosqichId == userProv.selectedBosqichIdFilter)
                          .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (val) => userProv.setGuruhFilter(val),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Users Alphabetical Table
          Expanded(
            child: userProv.users.isEmpty
                ? const Center(
                    child: Text('Kursantlar topilmadi', style: TextStyle(color: AppColors.textMuted)),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: ListView.separated(
                      itemCount: userProv.users.length,
                      separatorBuilder: (_, index) => const Divider(color: AppColors.cardBorder, height: 1),
                      itemBuilder: (context, index) {
                        final u = userProv.users[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.inputBackground,
                              border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.5)),
                            ),
                            child: u.imagePath != null && File(u.imagePath!).existsSync()
                                ? ClipOval(
                                    child: Image.file(File(u.imagePath!), fit: BoxFit.cover),
                                  )
                                : const Icon(Icons.person, color: AppColors.goldPrimary),
                          ),
                          title: Text(
                            u.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          ),
                          subtitle: Text(
                            'Bosqich: ${u.bosqichName ?? '—'} | Guruh: ${u.guruhName ?? '—'} | Karta ID: ${u.readerCardId}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // A'zolik Kartasi & PDF Export button
                              ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => ReaderCardDialog(user: u),
                                  );
                                },
                                icon: const Icon(Icons.badge_outlined, size: 16),
                                label: const Text('A\'zolik Kartasi (PDF)'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.goldDark,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: AppColors.textMuted),
                                onPressed: () => _showAddEditUserDialog(context, user: u),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                onPressed: () => _confirmDeleteUser(context, u, userProv),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddEditUserDialog(BuildContext context, {UserModel? user}) {
    final isEditing = user != null;
    final nameCtrl = TextEditingController(text: user?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    String? selectedBosqichId = user?.bosqichId;
    String? selectedGuruhId = user?.guruhId;
    String? imagePath = user?.imagePath;

    final userProv = context.read<UserProvider>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredGuruhlar = userProv.guruhlar
                .where((g) => selectedBosqichId == null || g.bosqichId == selectedBosqichId)
                .toList();

            return AlertDialog(
              backgroundColor: AppColors.cardDark,
              title: Text(
                isEditing ? 'Kursant Ma\'lumotlarini Tahrirlash' : 'Yangi Kursant Qo\'shish',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Photo Picker
                      GestureDetector(
                        onTap: () async {
                          final path = await LocalFileService.instance.pickAndSaveImage(category: 'user_photos');
                          if (path != null) {
                            setDialogState(() {
                              imagePath = path;
                            });
                          }
                        },
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: AppColors.inputBackground,
                          backgroundImage: imagePath != null && File(imagePath!).existsSync()
                              ? FileImage(File(imagePath!))
                              : null,
                          child: imagePath == null || !File(imagePath!).existsSync()
                              ? const Icon(Icons.add_a_photo, color: AppColors.goldPrimary, size: 26)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: nameCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'To\'liq Ism-Familiyasi (F.I.O) *'),
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: phoneCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Telefon raqami'),
                      ),
                      const SizedBox(height: 10),

                      DropdownButtonFormField<String?>(
                        isExpanded: true,
                        initialValue: selectedBosqichId,
                        decoration: const InputDecoration(labelText: 'Bosqich (Kurs)'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tanlanmagan', overflow: TextOverflow.ellipsis)),
                          ...userProv.bosqichlar.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name, overflow: TextOverflow.ellipsis))),
                        ],
                        onChanged: (v) {
                          setDialogState(() {
                            selectedBosqichId = v;
                            selectedGuruhId = null;
                          });
                        },
                      ),
                      const SizedBox(height: 10),

                      DropdownButtonFormField<String?>(
                        isExpanded: true,
                        initialValue: selectedGuruhId,
                        decoration: const InputDecoration(labelText: 'Guruh'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tanlanmagan', overflow: TextOverflow.ellipsis)),
                          ...filteredGuruhlar.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name, overflow: TextOverflow.ellipsis))),
                        ],
                        onChanged: (v) => setDialogState(() => selectedGuruhId = v),
                      ),
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
                    if (nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Iltimos, kursant F.I.O ni kiriting!')),
                      );
                      return;
                    }

                    final bosqichObj = userProv.bosqichlar.where((b) => b.id == selectedBosqichId).firstOrNull;
                    final guruhObj = userProv.guruhlar.where((g) => g.id == selectedGuruhId).firstOrNull;

                    final newUser = UserModel(
                      id: isEditing ? user.id : 'usr_${DateTime.now().millisecondsSinceEpoch}',
                      fullName: nameCtrl.text.trim(),
                      bosqichId: selectedBosqichId,
                      bosqichName: bosqichObj?.name,
                      guruhId: selectedGuruhId,
                      guruhName: guruhObj?.name,
                      phone: phoneCtrl.text.trim(),
                      readerCardId: isEditing ? user.readerCardId : 'IIL-CARD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                      imagePath: imagePath,
                      createdAt: isEditing ? user.createdAt : DateTime.now().toIso8601String(),
                    );

                    if (isEditing) {
                      await userProv.updateUser(newUser);
                    } else {
                      await userProv.addUser(newUser);
                    }

                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: Text(isEditing ? 'Saqlash' : 'Qo\'shish'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteUser(BuildContext context, UserModel u, UserProvider userProv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Kursantni o\'chirish', style: TextStyle(color: Colors.white)),
        content: Text('Siz rostdan ham "${u.fullName}" kursantini ro\'yxatdan o\'chirmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await userProv.deleteUser(u.id);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
  }
}
