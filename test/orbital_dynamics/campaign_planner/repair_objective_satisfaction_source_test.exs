defmodule OrbitalDynamics.CampaignPlanner.RepairObjectiveSatisfactionSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical objective-satisfaction reports" do
    report = %{
      "schema_contract" => "objective_satisfaction_report.v1",
      "rows" => [%{"objective" => "target_coverage", "status" => "partial"}]
    }

    assert RepairSourceReports.objective_satisfaction(%{
             "source_objective_satisfaction_report" => report
           }) == report

    assert RepairSourceReports.objective_satisfaction(%{
             "source_objective_satisfaction_report" => [report]
           }) == report

    assert RepairSourceReports.objective_satisfaction(%{
             "objective_satisfaction_report" => report
           }) == report
  end

  test "returns nil when candidate refresh has no objective-satisfaction report" do
    assert RepairSourceReports.objective_satisfaction(%{}) == nil
    assert RepairSourceReports.objective_satisfaction(nil) == nil
  end
end
