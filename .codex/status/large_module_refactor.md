# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operational-timeline validation context extraction.

Status:
Completed and pushed.

Selected boundary:
Add owner-default required-report, optional-report, and row entry points to
OperationalTimelineValidation. Derive required fields, timeline model limits,
and row callbacks from existing registry/capability/timeline owners, route one
required validation plus two optional callbacks and one row callback directly,
and remove both facade wrappers. Keep the callback-based owner APIs.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,734 lines; the other
  targeted public facades are now 164 to 524 lines.
- The required validator needs only registry required fields, timeline model
  limits, and the operational row validator.
- The row wrapper supplies only TimelineContextValidation owner callbacks.
- Exact usage finds one required report, two optional report callbacks, and one
  row callback.
- Existing registry, capability, and timeline validation owners provide every
  dependency without recursive Schema lookup.
- Owner-default entry points preserve the callback-based APIs.

Implementation:
Added owner-default required-report, optional-report, and row entry points to
OperationalTimelineValidation. Kept the callback-based APIs, derived required
fields/model limits/row callbacks from existing owners, routed one required
validation and two optional facade callbacks directly, and removed the
optional-report and row wrappers. `schema.ex` moved from 5,734 to 5,707 lines.

Verification:
- Strict timeline/campaign/operator-review/Cadence baseline before extraction:
  16 passed.
- The same strict focused suite after extraction: 16 passed.
- Strict checked-in export, JSON Schema export, review/import handoff, and
  contact-feedback coverage: 27 passed.
- The full schema-export task completed and produced no checked-in changes.
- Exact static inspection confirms one direct required validation, two direct
  optional callbacks, owner-internal row routing, zero facade wrappers, and
  retained callback-based owner APIs.
- `mix xref callers OrbitalDynamics.Schema.OperationalTimelineValidation`
  reports only the expected Schema facade runtime caller.
- `mix format --check-formatted` and `git diff --check` passed.
- Strict forced compile passed across 4,072 files with no warnings.
- Bounded local diff review found no must-fix findings.
- Implementation commit `9b73959d` pushed to `main`.

Behavior/schema changes:
None. Required fields, timeline model limits, row callbacks, issue ordering and
paths, callback-based owner entry points, public Schema APIs, validation
results, and checked-in exports remain unchanged.

Last completed slice:
Schema operational-timeline validation context extraction, selected in
`68d32061` and implemented in `9b73959d`.
`schema.ex` moved from 5,734 to 5,707 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.
