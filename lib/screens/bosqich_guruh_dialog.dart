import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bosqich.dart';
import '../models/guruh.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';

/// Bosqichlar va guruhlarni boshqarish (qo'shish, tahrirlash, o'chirish)
void showBosqichGuruhDialog(BuildContext context) {
  showDialog(context: context, builder: (_) => const _BosqichGuruhDialog());
}

class _BosqichGuruhDialog extends StatefulWidget {
  const _BosqichGuruhDialog();

  @override
  State<_BosqichGuruhDialog> createState() => _BosqichGuruhDialogState();
}

class _BosqichGuruhDialogState extends State<_BosqichGuruhDialog> {
  String? _selectedBosqichId;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<UserProvider>();
    final bosqichlar = prov.bosqichlar;

    // Tanlangan bosqich o'chirilgan bo'lsa yoki hali tanlanmagan bo'lsa — birinchisini tanlaymiz
    if (!bosqichlar.any((b) => b.id == _selectedBosqichId)) {
      _selectedBosqichId = bosqichlar.isNotEmpty ? bosqichlar.first.id : null;
    }
    final selected = bosqichlar.where((b) => b.id == _selectedBosqichId).firstOrNull;
    final guruhlar = prov.guruhlar.where((g) => g.bosqichId == _selectedBosqichId).toList();

    return AlertDialog(
      backgroundColor: AppColors.cardDark,
      title: const Text('Bosqich va Guruhlarni Boshqarish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 720,
        height: 420,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bosqichlar
            Expanded(
              child: _panel(
                title: 'Bosqichlar',
                onAdd: () => _editBosqich(context, prov),
                addLabel: 'Bosqich qo\'shish',
                emptyText: 'Bosqichlar yo\'q',
                children: bosqichlar.map((b) {
                  final isSelected = b.id == _selectedBosqichId;
                  final groupCount = prov.guruhlar.where((g) => g.bosqichId == b.id).length;
                  return ListTile(
                    dense: true,
                    selected: isSelected,
                    selectedTileColor: AppColors.goldPrimary.withValues(alpha: 0.12),
                    onTap: () => setState(() => _selectedBosqichId = b.id),
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: isSelected ? AppColors.goldPrimary : AppColors.inputBackground,
                      child: Text(
                        '${b.levelNumber}',
                        style: TextStyle(fontSize: 12, color: isSelected ? AppColors.backgroundDark : Colors.white),
                      ),
                    ),
                    title: Text(b.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('$groupCount ta guruh', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    trailing: _actions(
                      onEdit: () => _editBosqich(context, prov, bosqich: b),
                      onDelete: () => _confirmDelete(context, '"${b.name}" bosqichini', () => prov.deleteBosqich(b.id)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 16),

            // Tanlangan bosqich guruhlari
            Expanded(
              child: _panel(
                title: selected == null ? 'Guruhlar' : 'Guruhlar — ${selected.name}',
                onAdd: selected == null ? null : () => _editGuruh(context, prov, bosqich: selected),
                addLabel: 'Guruh qo\'shish',
                emptyText: selected == null ? 'Avval bosqich qo\'shing' : 'Bu bosqichda guruhlar yo\'q',
                children: guruhlar.map((g) {
                  final userCount = prov.allUsersCountInGuruh(g.id);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.groups_outlined, color: AppColors.emeraldAccent, size: 20),
                    title: Text(g.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('$userCount nafar kursant', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    trailing: _actions(
                      onEdit: () => _editGuruh(context, prov, bosqich: selected!, guruh: g),
                      onDelete: () => _confirmDelete(context, '"${g.name}" guruhini', () => prov.deleteGuruh(g.id)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Yopish', style: TextStyle(color: AppColors.textMuted)),
        ),
      ],
    );
  }

  Widget _panel({
    required String title,
    required VoidCallback? onAdd,
    required String addLabel,
    required String emptyText,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(color: AppColors.goldPrimary, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(addLabel, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),
          Expanded(
            child: children.isEmpty
                ? Center(child: Text(emptyText, style: const TextStyle(color: AppColors.textMuted)))
                : ListView(children: children),
          ),
        ],
      ),
    );
  }

  Widget _actions({required VoidCallback onEdit, required VoidCallback onDelete}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Tahrirlash',
          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
          onPressed: onEdit,
        ),
        IconButton(
          tooltip: 'O\'chirish',
          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
          onPressed: onDelete,
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, String what, Future<String?> Function() delete) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('O\'chirishni tasdiqlang', style: TextStyle(color: Colors.white)),
        content: Text('$what o\'chirmoqchimisiz?', style: const TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor qilish')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final error = await delete();
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _editBosqich(BuildContext context, UserProvider prov, {Bosqich? bosqich}) async {
    final nextLevel = prov.bosqichlar.fold(0, (m, b) => b.levelNumber > m ? b.levelNumber : m) + 1;
    final nameCtrl = TextEditingController(text: bosqich?.name ?? '');
    final levelCtrl = TextEditingController(text: '${bosqich?.levelNumber ?? nextLevel}');
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Text(
            bosqich == null ? 'Yangi Bosqich' : 'Bosqichni Tahrirlash',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error != null) ...[
                  Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Bosqich nomi *', hintText: 'Masalan: 1-bosqich (1-kurs)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: levelCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Tartib raqami *'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish', style: TextStyle(color: AppColors.textMuted))),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final level = int.tryParse(levelCtrl.text.trim());
                if (name.isEmpty || level == null || level <= 0) {
                  setDialogState(() => error = 'Bosqich nomi va tartib raqamini to\'g\'ri kiriting');
                  return;
                }
                if (prov.bosqichlar.any((b) => b.id != bosqich?.id && b.name.toLowerCase() == name.toLowerCase())) {
                  setDialogState(() => error = 'Bunday nomli bosqich allaqachon mavjud');
                  return;
                }
                if (bosqich == null) {
                  await prov.addBosqich(name, level);
                } else {
                  await prov.updateBosqich(bosqich.copyWith(name: name, levelNumber: level));
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(bosqich == null ? 'Qo\'shish' : 'Saqlash'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editGuruh(BuildContext context, UserProvider prov, {required Bosqich bosqich, Guruh? guruh}) async {
    final nameCtrl = TextEditingController(text: guruh?.name ?? '');
    String bosqichId = bosqich.id;
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Text(
            guruh == null ? 'Yangi Guruh' : 'Guruhni Tahrirlash',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error != null) ...[
                  Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Guruh nomi *', hintText: 'Masalan: 101-guruh'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: bosqichId,
                  decoration: const InputDecoration(labelText: 'Bosqich *'),
                  items: prov.bosqichlar
                      .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => bosqichId = v ?? bosqichId,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish', style: TextStyle(color: AppColors.textMuted))),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  setDialogState(() => error = 'Guruh nomini kiriting');
                  return;
                }
                if (prov.guruhlar.any((g) => g.id != guruh?.id && g.name.toLowerCase() == name.toLowerCase())) {
                  setDialogState(() => error = 'Bunday nomli guruh allaqachon mavjud');
                  return;
                }
                final target = prov.bosqichlar.firstWhere((b) => b.id == bosqichId);
                if (guruh == null) {
                  await prov.addGuruh(name, target);
                } else {
                  await prov.updateGuruh(guruh.copyWith(name: name, bosqichId: target.id, bosqichName: target.name));
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(guruh == null ? 'Qo\'shish' : 'Saqlash'),
            ),
          ],
        ),
      ),
    );
  }
}
