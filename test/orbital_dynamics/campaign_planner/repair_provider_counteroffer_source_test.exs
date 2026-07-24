defmodule OrbitalDynamics.CampaignPlanner.RepairProviderCounterofferSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical provider-counteroffer reports" do
    report = %{
      "schema_contract" => "provider_counteroffer_report.v1",
      "source" => "station_calendar_report.affected_contacts",
      "counteroffer_count" => 1
    }

    assert RepairSourceReports.provider_counteroffer(%{
             "source_provider_counteroffer_report" => report
           }) == report

    assert RepairSourceReports.provider_counteroffer(%{
             "source_provider_counteroffer_report" => [report]
           }) == report

    assert RepairSourceReports.provider_counteroffer(%{
             "provider_counteroffer_report" => report
           }) == report
  end

  test "returns nil when candidate refresh has no provider-counteroffer report" do
    assert RepairSourceReports.provider_counteroffer(%{}) == nil
    assert RepairSourceReports.provider_counteroffer(nil) == nil
  end

  test "resolves source, collected, and canonical provider-counteroffer plan-impact summaries" do
    summary = %{
      "schema_contract" => "provider_counteroffer_plan_impact_summary.v1",
      "plan_impact_status" => "review_required",
      "impact_counteroffer_ids" => ["provider_offer_1"]
    }

    assert RepairSourceReports.provider_counteroffer_plan_impact(%{
             "source_provider_counteroffer_plan_impact_summary" => summary
           }) == summary

    assert RepairSourceReports.provider_counteroffer_plan_impact(%{
             "source_provider_counteroffer_plan_impact_summary" => [summary]
           }) == summary

    assert RepairSourceReports.provider_counteroffer_plan_impact(%{
             "provider_counteroffer_plan_impact_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no provider-counteroffer plan impact" do
    assert RepairSourceReports.provider_counteroffer_plan_impact(%{}) == nil
    assert RepairSourceReports.provider_counteroffer_plan_impact(nil) == nil
  end
end
