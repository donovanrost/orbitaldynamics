# 22. Security, Trust, and External Input Handling

Status: **implemented** (with **partial**, **near-term**, **later**, and **out of scope** items below).

## Implemented

### Manifest decoding, validation, and linting

- Study manifests are decoded from JSON, and constructors perform basic domain validation.
- `mix orbital_dynamics.manifest.lint` validates manifests without running propagation.
- `mix orbital_dynamics.manifest.schema.export` writes the `study_manifest.v1` JSON Schema for external tooling, including nested candidate-refresh input fields.
- Manifest lint can emit a JSON validation report with stable error codes, paths, messages, executable-validator metadata, export-command metadata, and supported value lists.

### Orbit-data import provenance and trust boundaries

- Simple JSON orbit-data imports stamp deterministic adapter provenance on accepted planning-state artifacts.
- Executable validation rejects imported accepted planning-state artifacts that declare adapter/input-format provenance without a `provenance.trust_boundary`.
- The exported `accepted_planning_state.v1` JSON Schema now exposes the same conditional import-provenance trust-boundary rule.
- Standalone and nested `spacecraft_state_estimate.v1` and `maneuver_execution_delta.v1` rows now require direct or provenance-supplied trust boundaries in both executable validation and JSON Schema.

### No-network policy and result-artifact validation

- Study run assumptions and metadata declare that planning runs make no hidden network calls unless external providers are explicitly configured.
- `result_artifact.v1` validation rejects:
  - hidden network calls under offline/no-network policy;
  - negative or mismatched provider counts;
  - explicit provider rows without stable provider IDs.
- Planning artifacts record provenance and assumptions.

### Linting saved artifacts and campaign requests

- Saved campaign artifacts and accepted planning-state snapshots can be linted against executable contracts.
- V2/V3 campaign request files have a non-running lint path that validates:
  - JSON object shape;
  - request type;
  - `source_plan_ref` resolution;
  - artifact-key lookup;
  - source campaign-plan contract.
- This runs before operators run repair or strategy planning.

### Realized activity rows

- Provider-shaped `realized_activity.v1` rows that declare provider or adapter identity must also declare external identity and trust boundary before they pass import-gate validation.
- Realized rows expose actual start/end timing, completion fraction, reason, and received/ingested timestamps through the standalone schema, with executable completion-fraction bounds.
- Realized rows can declare provider-shaped `target`, `station`, `ground_station`, `spacecraft`, and `satellite` objects, whose nested identity fields are covered by JSON Schema and stable-ID validation.
- **Nested Cadence import metadata** applies the same adapter/provider trust-boundary rule when adapter context is present.

### Cadence import metadata trust boundaries

- **Proposed-contact** Cadence import metadata that declares provider or adapter identity must declare a direct or provenance-supplied trust boundary.
- **Nested activity-context** Cadence import metadata preserves partial activity identity but applies the same adapter/provider trust-boundary rule when adapter context is present.
- Generated Cadence import manifest rows preserve that adapter/provider trust context for downstream import gates.

### Station-calendar provider inputs

- Declared `station_calendar_provider.v1` inputs must also declare a trust boundary either directly or in provenance before schema validation accepts provider availability or reservation overlays.
- Normalized station-calendar review rows preserve that provider provenance for downstream import gates.

### Resource summary and projection rows

- `resource_summary.v1` rows preserve declared or provenance-supplied trust boundaries as schema-visible fields while remaining planning-grade external summaries.
- Resource filter/projection rows expose declared-vs-missing trust-boundary status counts while carrying row-level resource trust provenance through approval, operator-review, and Cadence import contexts.

### Policy-adapter bundles

- Organization policy-adapter bundles that declare adapter, source, or policy-source provenance now require `provenance.trust_boundary` before schema validation accepts them.

### Network-access capability rows

- Environment model and provider capability rows with `network_access: true` now require a direct or provenance-supplied trust boundary in both runtime validation and exported JSON Schema.
- As a result, future network-backed ephemeris or Earth-orientation adapters cannot enter the capability catalog as anonymous external models or providers.

### Realized-feedback trust boundaries

- Timeline-feedback, operator-review, and Cadence-import rows that declare realized provider, adapter, or adapter-version metadata now require `realized_trust_boundary` or `realized_provenance.trust_boundary` before schema validation accepts that external feedback context.
- Standalone `realized_activity.v1` and `realized_state_snapshot.v1` activity rows now expose and enforce the same provider feedback boundary in exported JSON Schema and executable validation, requiring `external_id` plus a direct `trust_boundary` or `provenance.trust_boundary` whenever provider, adapter, adapter-version, or external-ID metadata is declared.

### Reconciliation stable-ID guards

- Timeline-feedback reconciliation also review-gates malformed provider-shaped realized `target`, `station`, `ground-station`, `spacecraft`, `satellite`, `source-window`, and `resource` identities before they can become derived `operational_feedback` keys.
- The public row-list handoff helper applies the same stable-ID guard to direct `station`, `target`, `spacecraft`, `maneuver`, `command`, and `resource` feedback keys.

### Validation reporting and remediation

- Failing `schema_validation_report.v1` artifacts now include remediation rows that classify missing required fields, type mismatches, constant mismatches, contract-inference failures, and other semantic validation failures with a concrete operator action.
- Batch validation reports flatten failing nested reports into the same review/import gate, while passing artifacts remain silent.

## Partial

- External inputs are not yet treated as a full first-class trust boundary.
- There are now lint entry points for study manifests and campaign artifacts, and orbit-data import adapters stamp input format, adapter, trust-boundary, and no-network-access provenance.
- However, broader provider provenance, backend trust, and unsafe/ambiguous input rejection policies remain incomplete.
- Result-artifact `external_provider_policy` rows now require direct or provenance-supplied trust boundaries when external providers are explicitly configured.

## Near-term

- Deeper manifest field references.
- Broader provenance conventions for all external inputs.
- Stronger enforcement around future provider adapters.

## Later

- Signed artifacts.
- Content-addressed inputs.
- Dependency/backend trust policy.
- External-provider sandboxing.
- Reproducible offline planning bundles.

## Out of scope

- Replacing enterprise security controls in Cadence or any external operations environment.
