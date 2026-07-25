defmodule OrbitalDynamics.CampaignPlanner.RepairContactIntentSummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical contact-intent summaries" do
    summary = %{
      "schema_contract" => "contact_intent_summary.v1",
      "direction_routing" => %{"downlink" => %{"contact_ids" => ["contact_1"]}}
    }

    assert RepairSourceReports.contact_intent_summary(%{
             "source_contact_intent_summary" => summary
           }) == summary

    assert RepairSourceReports.contact_intent_summary(%{
             "source_contact_intent_summary" => [summary]
           }) == summary

    assert RepairSourceReports.contact_intent_summary(%{
             "contact_intent_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no contact-intent summary" do
    assert RepairSourceReports.contact_intent_summary(%{}) == nil
    assert RepairSourceReports.contact_intent_summary(nil) == nil
  end
end
