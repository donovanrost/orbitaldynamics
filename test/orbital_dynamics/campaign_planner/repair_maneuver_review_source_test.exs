defmodule OrbitalDynamics.CampaignPlanner.RepairManeuverReviewSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical maneuver-review reports" do
    report = %{
      "schema_contract" => "maneuver_review_report.v1",
      "maneuver_count" => 1
    }

    assert RepairSourceReports.maneuver_review(%{
             "source_maneuver_review_report" => report
           }) == report

    assert RepairSourceReports.maneuver_review(%{
             "source_maneuver_review_report" => [report]
           }) == report

    assert RepairSourceReports.maneuver_review(%{
             "maneuver_review_report" => report
           }) == report
  end

  test "returns nil when candidate refresh has no maneuver-review report" do
    assert RepairSourceReports.maneuver_review(%{}) == nil
    assert RepairSourceReports.maneuver_review(nil) == nil
  end
end
