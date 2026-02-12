# Changelog

<!--
   You should *NOT* be adding new change log entries to this file.
   You should create a file in the news directory instead.
   For helpful instructions, please see:
   https://github.com/plone/plone.releaser/blob/master/ADD-A-NEWS-ITEM.rst
-->

<!-- towncrier release notes start -->

## 1.0.0 (2026-02-12)

{% if sections[] %}
{% for category, val in definitions.items() if category in sections[] %}

### {{ definitions[category]['name'] }}

{% for text, values in sections[][category].items() %}
- {{ text }} {{ values|join(', ') }}
{% endfor %}

{% endfor %}
{% else %}
No significant changes.


{% endif %}
