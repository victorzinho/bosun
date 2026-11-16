from pathlib import Path

import pytest

from bosun.changelog import main

CHANGELOG = """\
# Changelog

## Unreleased

- New thing.

## 0.1.0

- First thing.
"""


@pytest.fixture(autouse=True)
def changelog(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
    monkeypatch.chdir(tmp_path)
    path = tmp_path / 'CHANGELOG.md'
    path.write_text(CHANGELOG)
    return path


def test_release_stable_adds_the_version_below_unreleased(changelog: Path):
    # WHEN
    main('release', '0.2.0')

    # THEN
    assert changelog.read_text() == CHANGELOG.replace('## Unreleased\n', '## Unreleased\n\n## 0.2.0\n')


@pytest.mark.parametrize('version', ['0.2.0rc1', '0.2.0.dev0'])
def test_release_prerelease_changes_nothing(changelog: Path, version: str):
    # WHEN
    main('release', version)

    # THEN
    assert changelog.read_text() == CHANGELOG


def test_notes_stable_prints_the_version_section(capsys: pytest.CaptureFixture[str]):
    # WHEN
    main('notes', '0.1.0')

    # THEN
    assert capsys.readouterr().out == '- First thing.\n'


def test_notes_prerelease_prints_the_unreleased_section(capsys: pytest.CaptureFixture[str]):
    # WHEN
    main('notes', '0.2.0rc1')

    # THEN
    assert capsys.readouterr().out == '- New thing.\n'


def test_notes_of_a_released_version_after_release(capsys: pytest.CaptureFixture[str]):
    # WHEN
    main('release', '0.2.0')
    main('notes', '0.2.0')

    # THEN
    assert capsys.readouterr().out == '- New thing.\n'


def test_missing_heading_exits_with_the_heading():
    # WHEN / THEN
    with pytest.raises(SystemExit, match='no `## 9.9.9`'):
        main('notes', '9.9.9')


def test_unknown_command_exits():
    # WHEN / THEN
    with pytest.raises(SystemExit, match='unknown command publish'):
        main('publish', '0.2.0')
