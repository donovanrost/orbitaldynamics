# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity lifecycle context extraction.

Status:
Complete and published.

Selected boundary:
Move conditional activity lifecycle context construction into one dedicated
module. Keep one private Timeline facade for the valid-context consumer and
route status and approval-status normalization directly through the existing
lifecycle and artifact-value policies.

Selection evidence:
- The builder conditionally emits status and approval status only when the
  activity or its metadata explicitly carries the corresponding field.
- Existing lifecycle normalization preserves defaults and provider aliases,
  while the context-specific presence check prevents implicit defaults from
  appearing in the reusable context.
- The builder has exactly one consumer in valid activity-context assembly.
- Direct existing policies satisfy the boundary without Timeline callbacks.
- The extraction should reduce the current 5,408-line Timeline while preserving
  the private coordinator seam.
- General lifecycle state normalization, transition decisions, timing, command
  windows, broad context coordination, public API, and schema remain outside the
  boundary.

Verification:
- Selection published in `a05a86dd`; implementation published in `55d76306`.
- Focused baseline and post-change lifecycle alias coverage: 2 passed.
- Strict warnings-as-errors compile: 3,798 files compiled.
- Full Timeline suite: 127 passed.
- Operational Timeline schema contracts: 36 passed.
- Canonical AST comparison: both moved functions equivalent after normalizing
  only the private helper name.
- Static checks confirmed unchanged public API, one private facade and one
  consumer, direct lifecycle normalization adapters, removal of the moved
  helper, Timeline-only runtime ownership, no temporary checker, and clean
  formatting/diff.
- Independent review: clean, with no production-code findings.
- Timeline is 5,390 lines; the extracted module is 39 lines.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity lifecycle context extraction, selected in `a05a86dd` and
implemented in `55d76306`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.
