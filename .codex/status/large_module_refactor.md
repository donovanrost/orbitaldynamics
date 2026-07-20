# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema low-fanout common primitive direct routing.

Status:
Completed and pushed.

Selected boundary:
Remove five zero-context, one-hop CommonJsonSchema helpers for
number-or-number-array, probability maps, string-value maps, string-list maps,
and nested-object maps. Route their eight low-fanout consumers directly to the
same owner APIs. Keep higher-fanout common primitives, context-bearing helpers,
schema composition, executable validation, and all public facades in
`OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,024 lines.
- All five helpers call same-arity zero-context CommonJsonSchema APIs and add no
  facade state, guards, defaults, transformation, or caching.
- The six eager consumers and two lazy callbacks can route directly with
  unchanged evaluation behavior.
- Exact primitive schemas, callback timing, composed JSON Schema, validation
  results, and checked-in exports must remain unchanged.

Implementation:
Removed the five low-fanout CommonJsonSchema helpers and routed all eight
consumers directly to the owner module. `schema.ex` moved from 6,024 to 6,006
lines.

Verification:
- Strict focused feedback/Cadence/review/export baseline before routing:
  26 passed.
- The same strict focused suite after routing: 26 passed.
- Strict strategy, timeline-report, handoff, and checked-in export coverage:
  17 passed.
- The full schema-export task completed and produced no checked-in changes.
- `mix xref callers OrbitalDynamics.Schema.CommonJsonSchema` reports the
  expected facade and internal schema-owner consumers.
- Static search confirms all five helper definitions and indirect references
  are gone.
- `git diff --check` passed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `68269a68` pushed to `main`.

Behavior/schema changes:
None. Public facades, primitive schemas, eager and lazy evaluation behavior,
composed schemas, executable validation, and checked-in exports remain
unchanged.

Last completed slice:
Schema low-fanout common primitive direct routing, selected in `a00982aa` and
implemented in `68269a68`.
`schema.ex` moved from 6,024 to 6,006 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
