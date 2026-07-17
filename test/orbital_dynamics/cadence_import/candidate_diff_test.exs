defmodule OrbitalDynamics.CadenceImport.CandidateDiffTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.Schema

  test "builds import manifest from standalone candidate diff report" do
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

    manifest = CadenceImport.from_candidate_diff_report(report)
    assert OrbitalDynamics.cadence_import_manifest(report) == manifest

    assert %{
             "source_artifact_type" => "candidate_diff_report.v1",
             "row_count" => 1,
             "import_action_counts" => %{"review_candidate_diff" => 1},
             "rows" => [
               %{
                 "import_action" => "review_candidate_diff",
                 "source_review_type" => "candidate_diff_review",
                 "refresh_gate" => "candidate_diff",
                 "refresh_gate_status" => "replaced_by_semantically_similar_candidate",
                 "candidate_diff_reason_count" => 2,
                 "activity_id" => "old_refresh_observe",
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
           } = manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_source_evidence =
      update_in(manifest, ["rows"], fn [row] ->
        [
          put_in(row, ["source_candidate_diff", "id"], "candidate diff with spaces")
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_candidate_diff.id")
           )

    stale_source_review =
      manifest
      |> put_in(
        ["rows", Access.at(0), "invalidated_reason"],
        "replacement_candidate_lost_station_access"
      )
      |> put_in(
        ["rows", Access.at(0), "source_candidate_diff", "invalidated_reason"],
        "replacement_candidate_lost_station_access"
      )

    assert {:error, stale_source_review_report} = Schema.validate_artifact(stale_source_review)

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.invalidated_reason" and
                 &1["message"] == "must match invalidated_reason on Cadence import row")
           )
  end

  test "builds import manifest rows for retained candidate diff semantic changes" do
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

    manifest = CadenceImport.from_candidate_diff_report(report)

    assert %{
             "row_count" => 1,
             "import_action_counts" => %{"review_candidate_diff" => 1},
             "rows" => [
               %{
                 "import_action" => "review_candidate_diff",
                 "source_review_type" => "candidate_diff_review",
                 "refresh_gate" => "candidate_diff",
                 "refresh_gate_status" => "present_in_prior_candidate_set_with_semantic_changes",
                 "candidate_diff_reason_count" => 2,
                 "activity_id" => "leo_1_downlink_equator_prime_1",
                 "semantic_change_reasons" => [
                   "estimated_throughput_mb_changed",
                   "contact_success_factor_changed"
                 ],
                 "source_candidate_diff" => %{
                   "diff_reason" => "present_in_prior_candidate_set_with_semantic_changes"
                 }
               } = row
             ]
           } = manifest

    refute Map.has_key?(row, "invalidated_candidate_id")

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "builds import manifest rows for unpaired semantic new candidate diffs" do
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

    manifest = CadenceImport.from_candidate_diff_report(report)

    assert %{
             "row_count" => 1,
             "import_action_counts" => %{"review_candidate_diff" => 1},
             "rows" => [
               %{
                 "import_action" => "review_candidate_diff",
                 "source_review_type" => "candidate_diff_review",
                 "refresh_gate" => "candidate_diff",
                 "refresh_gate_status" => "semantically_similar_prior_candidate_changed",
                 "candidate_diff_reason_count" => 2,
                 "activity_id" => "refresh_observe",
                 "semantic_change_reasons" => [
                   "starts_at_s_changed",
                   "source_window_id_changed"
                 ],
                 "source_candidate_diff" => %{
                   "matched_prior_candidate_id" => "old_refresh_observe"
                 }
               } = row
             ]
           } = manifest

    refute Map.has_key?(row, "invalidated_candidate_id")

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "builds import manifest rows for ambiguous semantic new candidate diffs" do
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

    manifest = CadenceImport.from_candidate_diff_report(report)

    assert %{
             "row_count" => 1,
             "import_action_counts" => %{"review_candidate_diff" => 1},
             "rows" => [
               %{
                 "import_action" => "review_candidate_diff",
                 "refresh_gate_status" => "ambiguous_prior_candidate",
                 "activity_id" => "refresh_observe",
                 "semantic_match_status" => "ambiguous_prior_candidate",
                 "semantic_match_candidate_count" => 2,
                 "semantic_match_candidate_ids" => [
                   "old_refresh_observe_1",
                   "old_refresh_observe_2"
                 ]
               }
             ]
           } = manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end
end
