defmodule OrbitalDynamics.CampaignPlanner.RepairTimelineActivityStatesSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "preserves every activity, status, and approval state in stable family order" do
    source_activity = %{schema_contract: "timeline_activity_state.v1", activity_id: "source"}

    canonical_activity = %{
      "schema_contract" => "timeline_activity_state.v1",
      "activity_id" => "canonical"
    }

    source_status = %{
      "schema_contract" => "timeline_activity_status_state.v1",
      "activity_id" => "source_status"
    }

    canonical_status = %{
      "schema_contract" => "timeline_activity_status_state.v1",
      "activity_id" => "canonical_status"
    }

    source_approval = %{
      "schema_contract" => "timeline_activity_approval_state.v1",
      "activity_id" => "source_approval"
    }

    canonical_approval = %{
      "schema_contract" => "timeline_activity_approval_state.v1",
      "activity_id" => "canonical_approval"
    }

    assert RepairSourceReports.timeline_activity_states(%{
             source_timeline_activity_state: [source_activity],
             timeline_activity_state: canonical_activity,
             source_timeline_activity_status_state: source_status,
             timeline_activity_status_state: [canonical_status],
             source_timeline_activity_approval_state: [source_approval],
             timeline_activity_approval_state: canonical_approval
           }) == [
             %{"schema_contract" => "timeline_activity_state.v1", "activity_id" => "source"},
             canonical_activity,
             source_status,
             canonical_status,
             source_approval,
             canonical_approval
           ]
  end

  test "returns an empty list without activity-state evidence" do
    assert RepairSourceReports.timeline_activity_states(%{}) == []
    assert RepairSourceReports.timeline_activity_states(nil) == []
  end
end
