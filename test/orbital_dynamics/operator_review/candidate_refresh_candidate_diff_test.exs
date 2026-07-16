defmodule OrbitalDynamics.OperatorReview.CandidateRefreshCandidateDiffTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema}

  test "candidate refresh source candidate diff reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:source_candidate_diff_review:001",
      "source_candidate_diff_report" => [
        %{
          "schema_contract" => "candidate_diff_report.v1",
          "model" => "candidate_id_set_diff_with_semantic_change_reasons",
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
              "semantic_change_reasons" => [
                "starts_at_s_changed",
                "source_window_id_changed"
              ],
              "semantic_change_details" => [
                %{
                  "field" => "starts_at_s",
                  "reason" => "starts_at_s_changed",
                  "prior_value" => 90.0,
                  "refreshed_value" => 100.0
                }
              ]
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
                "duration_s" => 60.0
              }
            }
          ]
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:source_candidate_diff_review:001",
             "review_count" => 1,
             "candidate_diff_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "candidate_diff_review",
               "source" =>
                 "candidate_refresh.source_candidate_diff_report[0].invalidated_candidates",
               "activity_id" => "old_refresh_observe",
               "target_id" => "target_a",
               "required_operator_action" => "review_candidate_diff",
               "replacement_candidate_id" => "refresh_observe",
               "replacement_source_window_id" => "window:leo_1:target_visibility:target_a:1",
               "replacement_source_window_type" => "target_visibility",
               "replacement_source_window" => %{
                 "id" => "window:leo_1:target_visibility:target_a:1"
               },
               "replacement_source_window_lineage" => %{
                 "candidate_activity_id" => "refresh_observe"
               },
               "semantic_change_reasons" => ["starts_at_s_changed"],
               "changed_fields" => ["starts_at_s"],
               "candidate_diff_changed_fields" => ["starts_at_s"],
               "source_candidate_diff" => %{"id" => "old_refresh_observe"}
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh state and wrapped candidate diff reports become review and import rows" do
    report = candidate_diff_report()

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:state_candidate_diff_review:001",
      "accepted_planning_state" => %{"source_candidate_diff_report" => report},
      "mission_state" => %{"candidate_diff_report" => report},
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_candidate_diff_report" => report
        }
      ],
      "result_artifact" => [
        report
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:state_candidate_diff_review:001",
             "review_count" => 4,
             "candidate_diff_review_count" => 4
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.accepted_planning_state.source_candidate_diff_report.invalidated_candidates",
             "candidate_refresh.mission_state.candidate_diff_report.invalidated_candidates",
             "candidate_refresh.source_result_artifact[0].source_candidate_diff_report.invalidated_candidates",
             "candidate_refresh.result_artifact[0].invalidated_candidates"
           ]

    assert %{
             "review_type" => "candidate_diff_review",
             "activity_id" => "old_refresh_observe",
             "target_id" => "target_a",
             "required_operator_action" => "review_candidate_diff",
             "replacement_candidate_id" => "refresh_observe",
             "replacement_source_window_id" => "window:leo_1:target_visibility:target_a:1",
             "replacement_source_window" => %{
               "id" => "window:leo_1:target_visibility:target_a:1"
             },
             "source_candidate_diff" => %{"id" => "old_refresh_observe"}
           } = List.first(package["rows"])

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:state_candidate_diff_review:001",
             "row_count" => 4,
             "source_review_type_counts" => %{"candidate_diff_review" => 4}
           } = manifest

    assert Enum.map(manifest["rows"], &get_in(&1, ["source_review_row", "source"])) == [
             "candidate_refresh.accepted_planning_state.source_candidate_diff_report.invalidated_candidates",
             "candidate_refresh.mission_state.candidate_diff_report.invalidated_candidates",
             "candidate_refresh.source_result_artifact[0].source_candidate_diff_report.invalidated_candidates",
             "candidate_refresh.result_artifact[0].invalidated_candidates"
           ]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  defp candidate_diff_report do
    %{
      "schema_contract" => "candidate_diff_report.v1",
      "model" => "candidate_id_set_diff_with_semantic_change_reasons",
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
          "semantic_change_reasons" => [
            "starts_at_s_changed",
            "source_window_id_changed"
          ],
          "semantic_change_details" => [
            %{
              "field" => "starts_at_s",
              "reason" => "starts_at_s_changed",
              "prior_value" => 90.0,
              "refreshed_value" => 100.0
            }
          ]
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
            "duration_s" => 60.0
          }
        }
      ]
    }
  end
end
