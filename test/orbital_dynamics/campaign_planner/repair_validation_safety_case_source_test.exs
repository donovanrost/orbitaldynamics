defmodule OrbitalDynamics.CampaignPlanner.RepairValidationSafetyCaseSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical validation-safety-case summaries" do
    summary = %{
      "schema_contract" => "validation_safety_case_summary.v1",
      "summary_id" => "validation_safety_case:example",
      "status" => "blocked"
    }

    assert RepairSourceReports.validation_safety_case(%{
             "source_validation_safety_case_summary" => summary
           }) == summary

    assert RepairSourceReports.validation_safety_case(%{
             "source_validation_safety_case_summary" => [summary]
           }) == summary

    assert RepairSourceReports.validation_safety_case(%{
             "validation_safety_case_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no validation safety case" do
    assert RepairSourceReports.validation_safety_case(%{}) == nil
    assert RepairSourceReports.validation_safety_case(nil) == nil
  end
end
