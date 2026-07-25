defmodule OrbitalDynamics.CampaignPlanner.RepairTimelinePreservationStatusesSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "preserves every source and canonical preservation status in source order" do
    source_a = %{
      schema_contract: "timeline_preservation_status.v1",
      activity_id: "source_a"
    }

    source_b = %{
      "schema_contract" => "timeline_preservation_status.v1",
      "activity_id" => "source_b"
    }

    canonical = %{
      "schema_contract" => "timeline_preservation_status.v1",
      "activity_id" => "canonical"
    }

    assert RepairSourceReports.timeline_preservation_statuses(%{
             source_timeline_preservation_status: [source_a, source_b],
             timeline_preservation_status: canonical
           }) == [
             %{
               "schema_contract" => "timeline_preservation_status.v1",
               "activity_id" => "source_a"
             },
             source_b,
             canonical
           ]
  end

  test "returns an empty list without preservation statuses" do
    assert RepairSourceReports.timeline_preservation_statuses(%{}) == []
    assert RepairSourceReports.timeline_preservation_statuses(nil) == []
  end
end
