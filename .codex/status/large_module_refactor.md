# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-allocation validation context extraction.

Status:
Completed and pushed.

Selected boundary:
Add owner-default entry points across ContactAllocationValidation's optional
report, report, row, capacity-pack group, counts, summary families, and
duplicate evidence. Compose the callback graph entirely from existing schema
owners, route every Schema consumer directly, and remove eleven wrappers plus
the shared callback bag. Keep all callback-based owner APIs.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,707 lines; the other
  targeted public facades are now 164 to 524 lines.
- The callback bag contains only ContactAllocationValidation self-callbacks and
  existing station/contact/contention/execution/priority schema owners.
- Exact usage spans six required artifact validations, one optional report,
  nested row/group/count validation, Cadence, and operator-review callbacks.
- No callback requires recursive Schema registry validation or facade
  capability context.
- Owner-default entry points preserve every callback-based API.

Implementation:
Added owner-default entry points across ContactAllocationValidation's optional
report, report, row, capacity-pack group, counts, summary families, and
duplicate evidence. Kept all callback-based APIs, moved the complete callback
graph into the owner, added owner-default handoff allocation validation, routed
all facade consumers directly, and removed eleven wrappers plus the callback
bag. `schema.ex` moved from 5,707 to 5,576 lines.

Verification:
- Strict contact-allocation/provider/campaign/Cadence/operator-review baseline
  before extraction: 17 passed.
- The same strict focused suite after extraction: 17 passed.
- Strict checked-in export, JSON Schema export, review/import handoff,
  contact-feedback, and communications coverage: 35 passed.
- The full schema-export task completed and produced no checked-in changes.
- Exact static inspection confirms six direct required validations, one direct
  optional report, three capacity-pack callbacks, three direct handoff
  callbacks, owner-internal row/count/duplicate recursion, zero facade wrappers
  or callback bags, and retained callback-based owner APIs.
- Xref reports the expected Schema/handoff consumers for
  ContactAllocationValidation and the expected Schema/callback-builder
  consumers for ContactAllocationHandoffContracts.
- `mix format --check-formatted` and `git diff --check` passed.
- Strict forced compile passed across 4,072 files with no warnings.
- Bounded local diff review found no must-fix findings.
- Implementation commit `b255fe53` pushed to `main`.

Behavior/schema changes:
None. Model limits, nested callback behavior, issue ordering and paths,
callback-based owner entry points, public Schema APIs, validation results, and
checked-in exports remain unchanged.

Last completed slice:
Schema contact-allocation validation context extraction, selected in
`526df568` and implemented in `b255fe53`.
`schema.ex` moved from 5,707 to 5,576 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.
