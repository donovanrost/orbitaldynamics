defmodule OrbitalDynamics.CampaignPlanner.RepairCandidateRefreshProvenanceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "preserves the exact non-empty CandidateRefresh provenance map" do
    provenance = %{
      run_id: "run:refresh:1",
      manifest: %{study: "leo_constellation"},
      source_reports: %{
        freshness_report: %{paths: ["study_results/freshness_report_v1.json"], count: 1}
      },
      run_input_sources: %{campaign_request: ["studies/leo_campaign.json"]}
    }

    assert RepairSourceReports.candidate_refresh_provenance(%{provenance: provenance}) == %{
             "run_id" => "run:refresh:1",
             "manifest" => %{"study" => "leo_constellation"},
             "source_reports" => %{
               "freshness_report" => %{
                 "paths" => ["study_results/freshness_report_v1.json"],
                 "count" => 1
               }
             },
             "run_input_sources" => %{
               "campaign_request" => ["studies/leo_campaign.json"]
             }
           }
  end

  test "omits absent, empty, or invalid CandidateRefresh provenance" do
    assert RepairSourceReports.candidate_refresh_provenance(nil) == nil
    assert RepairSourceReports.candidate_refresh_provenance(%{}) == nil
    assert RepairSourceReports.candidate_refresh_provenance(%{provenance: %{}}) == nil
    assert RepairSourceReports.candidate_refresh_provenance(%{provenance: []}) == nil
  end
end
