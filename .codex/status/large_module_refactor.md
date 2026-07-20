# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Ground-network communications JSON-property family extraction.

Status:
Implemented and verified.

Selected boundary:
Extract the ten contiguous command-window, station calendar/reservation,
link-capacity, relay-data-path, and contact-allocation clauses from
`JsonSchemaPropertyRouter` into a ground-network communications family owner.
Keep the parent router's exact guarded and literal clause heads/order as
delegations.

Selection evidence:
- The parent router remains 1,021 lines across 76 contract-family clauses.
- Ten adjacent clauses form a roughly 210-line ground-network communications
  boundary covering twenty related contracts.
- The bodies already delegate through focused ground-network, link, relay, and
  allocation dispatchers with shared lazy providers/context/fallback.
- No recursive parent callback or cross-family property lookup is required;
  the only shared alias is the existing timeline-context schema owner.

Implementation:
- Added a 218-line `GroundNetworkPropertyRouter` with ten mechanically moved
  ground-network communications clause bodies spanning twenty contracts.
- Kept all literal and guarded parent clause heads in place as ordered
  delegations.
- Reused shared lazy provider/context/fallback support and the existing
  timeline-context schema owner without a parent callback.
- The parent router moved from 1,021 to 914 lines.

Verification:
- Strict pre-change baseline and post-change schema/validation suite: 359 tests
  passed in each run.
- AST comparison confirmed all ten moved bodies are exact and all 76 parent
  clause heads remain in their original order.
- Full schema export regenerated 121 contract schemas and the bundle with no
  checked-in schema diff.
- `mix xref trace` confirms the ten intended family edges.
- Formatting, `git diff --check`, and bounded source/schema diff review passed.
- Strict compile passed for 4,103 files with warnings as errors.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Ground-network communications JSON-property family extraction, selected in
`eef80e1a` and implemented in `7a87bb6f`. The parent router moved from 1,021 to
914 lines.

Next candidate:
Re-rank the adjacent filter/resource/contention and objective/optimizer cohorts
for the next broad exact-body family move.

Blocked:
No.
