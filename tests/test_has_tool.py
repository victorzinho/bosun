from pathlib import Path

import pytest

from bosun.has_tool import has_tool


@pytest.fixture(autouse=True)
def workdir(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
    monkeypatch.chdir(tmp_path)
    return tmp_path


def test_configured_tool(workdir: Path):
    # GIVEN
    (workdir / 'pyproject.toml').write_text('[tool.coverage.run]\nbranch = true\n')

    # WHEN / THEN
    assert has_tool('coverage')


def test_unconfigured_tool(workdir: Path):
    # GIVEN
    (workdir / 'pyproject.toml').write_text('[project]\nname = "p"\n')

    # WHEN / THEN
    assert not has_tool('coverage')


def test_no_pyproject():
    # WHEN / THEN
    assert not has_tool('coverage')
