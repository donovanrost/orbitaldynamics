defmodule OrbitalDynamics.CampaignPlanner.RepairTimelineActivityLifecycleStatesSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "preserves every source and canonical activity-lifecycle state in source order" do
    source_a = %{
      schema_contract: "timeline_activity_lifecycle_state.v1",
      activity_id: "cmd_source_a"
    }

    source_b = %{
      "schema_contract" => "timeline_activity_lifecycle_state.v1",
      "activity_id" => "cmd_source_b"
    }

    canonical = %{
      "schema_contract" => "timeline_activity_lifecycle_state.v1",
      "activity_id" => "cmd_canonical"
    }

    assert RepairSourceReports.timeline_activity_lifecycle_states(%{
             source_timeline_activity_lifecycle_state: [source_a, source_b],
             timeline_activity_lifecycle_state: canonical
           }) == [
             %{
               "schema_contract" => "timeline_activity_lifecycle_state.v1",
               "activity_id" => "cmd_source_a"
             },
             source_b,
             canonical
           ]
  end

  test "returns an empty list without activity-lifecycle states" do
    assert RepairSourceReports.timeline_activity_lifecycle_states(%{}) == []
    assert RepairSourceReports.timeline_activity_lifecycle_states(nil) == []
  end
end
