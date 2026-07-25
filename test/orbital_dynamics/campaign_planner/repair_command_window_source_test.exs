defmodule OrbitalDynamics.CampaignPlanner.RepairCommandWindowSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical command-window reports" do
    report = %{
      "schema_contract" => "command_window_report.v1",
      "window_count" => 1
    }

    assert RepairSourceReports.command_window(%{
             "source_command_window_report" => report
           }) == report

    assert RepairSourceReports.command_window(%{
             "source_command_window_report" => [report]
           }) == report

    assert RepairSourceReports.command_window(%{
             "command_window_report" => report
           }) == report
  end

  test "returns nil when candidate refresh has no command-window report" do
    assert RepairSourceReports.command_window(%{}) == nil
    assert RepairSourceReports.command_window(nil) == nil
  end
end
