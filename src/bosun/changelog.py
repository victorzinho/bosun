"""Release a version in the CHANGELOG.md of the working directory, or print its release notes.

Usage:
    python3 -m bosun.changelog release <version>  # adds `## <version>` below `## Unreleased`; nothing for a pre-release
    python3 -m bosun.changelog notes <version>    # the version's section; Unreleased's for a pre-release
"""

import re
import sys
from pathlib import Path

CHANGELOG = Path('CHANGELOG.md')
UNRELEASED = '## Unreleased'


def is_prerelease(version: str) -> bool:
    return re.fullmatch(r'\d+(\.\d+)*', version) is None


def find(lines: list[str], heading: str) -> int:
    if heading not in lines:
        sys.exit(f'{CHANGELOG}: no `{heading}`')
    return lines.index(heading)


def release(lines: list[str], version: str) -> list[str]:
    if is_prerelease(version):
        return lines
    index = find(lines, UNRELEASED)
    return [*lines[: index + 1], '', f'## {version}', *lines[index + 1 :]]


def notes(lines: list[str], version: str) -> list[str]:
    heading = UNRELEASED if is_prerelease(version) else f'## {version}'
    start = find(lines, heading) + 1
    end = next((i for i in range(start, len(lines)) if lines[i].startswith('## ')), len(lines))
    return lines[start:end]


def main(command: str, version: str) -> None:
    lines = CHANGELOG.read_text().splitlines()
    if command == 'release':
        CHANGELOG.write_text('\n'.join(release(lines, version)) + '\n')
    elif command == 'notes':
        print('\n'.join(notes(lines, version)).strip())
    else:
        sys.exit(f'bosun.changelog: unknown command {command}')


if __name__ == '__main__':
    main(*sys.argv[1:])
