# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Cadence-import-manifest callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 18-entry callback bag in `CadenceImportManifestContracts` with
direct primitive, stable-ID, collection, and quality-gate-handoff owners while
retaining explicit row, expiration-handoff, and suppression-group validators.

Why this slice:
Live inventory leaves `schema.ex` at 11,719 lines. The 328-line manifest owner
still receives 18 opaque entries even though most point to shared validators or
the now-direct quality-gate-handoff owner. Keeping only its three genuine
composition validators explicit removes the bag without flattening row or
contact/suppression ownership into the manifest.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and every Cadence import manifest
validation path, including contract/model/stable IDs, scalar/count maps,
reservation and quality-gate handoffs, model limits/assumptions, import rows,
suppression groups, derived counts, exact messages/error order, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/cadence_import_manifest_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused readiness/schema/quality-gate replay/operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No Cadence-import-manifest callback bag or lookup/apply trampolines remain;
direct shared/handoff owners preserve validation while row, expiration, and
suppression validators remain explicit boundaries; focused, broader, and export
checks pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Quality-gate-handoff callback collapse published as `d1094610`: `schema.ex`
fell from 11,733 to 11,719 lines and its owner from 212 to 174. The 7-entry bag
became direct primitive/stable-ID owners plus exact local optional array-map
composition. 183 focused, 1,167 broader, and 22 export tests passed; compile,
xref, format, diff hygiene, checked-in regeneration, and bounded review were
clean.

Blocked:
No.
