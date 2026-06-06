# Autonomous Product Loop Status

Current slice:
Advertise provider-ID routing in storage/downlink replay summaries.

Status:
Implemented, focused-verified, read-only reviewed, committed, and pushed; broader
CandidateRefresh test failure noted separately.

What changed:
CandidateRefresh capability metadata now names storage/downlink replay provider
routing maps. CandidateRefresh capability tests pin the semantic, and both the
spacecraft/payload capability map and candidate-refresh field-family docs now
describe provider ID routing alongside provider-entry routing for storage/downlink
pressure replay summaries.

Why this slice:
CandidateRefresh storage/downlink pressure replay already preserves
resource-projection provider-ID routing maps and treats them as branch-local
downlink pressure, with tests covering the runtime behavior. The high-level docs
still describe only provider-entry routing in the storage/downlink replay
surface, and capability metadata does not name provider routing for that replay
summary.

Likely files:
- `lib/orbital_dynamics/candidate_refresh.ex`
- `test/orbital_dynamics/candidate_refresh_test.exs`
- `docs/feature_set/capability_map/06_spacecraft_and_payload_modeling.md`
- `docs/artifacts/field_families/candidate_refresh_artifact.md`

Verification:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:6 test/orbital_dynamics/candidate_refresh_test.exs:12710 test/orbital_dynamics/candidate_refresh_test.exs:13005` -> 2 passed, 682 excluded.
- `mix format lib/orbital_dynamics/candidate_refresh.ex test/orbital_dynamics/candidate_refresh_test.exs --check-formatted` -> pass.
- `git diff --check` -> pass.
- `mix test test/orbital_dynamics/candidate_refresh_test.exs` -> 682/684 passed; two failures at `test/orbital_dynamics/candidate_refresh_test.exs:51916` and `test/orbital_dynamics/candidate_refresh_test.exs:51990` both fail schema validation because `contact_allocation_report.status_blocked_contact_ids` does not match row-derived values. This appears outside the provider-ID replay advertising slice.

Read-only review:
Sidecar `019e9cb3-1116-7c11-988e-72410ad8e709` reported no findings. It
confirmed the semantic name is accurate, docs mention provider IDs alongside
provider-entry IDs, existing replay tests cover both maps and provider-ID-only
pressure, and the ledger accurately records the unrelated broader
CandidateRefresh failures.

Implementation commit:
`e3592be8ca29c033be05c299740dc55c2b7c2338` pushed to `origin/main`.

Last completed implementation commit:
`e3592be8ca29c033be05c299740dc55c2b7c2338` pushed to `origin/main`.

Last ledger correction commit:
`d979c68e567c1f7fa5541a7eeeacda9a571bfb09` pushed to `origin/main`.

Next candidate:
Continue the resource/communications allocation queue after this replay contract
is advertised.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.
