# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema provider-counteroffer report ownership handoff.

Status:
Published as `09224bd4`.

Selected slice:
Point the standalone `provider_counteroffer_report.v1` pipe directly at
`Schema.ProviderCounterofferReportContracts.validate/3` and remove the pure
facade delegate.

Why this slice:
`Schema` remains a 7,861-line hotspot. Broad search confirms one final pipe and
one exact-signature wrapper.

Public facade to preserve:
All Schema APIs, final pipe position, exact issues/messages, JSON Schema and
checked export bytes, and provider-counteroffer report behavior.

Definition of done:
The pipe retains `require_fields`, calls the established owner in the same final
position, the wrapper is absent, focused/full/schema proof is exact, and review
is clean.

Verification gaps:
None.

Tests run:
- Source baseline: one standalone final pipe and one pure delegate.
- Focused station-provider baseline: 6 tests passed with warnings as errors.
- Generated bundle: 121 schemas, 15,506,740 bytes, digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Checked bundle digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.
- Source proof against `83404d40`: the pipe retains `require_fields`, ends at
  `ProviderCounterofferReportContracts.validate/3`, and wrapper is absent.
- Focused station-provider tests: 6 passed; complete schema/export suite: 182
  passed, all with warnings as errors.
- Generated bundle remains exact; export regeneration produced no schema diff
  and checked digest is unchanged.
- Strict compile, format, xref, and diff hygiene passed.
- Independent review against `83404d40` was clean across source ownership,
  focused 6, complete 182, all 122 exports, digests, strict compile, xref,
  formatting, sizes, ledger, and hygiene.

Behavior/schema changes:
None.

Outcome:
The pipe references the established owner and wrapper is gone. `schema.ex`
decreased from 7,861 to 7,853 lines.

Last completed slice:
Provider-counteroffer summary family published as `d1d12861`: `schema.ex`
shrank from 7,879 to 7,861 lines, focused 6 and complete 182 tests passed, all
122 exports byte-matched, and review was clean.

Next candidate:
Map the strategy validator's single `validate_operational_feedback/3` callback
capture. Broad search shows one capture plus one pure exact-signature delegate
to `OperationalFeedbackContracts.validate/3`; capture its neighboring callback
positions and focused strategy behavior before selection.

Blocked:
No.
