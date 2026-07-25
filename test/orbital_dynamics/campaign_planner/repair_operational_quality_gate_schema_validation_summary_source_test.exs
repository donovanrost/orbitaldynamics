defmodule OrbitalDynamics.CampaignPlanner.RepairOperationalQualityGateSchemaValidationSummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical schema-validation quality-gate summaries" do
    summary = %{
      "schema_contract" => "operational_quality_gate_schema_validation_summary.v1",
      "schema_validation_row_count" => 1,
      "schema_validation_import_blocked" => true
    }

    assert RepairSourceReports.operational_quality_gate_schema_validation_summary(%{
             "source_operational_quality_gate_schema_validation_summary" => summary
           }) == summary

    assert RepairSourceReports.operational_quality_gate_schema_validation_summary(%{
             "source_operational_quality_gate_schema_validation_summary" => [summary]
           }) == summary

    assert RepairSourceReports.operational_quality_gate_schema_validation_summary(%{
             "operational_quality_gate_schema_validation_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no schema-validation quality-gate summary" do
    assert RepairSourceReports.operational_quality_gate_schema_validation_summary(%{}) == nil
    assert RepairSourceReports.operational_quality_gate_schema_validation_summary(nil) == nil
  end
end
