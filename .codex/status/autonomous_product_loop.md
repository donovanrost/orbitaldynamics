# Autonomous Product Loop Status

Current slice:
Advertise activity-template provenance as a timeline row semantic.

Status:
Implemented, verified, and read-only reviewed.

What changed:
- Added `:activity_template_provenance` to `Timeline.capabilities/0`
  row semantics.
- Added focused test coverage for the advertised row semantic.
- Documented guarded `activity_template.v1` provenance preservation in mission
  activity rows, timeline integrity review rows, and contact-intent activity
  context.
- Updated near-term planning candidate docs to reflect the implemented baseline
  template catalog and remaining follow-on catalog expansion.

Verification:
- `mix test test/orbital_dynamics/timeline_test.exs:10` -> 1 passed, 124
  excluded.
- `mix format lib/orbital_dynamics/timeline.ex
  test/orbital_dynamics/timeline_test.exs --check-formatted` -> pass.
- `git diff --check` -> pass.

Read-only review:
Sidecar `019e9c9b-5bc3-7032-b706-96ae64ca74b4` reported one low handoff
accuracy issue: ledger status was stale after implementation. This update fixes
that before commit.

Implementation commit:
Pending.

Last completed implementation commit:
`3de21c0d40223c92b67861c8528f324daf6b6c7f` pushed to `origin/main`.

Last ledger correction commit:
`d0360f63654394baca67c217c78b7a519f5eeb85` pushed to `origin/main`.

Next candidate:
After this slice, move to the resource/communications allocation queue unless a
new activity-template handoff gap appears.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.
