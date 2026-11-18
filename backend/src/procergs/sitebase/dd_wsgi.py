"""Opt-in Datadog WSGI instrumentation."""

from __future__ import annotations

import os
from typing import Any


_TRUE_VALUES = frozenset({"1", "on", "true", "yes"})


def _tracing_enabled() -> bool:
    value = os.getenv("DD_TRACE_ENABLED", "")
    return value.strip().lower() in _TRUE_VALUES


def filter_factory(global_conf: Any, **local_conf: Any):
    """Create the Paste filter, enabling Datadog only when explicitly requested."""

    from ddtrace import patch

    patch(logging=True)

    def filter_app(app):
        if not _tracing_enabled():
            return app

        from ddtrace.contrib.wsgi import DDWSGIMiddleware

        return DDWSGIMiddleware(app)

    return filter_app
