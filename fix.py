import sys

with open('lib/features/properties/widgets/property_card.dart', 'r', encoding='utf-8') as f:
    content = f.read()

bad_str = '''return GestureDetector(
      onTap: widget.isSelectionMode
          ? () {
              if (widget.onSelectChanged != null) {
                widget.onSelectChanged!(!(widget.isSelected));
              }
            }
          : widget.onTap,
      child: Container('''

parts = content.split(bad_str)

if len(parts) != 4:
    print('Expected 3 instances of bad string, found', len(parts) - 1)
    sys.exit(1)

# Keep the first one, revert the other two
new_content = parts[0] + bad_str + parts[1] + 'return Container(' + parts[2] + 'return Container(' + parts[3]

with open('lib/features/properties/widgets/property_card.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)

print('Fixed!')
