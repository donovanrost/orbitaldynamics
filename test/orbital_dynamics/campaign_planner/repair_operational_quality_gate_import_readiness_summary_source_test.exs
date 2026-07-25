defmodule OrbitalDynamics.CampaignPlanner.RepairOperationalQualityGateImportReadinessSummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical import-readiness quality-gate summaries" do
    summary = %{
      "schema_contract" => "operational_quality_gate_import_readiness_summary.v1",
      "import_readiness_row_count" => 1,
      "freshness_review_required" => true
    }

    assert RepairSourceReports.operational_quality_gate_import_readiness_summary(%{
             "source_operational_quality_gate_import_readiness_summary" => summary
           }) == summary

    assert RepairSourceReports.operational_quality_gate_import_readiness_summary(%{
             "source_operational_quality_gate_import_readiness_summary" => [summary]
           }) == summary

    assert RepairSourceReports.operational_quality_gate_import_readiness_summary(%{
             "operational_quality_gate_import_readiness_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no import-readiness quality-gate summary" do
    assert RepairSourceReports.operational_quality_gate_import_readiness_summary(%{}) == nil
    assert RepairSourceReports.operational_quality_gate_import_readiness_summary(nil) == nil
  end
end
