# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-intent callback-bag and policy-field ownership collapse.

Status:
Complete and ready to publish.

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
The 21-entry bag and every contact-intent lookup/apply trampoline are gone.
Primitive, collection, stable-ID, interval, station-calendar count, capability,
approval-requirement, and policy-decision ownership is direct. Nine policy
field lists moved unchanged into one shared owner used by validators and JSON
schema generation. Candidate refresh now calls contact intent directly and
retains only its two genuine report hooks. `schema.ex` fell from 11,079 to
10,818 lines and the contact-intent owner from 334 to 268; including the new
257-line policy owner and four-line candidate-refresh reduction, the slice is a
net 74-line reduction. Nine hundred eighty-four focused, 1,340 attributable
broader, and 24 export tests pass; compile, checked-in regeneration,
compile-connected xref within its existing three-edge threshold, format, and
diff hygiene are clean. Bounded review found no blocker and confirmed exact
pipeline/order/paths/messages, all nine ordered policy lists and group shapes,
direct capability/policy behavior, JSON-schema inputs, hook reduction, and
orphan cleanup.

Verification gaps:
- Full repository suite not run.
- The 1,345-test broader batch has the same five known campaign-planner baseline
  failures previously reproduced on pre-slice commit `6f1f0ac1`; the
  attributable result is 1,340/1,340.

Last completed slice:
Candidate-refresh callback collapse published as `9cb88173`: `schema.ex` fell
from 11,185 to 11,079 lines; the 27-entry factory and six orphan forwarders
disappeared. Nine hundred forty-eight focused, 1,340 attributable broader, and
24 export tests passed; compile, regeneration, xref, format, diff hygiene, and
bounded review were clean.

Blocked:
No.
