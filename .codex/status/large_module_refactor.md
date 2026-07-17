# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operational-feedback callback ownership mapping.

Status:
Ready for publication.

Selected slice:
Point the campaign-strategy operational-feedback callback directly at
`Schema.OperationalFeedbackContracts.validate/3` and remove the pure wrapper.

Why this slice:
`Schema` remains a 7,853-line hotspot. Broad mapping confirms one callback
capture plus one pure exact-signature delegate.

Public facade to preserve:
All Schema APIs, campaign-strategy validator argument order, exact issues and
messages, JSON Schema and checked export bytes, and feedback behavior.

Definition of done:
The direct callback remains the first strategy-specific validator argument,
immediately before branch and recommendation callbacks; the wrapper is absent;
focused/full/schema proof and review remain clean.

Verification gaps:
None.

Tests run:
- Source baseline: one strategy callback capture and one pure delegate.
- Focused repair/strategy baseline: 2 tests passed with warnings as errors.
- Generated bundle: 121 schemas, 15,506,740 bytes, digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Checked bundle digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.
- Source proof against `d0e908c6`: the direct owner callback remains first
  before branch/recommendation callbacks and the wrapper is absent.
- Focused repair/strategy tests: 2 passed; complete schema/export suite: 182
  passed, all with warnings as errors.
- Generated bundle remains exact; export regeneration produced no schema diff
  and checked digest is unchanged.
- Strict compile, format, xref, and diff hygiene passed.
- Independent review against `d0e908c6` was clean across callback order,
  focused 2, complete 182, all 122 exports, digests, strict compile, xref,
  formatting, sizes, ledger, and hygiene.

Behavior/schema changes:
None.

Outcome:
The strategy validator references the established owner directly and wrapper is
gone. `schema.ex` decreased from 7,853 to 7,845 lines.

Last completed slice:
Provider-counteroffer report cleanup published as `09224bd4`: `schema.ex`
shrank from 7,861 to 7,853 lines, focused 6 and complete 182 tests passed, all
122 exports byte-matched, and review was clean.

Next candidate:
After review and publication, continue the robust exact-signature inventory.

Blocked:
No.
