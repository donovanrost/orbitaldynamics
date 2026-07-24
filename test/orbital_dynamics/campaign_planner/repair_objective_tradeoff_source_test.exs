defmodule OrbitalDynamics.CampaignPlanner.RepairObjectiveTradeoffSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical objective-tradeoff reports" do
    report = %{
      "schema_contract" => "objective_tradeoff_report.v1",
      "tradeoffs" => [%{"scenario_id" => "leo_1", "rank" => 1}]
    }

    assert RepairSourceReports.objective_tradeoff(%{
             "source_objective_tradeoff_report" => report
           }) == report

    assert RepairSourceReports.objective_tradeoff(%{
             "source_objective_tradeoff_report" => [report]
           }) == report

    assert RepairSourceReports.objective_tradeoff(%{
             "objective_tradeoff_report" => report
           }) == report
  end

  test "returns nil when candidate refresh has no objective-tradeoff report" do
    assert RepairSourceReports.objective_tradeoff(%{}) == nil
    assert RepairSourceReports.objective_tradeoff(nil) == nil
  end
end
