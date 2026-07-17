# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema provider-counteroffer summary ownership mapping.

Status:
Ready for publication.

Selected slice:
Point the standalone review, import-readiness, and plan-impact summary pipes
directly at their exact functions in
`Schema.ProviderCounterofferSummaryContracts`. Remove all three pure delegates.

Why this slice:
`Schema` remains a 7,879-line hotspot. Broad bare-name mapping confirms each
cohesive family member has one final pipe and one pure exact-signature delegate.

Public facade to preserve:
All Schema APIs, final pipe positions, issue ordering/messages, JSON Schema and
checked export bytes, and all three provider-counteroffer summary behaviors.

Definition of done:
Each pipe retains `require_fields`, calls its matching established owner
function in the same final position, all three delegates are absent, focused
and complete proof remains exact, and review is clean.

Verification gaps:
None.

Tests run:
- Source baseline: three standalone final pipes and three pure delegates, with
  exact owner functions `validate_review/3`, `validate_import_readiness/3`, and
  `validate_plan_impact/3`.
- Focused `station_provider_contracts_test.exs`: 6 tests passed with warnings as
  errors.
- Generated bundle: 121 schemas, 15,506,740 bytes, digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Checked bundle digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.
- Source proof against `ebdc3cc3`: all three pipes retain `require_fields`, call
  their matching established owner functions, and all delegates are absent.
- Focused station-provider tests: 6 passed; complete schema/export suite: 182
  passed, all with warnings as errors.
- Generated bundle remains exact; export regeneration produced no schema diff
  and checked digest is unchanged.
- Strict compile, format, xref, and diff hygiene passed.
- Independent review against `ebdc3cc3` was clean across all three pipes,
  focused 6, complete 182, all 122 exports, digests, strict compile, xref,
  formatting, sizes, ledger, and hygiene.

Behavior/schema changes:
None.

Outcome:
All three pipes reference their established owners and delegates are gone.
`schema.ex` decreased from 7,879 to 7,861 lines.

Last completed slice:
Plan-delta cleanup published as `fb837511`: `schema.ex` shrank from 7,887 to
7,879 lines, focused 2 and complete 182 tests passed, all 122 exports
byte-matched, and bounded review was clean.

Next candidate:
After review and publication, continue the robust exact-signature inventory.

Blocked:
No.
