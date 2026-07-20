# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema trust-boundary status count-map routing.

Status:
Completed and pushed.

Selected boundary:
Expose the existing three-state trust-boundary status count-map schema from
`OperationalReadinessContextJsonSchema`, route the facade's lazy and eager
consumers directly to that owner, and remove the duplicate facade helper.
Preserve callback timing, enum values, public Schema APIs, generated JSON
Schema, executable validation, and checked-in exports.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,934 lines; the other
  targeted public facades are now 164 to 524 lines.
- The facade helper has eight consumers and duplicates the exact existing
  `declared`/`missing`/`untrusted` non-negative count-map shape in the
  operational-readiness context owner.
- The owner API remains zero-arity, preserving both callback timing and eager
  evaluation.
- The distinct strategy recommendation shape intentionally permits only
  `declared`/`missing` and remains out of scope.
- Context-bearing shared-schema helpers remain out of scope.

Implementation:
Made the existing operational-readiness trust-boundary status count-map owner
function directly reusable, routed seven lazy callbacks and one eager facade
consumer to it, and removed the duplicate facade schema. Provider keys remain
unchanged. `schema.ex` moved from 5,934 to 5,927 lines.

Verification:
- Strict focused export/communications/Cadence/review/resource baseline before
  routing: 35 passed.
- The same strict focused suite after routing: 35 passed.
- Strict checked-in export, timeline-report, and review/import handoff
  coverage: 15 passed.
- The full schema-export task completed and produced no checked-in changes.
- Exact static inspection confirms seven direct lazy callbacks, one direct
  eager call, three unchanged provider keys, and zero facade helper references.
- `mix xref callers
  OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema` reports the
  expected Schema facade and internal schema-owner consumers.
- `git diff --check` passed.
- Strict forced compile passed across 4,072 files.
- Implementation commit `13ccc089` pushed to `main`.

Behavior/schema changes:
None. The `declared`/`missing`/`untrusted` enum and non-negative integer value
shape, callback timing, provider keys, public Schema APIs, executable
validation, and checked-in exports remain unchanged. The separate two-state
strategy schema remains untouched.

Last completed slice:
Schema trust-boundary status count-map routing, selected in `e71931de` and
implemented in `13ccc089`.
`schema.ex` moved from 5,934 to 5,927 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.
