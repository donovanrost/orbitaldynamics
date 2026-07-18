# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport contact-allocation manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `contact_allocation_manifest_row/2` and its exclusively used
`contact_allocation_import_action/1` clauses into internal
`CadenceImport.ContactAllocationManifestRow.build/3`. Inject only the four
shared facade helpers for review action, adapter status, provider-result value
normalization, and compact-map cleanup.

Why this slice:
`CadenceImport` is 6,683 lines. The contact-allocation builder is a 205-line
transformation with 185 projected keys and one facade caller.

Current coupling/problem:
The main artifact adapter embeds a large contact-allocation projection and its
provider-reservation action policy alongside every other source transformation.

Public facade to preserve:
All `CadenceImport` APIs; all contact-allocation row keys and value expressions;
approval/import defaults, provider-reservation import action, import status,
compaction, deterministic output, and artifact contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/contact_allocation_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 185-key projection and exclusive action
clauses; the facade supplies only four same-purpose callbacks; focused
Cadence-import and schema-contract tests pass; strict warnings-as-errors
compile, projection equivalence, public API checks, and independent review are
clean.

Verification gaps:
- Initial implementation compile identified two shared provider-result
  normalization calls omitted from the selection count; this correction is
  published before a successful implementation compile.
- Implementation proof, strict compile, and independent review remain.

Tests run:
- Focused baseline: 100/100.

Behavior/schema changes:
None intended.

Last completed slice:
CadenceImport strategy-tradeoff row builder published as implementation
`aec22fe0` and handoff `fa2e78d0`: focused 100/100, strict 3,677-file compile,
exact 184-entry AST/pipeline comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module and select the next source-specific
manifest-row builder.

Blocked:
No.
