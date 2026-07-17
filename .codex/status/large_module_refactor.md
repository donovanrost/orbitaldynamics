# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-integrity-evidence callback ownership mapping.

Status:
Ready for implementation.

Selected slice:
Point both captures of `validate_timeline_integrity_evidence/3` directly at
`Schema.TimelineIntegrityEvidenceContracts.validate/3` and remove the wrapper.

Why this slice:
`Schema` remains a 7,813-line hotspot. Structural mapping confirms two captures
and one pure exact-signature delegate.

Public facade to preserve:
All Schema APIs, callback order, exact issues/messages, JSON Schema and checked
exports, and operational/transition integrity-evidence behavior.

Definition of done:
Operational timeline evidence remains after optional preconditions/context and
before identity; transition selected activity evidence remains final after
optional context. Both capture the owner, wrapper is absent, and proof is exact.

Verification gaps:
- Implementation and post-change verification pending.

Tests run:
- Source baseline: two captures and one pure delegate at positions above.
- Focused operational-timeline plus timeline-report baseline: 10 tests passed
  with warnings as errors.
- Generated bundle: 121 schemas, 15,506,740 bytes, digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Checked bundle digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.

Behavior/schema changes:
None.

Outcome:
No timeline-integrity-evidence implementation has started.

Last completed slice:
Timeline-transition trio published as `fb19b31b`: `schema.ex` shrank from 7,837
to 7,813 lines, focused 8 and complete 182 tests passed, all 122 exports
byte-matched, and review was clean.

Next candidate:
Implement both direct captures and remove the wrapper.

Blocked:
No.
