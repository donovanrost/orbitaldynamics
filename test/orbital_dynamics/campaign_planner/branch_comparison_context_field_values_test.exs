defmodule OrbitalDynamics.CampaignPlanner.BranchComparisonContextFieldValuesTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.BranchComparisonContext.FieldValues

  test "correlates partial event timing by canonical source-window identity" do
    events = [
      %{"source_window_id" => "window_b", "starts_at_s" => "20"},
      %{"source_window_id" => "window_a", "starts_at_s" => 10.0, "ends_at_s" => 50.0},
      %{"source_window_ids" => ["window_c", "window_b"], "ends_at_s" => 40.0},
      %{"source_window_id" => "window_b", "starts_at_s" => 15.0, "ends_at_s" => 35.0},
      %{"source_window_id" => "window_without_timing"},
      %{"starts_at_s" => 0.0, "ends_at_s" => 1_000.0}
    ]

    assert FieldValues.branch_source_window_bounds(events) == [
             %{
               "source_window_id" => "window_a",
               "earliest_starts_at_s" => 10.0,
               "latest_ends_at_s" => 50.0
             },
             %{
               "source_window_id" => "window_b",
               "earliest_starts_at_s" => 15.0,
               "latest_ends_at_s" => 40.0
             },
             %{"source_window_id" => "window_c", "latest_ends_at_s" => 40.0}
           ]
  end
end
