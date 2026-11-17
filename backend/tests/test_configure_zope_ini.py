from pathlib import Path
import subprocess
import sys


ZOPE_INI = """\
[app:zope]
use = egg:Zope#main

[filter:translogger]
use = egg:Paste#translogger

[pipeline:main]
pipeline =
    translogger
    egg:Zope#httpexceptions
    zope
"""


SCRIPT = Path(__file__).parents[1] / "scripts" / "configure_zope_ini.py"


def run_configurator(config, **kwargs):
    return subprocess.run(  # noqa: S603
        [sys.executable, str(SCRIPT), str(config)],
        **kwargs,
    )


def test_configure_zope_ini_adds_datadog_filter_and_pipeline_entry(tmp_path):
    config = tmp_path / "zope.ini"
    config.write_text(ZOPE_INI)

    run_configurator(config, check=True)
    configured = config.read_text()

    assert (
        "[filter:ddtrace]\n"
        "paste.filter_factory = procergs.sitebase.dd_wsgi:filter_factory\n"
        "\n"
    ) in configured
    assert configured.count("    ddtrace\n") == 1
    assert configured.index("    ddtrace\n") < configured.index("    translogger\n")


def test_configure_zope_ini_is_idempotent(tmp_path):
    config = tmp_path / "zope.ini"
    config.write_text(ZOPE_INI)

    run_configurator(config, check=True)
    configured = config.read_text()
    run_configurator(config, check=True)

    assert config.read_text() == configured


def test_configure_zope_ini_rejects_missing_pipeline(tmp_path):
    config = tmp_path / "zope.ini"
    config.write_text("[app:zope]\nuse = egg:Zope#main\n")

    result = run_configurator(
        config,
        capture_output=True,
        text=True,
    )

    assert result.returncode != 0
    assert "[pipeline:main]" in result.stderr
