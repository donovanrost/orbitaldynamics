defmodule OrbitalDynamics.CampaignPlanner.RepairRealizedStateSnapshotSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical realized-state snapshots" do
    snapshot = %{
      "schema_contract" => "realized_state_snapshot.v1",
      "activities" => []
    }

    assert RepairSourceReports.realized_state_snapshot(%{
             "source_realized_state_snapshot" => snapshot
           }) == snapshot

    assert RepairSourceReports.realized_state_snapshot(%{
             "source_realized_state_snapshot" => [snapshot]
           }) == snapshot

    assert RepairSourceReports.realized_state_snapshot(%{
             "realized_state_snapshot" => snapshot
           }) == snapshot
  end

  test "returns nil when candidate refresh has no realized-state snapshot" do
    assert RepairSourceReports.realized_state_snapshot(%{}) == nil
    assert RepairSourceReports.realized_state_snapshot(nil) == nil
  end
end
