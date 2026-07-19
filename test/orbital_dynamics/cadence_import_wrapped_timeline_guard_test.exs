defmodule OrbitalDynamics.CadenceImportWrappedTimelineGuardTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, Schema, Timeline}

  test "candidate refresh import preserves wrapped timeline preservation reports" do
    report = timeline_preservation_report()
    source_preservation = hd(report["rows"])
    review_preservation = Enum.at(report["rows"], 1)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_preservation_report_import",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "timeline_preservation_report" => report
        }
      ]
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_preservation_report_import",
             "row_count" => 2,
             "ready_count" => 1,
             "review_required_count" => 1,
             "import_action_counts" => %{"review_timeline_preservation" => 2},
             "source_review_type_counts" => %{"timeline_preservation_review" => 2}
           } = manifest

    assert Enum.map(manifest["rows"], & &1["source"]) == [
             "candidate_refresh.source_result_artifact[0].timeline_preservation_report.rows",
             "candidate_refresh.source_result_artifact[0].timeline_preservation_report.rows"
           ]

    assert [
             %{
               "import_action" => "review_timeline_preservation",
               "import_status" => "ready_for_import",
               "source_review_type" => "timeline_preservation_review",
               "source_review_action" => "record_timeline_preservation",
               "approval_status" => "not_required",
               "timeline_id" => "timeline:planned_contact",
               "activity_id" => "contact_locked",
               "timeline_preservation_status" => "preservation_required",
               "requires_preservation" => true,
               "requires_operator_review" => false,
               "timeline_preservation_protection_decision" => "preserve",
               "timeline_preservation_protection_category" => "locked_or_approved",
               "timeline_preservation_protection_reason" => "activity_locked_or_approved",
               "preserve_activity_count" => 1,
               "review_change_activity_count" => 1,
               "preservation_sensitive_activity_count" => 2,
               "has_cadence_import" => false,
               "source_timeline_preservation" => ^source_preservation,
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.source_result_artifact[0].timeline_preservation_report.rows",
                 "review_type" => "timeline_preservation_review",
                 "source_timeline_preservation" => ^source_preservation
               }
             },
             %{
               "import_action" => "review_timeline_preservation",
               "import_status" => "review_required_before_import",
               "source_review_type" => "timeline_preservation_review",
               "source_review_action" => "review_timeline_preservation",
               "approval_status" => "operator_review_required",
               "timeline_id" => "timeline:invalid_activity_input:bad_missing_type",
               "activity_id" => "bad_missing_type",
               "timeline_preservation_status" => "review_required",
               "requires_preservation" => false,
               "requires_operator_review" => true,
               "timeline_preservation_protection_decision" => "review_change",
               "invalid_activity_input" => true,
               "invalid_activity_input_reason" => "missing_activity_type",
               "source_timeline_preservation" => ^review_preservation,
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.source_result_artifact[0].timeline_preservation_report.rows",
                 "review_type" => "timeline_preservation_review",
                 "source_timeline_preservation" => ^review_preservation
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh import preserves wrapped timeline integrity reports" do
    report = timeline_integrity_report()
    exclusivity_integrity = hd(report["rows"])
    dependency_integrity = Enum.at(report["rows"], 1)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_integrity_report_import",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "timeline_integrity_report" => report
        }
      ]
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_integrity_report_import",
             "row_count" => 2,
             "ready_count" => 0,
             "review_required_count" => 2,
             "import_action_counts" => %{"review_timeline_integrity" => 2},
             "source_review_type_counts" => %{"timeline_integrity_review" => 2}
           } = manifest

    assert Enum.map(manifest["rows"], & &1["source"]) == [
             "candidate_refresh.source_result_artifact[0].timeline_integrity_report.rows",
             "candidate_refresh.source_result_artifact[0].timeline_integrity_report.rows"
           ]

    assert [
             %{
               "import_action" => "review_timeline_integrity",
               "import_status" => "review_required_before_import",
               "source_review_type" => "timeline_integrity_review",
               "source_review_action" => "review_timeline_integrity",
               "approval_status" => "operator_review_required",
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
               "has_cadence_import" => false,
               "source_timeline_integrity" => ^exclusivity_integrity,
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.source_result_artifact[0].timeline_integrity_report.rows",
                 "review_type" => "timeline_integrity_review",
                 "source_timeline_integrity" => ^exclusivity_integrity
               }
             },
             %{
               "import_action" => "review_timeline_integrity",
               "import_status" => "review_required_before_import",
               "source_review_type" => "timeline_integrity_review",
               "source_review_action" => "review_timeline_integrity",
               "approval_status" => "operator_review_required",
               "activity_id" => "cmd_main",
               "timeline_id" => "timeline:command:dss_14:10.0",
               "timeline_integrity_status" => "review_required",
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
               "source_dependency_issue_count" => 6,
               "source_timeline_integrity" => ^dependency_integrity,
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.source_result_artifact[0].timeline_integrity_report.rows",
                 "review_type" => "timeline_integrity_review",
                 "source_timeline_integrity" => ^dependency_integrity
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  defp timeline_preservation_report do
    Timeline.preservation_report(
      [
        %{id: :cmd_mutable, type: :command, status: :planned, approval_status: :pending},
        %{id: :contact_locked, type: :planned_contact, locked: true, approval_status: :pending},
        %{id: :bad_missing_type, status: :planned}
      ],
      source: "selected_activities"
    )
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
