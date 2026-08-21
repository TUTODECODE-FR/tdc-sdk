#!/usr/bin/env python3
"""Validateur basique des fichiers .tdc (structure entry/course/locale)."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def validate_tdc(path: Path) -> bool:
    text = path.read_text(encoding='utf-8')
    errors = []

    open_count = text.count('{')
    close_count = text.count('}')
    if open_count != close_count:
        errors.append(f'Balise des accolades : {open_count} ouvrantes, {close_count} fermantes')

    triple_count = text.count('"""')
    if triple_count % 2 != 0:
        errors.append(f'Guillemets triples non fermés : {triple_count} occurrences')

    if not re.search(r'\b(course|entry|locale)\b', text):
        errors.append("Aucun bloc 'course', 'entry' ou 'locale' trouvé")

    for m in re.finditer(r'\b(course|entry|locale)\b', text):
        rest = text[m.end():m.end() + 100].strip()
        if not rest.startswith('"'):
            errors.append(f"Bloc {m.group(0)} sans identifiant entre guillemets")

    if errors:
        print(f'❌ {path}:')
        for e in errors:
            print(f'   - {e}')
        return False

    print(f'✅ {path}')
    return True


def main() -> int:
    paths = [Path(a) for a in sys.argv[1:]]
    if not paths:
        paths = list((ROOT / 'examples').glob('*.tdc'))
    ok = True
    for p in paths:
        target = ROOT / p if not p.is_absolute() else p
        if not target.exists():
            print(f'⚠️ Fichier introuvable : {target}')
            ok = False
            continue
        if not validate_tdc(target):
            ok = False
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
