with open('lib/features/properties/widgets/property_card.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i in range(1060, 1110):
    print(f'{i+1}: {lines[i].rstrip()}')
