import sys

with open('lib/features/properties/widgets/property_card.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = lines[:1220] + [
    '                    ],\n',
    '                  ),\n',
    '                ],\n',
    '              ),\n',
    '            ),\n',
    '          ),\n',
    '        );\n',
    '  }\n'
] + lines[1234:]

with open('lib/features/properties/widgets/property_card.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
