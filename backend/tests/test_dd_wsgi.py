from procergs.sitebase import dd_wsgi


def test_filter_returns_original_application_when_tracing_is_not_enabled(
    monkeypatch,
):
    monkeypatch.delenv("DD_TRACE_ENABLED", raising=False)
    app = object()

    wrapped = dd_wsgi.filter_factory({})(app)

    assert wrapped is app


def test_filter_returns_original_application_for_false_values(monkeypatch):
    app = object()

    for value in ("", "0", "false", "off", "no", "unexpected"):
        monkeypatch.setenv("DD_TRACE_ENABLED", value)
        assert dd_wsgi.filter_factory({})(app) is app


def test_filter_wraps_application_when_tracing_is_enabled(monkeypatch):
    class FakeMiddleware:
        def __init__(self, app):
            self.app = app

    monkeypatch.setenv("DD_TRACE_ENABLED", "true")
    monkeypatch.setattr(
        "ddtrace.contrib.wsgi.DDWSGIMiddleware",
        FakeMiddleware,
    )
    app = object()

    wrapped = dd_wsgi.filter_factory({})(app)

    assert isinstance(wrapped, FakeMiddleware)
    assert wrapped.app is app
