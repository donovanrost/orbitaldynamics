defmodule OrbitalDynamics.CampaignPlanner.RepairOperationalQualityGateOperatorTrainingSummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical operator-training quality-gate summaries" do
    summary = %{
      "schema_contract" => "operational_quality_gate_operator_training_summary.v1",
      "operator_training_requirement_count" => 5,
      "required_operator_roles" => ["contact_operator", "mission_director"]
    }

    assert RepairSourceReports.operational_quality_gate_operator_training_summary(%{
             "source_operational_quality_gate_operator_training_summary" => summary
           }) == summary

    assert RepairSourceReports.operational_quality_gate_operator_training_summary(%{
             "source_operational_quality_gate_operator_training_summary" => [summary]
           }) == summary

    assert RepairSourceReports.operational_quality_gate_operator_training_summary(%{
             "operational_quality_gate_operator_training_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no operator-training quality-gate summary" do
    assert RepairSourceReports.operational_quality_gate_operator_training_summary(%{}) == nil
    assert RepairSourceReports.operational_quality_gate_operator_training_summary(nil) == nil
  end
end
