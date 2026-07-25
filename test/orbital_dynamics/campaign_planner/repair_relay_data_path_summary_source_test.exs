defmodule OrbitalDynamics.CampaignPlanner.RepairRelayDataPathSummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical relay data-path summaries" do
    summary = %{
      "schema_contract" => "relay_data_path_summary.v1",
      "route_ids" => ["relay_route_1"]
    }

    assert RepairSourceReports.relay_data_path_summary(%{
             "source_relay_data_path_summary" => summary
           }) == summary

    assert RepairSourceReports.relay_data_path_summary(%{
             "source_relay_data_path_summary" => [summary]
           }) == summary

    assert RepairSourceReports.relay_data_path_summary(%{
             "relay_data_path_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no relay data-path summary" do
    assert RepairSourceReports.relay_data_path_summary(%{}) == nil
    assert RepairSourceReports.relay_data_path_summary(nil) == nil
  end
end
