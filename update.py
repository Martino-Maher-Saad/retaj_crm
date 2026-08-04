import re

with open('lib/features/properties/screens/properties_list_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add _bulkDelete function
bulk_delete_func = '''
  Future<void> _bulkDelete(List<String> ids) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف \ عقار نهائياً؟ هذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف نهائي', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _cubit.deleteProperties(ids);
      setState(() {
        _isSelectionMode = false;
        _selectedProperties.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف العقارات المحددة بنجاح')),
        );
      }
    }
  }

'''

content = content.replace('Future<void> _exportProperties() async {', bulk_delete_func + '  Future<void> _exportProperties() async {')


# Update extraAction in PropertyListHeader
old_extra = '''extraAction: (widget.role == 'manager' || widget.role == 'admin' || widget.role == 'ceo')
                          ? OutlinedButton.icon(
                              onPressed: _exportProperties,
                              icon: const Icon(Icons.file_download, size: 18),
                              label: const Text('تصدير'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.brandPrimary,
                                side: BorderSide(color: AppColors.brandPrimary, width: 1.5),
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                              ),
                            )
                          : null,'''

new_extra = '''extraAction: (widget.role == 'manager' || widget.role == 'admin' || widget.role == 'ceo')
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isSelectionMode = true;
                                    });
                                  },
                                  icon: const Icon(Icons.check_box_outlined, size: 18),
                                  label: const Text('تحديد'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.brandPrimary,
                                    side: BorderSide(color: AppColors.brandPrimary, width: 1.5),
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                                  ),
                                ),
                                SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: _exportProperties,
                                  icon: const Icon(Icons.file_download, size: 18),
                                  label: const Text('تصدير'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.brandPrimary,
                                    side: BorderSide(color: AppColors.brandPrimary, width: 1.5),
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                                  ),
                                ),
                              ],
                            )
                          : null,'''

content = content.replace(old_extra, new_extra)

# Insert _isSelectionMode Header
old_header = '''PropertyListHeader('''
new_header = '''if (_isSelectionMode)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        color: AppColors.brandPrimary.withValues(alpha: 0.1),
                        child: Row(
                          children: [
                            Text("تم تحديد \ عقار", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.brandPrimary)),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  if (_selectedProperties.length == properties.length) {
                                    _selectedProperties.clear();
                                  } else {
                                    _selectedProperties = properties.map((p) => p.id).toSet();
                                  }
                                });
                              },
                              icon: Icon(_selectedProperties.length == properties.length ? Icons.deselect : Icons.select_all),
                              label: Text(_selectedProperties.length == properties.length ? "إلغاء تحديد الكل" : "تحديد الكل"),
                            ),
                            SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _selectedProperties.isEmpty ? null : () => _bulkDelete(_selectedProperties.toList()),
                              icon: const Icon(Icons.delete_outline, color: Colors.white),
                              label: const Text("حذف", style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            ),
                            SizedBox(width: 16),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _isSelectionMode = false;
                                  _selectedProperties.clear();
                                });
                              },
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                    PropertyListHeader('''

content = content.replace(old_header, new_header)


# Update PropertyCard usage
old_card = '''return PropertyCard(
                            property: p,
                            currentUserId: widget.userId,
                            role: widget.role,
                            onEdit: () {'''
                            
new_card = '''return PropertyCard(
                            property: p,
                            currentUserId: widget.userId,
                            role: widget.role,
                            isSelectionMode: _isSelectionMode,
                            isSelected: _selectedProperties.contains(p.id),
                            onSelectChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedProperties.add(p.id);
                                } else {
                                  _selectedProperties.remove(p.id);
                                }
                              });
                            },
                            onEdit: () {'''

content = content.replace(old_card, new_card)

with open('lib/features/properties/screens/properties_list_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
