from pathlib import Path
import subprocess
import sys


ZOPE_INI = """\
[app:zope]
use = egg:Zope#main

[filter:translogger]
use = egg:Paste#translogger

[handler_accesslog]
class = StreamHandler
args = (sys.stdout,)
level = INFO
formatter = message

[pipeline:main]
pipeline =
    translogger
    egg:Zope#httpexceptions
    zope

[formatter_generic]
format = %(asctime)s %(levelname)s %(message)s

[formatter_message]
format = %(message)s
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
    assert (
        "format = %(asctime)s %(levelname)-5s "
        "[dd.service=%(dd.service)s dd.env=%(dd.env)s "
        "dd.trace_id=%(dd.trace_id)s dd.span_id=%(dd.span_id)s] "
        "[%(name)s:%(lineno)s] (%(threadName)s) %(message)s\n"
    ) in configured
    assert "datefmt = %Y-%m-%dT%H:%M:%S%z\n" in configured
    assert "formatter = generic\n" in configured


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


def test_configure_zope_ini_rejects_missing_logging_sections(tmp_path):
    config = tmp_path / "zope.ini"
    config.write_text(
        """\
[pipeline:main]
pipeline =
    zope
"""
    )

    result = run_configurator(
        config,
        capture_output=True,
        text=True,
    )

    assert result.returncode != 0
    assert (
        "[handler_accesslog]" in result.stderr or "[formatter_generic]" in result.stderr
    )
