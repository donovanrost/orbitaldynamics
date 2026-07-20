# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema optional policy-escalation validation direct routing.

Status:
Completed and pushed.

Selected boundary:
Remove the Schema facade's one-hop optional policy-escalation validation
wrapper.
Route its three callback-map captures directly to
`PolicyValidation.validate_optional_escalation/4`.
Keep callback-map composition, policy validators that add facade-owned model
limits/field groups, and all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,092 lines.
- The wrapper forwards the same four arguments to PolicyValidation and adds no
  guards, defaults, callbacks, path adaptation, or result transformation.
- Three callback maps can capture the existing owner API directly.
- Exact callback arity/timing, issue ordering, paths/messages, validation
  results, and checked-in schema exports must remain unchanged.

Implementation:
Removed the one-hop optional policy-escalation validation wrapper and routed
all three callback-map captures directly to PolicyValidation.
`schema.ex` moved from 6,092 to 6,089 lines.

Verification:
- Strict focused Cadence-import/Cadence-row/operator-review/validation-policy/
  policy baseline before routing: 9 passed.
- The same strict focused suite after routing: 9 passed.
- Strict full schema-export task plus adjacent JSON Schema export,
  contact-feedback, and fixture-visibility coverage: 22 passed.
- `mix xref callers OrbitalDynamics.Schema.PolicyValidation` reports
  `lib/orbital_dynamics/schema.ex (runtime)`.
- Static search confirms the wrapper definition and all indirect captures are
  gone.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `d62e1c35` pushed to `main`.

Behavior/schema changes:
None. Public facades, callback arity/timing, issue ordering, paths/messages,
validation behavior, and checked-in exports remain unchanged.

Last completed slice:
Schema optional policy-escalation validation direct routing, selected in
`04ccebf0` and implemented in `d62e1c35`.
`schema.ex` moved from 6,092 to 6,089 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
