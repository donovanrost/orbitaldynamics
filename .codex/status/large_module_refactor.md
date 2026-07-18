# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline station-calendar context extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move `station_calendar_context/1`, source-overlap expiration lookup, number-list
normalization, reservation-expiration aggregation, direction normalization,
nested entry-ID flattening, and calendar ID-list normalization into
`Timeline.StationCalendarContext.build/2`. `Timeline` retains all public
functions plus shared numeric parsing, JSON encoding, stable-ID validation,
ID-list normalization, and map compaction behind callbacks.

Why this slice:
After the throughput extraction, the 9,556-line Timeline facade remains the
largest cohesive implementation hotspot outside Schema. This approximately
230-line cluster owns one artifact projection: the 22 direct station-calendar
fields plus deterministic normalization of nested entry, direction,
expiration, and stable-ID evidence. It has two facade callers and focused
regression coverage. Shared `numeric_value/1` and `vector_norm/1` remain with
execution-uncertainty math, avoiding a mixed ownership boundary.

Planned proof:
- Focused Timeline tests covering reservation ownership/expiration,
  stable-ID-list cleanup, nested entry flattening, and diff sensitivity.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for the exact projection and every moved clause
  after normalizing only callback boundaries.
- Format, diff, whitespace, ownership, caller, public-definition, and xref
  checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline throughput-context extraction, implementation published in `545b4848`
and handoff published in `2c33c26b`.

Next candidate:
Remap the reduced Timeline facade after this slice; execution-uncertainty
context is the leading smaller candidate.

Blocked:
No.
