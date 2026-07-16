defmodule OrbitalDynamics.OperatorReview.CandidateRefreshFreshnessBudgetTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema}

  test "candidate refresh source freshness and refresh budget reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_freshness_budget_review:001",
      "source_freshness_report" => [
        %{
          "schema_contract" => "freshness_report.v1",
          "model" => "candidate_refresh_state_freshness",
          "status" => "stale",
          "generated_at" => "2026-05-31T00:00:00Z",
          "accepted_at" => "2026-05-30T00:00:00Z",
          "current_epoch_s" => 1200.0,
          "accepted_snapshot_age_s" => 900.0,
          "max_snapshot_age_s" => 600.0,
          "stale_reasons" => ["accepted_snapshot_age_exceeded"]
        },
        %{
          "schema_contract" => "freshness_report.v1",
          "model" => "candidate_refresh_state_freshness",
          "status" => "current"
        }
      ],
      "source_refresh_budget_report" => [
        %{
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
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_freshness_budget_review:001",
             "review_count" => 2,
             "freshness_review_count" => 1,
             "refresh_budget_review_count" => 1
           } = package

    assert [freshness_row, budget_row] = package["rows"]

    assert %{
             "review_type" => "freshness_review",
             "source" => "candidate_refresh.source_freshness_report[0]",
             "subject_id" => "freshness:stale",
             "required_operator_action" => "review_refresh_freshness",
             "freshness_status" => "stale",
             "stale_reasons" => ["accepted_snapshot_age_exceeded"],
             "source_freshness_report" => %{
               "status" => "stale",
               "stale_reasons" => ["accepted_snapshot_age_exceeded"]
             }
           } = freshness_row

    assert freshness_row["accepted_snapshot_age_s"] == 900.0

    assert %{
             "review_type" => "refresh_budget_review",
             "source" => "candidate_refresh.source_refresh_budget_report[0]",
             "subject_id" => "refresh_budget",
             "required_operator_action" => "review_refresh_budget",
             "input_candidate_count" => 3,
             "kept_candidate_count" => 2,
             "dropped_candidate_count" => 1,
             "dropped_candidate_ids" => ["old_refresh_downlink"],
             "source_refresh_budget_report" => %{
               "schema_contract" => "refresh_budget_report.v1",
               "dropped_candidate_count" => 1
             }
           } = budget_row

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact freshness and refresh budget reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_freshness_budget_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "freshness_report" => %{
          "schema_contract" => "freshness_report.v1",
          "model" => "candidate_refresh_state_freshness",
          "status" => "stale",
          "generated_at" => "2026-05-31T00:00:00Z",
          "accepted_at" => "2026-05-30T00:00:00Z",
          "current_epoch_s" => 1200.0,
          "accepted_snapshot_age_s" => 900.0,
          "max_snapshot_age_s" => 600.0,
          "stale_reasons" => ["accepted_snapshot_age_exceeded"]
        },
        "refresh_budget_report" => %{
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
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_freshness_budget_review:001",
             "review_count" => 2,
             "freshness_review_count" => 1,
             "refresh_budget_review_count" => 1
           } = package

    assert [freshness_row, budget_row] = package["rows"]

    assert %{
             "review_type" => "freshness_review",
             "source" => "candidate_refresh.source_result_artifact.freshness_report",
             "subject_id" => "freshness:stale",
             "required_operator_action" => "review_refresh_freshness",
             "freshness_status" => "stale",
             "stale_reasons" => ["accepted_snapshot_age_exceeded"],
             "source_freshness_report" => %{
               "status" => "stale",
               "stale_reasons" => ["accepted_snapshot_age_exceeded"]
             }
           } = freshness_row

    assert freshness_row["accepted_snapshot_age_s"] == 900.0

    assert %{
             "review_type" => "refresh_budget_review",
             "source" => "candidate_refresh.source_result_artifact.refresh_budget_report",
             "subject_id" => "refresh_budget",
             "required_operator_action" => "review_refresh_budget",
             "input_candidate_count" => 3,
             "kept_candidate_count" => 2,
             "dropped_candidate_count" => 1,
             "dropped_candidate_ids" => ["old_refresh_downlink"],
             "source_refresh_budget_report" => %{
               "schema_contract" => "refresh_budget_report.v1",
               "dropped_candidate_count" => 1
             }
           } = budget_row

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh state-scoped freshness and refresh budget reports become review and import rows" do
    freshness_report = %{
      "schema_contract" => "freshness_report.v1",
      "model" => "candidate_refresh_state_freshness",
      "status" => "stale",
      "generated_at" => "2026-05-31T00:00:00Z",
      "accepted_at" => "2026-05-30T00:00:00Z",
      "current_epoch_s" => 1200.0,
      "accepted_snapshot_age_s" => 900.0,
      "max_snapshot_age_s" => 600.0,
      "stale_reasons" => ["accepted_snapshot_age_exceeded"]
    }

    budget_report = %{
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

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:state_freshness_budget_review:001",
      "accepted_planning_state" => %{
        "source_freshness_report" => freshness_report,
        "source_refresh_budget_report" => budget_report
      },
      "mission_state" => %{
        "freshness_report" => freshness_report,
        "refresh_budget_report" => budget_report
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:state_freshness_budget_review:001",
             "review_count" => 4,
             "freshness_review_count" => 2,
             "refresh_budget_review_count" => 2
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.accepted_planning_state.source_freshness_report",
             "candidate_refresh.mission_state.freshness_report",
             "candidate_refresh.accepted_planning_state.source_refresh_budget_report",
             "candidate_refresh.mission_state.refresh_budget_report"
           ]

    assert %{
             "review_type" => "freshness_review",
             "freshness_status" => "stale",
             "stale_reasons" => ["accepted_snapshot_age_exceeded"],
             "source_freshness_report" => %{"status" => "stale"}
           } = List.first(package["rows"])

    assert %{
             "review_type" => "refresh_budget_review",
             "dropped_candidate_count" => 1,
             "dropped_candidate_ids" => ["old_refresh_downlink"],
             "source_refresh_budget_report" => %{
               "schema_contract" => "refresh_budget_report.v1"
             }
           } = Enum.find(package["rows"], &(&1["review_type"] == "refresh_budget_review"))

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:state_freshness_budget_review:001",
             "row_count" => 4,
             "source_review_type_counts" => %{
               "freshness_review" => 2,
               "refresh_budget_review" => 2
             }
           } = manifest

    assert Enum.map(manifest["rows"], &get_in(&1, ["source_review_row", "source"])) ==
             Enum.map(package["rows"], & &1["source"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end
end
