# 21. Developer and User Experience

## Status: **implemented**

### Public APIs, examples, and docs

- Public Elixir APIs for propagation, study running, reports, benchmark tasks, study manifests, manifest linting, campaign planning, repair, strategy, timeline feedback, operational timeline reports, and artifact schema validation.
- Examples in `README.md`.
- Docs for mission-planning spec, LEO campaign planner, and canonical artifact examples.

### Checked Level 5 workflow

- [`level5_workflow.md`](../level5_workflow.md) is the supported V1/V2/V3 Level 5 workflow index. Its checked JSON block pins existing `study.run` and `campaign.run` tasks and argv, all direct and referenced inputs, output contracts and versions, capability discovery, schema policy versions, deterministic run/generated timestamps where supported, and actionable failure remediation.
- The focused workflow test parses that JSON block, validates every link, task, input, live capability/schema version, and expected contract, then runs V1 study, V2 repair, and V3 strategy synchronously into one temporary output root without changing checked fixtures.
- The same permanent proof builds an opt-in hard-eligibility V3 strategy and verifies identical full-artifact/direct-manifest `CadenceImport.dry_run/3` conformance, idempotency, source identity, and immutable authority evidence through an exact no-write test adapter. No new CLI or production executor is introduced.

### Campaign lint and run tasks

- **`mix orbital_dynamics.campaign.lint --type repair|strategy`** — validates V2/V3 campaign request JSON files without running planning, including:
  - request type,
  - JSON object shape,
  - `source_plan_ref` resolution,
  - artifact-key lookup,
  - and source campaign-plan contract checks,
  - with text or JSON reports.
- **`mix orbital_dynamics.campaign.lint --output`** — writes `campaign_request_lint.v1` reports for import-gate pipelines, with executable integer `error_count`, `lint_task`, and `semantic_validator` validation matching the exported JSON Schema.
- **`mix orbital_dynamics.campaign.run --type repair|strategy`** — executes checked-in V2/V3 campaign request JSON files:
  - resolves `source_plan_ref`,
  - preflights the request through the same campaign lint path before planning,
  - validates the generated artifact contract,
  - writes compact artifact JSON,
  - and supports `--format json` summaries for automation.

### Manifest lint and reference tasks

- **`Study.Manifest.validation_report/1`** and **`mix orbital_dynamics.manifest.lint --format json`** — provide machine-readable manifest lint status, including:
  - executable `error_count` / `warning_count` summaries,
  - error codes,
  - lint-task and schema export command metadata,
  - executable validator metadata,
  - supported output/propagator/objective lists,
  - and a first-class `study_manifest_lint.v1` report contract that preserves `manifest_schema_contract: study_manifest.v1` for the manifest being checked.
- **`mix orbital_dynamics.manifest.lint --output`** — writes the same report for preflight automation.
- **`mix orbital_dynamics.manifest.reference --format json`** — provides a compact manifest field reference derived from the exported JSON Schema.
- **`mix orbital_dynamics.manifest.reference --output`** — writes that reference for docs and import-gate automation.
- The generated reference is now lintable as `manifest_field_reference.v1` while preserving `schema_contract: study_manifest.v1` as the schema being described.

### Operator-review package provenance

- The `operator_review_package.v1` schema now exposes package-level provenance fields for source plans, repairs, strategies, nested source provenance, and candidate-source handoff metadata, with stable-ID validation for the identifier fields.
- Operator-review package rows and Cadence import manifest rows now reject duplicate row IDs during executable validation, so review/import queues have stable row identities, not just stable ID shapes.

### Cadence import contracts and provenance

- Cadence import capability metadata declares the `record_preserved_executed_activity` action that plan-delta imports emit for already-executed timeline preservation, so adapter implementations can rely on the advertised action list.
- Every advertised Cadence import supported-source contract now has an executable fixture compatibility check that builds and validates an import manifest, including:
  - checked-in result-artifact wrappers for V1 campaign and candidate-refresh outputs,
  - standalone proposed-contact rows inferred from their nested Cadence import contract,
  - and JSON-decoded null values normalized before review/import rows are validated.
- Cadence import rows that embed `source_review_row` now:
  - validate and export JSON Schema coverage for the embedded row's `id`, `review_type`, and `action`,
  - require dependent `source_review_type` and `source_review_action` adapter fields in the exported schema,
  - and validate that `source_review_row_id`, `source_review_type`, and `source_review_action` match those embedded values.
- Import-manifest generators populate `source_review_action` from the embedded review row's `action` before falling back to generic `required_operator_action`, preserving the import-to-review join without requiring Cadence adapters to trust duplicated fields blindly.

### Cadence import trust boundaries

- Cadence import manifest rows, operator-review rows, and operational timeline rows that declare provider, adapter, or adapter-version metadata now require a direct `cadence_import_trust_boundary` or `cadence_import_provenance.trust_boundary` in both executable validation and exported JSON Schema coverage.
- The same adapter trust-boundary condition is exposed in executable validation and exported nested JSON Schema for:
  - planned/candidate activity `cadence_import` objects,
  - proposed-contact `cadence_import` objects,
  - optional contact-intent and realized-activity `cadence_import` objects,
  - plus plan-delta nested planned activity and reusable activity-context `cadence_import` objects.
- Operational timeline rows and V2 plan-delta activity contexts preserve malformed non-object Cadence import context as explicit invalid import evidence, instead of letting nested adapter metadata crash normalization before schema validation.

### Manifest schema nested coverage

The `study_manifest.v1` JSON Schema export includes nested coverage for:

- candidate-refresh accepted planning-state artifacts,
- simple orbit-data rows,
- remaining-horizon fields,
- ground-network entries,
- resource summaries,
- resource filter policies,
- candidate limit policies,
- operational feedback,
- prior candidates,
- and mission-plan activity provider-shaped `target`, `station`, `ground_station`, `spacecraft`, and `satellite` identity objects.

### Schema and policy export output

- `mix orbital_dynamics.schema.export`, `mix orbital_dynamics.manifest.schema.export`,
  and `mix orbital_dynamics.policy.export` preserve caller-selected output paths
  and canonical JSON bytes while publishing each output file through a
  same-directory temp file and rename under a cooperative local-filesystem,
  single-writer envelope. This path does not hold anchored directory handles and
  does not claim protection against hostile concurrent ancestor or target swaps.
- Existing regular-file outputs can be replaced. Symlink targets or ancestors,
  broken symlink targets or ancestors, directory/device/special targets,
  malformed paths, and path/content resource bounds fail closed before
  destination writes. The only ancestor-symlink admission path is a closed
  root-level system directory alias rule: the alias and resolved directory chain
  must be root-owned, not group/world-writable, exist, and match the expected
  directory target. The direct root-alias readlink target is checked for path
  bounds and relative escapes, normalized lexically, and must equal the expected
  target before any target path is lstat/stat checked. No intermediate alias
  hops are followed. The concrete checked regression is the macOS `/var` to
  `/private/var` `System.tmp_dir` alias; pathname `/var` alone is not
  authority. Alias readlink/lstat/stat errors, relative escapes, target
  mismatches, mutable aliases, and caller-owned aliases fail closed.
- Failed parent creation, temp open/write, or rename leaves the destination
  unchanged. Owned-temp cleanup is attempted; a cleanup failure is reported as a
  typed `temporary_cleanup_failed` result and may leave residue.
- Invalid or unsafe export destinations deliberately raise `ArgumentError` from
  the CLI exporters, replacing prior raw filesystem exception surfacing for this
  hardened path.

### Schema lint tasks and reports

- **`Schema.validation_report/2`** and **`mix orbital_dynamics.schema.lint --format json`** — provide schema-validated artifact lint reports with stable path/message issue rows.
- **`mix orbital_dynamics.schema.lint --output`** — writes those reports as `schema_validation_report.v1` artifacts with schema-visible `model_limits` for import-gate pipelines and executable validation against the emitted schema-validation model limits, with exported JSON Schema constraining those report-level and nested validation-report `model_limits` arrays as the same exact string set.
- **`mix orbital_dynamics.schema.lint --all --input-dir study_results`** — validates the checked-in artifact-contract directory in one pass and reports a batch pass/fail `schema_validation_batch_report.v1` artifact with nested `schema_validation_report.v1` entries, while skipping non-artifact manifest-schema files through explicit skipped-file rows.
- The checked-in `study_results/schema_validation_batch_report_v1.json` fixture now makes that directory-level gate lintable alongside the artifacts it summarizes, with the same exact schema-validation `model_limits` boundary declared at the batch top level.

### Schema-validation report behavior

- Standalone schema-validation batch reports now normalize failing nested reports into typed operator-review and Cadence import validation gates while preserving the batch entry path.
- Executable validation now enforces validation-report and batch-report summary counts plus validated schema versions as integers, and derives standalone validation-report status/counts from issue/remediation rows.
- Schema-validation reports now emit remediation categories for:
  - missing required fields,
  - type mismatches,
  - constant mismatches,
  - unsupported enum-like values,
  - contract-inference failures,
  - unsupported contracts,
  - and fallback semantic validation failures.
- Contract-inference failures remain schema-valid reports with `validated_contract: unknown`.
- `study_results` artifact lint now treats the generated manifest field reference as a validated artifact instead of a skipped JSON file.

### Top-level facades

- **`OrbitalDynamics.validate_artifact/2`**, **`OrbitalDynamics.schema_validation_report/2`**, **`OrbitalDynamics.artifact_json_schema/1`**, and **`OrbitalDynamics.artifact_json_schema_bundle/0`** facades expose the same validation and compatibility-schema boundary for application callers.
- Standalone schema-validation reports now normalize into `schema_validation_review` operator-review rows and `review_schema_validation` Cadence import gates with `schema_validation_gate=artifact_contract_validation`, gate status, and issue count, while preserving issue, remediation, and full source-report context for adapter queues.

### Capability and dependency discovery

- **`OrbitalDynamics.capability_catalog/0`** exposes through one public discovery point the declared:
  - analysis, planning, operations including Cadence import manifests,
  - all scalar/Nx/EXLA propagator capability records,
  - deterministic search generator capabilities,
  - artifact-metric constraint capabilities,
  - executable schema-registry capability metadata with contract lists and policy versions,
  - persisted result/benchmark report capabilities,
  - and environment model/provider capability metadata.
- **`OrbitalDynamics.capability_catalog_artifact/0`** exposes the same discovery payload as lintable `capability_catalog.v1`.
- **`OrbitalDynamics.dependency_policy/0`** exposes the numerical backend package policy that keeps Nx required while Nx-backed modules compile unconditionally and leaves EXLA optional for experimental accelerator backends.

### Refresh and automation tasks

- **`mix orbital_dynamics.study.run --run-id`** and **`mix orbital_dynamics.study.demo --run-id`** support repeatable artifact refreshes.
- **`mix orbital_dynamics.study.run --retry-failed-from SOURCE --output NEW`**
  validates the source result artifact against the current manifest, retries
  only its failed scenario IDs/indexes in source-manifest order, records source
  path/SHA/run provenance, and requires a separate output so failure evidence is
  not overwritten. It is mutually exclusive with checked-artifact `--resume`.
- **`mix orbital_dynamics.study.run --checkpoint PATH`** creates an opt-in local
  between-scenario checkpoint; **`--resume-checkpoint PATH`** integrity-checks
  and reuses completed outcomes, runs only missing manifest indexes, and reports
  exact reuse/run counts. Both are separate from whole-artifact resume and
  failed-scenario retry, and reject batch/distributed modes and output aliases.
- **`mix orbital_dynamics.schema.export --all --directory`** supports checked-in per-contract schema refreshes.
- **`mix orbital_dynamics.policy.export`** refreshes the complete checked-in built-in policy bundle fixture set.
- **`mix orbital_dynamics.capabilities --format json`** exposes the same public capability catalog artifact for automation without hand-written `mix run -e` wrappers.
- Study run `--format json` provides an automation-friendly summary after writing the artifact.
- Test coverage across the current slice.

## Status: **partial**

- API docs are uneven.
- The manifest schema export has concrete nested coverage for the highest-traffic manifest sections, and the generated field reference now exposes:
  - parent paths,
  - top-level sections,
  - array-item markers,
  - object-level required-child lists,
  - direct and `allOf`-wrapped `anyOf` required alternatives,
  - embedded artifact `schema_contract_ref` values,
  - nested-contract lists,
  - numeric map `additional_properties_type` hints,
  - stable public-ID patterns for ID-like fields and dependency ID arrays,
  - trust-boundary source hints for imported state rows that accept either direct `trust_boundary` or `provenance.trust_boundary`,
  - numeric bounds,
  - executable row-count consistency,
  - duplicate-path and parent-path integrity checks,
  - top-level required-field and activation-section consistency,
  - supported output/propagator/objective vocabulary consistency with schema enum rows,
  - a schema-visible `supported` object shape,
  - section/array-item consistency,
  - and row-level routing-field checks for CLI and adapter tooling.
- But it still is not a complete semantic contract for every nested campaign, repair, or strategy payload.
- Error messages are practical but not yet a polished user contract.
- Manifest linting remains the executable semantic gate.

## Status: **near-term**

- Canonical feature docs.
- Broader schema validation/lint command coverage.
- More examples per maturity level beyond the checked V1/V2/V3 path.

## Status: **later**

- Generated docs.
- Cookbook examples.
- Release compatibility guide.
- Stable public API versioning.

## Status: **out of scope**

- A full Cadence UI or broad product website in this repo.
