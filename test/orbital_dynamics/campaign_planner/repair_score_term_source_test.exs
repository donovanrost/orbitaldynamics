defmodule OrbitalDynamics.CampaignPlanner.RepairScoreTermSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical score-term reports" do
    report = %{
      "schema_contract" => "score_term_report.v1",
      "rows" => [%{"scenario_id" => "leo_1", "term_key" => "target_value"}]
    }

    assert RepairSourceReports.score_term(%{"source_score_term_report" => report}) == report
    assert RepairSourceReports.score_term(%{"source_score_term_report" => [report]}) == report
    assert RepairSourceReports.score_term(%{"score_term_report" => report}) == report
  end

  test "returns nil when candidate refresh has no score-term report" do
    assert RepairSourceReports.score_term(%{}) == nil
    assert RepairSourceReports.score_term(nil) == nil
  end
end
