# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational-readiness-evidence callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 11-entry callback bag in `OperationalReadinessEvidenceContracts`
with direct primitive owners, exact local stable sorting/sum/error behavior, and
two explicit validator boundaries for resource and timeline-publication context.

Why this slice:
Live inventory leaves `schema.ex` at 11,860 lines. The 531-line readiness-
evidence owner has nine shared/pure bag entries and only two real orchestration
hooks. Making those two functions explicit preserves dependency injection while
removing lookup/apply trampolines and keeping evidence aggregation ownership in
the extracted module.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and every readiness resource,
timeline-publication, evidence/count-map, and gate-derived validation path,
including optional fields, exact messages/error order, stable ID ordering,
numeric/count-map aggregation, quality-gate behavior, replay consumers, and
exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/operational_readiness_evidence_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused readiness/schema/quality-gate replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No readiness-evidence callback bag or lookup/apply trampolines remain; shared
primitive and exact local helpers preserve gate/evidence aggregation behavior;
the resource and timeline validators remain explicit boundaries; focused,
broader, and export checks pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Operational-readiness-context callback collapse published as `fc0ddf20`:
`schema.ex` fell from 11,876 to 11,860 lines and its owner from 355 to 293. The
7-entry bag became direct primitive/stable-ID owners plus an exact local sum.
61 focused, 1,054 broader, and 22 export tests passed; compile, xref, format,
diff hygiene, checked-in schema regeneration, and bounded review were clean.

Blocked:
No.
