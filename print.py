with open('lib/features/properties/widgets/property_card.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i in range(612, 625):
    print(f'{i+1}: {lines[i].rstrip()}')
