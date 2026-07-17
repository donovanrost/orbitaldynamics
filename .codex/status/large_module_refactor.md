# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema plan-delta callback ownership handoff.

Status:
Published as `fb837511`.

Selected slice:
Point both facade uses of `validate_plan_delta/3` directly at
`Schema.PlanDeltaContracts.validate/3`: the standalone final pipe and the
campaign-repair callback capture. Remove the pure wrapper.

Why this slice:
`Schema` remains a 7,887-line hotspot. Broad bare-name mapping confirms one
standalone use, one callback capture, and one pure exact-signature wrapper.

Public facade to preserve:
All Schema APIs, callback key/order, exact issue ordering/messages, JSON Schema
and checked export bytes, and standalone/nested plan-delta behavior.

Definition of done:
The standalone pipe retains `require_fields`; the repair callback key remains
between optional station-calendar report and approval requirement; both
reference `PlanDeltaContracts.validate/3`; the wrapper is absent; all proof and
review remain clean.

Verification gaps:
None.

Tests run:
- Source baseline: one standalone pipe, one campaign-repair callback capture,
  and one pure wrapper.
- Focused campaign repair/strategy baseline: 2 tests passed with warnings as
  errors and covers standalone plus nested plan deltas.
- Generated bundle: 121 schemas, 15,506,740 bytes, digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Checked bundle digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.
- Source proof against `48e5a3d9`: standalone and repair callback uses reference
  `PlanDeltaContracts.validate/3` in their original positions; wrapper absent.
- Focused repair/strategy tests: 2 passed; complete schema/export suite: 182
  passed, all with warnings as errors.
- Generated bundle remains exact; export regeneration produced no schema diff
  and checked digest is unchanged.
- Strict compile, format, xref, and diff hygiene passed.
- Independent review against `48e5a3d9` was clean across both positions,
  focused 2, complete 182, all 122 exports, digests, strict compile, xref,
  formatting, sizes, ledger, and hygiene.

Behavior/schema changes:
None.

Outcome:
Both facade uses reference the owner and the wrapper is gone. `schema.ex`
decreased from 7,887 to 7,879 lines.

Last completed slice:
Resource-summary cleanup published as `405b94cd`: `schema.ex` shrank from 7,895
to 7,887 lines, corrected focused 8 and complete 182 tests passed, all 122
exports byte-matched, and bounded review was clean.

Next candidate:
Map the cohesive provider-counteroffer summary family: standalone review,
import-readiness, and plan-impact pipes each have a single pure exact-signature
facade delegate to `ProviderCounterofferSummaryContracts`. Confirm all bare-name
caller counts and use the focused station-provider contracts before selection.

Blocked:
No.
