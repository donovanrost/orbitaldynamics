# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema base Cadence-import callback-provider extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move callback-key ordering and external contract wiring from the base list in
`cadence_import_row_contract_callbacks/0` into an internal
`Schema.CadenceImportRowCallbacks.build/1`, injecting only facade-private
validators. Preserve the existing merge with the extracted handoff provider.

Why this slice:
`Schema` is 7,447 lines. The base import registry is a 65-line responsibility
with 35 ordered callback keys, 19 stable external captures, and 16
facade-private captures.

Current coupling/problem:
The facade still owns the base Cadence-import dependency registry and callback
ordering even after the larger handoff registry was extracted.

Public facade to preserve:
All `Schema` APIs; Cadence import and source-review validation behavior;
callback keys, order, values, arities, merge behavior, error ordering,
deterministic output, and all schema exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/cadence_import_row_callbacks.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The new provider owns the exact ordered 35-key base registry and 19 external
captures; `Schema` passes only 16 private callback captures and preserves the
handoff merge; focused Cadence import, review-handoff, readiness, timeline, and
export tests pass; strict compile, full byte-clean schema regeneration, exact
registry comparison, and independent review are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, export proof, and
  independent review remain.

Tests run:
- None yet for this selected slice.

Behavior/schema changes:
None intended.

Last completed slice:
Cadence-import handoff callback provider published as implementation
`14f0715a` and handoff `13b3ae98`: focused 34/34, strict 3,669-file compile,
full byte-clean schema regeneration, exact 96-key comparison, and independent
review passed.

Next candidate:
After remapping the reduced facade, extract the operator-review row callback
registry.

Blocked:
No.
