defmodule OrbitalDynamics.CampaignPlanner.RepairModelAcceptanceSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical model-acceptance reports" do
    report = %{
      "schema_contract" => "model_acceptance_report.v1",
      "intended_use" => "operational_import",
      "status" => "blocked"
    }

    assert RepairSourceReports.model_acceptance(%{
             "source_model_acceptance_report" => report
           }) == report

    assert RepairSourceReports.model_acceptance(%{
             "source_model_acceptance_report" => [report]
           }) == report

    assert RepairSourceReports.model_acceptance(%{"model_acceptance_report" => report}) ==
             report
  end

  test "returns nil when candidate refresh has no model-acceptance report" do
    assert RepairSourceReports.model_acceptance(%{}) == nil
    assert RepairSourceReports.model_acceptance(nil) == nil
  end
end
