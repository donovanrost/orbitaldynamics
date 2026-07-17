# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-intent callback-bag and policy-field ownership collapse.

Status:
Selected; implementation not started.

Selected slice:
Replace the 21-entry `ContactIntentContracts` keyword bag with direct shared
owners, extract policy context/action-rule field groups from `schema.ex`, and
let candidate refresh call the contact-intent owner directly.

Why this slice:
Live inventory leaves `schema.ex` at 11,079 lines. The 334-line contact-intent
owner routes 21 dependencies through lookup/apply even though primitives,
stable IDs, intervals, station-calendar counts, and policy validators already
have extracted owners. Policy field groups remain duplicated configuration in
the facade, preventing direct policy validation and keeping contact intent as
one of candidate refresh's three explicit hooks.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, all contact-intent and
candidate-refresh fields, exact paths/messages/order, consumers, deterministic
artifacts, and schema exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/contact_intent_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_contracts.ex`
- one shared policy field-group owner under `lib/orbital_dynamics/schema/`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused contact-intent and candidate-refresh tests
- broader campaign-planner/operator-review/schema regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No contact-intent keyword bag or lookup/apply trampolines remain; policy field
groups have one extracted owner; candidate refresh directly validates contact
intents and retains only its two genuine report hooks; focused, broader, and
export checks pass; and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Not yet verified.

Last completed slice:
Candidate-refresh callback collapse published as `9cb88173`: `schema.ex` fell
from 11,185 to 11,079 lines; the 27-entry factory and six orphan forwarders
disappeared. Nine hundred forty-eight focused, 1,340 attributable broader, and
24 export tests passed; compile, regeneration, xref, format, diff hygiene, and
bounded review were clean.

Blocked:
No.
