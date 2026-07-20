# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema trust-boundary status count-map routing.

Status:
Selected; implementation not started.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema validation-level owner routing, selected in `d84e94f8` and implemented
in `8ede25ac`.
`schema.ex` moved from 5,941 to 5,934 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.
