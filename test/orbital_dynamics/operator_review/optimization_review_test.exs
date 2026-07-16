defmodule OrbitalDynamics.OperatorReview.OptimizationReviewTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "constraint report source ids fall back through report id generation" do
    assert %{"source_artifact_id" => "constraint_report:constraint:report"} =
             OperatorReview.from_constraint_report(%{id: :"constraint:report"})

    assert %{"source_artifact_id" => "constraint_report:constraint:source"} =
             OperatorReview.from_constraint_report(%{
               assumptions: %{source: :"constraint:source"}
             })

    assert %{"source_artifact_id" => "constraint_report:warning"} =
             OperatorReview.from_constraint_report(%{status: :warning})

    assert %{"source_artifact_id" => "constraint_report"} =
             OperatorReview.from_constraint_report(%{})
  end

  test "objective satisfaction report source ids fall back through defaults" do
    assert %{"source_artifact_id" => "objective:report"} =
             OperatorReview.from_objective_satisfaction_report(%{id: :"objective:report"})

    assert %{"source_artifact_id" => "objective:source"} =
             OperatorReview.from_objective_satisfaction_report(%{
               source: :"objective:source"
             })

    assert %{"source_artifact_id" => "objective_satisfaction_report"} =
             OperatorReview.from_objective_satisfaction_report(%{})
  end

  test "score term report source ids fall back through defaults" do
    assert %{"source_artifact_id" => "score-term:report"} =
             OperatorReview.from_score_term_report(%{id: :"score-term:report"})

    assert %{"source_artifact_id" => "score-term:source"} =
             OperatorReview.from_score_term_report(%{source: :"score-term:source"})

    assert %{"source_artifact_id" => "score_term_report"} =
             OperatorReview.from_score_term_report(%{})
  end

  test "objective tradeoff report source ids fall back through defaults" do
    assert %{"source_artifact_id" => "objective-tradeoff:report"} =
             OperatorReview.from_objective_tradeoff_report(%{
               id: :"objective-tradeoff:report"
             })

    assert %{"source_artifact_id" => "objective-tradeoff:source"} =
             OperatorReview.from_objective_tradeoff_report(%{
               source: :"objective-tradeoff:source"
             })

    assert %{"source_artifact_id" => "objective_tradeoff_report"} =
             OperatorReview.from_objective_tradeoff_report(%{})
  end

  test "builds review package from failing and warning constraint report rows" do
    report = constraint_report()

    package = OperatorReview.from_constraint_report(report)

    assert OrbitalDynamics.operator_review_package(
             %{schema_contract: "constraint_report.v1"}
             |> Map.merge(report)
           ) ==
             package

    assert %{
             "source_artifact_type" => "constraint_report.v1",
             "source_artifact_id" => "constraint_report:study_metadata.constraints",
             "review_count" => 2,
             "constraint_review_count" => 2,
             "review_type_counts" => %{"constraint_review" => 2},
             "review_queue_counts" => %{
               "constraint_review|review_constraint|operator_review_required" => 2
             }
           } = package

    assert Enum.map(package["rows"], & &1["constraint_status"]) == ["fail", "warning"]

    assert %{
             "review_type" => "constraint_review",
             "source" => "constraint_report.rows",
             "subject_id" => "dispersion_2",
             "scenario_id" => "dispersion_2",
             "constraint_id" => "minimum_operational_altitude",
             "metric" => "min_altitude_km",
             "operator" => ">=",
             "threshold" => 621.5,
             "value" => 621.19,
             "score" => -0.31,
             "constraint_status" => "fail",
             "required_operator_action" => "review_constraint",
             "action" => "review_constraint",
             "review_queue" => "review_constraint",
             "review_queue_key" => "constraint_review|review_constraint|operator_review_required",
             "reason" =>
               "review fail constraint minimum_operational_altitude for dispersion_2: min_altitude_km >= 621.5",
             "source_constraint_row" => %{"status" => "fail"}
           } = List.first(package["rows"])

    refute Enum.any?(package["rows"], &(&1["constraint_status"] == "pass"))

    assert {:ok, %{"schema_contract" => "constraint_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_evidence =
      put_in(package, ["rows", Access.at(0), "source_constraint_row", "status"], "warning")

    assert {:error, stale_source_report} = Schema.validate_artifact(stale_source_evidence)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] == "$.rows[0].constraint_status" and
                 &1["message"] == "must match source_constraint_row.status")
           )
  end

  test "builds review package from unmet objective satisfaction rows" do
    report = objective_satisfaction_report()

    package = OperatorReview.from_objective_satisfaction_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "objective_satisfaction_report.v1",
             "source_artifact_id" => "campaign_plan.activities",
             "review_count" => 3,
             "objective_satisfaction_review_count" => 3,
             "review_type_counts" => %{"objective_satisfaction_review" => 3}
           } = package

    assert Enum.map(package["rows"], & &1["objective_status"]) == [
             "partial",
             "unmet",
             "no_candidate_window"
           ]

    assert %{
             "review_type" => "objective_satisfaction_review",
             "subject_id" => "objective:target_coverage",
             "objective" => "target_coverage",
             "objective_status" => "partial",
             "required_count" => 2,
             "candidate_count" => 1,
             "selected_count" => 1,
             "satisfied_count" => 1,
             "candidate_target_ids" => ["target_a"],
             "selected_target_ids" => ["target_a"],
             "required_operator_action" => "review_objective_satisfaction",
             "reason" => "review partial objective target_coverage for objective:target_coverage",
             "source_objective_satisfaction" => %{"status" => "partial"}
           } = List.first(package["rows"])

    refute Enum.any?(package["rows"], &(&1["objective_status"] == "selected"))

    assert {:ok, %{"schema_contract" => "objective_satisfaction_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_evidence =
      put_in(
        package,
        ["rows", Access.at(0), "source_objective_satisfaction", "status"],
        "unmet"
      )

    assert {:error, stale_source_report} = Schema.validate_artifact(stale_source_evidence)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] == "$.rows[0].objective_status" and
                 &1["message"] == "must match source_objective_satisfaction.status")
           )
  end

  test "builds review package from score term report rows" do
    report = score_term_report()

    package = OperatorReview.from_score_term_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "score_term_report.v1",
             "source_artifact_id" => "campaign_plan.score_terms",
             "review_count" => 2,
             "score_term_review_count" => 2,
             "review_type_counts" => %{"score_term_review" => 2}
           } = package

    assert %{
             "review_type" => "score_term_review",
             "source" => "score_term_report.rows",
             "subject_id" => "score_term:leo_1:1:target_value",
             "scenario_id" => "leo_1",
             "term_key" => "target_value",
             "value" => 120.0,
             "timeline_score" => 140.0,
             "selected" => true,
             "required_operator_action" => "review_score_term",
             "reason" => "review score term target_value for leo_1: value 120.0",
             "source_score_term" => %{"term_key" => "target_value"}
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "score_term_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_evidence =
      put_in(package, ["rows", Access.at(0), "source_score_term", "value"], 121.0)

    assert {:error, stale_source_report} = Schema.validate_artifact(stale_source_evidence)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] == "$.rows[0].value" and
                 &1["message"] == "must match source_score_term.value")
           )
  end

  test "builds review package from objective tradeoff report rows" do
    report = objective_tradeoff_report()

    package = OperatorReview.from_objective_tradeoff_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "objective_tradeoff_report.v1",
             "source_artifact_id" => "objective_tradeoff_report",
             "review_count" => 2,
             "objective_tradeoff_review_count" => 2,
             "review_type_counts" => %{"objective_tradeoff_review" => 2}
           } = package

    assert %{
             "review_type" => "objective_tradeoff_review",
             "source" => "objective_tradeoff_report.tradeoffs",
             "subject_id" => "leo_2",
             "scenario_id" => "leo_2",
             "score" => 95.0,
             "score_delta_from_selected" => -45.0,
             "activity_count" => 1,
             "score_terms" => %{"target_value" => 100.0, "activity_count_penalty" => -5.0},
             "activity_ids" => ["leo_2_observe_target_b_1"],
             "required_operator_action" => "review_objective_tradeoff",
             "reason" => "review objective tradeoff for leo_2: score delta -45.0",
             "source_objective_tradeoff" => %{"scenario_id" => "leo_2"}
           } = List.last(package["rows"])

    assert {:ok, %{"schema_contract" => "objective_tradeoff_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_evidence =
      put_in(
        package,
        ["rows", Access.at(1), "source_objective_tradeoff", "score"],
        96.0
      )

    assert {:error, stale_source_report} = Schema.validate_artifact(stale_source_evidence)

    assert Enum.any?(
             stale_source_report["errors"],
             &(&1["path"] == "$.rows[1].score" and
                 &1["message"] == "must match source_objective_tradeoff.score")
           )
  end

  defp constraint_report do
    %{
      "schema_contract" => "constraint_report.v1",
      "model" => "artifact_metric_threshold",
      "status" => "fail",
      "constraint_count" => 2,
      "row_count" => 3,
      "status_counts" => %{"fail" => 1, "pass" => 1, "warning" => 1},
      "assumptions" => %{
        "constraint_model" => "artifact_level_metric_thresholds",
        "missing_or_nil_values" => "fail",
        "source" => "study_metadata.constraints"
      },
      "rows" => [
        %{
          "constraint_id" => "minimum_operational_altitude",
          "metric" => "min_altitude_km",
          "operator" => ">=",
          "scenario_id" => "dispersion_1",
          "score" => 0.42,
          "status" => "pass",
          "threshold" => 621.5,
          "value" => 621.92
        },
        %{
          "constraint_id" => "minimum_operational_altitude",
          "metric" => "min_altitude_km",
          "operator" => ">=",
          "scenario_id" => "dispersion_2",
          "score" => -0.31,
          "status" => "fail",
          "threshold" => 621.5,
          "value" => 621.19
        },
        %{
          "constraint_id" => "downlink_margin",
          "metric" => "estimated_throughput_mb",
          "operator" => ">=",
          "scenario_id" => "dispersion_3",
          "status" => "warning",
          "threshold" => 120.0
        }
      ]
    }
  end

  defp objective_satisfaction_report do
    %{
      "schema_contract" => "objective_satisfaction_report.v1",
      "source" => "campaign_plan.activities",
      "model" => "campaign_v1_selected_activity_objective_summary",
      "objective_count" => 4,
      "rows" => [
        %{
          "id" => "objective:target_coverage",
          "objective" => "target_coverage",
          "status" => "partial",
          "required_count" => 2,
          "candidate_count" => 1,
          "selected_count" => 1,
          "satisfied_count" => 1,
          "candidate_target_ids" => ["target_a"],
          "selected_target_ids" => ["target_a"]
        },
        %{
          "id" => "objective:downlink_completion",
          "objective" => "downlink_completion",
          "status" => "unmet",
          "required_downlink_mb" => 150.0,
          "candidate_downlink_mb" => 160.0,
          "candidate_count" => 1,
          "selected_count" => 0,
          "satisfied_count" => 0,
          "selected_downlink_mb" => 0.0,
          "satisfied_downlink_mb" => 0.0,
          "selected_contact_ids" => []
        },
        %{
          "id" => "objective:target_commitment:target_a",
          "objective" => "target_commitment",
          "target_id" => "target_a",
          "status" => "selected",
          "required_count" => 1,
          "candidate_count" => 1,
          "selected_count" => 1,
          "satisfied_count" => 1,
          "selected_activity_ids" => ["leo_1_observe_target_a_1"]
        },
        %{
          "id" => "objective:target_commitment:target_b",
          "objective" => "target_commitment",
          "target_id" => "target_b",
          "status" => "no_candidate_window",
          "required_count" => 1,
          "candidate_count" => 0,
          "selected_count" => 0,
          "satisfied_count" => 0,
          "selected_activity_ids" => []
        }
      ],
      "assumptions" => %{"selection" => "best_ranked_timeline_is_selected"}
    }
  end

  defp score_term_report do
    %{
      "schema_contract" => "score_term_report.v1",
      "model" => "ranked_timeline_score_terms",
      "source" => "campaign_plan.score_terms",
      "row_count" => 2,
      "score_term_keys" => ["activity_count_penalty", "target_value"],
      "rows" => [
        %{
          "id" => "score_term:leo_1:1:target_value",
          "rank" => 1,
          "scenario_id" => "leo_1",
          "term_key" => "target_value",
          "value" => 120.0,
          "timeline_score" => 140.0,
          "selected" => true
        },
        %{
          "id" => "score_term:leo_1:1:activity_count_penalty",
          "rank" => 1,
          "scenario_id" => "leo_1",
          "term_key" => "activity_count_penalty",
          "value" => -10.0,
          "timeline_score" => 140.0,
          "selected" => true
        }
      ],
      "assumptions" => %{"score_model" => "transparent_term_sum"}
    }
  end

  defp objective_tradeoff_report do
    %{
      "schema_contract" => "objective_tradeoff_report.v1",
      "model" => "ranked_timeline_score_term_tradeoffs",
      "objective" => "campaign_timeline_score",
      "ranking_count" => 2,
      "score_term_keys" => ["activity_count_penalty", "target_value"],
      "tradeoffs" => [
        %{
          "rank" => 1,
          "scenario_id" => "leo_1",
          "score" => 140.0,
          "score_delta_from_selected" => 0.0,
          "activity_count" => 2,
          "selected_observation_count" => 1,
          "selected_contact_count" => 1,
          "score_terms" => %{"target_value" => 150.0, "activity_count_penalty" => -10.0},
          "activity_ids" => ["leo_1_observe_target_a_1", "leo_1_downlink_1"]
        },
        %{
          "rank" => 2,
          "scenario_id" => "leo_2",
          "score" => 95.0,
          "score_delta_from_selected" => -45.0,
          "activity_count" => 1,
          "selected_observation_count" => 1,
          "selected_contact_count" => 0,
          "score_terms" => %{"target_value" => 100.0, "activity_count_penalty" => -5.0},
          "activity_ids" => ["leo_2_observe_target_b_1"]
        }
      ],
      "assumptions" => %{"selected_rank" => 1}
    }
  end
end
