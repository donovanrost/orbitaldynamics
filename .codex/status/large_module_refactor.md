# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline throughput-context extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move `activity_throughput_context/1` and its private throughput lookup and
data-rate derivation helpers into `Timeline.ThroughputContext.build/2`.
`OrbitalDynamics.Timeline` retains every public function and supplies its
existing `first_number`, `first_value`, `stringify_keys`, `delta`,
`completion_fraction`, and `compact_map` behavior through callbacks.

Why this slice:
The refreshed production inventory makes the 9,657-line `Timeline` the
largest cohesive implementation hotspot outside the callback-heavy Schema
facade. The selected approximately 113-line cluster has one responsibility:
normalize declared throughput evidence or deterministically derive actual
throughput from an actual data rate and duration. It has two facade callers
and focused regression coverage, while avoiding lifecycle, diff, integrity,
and schema ownership.

Planned proof:
- Focused Timeline tests covering throughput projection, numeric-string
  normalization, data-rate derivation, and throughput-sensitive diffs.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for the exact five-key projection and all moved
  derivation clauses after normalizing only callback boundaries.
- Format, diff, whitespace, ownership, caller, public-definition, and xref
  checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
CadenceImport operational-feedback manifest-context extraction, implementation
published in `ea240845` and handoff published in `46ba5c39`.

Next candidate:
Remap Timeline after this slice; likely link-context or station-calendar
context if the live dependency boundary remains cohesive.

Blocked:
No.
