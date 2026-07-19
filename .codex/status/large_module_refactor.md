# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Study.Manifest input field extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract required/optional scalar, number, boolean, string, identifier, map,
list, integer, vector, atom, station-availability, and interval field readers
into `OrbitalDynamics.Study.Manifest.InputField`. Preserve the existing private
field-reader seams in the Manifest facade.

Selection evidence:
- Live re-ranking places `study/manifest.ex` at 4,489 lines.
- The selected 4,193-4,476 helper family is a pure typed field-reader layer
  shared across manifest parsing branches.
- Manifest source routing, domain-specific assembly, run options, planning
  state interpretation, and public load/validation APIs remain in the facade.
- Field-reference normalization and validation-error shaping remain with their
  existing dedicated owners.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
ContactAllocation contact-identity extraction, selected in `452b1c23` and
implemented in `ed1e1cbd`. `communications/contact_allocation.ex` moved from
4,296 to 4,127 lines; the dedicated owner is 243 lines.

Next candidate:
Implement and verify the selected Study.Manifest input field extraction.

Blocked:
No.
