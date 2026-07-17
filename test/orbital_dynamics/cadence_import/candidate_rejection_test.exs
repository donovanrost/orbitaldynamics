defmodule OrbitalDynamics.CadenceImport.CandidateRejectionTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.Schema

  test "builds import manifest from standalone candidate rejection report" do
    report =
      OrbitalDynamics.candidate_rejection_report(
        [
          %{
            id: :dl_reserved,
            type: :downlink,
            timeline_id: :candidate_timeline,
            ground_station_id: :dss_14,
            station_availability: "Reservation Hold",
            starts_at_s: 30.0,
            ends_at_s: 35.0,
            min_duration_s: 10.0,
            violated_constraint: :station_calendar,
            required_margin: 10.0,
            actual_margin: 5.0
          },
          %{id: :cmd_ready, type: :command, reviewable: false}
        ],
        source: :candidate_refresh
      )

    manifest = CadenceImport.from_candidate_rejection_report(report)
    assert CadenceImport.manifest(report) == manifest
    assert OrbitalDynamics.cadence_import_manifest(report) == manifest

    assert %{
             "source_artifact_type" => "candidate_rejection_report.v1",
             "source_artifact_id" => "candidate_refresh",
             "row_count" => 1,
             "review_required_count" => 1,
             "import_action_counts" => %{"review_candidate_rejection" => 1},
             "source_review_type_counts" => %{"candidate_rejection_review" => 1},
             "rows" => [
               %{
                 "import_action" => "review_candidate_rejection",
                 "import_status" => "review_required_before_import",
                 "source_review_type" => "candidate_rejection_review",
                 "source_review_action" => "review_candidate_rejection",
                 "subject_id" => "dl_reserved",
                 "activity_id" => "dl_reserved",
                 "activity_type" => "downlink",
                 "timeline_id" => "candidate_timeline",
                 "primary_rejection_reason" => "contact_too_short",
                 "candidate_rejection_reason_count" => 2,
                 "violated_constraint" => "station_calendar",
                 "required_margin" => 10.0,
                 "actual_margin" => 5.0,
                 "import_activity_context" => %{"ground_station_id" => "dss_14"},
                 "source_candidate_rejection" => %{"candidate_id" => "dl_reserved"},
                 "source_review_row" => %{
                   "review_type" => "candidate_rejection_review",
                   "source_candidate_rejection" => %{"candidate_id" => "dl_reserved"}
                 }
               }
             ]
           } = manifest

    [row] = manifest["rows"]
    assert "contact_too_short" in row["candidate_rejection_reasons"]
    assert "station_reserved" in row["candidate_rejection_reasons"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_source_evidence =
      update_in(manifest, ["rows"], fn [row] ->
        [
          put_in(
            row,
            ["source_candidate_rejection", "candidate_id"],
            "candidate rejection with spaces"
          )
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_candidate_rejection.candidate_id")
           )

    invalid_nested_source_evidence =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_review_row", "source_candidate_rejection", "candidate_id"],
        "candidate rejection with spaces"
      )

    assert {:error, nested_source_report} =
             Schema.validate_artifact(invalid_nested_source_evidence)

    assert Enum.any?(
             nested_source_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_candidate_rejection.candidate_id")
           )

    invalid_source_reason =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_candidate_rejection", "primary_rejection_reason"],
        "unsupported_rejection_reason"
      )

    assert {:error, source_reason_report} = Schema.validate_artifact(invalid_source_reason)

    assert Enum.any?(
             source_reason_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_candidate_rejection.primary_rejection_reason")
           )

    invalid_nested_source_reason =
      put_in(
        manifest,
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "source_candidate_rejection",
          "primary_rejection_reason"
        ],
        "unsupported_rejection_reason"
      )

    assert {:error, nested_source_reason_report} =
             Schema.validate_artifact(invalid_nested_source_reason)

    assert Enum.any?(
             nested_source_reason_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_candidate_rejection.primary_rejection_reason")
           )

    stale_source_review =
      manifest
      |> put_in(["rows", Access.at(0), "primary_rejection_reason"], "station_reserved")
      |> put_in(
        ["rows", Access.at(0), "source_candidate_rejection", "primary_rejection_reason"],
        "station_reserved"
      )

    assert {:error, stale_source_review_report} = Schema.validate_artifact(stale_source_review)

    assert Enum.any?(
             stale_source_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.primary_rejection_reason" and
                 &1["message"] == "must match primary_rejection_reason on Cadence import row")
           )
  end

  test "builds import manifest from standalone invalidated candidate" do
    candidate = %{
      "schema_contract" => "invalidated_candidate.v1",
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

    manifest = CadenceImport.from_invalidated_candidate(candidate)
    assert OrbitalDynamics.cadence_import_manifest(candidate) == manifest

    assert %{
             "source_artifact_type" => "invalidated_candidate.v1",
             "source_artifact_id" => "old_refresh_observe",
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
                 "source_candidate_diff" => %{"schema_contract" => "invalidated_candidate.v1"}
               }
             ]
           } = manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end
end
