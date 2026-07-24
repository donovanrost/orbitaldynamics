defmodule OrbitalDynamics.CampaignPlanner.RepairConstraintSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical constraint reports" do
    report = %{
      "schema_contract" => "constraint_report.v1",
      "rows" => [%{"constraint_id" => "minimum_operational_altitude"}]
    }

    assert RepairSourceReports.constraint(%{"source_constraint_report" => report}) == report

    assert RepairSourceReports.constraint(%{"source_constraint_report" => [report]}) == report

    assert RepairSourceReports.constraint(%{"constraint_report" => report}) == report
  end

  test "returns nil when candidate refresh has no constraint report" do
    assert RepairSourceReports.constraint(%{}) == nil
    assert RepairSourceReports.constraint(nil) == nil
  end
end
