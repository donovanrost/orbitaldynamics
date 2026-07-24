defmodule OrbitalDynamics.CampaignPlanner.RepairOperationalImportEligibilitySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical operational import-eligibility summaries" do
    summary = %{
      "schema_contract" => "operational_import_eligibility_summary.v1",
      "import_eligible" => true,
      "import_classification" => "importable"
    }

    assert RepairSourceReports.operational_import_eligibility(%{
             "source_operational_import_eligibility_summary" => summary
           }) == summary

    assert RepairSourceReports.operational_import_eligibility(%{
             "source_operational_import_eligibility_summary" => [summary]
           }) == summary

    assert RepairSourceReports.operational_import_eligibility(%{
             "operational_import_eligibility_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no operational import eligibility" do
    assert RepairSourceReports.operational_import_eligibility(%{}) == nil
    assert RepairSourceReports.operational_import_eligibility(nil) == nil
  end
end
