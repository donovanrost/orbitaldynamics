defmodule OrbitalDynamics.OperatorReview.FreshnessBudgetTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "freshness report source ids fall back through defaults" do
    assert %{"source_artifact_id" => "freshness:report"} =
             OperatorReview.from_freshness_report(%{id: :"freshness:report"})

    assert %{"source_artifact_id" => "freshness:source"} =
             OperatorReview.from_freshness_report(%{source: :"freshness:source"})

    assert %{"source_artifact_id" => "freshness_report"} =
             OperatorReview.from_freshness_report(%{})
  end

  test "refresh budget report source ids fall back through defaults" do
    assert %{"source_artifact_id" => "refresh-budget:report"} =
             OperatorReview.from_refresh_budget_report(%{id: :"refresh-budget:report"})

    assert %{"source_artifact_id" => "refresh-budget:source"} =
             OperatorReview.from_refresh_budget_report(%{source: :"refresh-budget:source"})

    assert %{"source_artifact_id" => "refresh_budget_report"} =
             OperatorReview.from_refresh_budget_report(%{})
  end

  test "builds standalone freshness and refresh-budget review packages" do
    stale_freshness = %{
      "schema_contract" => "freshness_report.v1",
      "model" => "accepted_snapshot_horizon_and_quality_freshness",
      "generated_at" => "2026-05-14T00:00:00Z",
      "accepted_at" => "2026-05-12T00:00:00Z",
      "accepted_state_quality_level" => "planning_accepted",
      "allowed_state_quality_levels" => ["accepted"],
      "state_quality_status" => "not_accepted",
      "current_epoch_s" => 0.0,
      "horizon_starts_at_s" => 30.0,
      "accepted_snapshot_age_s" => 172_800.0,
      "horizon_start_offset_s" => 30.0,
      "max_snapshot_age_s" => 86_400.0,
      "max_horizon_start_offset_s" => 1.0,
      "status" => "stale",
      "stale_reasons" => ["accepted_snapshot_older_than_policy"],
      "unknown_reasons" => []
    }

    current_freshness = %{
      stale_freshness
      | "status" => "current",
        "stale_reasons" => [],
        "state_quality_status" => "accepted"
    }

    budget = %{
      "schema_contract" => "refresh_budget_report.v1",
      "model" => "deterministic_candidate_limit_after_filters",
      "input_candidate_count" => 3,
      "kept_candidate_count" => 2,
      "dropped_candidate_count" => 1,
      "max_candidate_activities" => 2,
      "selection_order" => "score_descending_then_start_then_id",
      "kept_candidate_ids" => ["refresh_downlink", "refresh_observe"],
      "dropped_candidate_ids" => ["old_refresh_downlink"]
    }

    empty_budget = %{budget | "dropped_candidate_count" => 0, "dropped_candidate_ids" => []}

    freshness_package = OperatorReview.from_freshness_report(stale_freshness)
    assert OrbitalDynamics.operator_review_package(stale_freshness) == freshness_package

    assert %{
             "source_artifact_type" => "freshness_report.v1",
             "review_count" => 1,
             "freshness_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "freshness_review",
                 "required_operator_action" => "review_refresh_freshness",
                 "freshness_status" => "stale",
                 "source_freshness_report" => %{"status" => "stale"}
               }
             ]
           } = freshness_package

    assert %{"review_count" => 0, "rows" => []} =
             OperatorReview.from_freshness_report(current_freshness)

    budget_package = OperatorReview.from_refresh_budget_report(budget)
    assert OrbitalDynamics.operator_review_package(budget) == budget_package

    assert %{
             "source_artifact_type" => "refresh_budget_report.v1",
             "review_count" => 1,
             "refresh_budget_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "refresh_budget_review",
                 "required_operator_action" => "review_refresh_budget",
                 "dropped_candidate_ids" => ["old_refresh_downlink"],
                 "source_refresh_budget_report" => %{
                   "schema_contract" => "refresh_budget_report.v1"
                 }
               }
             ]
           } = budget_package

    assert %{"review_count" => 0, "rows" => []} =
             OperatorReview.from_refresh_budget_report(empty_budget)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(freshness_package)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(budget_package)

    invalid_freshness_source_status_value =
      update_in(freshness_package, ["rows"], fn [row] ->
        [
          put_in(
            row,
            ["source_freshness_report", "status"],
            "freshness status with spaces"
          )
        ]
      end)

    assert {:error, invalid_freshness_source_status_value_report} =
             Schema.validate_artifact(invalid_freshness_source_status_value)

    assert Enum.any?(
             invalid_freshness_source_status_value_report["errors"],
             &(&1["path"] == "$.rows[0].source_freshness_report.status")
           )

    invalid_freshness_source_status =
      update_in(freshness_package, ["rows"], fn [row] ->
        [Map.put(row, "freshness_status", "current")]
      end)

    assert {:error, invalid_freshness_source_status_report} =
             Schema.validate_artifact(invalid_freshness_source_status)

    assert Enum.any?(
             invalid_freshness_source_status_report["errors"],
             &(&1["path"] == "$.rows[0].source_freshness_report.status" and
                 &1["message"] == "must match freshness_status")
           )

    invalid_budget_source_evidence =
      update_in(budget_package, ["rows"], fn [row] ->
        [
          put_in(
            row,
            ["source_refresh_budget_report", "dropped_candidate_ids"],
            ["old refresh downlink"]
          )
        ]
      end)

    assert {:error, invalid_budget_source_evidence_report} =
             Schema.validate_artifact(invalid_budget_source_evidence)

    assert Enum.any?(
             invalid_budget_source_evidence_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_refresh_budget_report.dropped_candidate_ids[0]")
           )

    stale_budget_source =
      update_in(
        budget_package,
        ["rows", Access.at(0), "source_refresh_budget_report"],
        fn report ->
          Map.put(report, "dropped_candidate_count", 2)
        end
      )

    assert {:error, stale_budget_source_report} = Schema.validate_artifact(stale_budget_source)

    assert Enum.any?(
             stale_budget_source_report["errors"],
             &(&1["path"] == "$.rows[0].dropped_candidate_count" and
                 &1["message"] ==
                   "must match source_refresh_budget_report.dropped_candidate_count")
           )
  end
end
