# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-publication-context callback ownership handoff.

Status:
Published as `b9f2988d`.

Selected slice:
Point all four captures of `validate_timeline_publication_context/3` directly at
`Schema.CandidateRefreshReportContracts.validate_timeline_publication_context/3`
and remove the pure wrapper.

Why this slice:
`Schema` remains a 7,845-line hotspot. Broad mapping confirms four captures and
one exact-signature delegate shared by a cohesive operational-readiness concern.

Public facade to preserve:
All Schema APIs, callback argument positions, exact issues/messages, JSON Schema
and checked export bytes, and readiness/quality-gate publication behavior.

Definition of done:
The owner remains the sole gate callback; second evidence callback after
resource context; final import-readiness callback after model limits; and third
quality-row callback after both handoff matchers. Wrapper is absent and all
proof/review remains exact.

Verification gaps:
None.

Tests run:
- Source baseline: four captures and one pure delegate at the positions above.
- Focused operational plus readiness baseline: 11 tests passed with warnings as
  errors.
- Generated bundle: 121 schemas, 15,506,740 bytes, digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Checked bundle digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.
- Source proof against `9cd227a7`: all four captures reference the established
  owner in their original argument positions and the wrapper is absent.
- Focused operational/readiness tests: 11 passed; complete schema/export suite:
  182 passed, all with warnings as errors.
- Generated bundle remains exact; export regeneration produced no schema diff
  and checked digest is unchanged.
- Strict compile, format, xref, and diff hygiene passed.
- Independent review against `9cd227a7` was clean across all four positions,
  focused 11, complete 182, all 122 exports, digests, strict compile, xref,
  formatting, sizes, ledger, and hygiene.

Behavior/schema changes:
None.

Outcome:
All four captures reference the established owner and wrapper is gone.
`schema.ex` decreased from 7,845 to 7,837 lines.

Last completed slice:
Operational-feedback cleanup published as `10967b5f`: `schema.ex` shrank from
7,853 to 7,845 lines, focused 2 and complete 182 tests passed, all 122 exports
byte-matched, and review was clean.

Next candidate:
Map the cohesive timeline-transition trio:
`validate_timeline_transition_application_report_counts/3`,
`validate_timeline_identity_collision_fields/3`, and
`validate_timeline_diff_row/3`. Each has one callback capture and one pure
exact-signature owner; preserve their positions in report/row callback chains
and use focused timeline-report contracts.

Blocked:
No.
