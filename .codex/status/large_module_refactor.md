# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport contact-intent manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `contact_intent_manifest_row/2` into internal
`CadenceImport.ContactIntentManifestRow.build/3`. Keep approval requirement,
rule-match, escalation, activity, normalization, and status helpers shared with
suppression and other builders; inject their exact twelve callback identities.

Why this slice:
The reduced `CadenceImport` facade is 4,909 lines. The builder has one dispatch
caller and an exact 104-key contact, calendar, reservation, result, dependency,
import, approval, and policy projection with a clear facade boundary.

Public facade to preserve:
All `CadenceImport` APIs; all 104 keys and fallback order; import-presence
classification; provider-result normalization; approval/rule/escalation
selection; activity normalization; compaction; deterministic output; and
artifact contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/contact_intent_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- `test/orbital_dynamics/cadence_import_test.exs`
- `test/orbital_dynamics/schema/cadence_import_contracts_test.exs`

Definition of done:
The internal builder owns the exact 104-key projection; shared policy and
normalization helpers stay in the facade, which supplies twelve exact callbacks;
focused tests, strict compile, equivalence/API checks, and independent review
are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, and review remain.

Behavior/schema changes:
None intended.

Last completed slice:
Proposed-contact row builder published in `f5481b14`; compact handoff published
in `dc9db652`.

Next candidate:
Remap the reduced `CadenceImport` module after this extraction.

Blocked:
No.
