defmodule OrbitalDynamics.CampaignPlanner.RepairTimelinePublicationSummariesSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "preserves every source and canonical publication summary in source order" do
    source_a = %{
      schema_contract: "timeline_publication_summary.v1",
      publication_id: "publication:source_a"
    }

    source_b = %{
      "schema_contract" => "timeline_publication_summary.v1",
      "publication_id" => "publication:source_b"
    }

    canonical = %{
      "schema_contract" => "timeline_publication_summary.v1",
      "publication_id" => "publication:canonical"
    }

    assert RepairSourceReports.timeline_publication_summaries(%{
             source_timeline_publication_summary: [source_a, source_b],
             timeline_publication_summary: canonical
           }) == [
             %{
               "schema_contract" => "timeline_publication_summary.v1",
               "publication_id" => "publication:source_a"
             },
             source_b,
             canonical
           ]
  end

  test "returns an empty list without publication summaries" do
    assert RepairSourceReports.timeline_publication_summaries(%{}) == []
    assert RepairSourceReports.timeline_publication_summaries(nil) == []
  end
end
