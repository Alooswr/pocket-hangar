"""SDE pipeline: turn CCP's JSONL Static Data Export into a compact SQLite file for the app.

Bump SCHEMA_VERSION whenever a table or column the app reads changes; the app refuses to
install a database whose schema version it does not understand.
"""

SCHEMA_VERSION = 1
