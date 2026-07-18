# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema main candidate-refresh property-dispatch extension.

Status:
Implementation published as `725a1184`; handoff publication pending.

Selected slice:
Move JSON-property dispatch/context assembly for the main candidate-refresh
contract into the existing internal `Schema.CandidateRefreshPropertyDispatch`
owner.

Why this slice:
`Schema` is 7,755 lines. The main candidate-refresh clause still assembles a
12-key context despite the newly extracted diff and auxiliary refresh family
having a dedicated owner.

Current coupling/problem:
The facade owns focused routing plus lazy lineage, invalidation, activity,
contact, resource, validation, model-limit, feedback, provider-action,
safety-count, and embedded-contract providers.

Public facade to preserve:
All `Schema` APIs; the candidate-refresh JSON Schema document; checked-in
exports, deterministic ordering, focused fallback behavior, lazy context order,
and all errors.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_property_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The main clause passes compact dependencies to the existing owner; named
context and focused fallback routing move out of `Schema`; focused
candidate-refresh and export tests pass; strict compile, full byte-clean schema
regeneration, and independent review are clean.

Verification gaps:
- None for this slice. Full checked-in schema regeneration is byte-identical.
- Independent review was clean. No API, schema, export, ordering,
  error-behavior, ownership, or behavioral finding remains.

Tests run:
- Baseline and post-change focused candidate-refresh/provenance/export subset:
  26 passed with warnings as errors.
- Strict forced compile: 3,661 files clean with warnings as errors.
- Full schema export regenerated every checked-in schema and bundle with zero
  diff.
- Public `Schema` definitions match selection commit `a262b4f9`; xref reports
  the dispatcher has only the `Schema` runtime caller.
- Format, changed-file whitespace, and `git diff --check` passed.
- Independent review confirmed the exact 12-key lazy context order, unchanged
  provider-action closure, untouched existing family and adjacent routes, then
  reran all proof clean.

Behavior/schema changes:
None intended.

Outcome:
The main candidate-refresh route now delegates to the existing
`CandidateRefreshPropertyDispatch`. Implementation published as `725a1184`.

Last completed slice:
Candidate-refresh diff/auxiliary schema dispatch published as implementation
`872b34a8` and handoff `90c9114a`: focused 26/26, strict 3,661-file compile,
full byte-clean schema regeneration, and independent review passed.

Next candidate:
After this slice, remap the remaining direct property clauses in `Schema`.

Blocked:
No.
