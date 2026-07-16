defmodule OrbitalDynamics.OperatorReview.CandidateDiffTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "candidate diff report source ids fall back through defaults" do
    assert %{"source_artifact_id" => "candidate-diff:report"} =
             OperatorReview.from_candidate_diff_report(%{id: :"candidate-diff:report"})

    assert %{"source_artifact_id" => "candidate-diff:source"} =
             OperatorReview.from_candidate_diff_report(%{source: :"candidate-diff:source"})

    assert %{"source_artifact_id" => "candidate_diff_report"} =
             OperatorReview.from_candidate_diff_report(%{})
  end

  test "builds standalone candidate diff review package" do
    report = %{
      "schema_contract" => "candidate_diff_report.v1",
      "model" => "candidate_id_set_diff_with_semantic_change_reasons",
      "prior_candidate_count" => 1,
      "refreshed_candidate_count" => 1,
      "retained_candidate_count" => 0,
      "new_candidate_count" => 1,
      "invalidated_candidate_count" => 1,
      "retained_candidates" => [],
      "new_candidates" => [
        %{
          "id" => "refresh_observe",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "target_id" => "target_a",
          "starts_at_s" => 100.0,
          "ends_at_s" => 160.0,
          "source_window_id" => "window:leo_1:target_visibility:target_a:1",
          "diff_reason" => "semantically_similar_prior_candidate_changed"
        }
      ],
      "invalidated_candidates" => [
        %{
          "id" => "old_refresh_observe",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "target_id" => "target_a",
          "source_window_id" => "window:leo_1:target_visibility:target_a:old",
          "starts_at_s" => 90.0,
          "ends_at_s" => 150.0,
          "replacement_candidate_id" => "refresh_observe",
          "invalidated_reason" => "replaced_by_semantically_similar_candidate",
          "semantic_change_reasons" => ["starts_at_s_changed", "source_window_id_changed"]
        }
      ],
      "source_window_lineage" => [
        %{
          "schema_contract" => "source_window_lineage.v1",
          "candidate_activity_id" => "refresh_observe",
          "source_window_id" => "window:leo_1:target_visibility:target_a:1",
          "source_window_type" => "target_visibility",
          "scenario_id" => "leo_1",
          "source_window" => %{
            "schema_contract" => "refreshed_window.v1",
            "id" => "window:leo_1:target_visibility:target_a:1",
            "type" => "target_visibility",
            "scenario_id" => "leo_1",
            "target_id" => "target_a",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "duration_s" => 60.0,
            "boundary_refinement" => "target_visibility_linear_margin_interpolation"
          }
        }
      ]
    }

    ordinary_new_report = %{
      report
      | "invalidated_candidate_count" => 0,
        "invalidated_candidates" => [],
        "new_candidates" => [
          %{
            "id" => "refresh_observe",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "source_window_id" => "window:leo_1:target_visibility:target_a:1",
            "diff_reason" => "not_present_in_prior_candidate_set"
          }
        ]
    }

    package = OperatorReview.from_candidate_diff_report(report)
    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "candidate_diff_report.v1",
             "review_count" => 1,
             "candidate_diff_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "candidate_diff_review",
                 "source" => "candidate_diff_report.invalidated_candidates",
                 "activity_id" => "old_refresh_observe",
                 "target_id" => "target_a",
                 "required_operator_action" => "review_candidate_diff",
                 "replacement_candidate_id" => "refresh_observe",
                 "replacement_source_window_id" => "window:leo_1:target_visibility:target_a:1",
                 "replacement_source_window" => %{
                   "id" => "window:leo_1:target_visibility:target_a:1"
                 },
                 "replacement_source_window_lineage" => %{
                   "candidate_activity_id" => "refresh_observe"
                 },
                 "source_candidate_diff" => %{"id" => "old_refresh_observe"}
               }
             ]
           } = package

    assert %{"review_count" => 0, "rows" => []} =
             OperatorReview.from_candidate_diff_report(ordinary_new_report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_evidence =
      update_in(package, ["rows"], fn [row] ->
        [
          put_in(row, ["source_candidate_diff", "id"], "candidate diff with spaces")
        ]
      end)

    assert {:error, invalid_source_evidence_report} =
             Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             invalid_source_evidence_report["errors"],
             &(&1["path"] == "$.rows[0].source_candidate_diff.id")
           )

    stale_source_evidence =
      put_in(
        package,
        ["rows", Access.at(0), "source_candidate_diff", "invalidated_reason"],
        "replacement_candidate_lost_station_access"
      )

    assert {:error, stale_source_report} = Schema.validate_artifact(stale_source_evidence)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] == "$.rows[0].invalidated_reason" and
                 &1["message"] == "must match source_candidate_diff.invalidated_reason")
           )

    assert {:ok, %{"schema_contract" => "candidate_diff_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_lineage_report =
      put_in(
        report,
        ["source_window_lineage", Access.at(0), "source_window_id"],
        "window:leo_1:target_visibility:target_a:mismatch"
      )

    assert {:error, invalid_lineage_validation} = Schema.validate_artifact(invalid_lineage_report)

    assert Enum.any?(
             invalid_lineage_validation["errors"],
             &(&1["path"] == "$.source_window_lineage[0].source_window_id" and
                 &1["message"] == "must match candidate activity source_window_id")
           )
  end

  test "builds candidate diff review rows for unpaired semantic new candidates" do
    report = %{
      "schema_contract" => "candidate_diff_report.v1",
      "model" => "candidate_id_set_diff_with_semantic_change_reasons",
      "prior_candidate_count" => 1,
      "refreshed_candidate_count" => 1,
      "retained_candidate_count" => 0,
      "new_candidate_count" => 1,
      "invalidated_candidate_count" => 0,
      "retained_candidates" => [],
      "new_candidates" => [
        %{
          "id" => "refresh_observe",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "target_id" => "target_a",
          "starts_at_s" => 100.0,
          "ends_at_s" => 160.0,
          "source_window_id" => "window:leo_1:target_visibility:target_a:1",
          "diff_reason" => "semantically_similar_prior_candidate_changed",
          "matched_prior_candidate_id" => "old_refresh_observe",
          "semantic_change_reasons" => ["starts_at_s_changed", "source_window_id_changed"]
        }
      ],
      "invalidated_candidates" => []
    }

    package = OperatorReview.from_candidate_diff_report(report)

    assert %{
             "review_count" => 1,
             "candidate_diff_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "candidate_diff_review",
                 "source" => "candidate_diff_report.new_candidates",
                 "activity_id" => "refresh_observe",
                 "target_id" => "target_a",
                 "reason" =>
                   "candidate diff requires review: semantically_similar_prior_candidate_changed",
                 "semantic_change_reasons" => [
                   "starts_at_s_changed",
                   "source_window_id_changed"
                 ],
                 "source_candidate_diff" => %{
                   "matched_prior_candidate_id" => "old_refresh_observe"
                 }
               } = row
             ]
           } = package

    refute Map.has_key?(row, "invalidated_candidate_id")

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "builds candidate diff review rows for ambiguous semantic new candidates" do
    report = %{
      "schema_contract" => "candidate_diff_report.v1",
      "model" => "candidate_id_set_diff_with_semantic_change_reasons",
      "prior_candidate_count" => 2,
      "refreshed_candidate_count" => 1,
      "retained_candidate_count" => 0,
      "new_candidate_count" => 1,
      "invalidated_candidate_count" => 0,
      "retained_candidates" => [],
      "new_candidates" => [
        %{
          "id" => "refresh_observe",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "target_id" => "target_a",
          "starts_at_s" => 100.0,
          "ends_at_s" => 160.0,
          "diff_reason" => "ambiguous_semantic_prior_candidate_match",
          "semantic_match_status" => "ambiguous_prior_candidate",
          "semantic_match_candidate_count" => 2,
          "semantic_match_candidate_ids" => [
            "old_refresh_observe_1",
            "old_refresh_observe_2"
          ]
        }
      ],
      "invalidated_candidates" => []
    }

    package = OperatorReview.from_candidate_diff_report(report)

    assert %{
             "review_count" => 1,
             "candidate_diff_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "candidate_diff_review",
                 "source" => "candidate_diff_report.new_candidates",
                 "activity_id" => "refresh_observe",
                 "semantic_match_status" => "ambiguous_prior_candidate",
                 "semantic_match_candidate_count" => 2,
                 "semantic_match_candidate_ids" => [
                   "old_refresh_observe_1",
                   "old_refresh_observe_2"
                 ]
               }
             ]
           } = package

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "builds candidate diff review rows for retained semantic changes" do
    report = %{
      "schema_contract" => "candidate_diff_report.v1",
      "model" => "candidate_id_set_diff_with_semantic_change_reasons",
      "prior_candidate_count" => 1,
      "refreshed_candidate_count" => 1,
      "retained_candidate_count" => 1,
      "new_candidate_count" => 0,
      "invalidated_candidate_count" => 0,
      "retained_candidates" => [
        %{
          "id" => "leo_1_downlink_equator_prime_1",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 300.0,
          "ends_at_s" => 420.0,
          "diff_reason" => "present_in_prior_candidate_set_with_semantic_changes",
          "semantic_change_reasons" => [
            "estimated_throughput_mb_changed",
            "contact_success_factor_changed"
          ]
        }
      ],
      "new_candidates" => [],
      "invalidated_candidates" => []
    }

    package = OperatorReview.from_candidate_diff_report(report)

    assert %{
             "review_count" => 1,
             "candidate_diff_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "candidate_diff_review",
                 "source" => "candidate_diff_report.retained_candidates",
                 "activity_id" => "leo_1_downlink_equator_prime_1",
                 "ground_station_id" => "equator_prime",
                 "semantic_change_reasons" => [
                   "estimated_throughput_mb_changed",
                   "contact_success_factor_changed"
                 ],
                 "source_candidate_diff" => %{
                   "diff_reason" => "present_in_prior_candidate_set_with_semantic_changes"
                 }
               } = row
             ]
           } = package

    refute Map.has_key?(row, "invalidated_candidate_id")

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end
end
