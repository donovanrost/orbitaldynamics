defmodule OrbitalDynamics.CampaignPlanner.RepairTimelineActivityPreconditionSummariesSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "preserves every source and canonical activity-precondition summary in source order" do
    source_a = %{
      schema_contract: "timeline_activity_precondition_summary.v1",
      activity_id: "cmd_source_a"
    }

    source_b = %{
      "schema_contract" => "timeline_activity_precondition_summary.v1",
      "activity_id" => "cmd_source_b"
    }

    canonical = %{
      "schema_contract" => "timeline_activity_precondition_summary.v1",
      "activity_id" => "cmd_canonical"
    }

    assert RepairSourceReports.timeline_activity_precondition_summaries(%{
             source_timeline_activity_precondition_summary: [source_a, source_b],
             timeline_activity_precondition_summary: canonical
           }) == [
             %{
               "schema_contract" => "timeline_activity_precondition_summary.v1",
               "activity_id" => "cmd_source_a"
             },
             source_b,
             canonical
           ]
  end

  test "returns an empty list without activity-precondition summaries" do
    assert RepairSourceReports.timeline_activity_precondition_summaries(%{}) == []
    assert RepairSourceReports.timeline_activity_precondition_summaries(nil) == []
  end
end
