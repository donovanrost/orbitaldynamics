defmodule OrbitalDynamics.CampaignPlanner.BranchComparisonContextFieldValuesTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.{BranchComparisonContext, PlanBranch}
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

  test "requires both endpoints on every source window for complete timing coverage" do
    partial_branch =
      branch_with_events([
        %{"source_window_id" => "window_a", "starts_at_s" => 10.0},
        %{"source_window_id" => "window_b", "ends_at_s" => 40.0}
      ])

    assert %{
             "branch_source_window_count" => 2,
             "branch_source_window_bound_count" => 2,
             "branch_untimed_source_window_count" => 0,
             "branch_source_window_timing_coverage_status" => "partial"
           } = BranchComparisonContext.event_fields(partial_branch)

    complete_branch =
      branch_with_events([
        %{
          "source_window_id" => "window_a",
          "starts_at_s" => 10.0,
          "ends_at_s" => 20.0
        },
        %{
          "source_window_id" => "window_b",
          "starts_at_s" => 30.0,
          "ends_at_s" => 40.0
        }
      ])

    assert %{"branch_source_window_timing_coverage_status" => "complete"} =
             BranchComparisonContext.event_fields(complete_branch)
  end

  defp branch_with_events(events) do
    %PlanBranch{
      id: "timing_coverage_branch",
      repair_result: %{},
      score: 0.0,
      score_terms: %{},
      events: events
    }
  end
end
