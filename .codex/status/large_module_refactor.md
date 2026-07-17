# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-intent callback ownership handoff.

Status:
Published as `6ba7ee63`.

Selected slice:
Point all three facade uses of `validate_contact_intent/3` directly at
`Schema.ContactIntentContracts.validate/3`: the standalone `contact_intent.v1`
contract pipe and the campaign-plan and campaign-repair callback-bag captures.
Remove the pure wrapper while preserving pipeline and callback ordering.

Why this slice:
`Schema` remains a named 7,942-line production hotspot. The established owner
already exposes the exact `/3` implementation, and live inspection found a
bounded direct-call plus two callback-capture boundary.

Current coupling/problem:
Standalone and nested campaign validation still route through a pure facade
wrapper even though all three uses can reference the established owner without
changing the callback contract.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, callback keys and ordering, exact
validation issue ordering, paths and messages, JSON Schema output, checked-in
export bytes, and contact-intent behavior.

Likely extraction target:
Existing `OrbitalDynamics.Schema.ContactIntentContracts.validate/3`.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact pipeline stage, callback keys and neighboring bag entries, and
  wrapper-removal proof
- focused communications, campaign-plan, and campaign-repair source-handoff
  contract tests
- complete schema-contract/export tests and full checked-in export regeneration
- aggregate generated and checked-in schema bundle digests
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The standalone contact-intent pipe ends at the established owner with unchanged
arguments; both callback bags capture that same owner under the unchanged key
and between the same neighboring entries; the wrapper is gone; issue ordering,
messages, and schema bytes are unchanged; tests pass; and review finds no
blocker.

Verification gaps:
None.

Tests run:
- Source baseline: `validate_contact_intent/3` is the final standalone pipe
  stage after `require_fields`, is captured once in
  `campaign_plan_contract_callbacks/0` between proposed-contact and optional
  contact-filter entries, is captured once in
  `campaign_repair_contract_callbacks/0` between activity and resource-summary
  entries, and has one pure facade definition.
- Focused communications, campaign-plan, and campaign-repair source-handoff
  baseline: 11 tests passed with warnings as errors.
- Generated 121-schema bundle JSON byte digest:
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`
  across 15,506,740 bytes.
- Checked-in `schemas/orbital_dynamics.schema_bundle.v1.json` digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.
- Source proof against selection commit `2870d928`: the standalone pipe retains
  `require_fields` and ends at `ContactIntentContracts.validate/3`; both
  callback bags retain the same key and neighbors while capturing that owner;
  the private facade delegate is absent.
- Focused communications, campaign-plan, and campaign-repair source-handoff
  tests: 11 passed with warnings as errors.
- Complete schema-contract and schema-export suite: 182 tests passed with
  warnings as errors.
- Generated bundle remains exactly 121 schemas, 15,506,740 bytes, and digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Full checked-in schema export regeneration completed with no schema diff;
  aggregate bundle digest remains
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review against selection commit `2870d928` was clean:
  exact pipeline arguments, callback keys and neighbors, unchanged owner,
  delegate removal, 11 focused and 182 complete tests, generated and checked
  bundle digests, all 122 exports byte-matched, strict compile, xref,
  formatting, sizes, ledger, and diff hygiene matched the recorded evidence.

Behavior/schema changes:
None.

Outcome:
All three facade uses now reference the established contact-intent owner
directly and the pure wrapper is gone. `schema.ex` decreased from 7,942 to
7,934 lines.

Last completed slice:
Contact-intent-summary wrapper cleanup published as `45e4e439`: the standalone
pipe now points directly at the established owner, `schema.ex` shrank from
7,950 to 7,942 lines, 8 focused and 182 complete tests passed, all 122 exports
byte-matched, and bounded review was clean.

Next candidate:
Map the single-use `validate_station_calendar_provider/3` facade delegate. Its
only caller is the final stage of the standalone `station_calendar_provider.v1`
pipe after `require_fields`, and the established owner exposes the exact
`StationCalendarProviderContracts.validate/3` implementation. Capture the
focused provider-contract and schema-byte baselines before replacing it.

Blocked:
No.
