defmodule OrbitalDynamics.CadenceImportWrappedTimelineSummariesTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, Schema, Timeline}

  test "candidate refresh import preserves wrapped timeline dependency-impact summaries" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_dependency_impact_import",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "timeline_dependency_impact_summary" => timeline_dependency_impact_summary()
        }
      ]
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_dependency_impact_import",
             "row_count" => 2,
             "review_required_count" => 2,
             "import_action_counts" => %{"review_timeline_dependency_impact" => 2},
             "source_review_type_counts" => %{"timeline_dependency_impact_review" => 2}
           } = manifest

    assert Enum.map(manifest["rows"], &get_in(&1, ["source_review_row", "source"])) == [
             "candidate_refresh.source_result_artifact[0].timeline_dependency_impact_summary.dependency_impact_rows",
             "candidate_refresh.source_result_artifact[0].timeline_dependency_impact_summary.dependency_impact_rows"
           ]

    assert Enum.all?(
             manifest["rows"],
             &match?(
               %{
                 "import_action" => "review_timeline_dependency_impact",
                 "source_review_type" => "timeline_dependency_impact_review",
                 "source_review_action" => "review_timeline_integrity",
                 "import_status" => "review_required_before_import",
                 "approval_status" => "operator_review_required",
                 "required_operator_action" => "review_timeline_integrity",
                 "timeline_id" => "timeline:command:20.0",
                 "activity_id" => "cmd_combo",
                 "dependency_impact_status" => "review_required",
                 "cadence_import_status" => "present",
                 "has_cadence_import" => false
               },
               &1
             )
           )

    assert %{
             "dependency_impact_scope" => "source",
             "impacted_source_activity_ids" => ["health_gate"],
             "impacted_source_timeline_ids" => ["timeline:health_check:0.0"],
             "dependent_activity_ids" => ["cmd_combo"],
             "dependent_timeline_ids" => ["timeline:command:20.0"],
             "source_dependent_activity_ids" => ["cmd_combo"],
             "source_dependent_timeline_ids" => ["timeline:command:20.0"],
             "replacement_dependent_activity_ids" => ["cmd_combo"],
             "replacement_dependent_timeline_ids" => ["timeline:command:20.0"],
             "dependency_timeline_ids" => ["timeline:health_check:0.0"],
             "exclusive_with_activity_ids" => ["health_gate"],
             "impacted_dependency_timeline_ids" => ["timeline:health_check:0.0"],
             "impacted_exclusive_with_activity_ids" => ["health_gate"],
             "source_timeline_dependency_impact" => %{
               "id" => "dependency_impact:source:timeline:command:20.0",
               "scope" => "source",
               "activity_id" => "cmd_combo",
               "dependency_impact_status" => "review_required"
             },
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_result_artifact[0].timeline_dependency_impact_summary.dependency_impact_rows",
               "source_activity_count" => 2,
               "replacement_activity_count" => 2,
               "changed_source_activity_count" => 1,
               "changed_source_timeline_count" => 1,
               "source_timeline_dependency_impact" => %{
                 "id" => "dependency_impact:source:timeline:command:20.0",
                 "scope" => "source",
                 "activity_id" => "cmd_combo",
                 "dependency_impact_status" => "review_required"
               }
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["dependency_impact_scope"] == "source")
             )

    assert %{
             "dependency_impact_scope" => "replacement",
             "source_timeline_dependency_impact" => %{
               "id" => "dependency_impact:replacement:timeline:command:20.0",
               "scope" => "replacement"
             },
             "source_review_row" => %{
               "source_timeline_dependency_impact" => %{
                 "id" => "dependency_impact:replacement:timeline:command:20.0",
                 "scope" => "replacement"
               }
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["dependency_impact_scope"] == "replacement")
             )

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh import preserves wrapped timeline publication summaries" do
    summary = timeline_publication_summary()

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_publication_summary_import",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "timeline_publication_summary" => summary
        }
      ]
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_publication_summary_import",
             "row_count" => 1,
             "review_required_count" => 1,
             "import_action_counts" => %{"review_timeline_publication" => 1},
             "source_review_type_counts" => %{"timeline_publication_review" => 1}
           } = manifest

    assert [
             %{
               "import_action" => "review_timeline_publication",
               "import_status" => "review_required_before_import",
               "source_review_type" => "timeline_publication_review",
               "source_review_action" => "review_timeline_publication",
               "approval_status" => "operator_review_required",
               "publication_id" =>
                 "timeline_publication:7:timeline:published_plan:v2:timeline:published_plan:v1",
               "publication_sequence" => 7,
               "publication_status" => "published_with_downstream_invalidations",
               "downstream_invalidation_status" => "invalidated",
               "publication_authority" => "mission_operations",
               "source_artifact_id" => "timeline:published_plan:v2",
               "source_artifact_type" => "operational_timeline_report.v1",
               "supersedes_artifact_ids" => ["timeline:published_plan:v1"],
               "downstream_product_ids" => [
                 "cadence_import:plan:v1",
                 "operator_review:plan:v1"
               ],
               "invalidated_downstream_product_ids" => [
                 "cadence_import:plan:v1",
                 "operator_review:plan:v1"
               ],
               "dependency_impact_status" => "review_required",
               "dependency_impact_row_count" => 2,
               "timeline_diff_row_count" => 3,
               "timeline_diff_review_required_count" => 2,
               "changed_field_counts" => %{"timeline_presence" => 2},
               "changed_timeline_ids" => [],
               "review_timeline_ids" => ["timeline:health_check:0.0", "timeline:health_check:5.0"],
               "timeline_ids_by_changed_field" => %{
                 "timeline_presence" => ["timeline:health_check:0.0", "timeline:health_check:5.0"]
               },
               "source_timeline_publication_summary" => ^summary,
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.source_result_artifact[0].timeline_publication_summary",
                 "review_type" => "timeline_publication_review",
                 "source_timeline_publication_summary" => ^summary
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh import preserves wrapped timeline lifecycle-state summaries" do
    summary = timeline_lifecycle_state_summary()
    source_lifecycle_state = hd(summary["review_rows"])

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_lifecycle_state_import",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "timeline_lifecycle_state_summary" => summary
        }
      ]
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_lifecycle_state_import",
             "row_count" => 1,
             "review_required_count" => 1,
             "import_action_counts" => %{"review_timeline_lifecycle_state" => 1},
             "source_review_type_counts" => %{"timeline_lifecycle_state_review" => 1}
           } = manifest

    assert [
             %{
               "import_action" => "review_timeline_lifecycle_state",
               "import_status" => "review_required_before_import",
               "source_review_type" => "timeline_lifecycle_state_review",
               "source_review_action" => "review_activity_approval",
               "approval_status" => "operator_review_required",
               "timeline_id" => "timeline:cmd_provider",
               "activity_id" => "cmd_provider",
               "planned_activity_id" => "cmd_provider",
               "realized_activity_id" => "cmd_provider",
               "timeline_lifecycle_state_status" => "review_required",
               "transition_decision" => "review",
               "status_transition_decision" => "record",
               "approval_transition_decision" => "review",
               "required_operator_action" => "review_activity_approval",
               "required_operator_actions" => [
                 "record_timeline_change",
                 "review_activity_approval"
               ],
               "operator_action_reasons" => [
                 "activity_execution_recorded",
                 "approval_grant_requires_operator_authority"
               ],
               "status_transition" => %{
                 "transition_category" => "execution_recorded",
                 "transition_type" => "changed"
               },
               "approval_transition" => %{
                 "transition_category" => "approval_granted",
                 "transition_type" => "changed"
               },
               "planned_status" => "planned",
               "realized_status" => "executed",
               "planned_approval_status" => "pending",
               "realized_approval_status" => "approved",
               "planned_protection_decision" => "mutable",
               "realized_protection_decision" => "preserve",
               "source_planned_activity_count" => 1,
               "source_realized_activity_count" => 1,
               "source_lifecycle_state_review_required_count" => 1,
               "has_cadence_import" => false,
               "source_review_row" => %{
                 "source" =>
                   "candidate_refresh.source_result_artifact[0].timeline_lifecycle_state_summary.review_rows",
                 "review_type" => "timeline_lifecycle_state_review"
               }
             } = row
           ] = manifest["rows"]

    assert row["source_timeline_lifecycle_state"] == source_lifecycle_state

    assert get_in(row, ["source_review_row", "source_timeline_lifecycle_state"]) ==
             source_lifecycle_state

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  defp timeline_dependency_impact_summary do
    source = [
      %{
        id: :health_gate,
        type: :health_check,
        starts_at_s: 0.0,
        ends_at_s: 10.0
      },
      %{
        id: :cmd_combo,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependency_timeline_ids: [:"timeline:health_check:0.0"],
        exclusive_with: [:health_gate]
      }
    ]

    replacement = [
      %{
        id: :health_gate,
        type: :health_check,
        starts_at_s: 5.0,
        ends_at_s: 15.0
      },
      %{
        id: :cmd_combo,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependency_timeline_ids: [:"timeline:health_check:0.0"],
        exclusive_with: [:health_gate]
      }
    ]

    Timeline.dependency_impact_summary(source, replacement)
  end

  defp timeline_publication_summary do
    source = [
      %{id: :health_gate, type: :health_check, starts_at_s: 0.0, ends_at_s: 10.0},
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependencies: [:health_gate]
      }
    ]

    replacement = [
      %{id: :health_gate, type: :health_check, starts_at_s: 5.0, ends_at_s: 15.0},
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependencies: [:health_gate]
      }
    ]

    Timeline.publication_summary(
      %{
        "schema_contract" => "operational_timeline_report.v1",
        "id" => "timeline:published_plan:v2"
      },
      publication_sequence: 7,
      publication_authority: :mission_operations,
      supersedes_artifact_ids: ["timeline:published_plan:v1"],
      downstream_product_ids: ["operator_review:plan:v1", "cadence_import:plan:v1"],
      dependency_impact_summary: Timeline.dependency_impact_summary(source, replacement),
      timeline_diff_summary: Timeline.diff_summary(source, replacement)
    )
  end

  defp timeline_lifecycle_state_summary do
    planned = [
      %{
        id: :cmd_provider,
        type: :command,
        status: :planned,
        approval_status: :pending,
        metadata: %{timeline_id: :"timeline:cmd_provider"}
      }
    ]

    realized = [
      %{
        id: :cmd_provider,
        type: :command,
        status: :executed,
        approval_status: :approved,
        metadata: %{timeline_id: :"timeline:cmd_provider"}
      }
    ]

    Timeline.lifecycle_state_summary(planned, realized)
  end
end
