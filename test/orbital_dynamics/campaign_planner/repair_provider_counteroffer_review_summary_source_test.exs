defmodule OrbitalDynamics.CampaignPlanner.RepairProviderCounterofferReviewSummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical provider counteroffer review summaries" do
    summary = %{
      "schema_contract" => "provider_counteroffer_review_summary.v1",
      "counteroffer_count" => 1,
      "counteroffer_review_status" => "review_required"
    }

    assert RepairSourceReports.provider_counteroffer_review(%{
             "source_provider_counteroffer_review_summary" => summary
           }) == summary

    assert RepairSourceReports.provider_counteroffer_review(%{
             "source_provider_counteroffer_review_summary" => [summary]
           }) == summary

    assert RepairSourceReports.provider_counteroffer_review(%{
             "provider_counteroffer_review_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no provider counteroffer review summary" do
    assert RepairSourceReports.provider_counteroffer_review(%{}) == nil
    assert RepairSourceReports.provider_counteroffer_review(nil) == nil
  end
end
