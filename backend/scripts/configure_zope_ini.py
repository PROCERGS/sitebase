#!/usr/bin/env python
"""Add the optional Datadog WSGI filter to a generated Paste configuration."""

from __future__ import annotations

import argparse
from pathlib import Path
import re


DDTRACE_FACTORY = "procergs.sitebase.dd_wsgi:filter_factory"
DDTRACE_FILTER_SECTION = "filter:ddtrace"
PIPELINE_SECTION = "pipeline:main"
ACCESS_LOG_HANDLER_SECTION = "handler_accesslog"
GENERIC_FORMATTER_SECTION = "formatter_generic"
GENERIC_FORMAT = (
    "%(asctime)s %(levelname)-5s "
    "[dd.service=%(dd.service)s dd.env=%(dd.env)s "
    "dd.trace_id=%(dd.trace_id)s dd.span_id=%(dd.span_id)s] "
    "[%(name)s:%(lineno)s] (%(threadName)s) %(message)s"
)
GENERIC_DATEFMT = "%Y-%m-%dT%H:%M:%S%z"


def _section_starts(lines: list[str]) -> list[tuple[int, str]]:
    starts = []
    for index, line in enumerate(lines):
        match = re.fullmatch(r"\[([^\]]+)\]", line.strip())
        if match:
            starts.append((index, match.group(1)))
    return starts


def _section_range(lines: list[str], name: str) -> tuple[int, int] | None:
    starts = _section_starts(lines)
    for position, (start, section_name) in enumerate(starts):
        if section_name == name:
            end = starts[position + 1][0] if position + 1 < len(starts) else len(lines)
            return start, end
    return None


def _ensure_filter_section(lines: list[str]) -> list[str]:
    section = _section_range(lines, DDTRACE_FILTER_SECTION)
    if section is not None:
        start, end = section
        factory_values = []
        for line in lines[start + 1 : end]:
            key, separator, value = line.partition("=")
            if separator and key.strip() == "paste.filter_factory":
                factory_values.append(value.strip())
        if factory_values != [DDTRACE_FACTORY]:
            raise ValueError(
                f"[{DDTRACE_FILTER_SECTION}] must define "
                f"paste.filter_factory = {DDTRACE_FACTORY}"
            )
        return lines

    pipeline = _section_range(lines, PIPELINE_SECTION)
    if pipeline is None:
        raise ValueError(f"missing [{PIPELINE_SECTION}] section")

    pipeline_start, _ = pipeline
    lines[pipeline_start:pipeline_start] = [
        f"[{DDTRACE_FILTER_SECTION}]",
        f"paste.filter_factory = {DDTRACE_FACTORY}",
        "",
    ]
    return lines


def _ensure_pipeline_entry(lines: list[str]) -> list[str]:
    section = _section_range(lines, PIPELINE_SECTION)
    if section is None:
        raise ValueError(f"missing [{PIPELINE_SECTION}] section")

    start, end = section
    assignments = [
        index
        for index in range(start + 1, end)
        if lines[index].strip().startswith("pipeline")
        and lines[index].partition("=")[0].strip() == "pipeline"
    ]
    if len(assignments) != 1:
        raise ValueError(f"[{PIPELINE_SECTION}] must define exactly one pipeline")

    assignment = assignments[0]
    if lines[assignment].partition("=")[2].strip():
        raise ValueError("inline pipeline values are not supported")

    for index in range(end - 1, assignment, -1):
        if lines[index].strip() == "ddtrace":
            del lines[index]

    section = _section_range(lines, PIPELINE_SECTION)
    if section is None:
        raise ValueError(f"missing [{PIPELINE_SECTION}] section")
    _, end = section
    indent = "    "
    for line in lines[assignment + 1 : end]:
        if line.strip() and not line.lstrip().startswith("#"):
            indent = line[: len(line) - len(line.lstrip())]
            break
    lines.insert(assignment + 1, f"{indent}ddtrace")
    return lines


def _set_section_option(
    lines: list[str],
    section_name: str,
    option_name: str,
    value: str,
) -> list[str]:
    section = _section_range(lines, section_name)
    if section is None:
        raise ValueError(f"missing [{section_name}] section")

    start, end = section
    assignments = [
        index
        for index in range(start + 1, end)
        if lines[index].partition("=")[0].strip() == option_name
    ]
    if len(assignments) > 1:
        raise ValueError(f"[{section_name}] must define {option_name} at most once")

    if assignments:
        index = assignments[0]
        indent = lines[index][: len(lines[index]) - len(lines[index].lstrip())]
        lines[index] = f"{indent}{option_name} = {value}"
    else:
        lines.insert(end, f"{option_name} = {value}")
    return lines


def _ensure_logging_format(lines: list[str]) -> list[str]:
    lines = _set_section_option(
        lines,
        GENERIC_FORMATTER_SECTION,
        "format",
        GENERIC_FORMAT,
    )
    lines = _set_section_option(
        lines,
        GENERIC_FORMATTER_SECTION,
        "datefmt",
        GENERIC_DATEFMT,
    )
    return _set_section_option(
        lines,
        ACCESS_LOG_HANDLER_SECTION,
        "formatter",
        "generic",
    )


def configure_zope_ini(content: str) -> str:
    """Return a Paste configuration with the Datadog filter enabled."""
    newline = "\r\n" if "\r\n" in content else "\n"
    trailing_newline = content.endswith(("\n", "\r"))
    lines = content.splitlines()
    lines = _ensure_filter_section(lines)
    lines = _ensure_pipeline_entry(lines)
    lines = _ensure_logging_format(lines)
    result = newline.join(lines)
    return result + (newline if trailing_newline else "")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("path", type=Path)
    args = parser.parse_args()

    try:
        content = args.path.read_text()
        configured = configure_zope_ini(content)
        args.path.write_text(configured)
    except (OSError, ValueError) as error:
        parser.error(str(error))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
