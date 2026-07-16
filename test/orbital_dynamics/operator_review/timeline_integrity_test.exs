defmodule OrbitalDynamics.OperatorReview.TimelineIntegrityTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema, Timeline}

  test "timeline integrity reports become operator review rows" do
    report = timeline_integrity_report()
    package = OperatorReview.from_timeline_integrity_report(report)

    atom_key_report =
      report
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
      |> Map.new()

    assert %{
             "source_artifact_type" => "timeline_integrity_report.v1",
             "source_artifact_id" => "selected_activities",
             "review_count" => 2,
             "timeline_integrity_review_count" => 2,
             "required_operator_action_counts" => %{"review_timeline_integrity" => 2},
             "review_type_counts" => %{"timeline_integrity_review" => 2}
           } = package

    assert [
             %{
               "review_type" => "timeline_integrity_review",
               "source" => "timeline_integrity_report.rows",
               "activity_id" => "dl_conflict",
               "timeline_id" => "timeline:downlink:12.0",
               "timeline_integrity_status" => "review_required",
               "timeline_integrity_issue_types" => [
                 "duplicate_exclusivity_timeline",
                 "exclusivity_overlap"
               ],
               "exclusivity_violation_activity_ids" => ["cmd_main"],
               "exclusivity_violation_timeline_ids" => ["timeline:command:dss_14:10.0"],
               "duplicate_exclusivity_timeline_ids" => ["timeline:command:dss_14:10.0"],
               "source_timeline_integrity_issue_count" => 11,
               "source_exclusivity_issue_count" => 5,
               "source_timeline_integrity" => %{
                 "activity_id" => "dl_conflict",
                 "timeline_integrity_status" => "review_required",
                 "exclusivity_violation_timeline_ids" => ["timeline:command:dss_14:10.0"],
                 "duplicate_exclusivity_timeline_ids" => ["timeline:command:dss_14:10.0"]
               }
             },
             %{
               "activity_id" => "cmd_main",
               "timeline_id" => "timeline:command:dss_14:10.0",
               "required_operator_action" => "review_timeline_integrity",
               "approval_status" => "operator_review_required",
               "timeline_integrity_issue_count" => 8,
               "missing_dependency_activity_ids" => ["missing_gate"],
               "missing_dependency_timeline_ids" => [
                 "timeline:health_gate",
                 "timeline:missing_gate"
               ],
               "duplicate_dependency_activity_ids" => ["health_gate"],
               "duplicate_dependency_timeline_ids" => ["timeline:health_gate"],
               "dependency_order_violation_activity_ids" => ["health_gate"],
               "exclusivity_violation_activity_ids" => ["dl_conflict"],
               "exclusivity_violation_timeline_ids" => ["timeline:downlink:12.0"],
               "dependency_review_activity_ids" => ["cmd_main"],
               "dependency_review_timeline_ids" => ["timeline:command:dss_14:10.0"],
               "exclusivity_review_activity_ids" => ["cmd_main", "dl_conflict"],
               "exclusivity_review_timeline_ids" => [
                 "timeline:command:dss_14:10.0",
                 "timeline:downlink:12.0"
               ],
               "review_activity_ids" => ["cmd_main", "dl_conflict"],
               "review_timeline_ids" => [
                 "timeline:command:dss_14:10.0",
                 "timeline:downlink:12.0"
               ],
               "source_timeline_integrity" => %{
                 "activity_template" => %{
                   "schema_contract" => "activity_template.v1",
                   "id" => "template:command:basic",
                   "activity_type" => "command"
                 },
                 "activity_context" => %{
                   "activity_template" => %{
                     "id" => "template:command:basic",
                     "activity_type" => "command"
                   }
                 }
               }
             }
           ] = package["rows"]

    assert "missing_dependency_activity" in hd(tl(package["rows"]))[
             "timeline_integrity_issue_types"
           ]

    assert "dependency_order_violation" in hd(tl(package["rows"]))[
             "timeline_integrity_issue_types"
           ]

    assert "exclusivity_overlap" in hd(tl(package["rows"]))["timeline_integrity_issue_types"]

    assert OrbitalDynamics.operator_review_package(report) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(report, "schema_contract")) ==
             package

    assert OrbitalDynamics.operator_review_package(atom_key_report) == package

    assert OrbitalDynamics.operator_review_package(Map.delete(atom_key_report, :schema_contract)) ==
             package

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_integrity =
      put_in(
        package,
        ["rows", Access.at(0), "source_timeline_integrity", "timeline_integrity_issue_types"],
        []
      )

    assert {:error, invalid_source_integrity_report} =
             Schema.validate_artifact(invalid_source_integrity)

    assert Enum.any?(
             invalid_source_integrity_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_timeline_integrity.timeline_integrity_issue_types")
           )
  end

  test "timeline integrity report source ids fall back through defaults" do
    assert %{"source_artifact_id" => "integrity:report"} =
             OperatorReview.from_timeline_integrity_report(%{
               id: :"integrity:report",
               rows: []
             })

    assert %{"source_artifact_id" => "integrity:source"} =
             OperatorReview.from_timeline_integrity_report(%{
               source: :"integrity:source",
               rows: []
             })

    assert %{"source_artifact_id" => "timeline_integrity_report"} =
             OperatorReview.from_timeline_integrity_report(%{rows: []})
  end

  test "CandidateRefresh lifts accepted planning state timeline integrity reports" do
    report =
      timeline_integrity_report()
      |> Map.put("source", "accepted_state.timeline_integrity_report")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:accepted_timeline_integrity_handoff",
      "accepted_planning_state" => %{
        "timeline_integrity_report" => report
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:accepted_timeline_integrity_handoff",
             "review_count" => 2,
             "timeline_integrity_review_count" => 2,
             "review_type_counts" => %{"timeline_integrity_review" => 2},
             "required_operator_action_counts" => %{"review_timeline_integrity" => 2}
           } = review

    assert Enum.map(review["rows"], & &1["source"]) == [
             "candidate_refresh.accepted_planning_state.timeline_integrity_report.rows",
             "candidate_refresh.accepted_planning_state.timeline_integrity_report.rows"
           ]

    assert %{
             "review_type" => "timeline_integrity_review",
             "source" =>
               "candidate_refresh.accepted_planning_state.timeline_integrity_report.rows",
             "activity_id" => "cmd_main",
             "timeline_id" => "timeline:command:dss_14:10.0",
             "source_timeline_integrity_issue_count" => 11,
             "source_dependency_issue_count" => 6,
             "missing_dependency_activity_ids" => ["missing_gate"],
             "duplicate_dependency_activity_ids" => ["health_gate"],
             "source_timeline_integrity" => %{
               "activity_id" => "cmd_main",
               "timeline_integrity_status" => "review_required",
               "activity_template" => %{
                 "schema_contract" => "activity_template.v1",
                 "id" => "template:command:basic"
               }
             }
           } = Enum.find(review["rows"], &(&1["activity_id"] == "cmd_main"))

    assert %{
             "row_count" => 2,
             "import_action_counts" => %{"review_timeline_integrity" => 2},
             "source_review_type_counts" => %{"timeline_integrity_review" => 2}
           } = import

    assert %{
             "import_action" => "review_timeline_integrity",
             "source_review_type" => "timeline_integrity_review",
             "activity_id" => "cmd_main",
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.accepted_planning_state.timeline_integrity_report.rows",
               "source_timeline_integrity" => %{
                 "activity_id" => "cmd_main",
                 "timeline_integrity_status" => "review_required"
               }
             }
           } = Enum.find(import["rows"], &(&1["activity_id"] == "cmd_main"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "CandidateRefresh lifts mission state timeline integrity reports" do
    report =
      timeline_integrity_report()
      |> Map.put("source", "mission_state.timeline_integrity_report")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "refresh:mission_timeline_integrity_handoff",
      "mission_state" => %{
        "source_timeline_integrity_report" => report
      }
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:mission_timeline_integrity_handoff",
             "review_count" => 2,
             "timeline_integrity_review_count" => 2
           } = review

    assert Enum.map(review["rows"], & &1["source"]) == [
             "candidate_refresh.mission_state.source_timeline_integrity_report.rows",
             "candidate_refresh.mission_state.source_timeline_integrity_report.rows"
           ]

    assert %{
             "review_type" => "timeline_integrity_review",
             "source" => "candidate_refresh.mission_state.source_timeline_integrity_report.rows",
             "activity_id" => "dl_conflict",
             "timeline_id" => "timeline:downlink:12.0",
             "timeline_integrity_issue_types" => [
               "duplicate_exclusivity_timeline",
               "exclusivity_overlap"
             ],
             "source_exclusivity_issue_count" => 5,
             "exclusivity_violation_activity_ids" => ["cmd_main"],
             "source_timeline_integrity" => %{
               "activity_id" => "dl_conflict",
               "exclusivity_violation_timeline_ids" => ["timeline:command:dss_14:10.0"]
             }
           } = Enum.find(review["rows"], &(&1["activity_id"] == "dl_conflict"))

    assert %{
             "row_count" => 2,
             "import_action_counts" => %{"review_timeline_integrity" => 2},
             "source_review_type_counts" => %{"timeline_integrity_review" => 2}
           } = import

    assert %{
             "import_action" => "review_timeline_integrity",
             "source_review_type" => "timeline_integrity_review",
             "activity_id" => "dl_conflict",
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.mission_state.source_timeline_integrity_report.rows",
               "source_timeline_integrity" => %{
                 "activity_id" => "dl_conflict"
               }
             }
           } = Enum.find(import["rows"], &(&1["activity_id"] == "dl_conflict"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  defp timeline_integrity_report do
    Timeline.integrity_report(
      [
        %{id: :health_gate, type: :health_check, starts_at_s: 20.0, ends_at_s: 30.0},
        %{
          id: :dl_conflict,
          type: :downlink,
          timeline_id: :"timeline:downlink:12.0",
          starts_at_s: 12.0,
          ends_at_s: 25.0,
          exclusive_with: [:cmd_main],
          exclusive_with_timeline_ids: [
            :"timeline:command:dss_14:10.0",
            :"timeline:command:dss_14:10.0"
          ]
        },
        %{
          id: :cmd_main,
          type: :command,
          timeline_id: :"timeline:command:dss_14:10.0",
          starts_at_s: 10.0,
          ends_at_s: 15.0,
          ground_station_id: :dss_14,
          dependency_activity_ids: [:missing_gate, :health_gate, :health_gate],
          dependency_timeline_ids: [
            :"timeline:missing_gate",
            :"timeline:health_gate",
            :"timeline:health_gate"
          ],
          exclusive_with: [:dl_conflict],
          exclusive_with_timeline_ids: [:"timeline:downlink:12.0"],
          activity_template: %{
            "schema_contract" => "activity_template.v1",
            "id" => "template:command:basic",
            "activity_type" => "command",
            "template_version" => 1,
            "validation_level" => "artifact_contract"
          }
        }
      ],
      source: "selected_activities"
    )
  end
end
