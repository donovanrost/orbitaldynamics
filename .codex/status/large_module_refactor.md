# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema Cadence-import handoff callback-provider extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move callback-key ordering and external contract wiring from
`cadence_import_row_handoff_contract_callbacks/0` into an internal
`Schema.CadenceImportRowHandoffCallbacks.build/1`, injecting only
facade-private validators. Leave the separate base import callback registry
unchanged.

Why this slice:
`Schema` is 7,613 lines. The handoff registry is a 194-line responsibility with
96 ordered callback keys, 83 stable external captures, and only 13
facade-private captures.

Current coupling/problem:
The facade owns the complete Cadence-import handoff dependency registry,
callback ordering, and dozens of external handoff-contract module captures.

Public facade to preserve:
All `Schema` APIs; Cadence import and source-review validation behavior;
callback keys, order, values, arities, merge behavior, error ordering,
deterministic output, and all schema exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/cadence_import_row_handoff_callbacks.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The new provider owns the exact ordered 96-key handoff registry and 83 external
captures; `Schema` passes only 13 private callback captures; focused Cadence
import, review-handoff, readiness, timeline, and export tests pass; strict
compile, full byte-clean schema regeneration, exact registry comparison, and
independent review are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, export proof, and
  independent review remain.

Tests run:
- None yet for this selected slice.

Behavior/schema changes:
None intended.

Last completed slice:
Cadence source-review callback provider published as implementation `e9fe1aae`
and handoff `7eb48e0d`: focused 34/34, strict 3,668-file compile, full
byte-clean schema regeneration, exact 89-key comparison, and independent
review passed.

Next candidate:
After remapping the reduced facade, extract the base Cadence-import or
operator-review callback registry.

Blocked:
No.
