defmodule OrbitalDynamics.Schema.TimelineChangeSummaryContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "exports and validates timeline publication summary fields" do
    assert {:ok, schema} = Schema.json_schema("timeline_publication_summary.v1")
    stable_id_pattern = Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, ["properties", "schema_contract", "const"]) ==
             "timeline_publication_summary.v1"

    assert get_in(schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_publication_summary"

    assert get_in(schema, ["properties", "validation_level", "const"]) == "artifact_contract"

    assert get_in(schema, ["properties", "publication_id", "pattern"]) == stable_id_pattern
    assert get_in(schema, ["properties", "publication_sequence", "minimum"]) == 0

    assert get_in(schema, ["properties", "publication_status", "enum"]) == [
             "published",
             "published_with_downstream_invalidations",
             "review_required"
           ]

    assert get_in(schema, ["properties", "downstream_invalidation_status", "enum"]) == [
             "clear",
             "invalidated"
           ]

    assert get_in(schema, ["properties", "dependency_impact_status", "enum"]) == [
             "clear",
             "not_evaluated",
             "review_required"
           ]

    assert "timeline_diff_summary.v1" in get_in(schema, [
             "x-orbital-dynamics",
             "nested_contracts"
           ])

    assert get_in(schema, ["properties", "timeline_diff_row_count", "minimum"]) == 0

    assert get_in(schema, [
             "properties",
             "changed_field_counts",
             "additionalProperties",
             "minimum"
           ]) == 0

    assert get_in(schema, [
             "properties",
             "changed_timeline_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(schema, [
             "properties",
             "timeline_ids_by_changed_field",
             "additionalProperties",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(schema, [
             "properties",
             "invalidated_downstream_product_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    timeline_diff_summary =
      OrbitalDynamics.Timeline.diff_summary(
        [
          %{
            id: :health_gate,
            type: :health_check,
            starts_at_s: 0.0,
            ends_at_s: 10.0
          }
        ],
        [
          %{
            id: :health_gate,
            type: :health_check,
            starts_at_s: 5.0,
            ends_at_s: 15.0
          }
        ]
      )

    summary =
      OrbitalDynamics.Timeline.publication_summary(
        %{
          "schema_contract" => "operational_timeline_report.v1",
          "id" => "timeline:published_plan:v2"
        },
        publication_sequence: 2,
        publication_authority: :mission_operations,
        downstream_product_ids: ["cadence_import:plan:v1"],
        invalidated_downstream_product_ids: ["cadence_import:plan:v1"],
        timeline_diff_summary: timeline_diff_summary
      )

    assert summary["source_timeline_diff_summary"] == timeline_diff_summary
    assert summary["timeline_diff_changed_count"] == timeline_diff_summary["changed_count"]

    assert {:ok, %{"schema_contract" => "timeline_publication_summary.v1"}} =
             Schema.validate_artifact(summary)

    stale_source = Map.put(summary, "source", "timeline_diff_report.v1")

    assert {:error, validation_report} = Schema.validate_artifact(stale_source)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.source" and &1["message"] == "must equal source_artifact_type")
           )

    stale_status = Map.put(summary, "publication_status", "published")

    assert {:error, validation_report} = Schema.validate_artifact(stale_status)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.publication_status" and
                 &1["message"] ==
                   "must equal downstream invalidation and dependency impact state")
           )

    stale_downstream_invalidation_status =
      Map.put(summary, "downstream_invalidation_status", "clear")

    assert {:error, validation_report} =
             Schema.validate_artifact(stale_downstream_invalidation_status)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.downstream_invalidation_status" and
                 &1["message"] == "must equal invalidated_downstream_product_ids state")
           )

    stale_model_limits = Map.put(summary, "model_limits", ["artifact_level_only"])

    assert {:error, validation_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match timeline report model limits")
           )

    stale_diff_ids =
      Map.put(summary, "changed_timeline_ids", ["timeline:stale_changed"])

    assert {:error, validation_report} = Schema.validate_artifact(stale_diff_ids)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.changed_timeline_ids" and
                 &1["message"] == "must equal source_timeline_diff_summary.changed_timeline_ids")
           )

    missing_diff_projection =
      Map.delete(summary, "changed_field_counts")

    assert {:error, validation_report} = Schema.validate_artifact(missing_diff_projection)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.changed_field_counts" and
                 &1["message"] ==
                   "must be present when source_timeline_diff_summary is present")
           )

    orphan_diff_count =
      summary
      |> Map.delete("source_timeline_diff_summary")
      |> Map.put("timeline_diff_changed_count", 1)

    assert {:error, validation_report} = Schema.validate_artifact(orphan_diff_count)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.source_timeline_diff_summary" and
                 &1["message"] ==
                   "must be present when timeline diff audit fields are present")
           )

    invalid_downstream_id =
      Map.put(summary, "invalidated_downstream_product_ids", ["bad downstream id"])

    assert {:error, validation_report} = Schema.validate_artifact(invalid_downstream_id)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.invalidated_downstream_product_ids[0]" and
                 &1["message"] =~ "stable ID")
           )

    undeclared_invalidation =
      Map.put(summary, "invalidated_downstream_product_ids", ["operator_review:plan:v1"])

    assert {:error, validation_report} = Schema.validate_artifact(undeclared_invalidation)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.invalidated_downstream_product_ids[0]" and
                 &1["message"] == "must be included in downstream_product_ids")
           )
  end

  test "validates checked-in timeline publication summary fixture" do
    publication_summary = read_json!("study_results/timeline_publication_summary_v1.json")

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

    dependency_impact = OrbitalDynamics.timeline_dependency_impact_summary(source, replacement)
    diff_summary = OrbitalDynamics.timeline_diff_summary(source, replacement)

    generated_publication_summary =
      OrbitalDynamics.timeline_publication_summary(
        %{
          "schema_contract" => "operational_timeline_report.v1",
          "id" => "timeline:published_plan:v2"
        },
        publication_sequence: 7,
        publication_authority: :mission_operations,
        supersedes_artifact_ids: ["timeline:published_plan:v1"],
        downstream_product_ids: ["operator_review:plan:v1", "cadence_import:plan:v1"],
        dependency_impact_summary: dependency_impact,
        timeline_diff_summary: diff_summary
      )

    assert generated_publication_summary == publication_summary

    assert {:ok, %{"schema_contract" => "timeline_publication_summary.v1"}} =
             Schema.validate_artifact(publication_summary)

    assert %{
             "source_artifact_type" => "operational_timeline_report.v1",
             "publication_id" =>
               "timeline_publication:7:timeline:published_plan:v2:timeline:published_plan:v1",
             "publication_sequence" => 7,
             "publication_status" => "published_with_downstream_invalidations",
             "downstream_invalidation_status" => "invalidated",
             "publication_authority" => "mission_operations",
             "supersedes_artifact_ids" => ["timeline:published_plan:v1"],
             "downstream_product_ids" => ["cadence_import:plan:v1", "operator_review:plan:v1"],
             "invalidated_downstream_product_ids" => [
               "cadence_import:plan:v1",
               "operator_review:plan:v1"
             ],
             "dependency_impact_status" => "review_required",
             "dependency_impact_row_count" => 2,
             "impacted_dependency_activity_ids" => ["health_gate"],
             "timeline_diff_row_count" => 3,
             "timeline_diff_changed_count" => 0,
             "timeline_diff_review_required_count" => 2,
             "changed_field_counts" => %{"timeline_presence" => 2},
             "changed_timeline_ids" => [],
             "review_timeline_ids" => [
               "timeline:health_check:0.0",
               "timeline:health_check:5.0"
             ],
             "timeline_ids_by_changed_field" => %{
               "timeline_presence" => [
                 "timeline:health_check:0.0",
                 "timeline:health_check:5.0"
               ]
             },
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "notification_delivery" => "host_system_owned",
               "publication_authority" => "mission_operations",
               "operator_authority" => "not_granted_by_summary"
             }
           } = publication_summary

    assert publication_summary["source_timeline_diff_summary"] == diff_summary
  end

  test "exports and validates timeline dependency-impact summary fields" do
    assert {:ok, schema} = Schema.json_schema("timeline_dependency_impact_summary.v1")
    stable_id_pattern = Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, ["properties", "schema_contract", "const"]) ==
             "timeline_dependency_impact_summary.v1"

    assert get_in(schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_dependency_impact_summary"

    assert get_in(schema, ["properties", "validation_level", "const"]) == "artifact_contract"
    assert get_in(schema, ["properties", "source", "const"]) == "timeline_diff_report.v1"

    assert get_in(schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert get_in(schema, ["properties", "dependency_impact_status", "enum"]) == [
             "clear",
             "review_required"
           ]

    assert get_in(schema, [
             "properties",
             "impacted_exclusive_with_timeline_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(schema, ["properties", "dependency_impact_rows", "items", "required"]) == [
             "id",
             "scope",
             "dependency_impact_status",
             "required_operator_action",
             "operator_action_reason",
             "activity_id",
             "timeline_id",
             "activity_type"
           ]

    assert get_in(schema, [
             "properties",
             "dependency_impact_rows",
             "items",
             "properties",
             "impacted_dependency_activity_ids",
             "items",
             "pattern"
           ]) == stable_id_pattern

    assert get_in(schema, [
             "properties",
             "dependency_impact_rows",
             "items",
             "properties",
             "operator_action_reason",
             "enum"
           ]) == [
             "dependency_changed_or_removed_source_activity",
             "exclusivity_changed_or_removed_source_activity",
             "dependency_and_exclusivity_changed_or_removed_source_activity"
           ]

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

    summary = OrbitalDynamics.Timeline.dependency_impact_summary(source, replacement)

    assert {:ok, %{"schema_contract" => "timeline_dependency_impact_summary.v1"}} =
             Schema.validate_artifact(summary)

    invalid_source = Map.put(summary, "source", "timeline_diff_report.v2")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_source)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.source" and
                 &1["message"] == "must equal \"timeline_diff_report.v1\"")
           )

    invalid_model = Map.put(summary, "model", "custom")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_model)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"artifact_only_timeline_dependency_impact_summary\"")
           )

    stale_model_limits = Map.put(summary, "model_limits", ["artifact_level_only"])

    assert {:error, validation_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match timeline report model limits")
           )

    stale_changed_source_count = Map.put(summary, "changed_source_activity_count", 2)

    assert {:error, validation_report} =
             Schema.validate_artifact(stale_changed_source_count)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.changed_source_activity_count" and
                 &1["message"] == "must equal impacted_source_activity_ids count")
           )

    stale_dependent_timeline_ids =
      Map.put(summary, "source_dependent_timeline_ids", ["timeline:other"])

    assert {:error, validation_report} = Schema.validate_artifact(stale_dependent_timeline_ids)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.source_dependent_timeline_ids" and
                 &1["message"] == "must equal row-derived source_dependent_timeline_ids")
           )

    stale_impact_status = Map.put(summary, "dependency_impact_status", "clear")

    assert {:error, validation_report} = Schema.validate_artifact(stale_impact_status)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.dependency_impact_status" and
                 &1["message"] == "must equal row-derived dependency_impact_status")
           )

    invalid_summary_id =
      Map.put(summary, "impacted_source_activity_ids", ["bad source activity"])

    assert {:error, validation_report} = Schema.validate_artifact(invalid_summary_id)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.impacted_source_activity_ids[0]" and
                 &1["message"] =~ "stable ID")
           )

    invalid_row_scope =
      put_in(summary, ["dependency_impact_rows", Access.at(0), "scope"], "both")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_row_scope)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.dependency_impact_rows[0].scope" and
                 &1["message"] =~ "must be one of")
           )

    invalid_row_impacted_id =
      put_in(
        summary,
        ["dependency_impact_rows", Access.at(0), "impacted_dependency_activity_ids"],
        ["bad dependency"]
      )

    assert {:error, validation_report} = Schema.validate_artifact(invalid_row_impacted_id)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] ==
                 "$.dependency_impact_rows[0].impacted_dependency_activity_ids[0]" and
                 &1["message"] =~ "stable ID")
           )
  end

  test "validates checked-in timeline dependency impact summary fixture" do
    summary = read_json!("study_results/timeline_dependency_impact_summary_v1.json")

    source = [
      %{id: :health_gate, type: :health_check, starts_at_s: 0.0, ends_at_s: 10.0},
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependencies: [:health_gate]
      },
      %{
        id: :dl_followup,
        timeline_id: :"timeline:dl_followup",
        type: :downlink,
        starts_at_s: 40.0,
        ends_at_s: 55.0,
        dependencies: [:cmd_main]
      },
      %{
        id: :obs_parallel,
        type: :observe,
        starts_at_s: 60.0,
        ends_at_s: 70.0,
        exclusive_with: [:dl_followup],
        exclusive_with_timeline_ids: [:"timeline:dl_followup"]
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
      },
      %{
        id: :obs_parallel,
        type: :observe,
        starts_at_s: 60.0,
        ends_at_s: 70.0,
        exclusive_with: [:dl_followup],
        exclusive_with_timeline_ids: [:"timeline:dl_followup"]
      }
    ]

    generated_summary = OrbitalDynamics.timeline_dependency_impact_summary(source, replacement)

    assert generated_summary == summary

    assert {:ok, %{"schema_contract" => "timeline_dependency_impact_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert %{
             "schema_contract" => "timeline_dependency_impact_summary.v1",
             "model" => "artifact_only_timeline_dependency_impact_summary",
             "validation_level" => "artifact_contract",
             "source" => "timeline_diff_report.v1",
             "source_activity_count" => 4,
             "replacement_activity_count" => 3,
             "changed_source_activity_count" => 2,
             "changed_source_timeline_count" => 2,
             "dependency_impact_status" => "review_required",
             "dependent_activity_count" => 4,
             "source_dependent_activity_count" => 2,
             "replacement_dependent_activity_count" => 2,
             "impacted_source_activity_ids" => ["dl_followup", "health_gate"],
             "impacted_source_timeline_ids" => [
               "timeline:dl_followup",
               "timeline:health_check:0.0"
             ],
             "dependent_activity_ids" => ["cmd_main", "obs_parallel"],
             "dependent_timeline_ids" => [
               "timeline:command:20.0",
               "timeline:observe:60.0"
             ],
             "source_dependent_activity_ids" => ["cmd_main", "obs_parallel"],
             "source_dependent_timeline_ids" => [
               "timeline:command:20.0",
               "timeline:observe:60.0"
             ],
             "replacement_dependent_activity_ids" => ["cmd_main", "obs_parallel"],
             "replacement_dependent_timeline_ids" => [
               "timeline:command:20.0",
               "timeline:observe:60.0"
             ],
             "impacted_dependency_activity_ids" => ["health_gate"],
             "impacted_dependency_timeline_ids" => [],
             "impacted_exclusive_with_activity_ids" => ["dl_followup"],
             "impacted_exclusive_with_timeline_ids" => ["timeline:dl_followup"],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "operator_authority" => "not_granted_by_summary"
             }
           } = summary

    assert Enum.map(summary["dependency_impact_rows"], &{&1["scope"], &1["activity_id"]}) == [
             {"source", "cmd_main"},
             {"source", "obs_parallel"},
             {"replacement", "cmd_main"},
             {"replacement", "obs_parallel"}
           ]

    assert Enum.map(summary["dependency_impact_rows"], & &1["required_operator_action"])
           |> Enum.uniq() == ["review_timeline_integrity"]

    assert summary["model_limits"] == OrbitalDynamics.Timeline.model_limits()
  end

  test "exports and validates timeline integrity report fields" do
    assert {:ok, schema} = Schema.json_schema("timeline_integrity_report.v1")

    assert get_in(schema, ["properties", "schema_contract", "const"]) ==
             "timeline_integrity_report.v1"

    assert get_in(schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_integrity_summary"

    assert get_in(schema, ["properties", "validation_level", "const"]) == "artifact_contract"
    assert get_in(schema, ["properties", "source", "type"]) == "string"

    assert get_in(schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert get_in(schema, [
             "properties",
             "timeline_integrity_issue_types",
             "items",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().timeline_integrity_issue_types

    assert get_in(schema, [
             "properties",
             "review_timeline_ids_by_required_operator_action",
             "additionalProperties",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, ["properties", "rows", "items", "required"]) == [
             "id",
             "activity_id",
             "timeline_id",
             "activity_type",
             "status",
             "approval_status",
             "locked",
             "has_source_window",
             "has_cadence_import",
             "timeline_identity"
           ]

    row_properties = get_in(schema, ["properties", "rows", "items", "properties"])

    assert get_in(row_properties, ["command_window_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_properties, ["command_window_type", "type"]) == "string"

    assert get_in(row_properties, [
             "timeline_integrity_issues",
             "items",
             "required"
           ]) == ["type"]

    assert get_in(row_properties, [
             "timeline_integrity_issues",
             "items",
             "properties",
             "type",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().timeline_integrity_issue_types

    assert get_in(row_properties, [
             "timeline_integrity_issues",
             "items",
             "properties",
             "dependency_order_violation_activity_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    activities = [
      %{
        id: :health_gate,
        type: :health_check,
        starts_at_s: 0.0,
        ends_at_s: 15.0,
        metadata: %{timeline_id: :"timeline:health_gate"}
      },
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        dependencies: [:health_gate, :missing_gate],
        metadata: %{timeline_id: :"timeline:cmd_main"}
      }
    ]

    report = OrbitalDynamics.Timeline.integrity_report(activities, source: "repair.activities")

    assert {:ok, %{"schema_contract" => "timeline_integrity_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_model = Map.put(report, "model", "custom")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_model)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"artifact_only_timeline_integrity_summary\"")
           )

    invalid_source = Map.put(report, "source", %{"artifact" => "repair.activities"})

    assert {:error, validation_report} = Schema.validate_artifact(invalid_source)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.source" and &1["message"] == "must be a binary")
           )

    stale_model_limits = Map.put(report, "model_limits", ["artifact_level_only"])

    assert {:error, validation_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match timeline report model limits")
           )

    stale_review_count = Map.put(report, "timeline_integrity_review_count", 99)

    assert {:error, validation_report} = Schema.validate_artifact(stale_review_count)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.timeline_integrity_review_count" and
                 &1["message"] == "must equal row-derived timeline_integrity_review_count")
           )

    stale_row_issue_types =
      put_in(report, ["rows", Access.at(0), "timeline_integrity_issue_types"], [])

    assert {:error, validation_report} = Schema.validate_artifact(stale_row_issue_types)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.rows[0].timeline_integrity_issue_types" and
                 &1["message"] == "must equal row-derived timeline_integrity_issue_types")
           )

    unknown_top_level_issue_type =
      Map.put(report, "timeline_integrity_issue_types", ["provider_custom"])

    assert {:error, validation_report} = Schema.validate_artifact(unknown_top_level_issue_type)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.timeline_integrity_issue_types[0]" and
                 &1["message"] =~ "must be one of")
           )

    unknown_row_issue_type =
      put_in(report, ["rows", Access.at(0), "timeline_integrity_issue_types"], [
        "provider_custom"
      ])

    assert {:error, validation_report} = Schema.validate_artifact(unknown_row_issue_type)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.rows[0].timeline_integrity_issue_types[0]" and
                 &1["message"] =~ "must be one of")
           )

    stale_action_map =
      put_in(
        report,
        ["review_timeline_ids_by_required_operator_action", "review_timeline_integrity"],
        ["timeline:health_gate"]
      )

    assert {:error, validation_report} = Schema.validate_artifact(stale_action_map)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.review_timeline_ids_by_required_operator_action" and
                 &1["message"] ==
                   "must equal row-derived review_timeline_ids_by_required_operator_action")
           )

    invalid_action_map_shape =
      Map.put(report, "review_timeline_ids_by_required_operator_action", "wrong-type")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_action_map_shape)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.review_timeline_ids_by_required_operator_action" and
                 &1["message"] == "must be a map")
           )

    invalid_action_map_id =
      put_in(
        report,
        ["review_timeline_ids_by_required_operator_action", "review_timeline_integrity"],
        ["bad timeline"]
      )

    assert {:error, validation_report} = Schema.validate_artifact(invalid_action_map_id)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] ==
                 "$.review_timeline_ids_by_required_operator_action.review_timeline_integrity[0]" and
                 &1["message"] =~ "stable ID")
           )
  end

  test "validates checked-in timeline integrity report fixture" do
    report = read_json!("study_results/timeline_integrity_report_v1.json")

    activities = [
      %{
        id: :health_gate,
        type: :health_check,
        starts_at_s: 0.0,
        ends_at_s: 15.0,
        ground_station_id: :dss_14,
        direction: :command
      },
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        ground_station_id: :dss_14,
        direction: :command,
        dependencies: [:health_gate, :missing_gate],
        exclusive_with: [:dl_conflict]
      },
      %{
        id: :dl_conflict,
        type: :downlink,
        starts_at_s: 12.0,
        ends_at_s: 22.0,
        ground_station_id: :dss_14,
        direction: :downlink
      }
    ]

    generated_report = OrbitalDynamics.timeline_integrity_report(activities, [])

    assert generated_report == report

    assert {:ok, %{"schema_contract" => "timeline_integrity_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "schema_contract" => "timeline_integrity_report.v1",
             "model" => "artifact_only_timeline_integrity_summary",
             "validation_level" => "artifact_contract",
             "source" => "timeline.activities",
             "activity_count" => 3,
             "valid_activity_count" => 3,
             "invalid_activity_input_count" => 0,
             "timeline_integrity_status" => "review_required",
             "timeline_integrity_review_count" => 1,
             "timeline_integrity_issue_count" => 3,
             "timeline_integrity_issue_types" => [
               "dependency_order_violation",
               "exclusivity_overlap",
               "missing_dependency_activity"
             ],
             "timeline_integrity_issue_type_counts" => %{
               "dependency_order_violation" => 1,
               "exclusivity_overlap" => 1,
               "missing_dependency_activity" => 1
             },
             "required_operator_action_counts" => %{"review_timeline_integrity" => 1},
             "operator_action_reason_counts" => %{"timeline_integrity_issue" => 1},
             "dependency_issue_count" => 2,
             "exclusivity_issue_count" => 1,
             "review_activity_ids" => ["cmd_main"],
             "review_timeline_ids" => ["timeline:command:dss_14:10.0"],
             "review_activity_ids_by_issue_type" => %{
               "dependency_order_violation" => ["cmd_main"],
               "exclusivity_overlap" => ["cmd_main"],
               "missing_dependency_activity" => ["cmd_main"]
             },
             "review_timeline_ids_by_issue_type" => %{
               "dependency_order_violation" => ["timeline:command:dss_14:10.0"],
               "exclusivity_overlap" => ["timeline:command:dss_14:10.0"],
               "missing_dependency_activity" => ["timeline:command:dss_14:10.0"]
             },
             "review_activity_ids_by_required_operator_action" => %{
               "review_timeline_integrity" => ["cmd_main"]
             },
             "review_timeline_ids_by_required_operator_action" => %{
               "review_timeline_integrity" => ["timeline:command:dss_14:10.0"]
             },
             "review_activity_ids_by_operator_action_reason" => %{
               "timeline_integrity_issue" => ["cmd_main"]
             },
             "review_timeline_ids_by_operator_action_reason" => %{
               "timeline_integrity_issue" => ["timeline:command:dss_14:10.0"]
             },
             "dependency_review_activity_ids" => ["cmd_main"],
             "dependency_review_timeline_ids" => ["timeline:command:dss_14:10.0"],
             "exclusivity_review_activity_ids" => ["cmd_main"],
             "exclusivity_review_timeline_ids" => ["timeline:command:dss_14:10.0"],
             "invalid_activity_input_ids" => [],
             "missing_dependency_activity_ids" => ["missing_gate"],
             "missing_dependency_timeline_ids" => [],
             "dependency_cycle_activity_ids" => [],
             "dependency_cycle_timeline_ids" => [],
             "dependency_order_violation_activity_ids" => ["health_gate"],
             "dependency_order_violation_timeline_ids" => [],
             "exclusivity_violation_activity_ids" => ["dl_conflict"],
             "exclusivity_violation_timeline_ids" => ["timeline:downlink:dss_14:12.0"],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "scope" => "dependency_and_exclusivity_integrity_validation",
               "missing_dependency_validation" => "enabled",
               "source" => "timeline.activities"
             },
             "model_limits" => [
               "artifact_level_only",
               "no_schedule_mutation",
               "no_command_execution",
               "derived_identity_when_no_persistent_timeline_id"
             ]
           } = report

    assert [
             %{
               "id" => "timeline_row:2:cmd_main",
               "activity_id" => "cmd_main",
               "timeline_id" => "timeline:command:dss_14:10.0",
               "activity_type" => "command",
               "status" => "planned",
               "approval_status" => "not_evaluated",
               "required_operator_action" => "review_timeline_integrity",
               "operator_action_reason" => "timeline_integrity_issue",
               "timeline_integrity_status" => "review_required",
               "timeline_integrity_issue_count" => 3,
               "timeline_integrity_issue_types" => [
                 "dependency_order_violation",
                 "exclusivity_overlap",
                 "missing_dependency_activity"
               ],
               "missing_dependency_activity_ids" => ["missing_gate"],
               "dependency_order_violation_activity_ids" => ["health_gate"],
               "exclusivity_violation_activity_ids" => ["dl_conflict"],
               "exclusivity_violation_timeline_ids" => ["timeline:downlink:dss_14:12.0"],
               "dependency_activity_ids" => ["health_gate", "missing_gate"],
               "exclusive_with_activity_ids" => ["dl_conflict"],
               "timeline_identity" => %{
                 "activity_id" => "cmd_main",
                 "activity_type" => "command",
                 "subject_id" => "dss_14",
                 "timeline_id" => "timeline:command:dss_14:10.0"
               },
               "activity_context" => %{
                 "command_window_id" => "command_window:cmd_main",
                 "command_window_type" => "command_window",
                 "dependencies" => ["health_gate", "missing_gate"],
                 "dependency_activity_ids" => ["health_gate", "missing_gate"],
                 "direction" => "command",
                 "duration_s" => 10.0,
                 "ends_at_s" => 20.0,
                 "exclusive_with_activity_ids" => ["dl_conflict"],
                 "ground_station_id" => "dss_14",
                 "starts_at_s" => 10.0,
                 "timeline_identity" => %{
                   "activity_id" => "cmd_main",
                   "activity_type" => "command",
                   "subject_id" => "dss_14",
                   "timeline_id" => "timeline:command:dss_14:10.0"
                 }
               }
             }
           ] = report["rows"]

    assert [
             %{"type" => "dependency_order_violation"},
             %{"type" => "missing_dependency_activity"},
             %{"type" => "exclusivity_overlap"}
           ] = hd(report["rows"])["timeline_integrity_issues"]
  end

  test "exports and validates timeline diff summary fields" do
    assert {:ok, schema} = Schema.json_schema("timeline_diff_summary.v1")

    assert get_in(schema, ["properties", "schema_contract", "const"]) ==
             "timeline_diff_summary.v1"

    assert get_in(schema, ["properties", "model", "const"]) ==
             "artifact_only_timeline_diff_summary"

    assert get_in(schema, ["properties", "validation_level", "const"]) == "artifact_contract"

    assert get_in(schema, ["properties", "source_artifact_type", "const"]) ==
             "timeline_diff_report.v1"

    assert get_in(schema, ["properties", "model_limits", "const"]) ==
             OrbitalDynamics.Timeline.model_limits()

    assert get_in(schema, [
             "properties",
             "diff_status_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().timeline_diff_statuses

    assert get_in(schema, [
             "properties",
             "review_timeline_ids_by_required_operator_action",
             "additionalProperties",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, [
             "properties",
             "review_rows",
             "items",
             "required"
           ]) == [
             "id",
             "rank",
             "timeline_id",
             "diff_status",
             "changed_fields",
             "requires_operator_review",
             "required_operator_action",
             "reason"
           ]

    review_row_properties =
      get_in(schema, ["properties", "review_rows", "items", "properties"])

    assert get_in(review_row_properties, ["operator_action_reason", "type"]) == "string"

    for field <- [
          "source_ground_station_id",
          "replacement_ground_station_id",
          "source_source_window_id",
          "replacement_source_window_id",
          "source_spacecraft_id",
          "replacement_spacecraft_id",
          "source_target_id",
          "replacement_target_id"
        ] do
      assert get_in(review_row_properties, [field, "pattern"]) ==
               Schema.identity_policy()["stable_id_pattern"]
    end

    protected_source = %{
      id: :cmd_lock,
      type: :command,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 10.0,
      ends_at_s: 20.0,
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    protected_replacement = %{
      id: :cmd_lock,
      type: :command,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 12.0,
      ends_at_s: 22.0,
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    added = %{
      id: :new_cmd,
      type: :command,
      starts_at_s: 70.0,
      ends_at_s: 80.0,
      metadata: %{timeline_id: :"timeline:new_cmd"}
    }

    summary =
      OrbitalDynamics.Timeline.diff_summary(
        [protected_source],
        [protected_replacement, added],
        source: "repair.activities"
      )

    assert {:ok, %{"schema_contract" => "timeline_diff_summary.v1"}} =
             Schema.validate_artifact(summary)

    invalid_review_row_evidence_id =
      put_in(summary, ["review_rows", Access.at(0), "source_spacecraft_id"], "bad id")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_review_row_evidence_id)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.review_rows[0].source_spacecraft_id" and
                 &1["message"] =~ "stable ID")
           )

    invalid_source_contract = Map.put(summary, "source_artifact_type", "timeline_diff_report.v2")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_source_contract)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.source_artifact_type" and
                 &1["message"] == "must equal \"timeline_diff_report.v1\"")
           )

    stale_model_limits = Map.put(summary, "model_limits", ["artifact_level_only"])

    assert {:error, validation_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match timeline report model limits")
           )

    stale_review_count = Map.put(summary, "review_required_count", 1)

    assert {:error, validation_report} = Schema.validate_artifact(stale_review_count)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.review_required_count" and
                 &1["message"] == "must equal row-derived review_required_count")
           )

    stale_action_map =
      put_in(
        summary,
        ["review_timeline_ids_by_required_operator_action", "review_added_activity"],
        ["timeline:cmd_lock"]
      )

    assert {:error, validation_report} = Schema.validate_artifact(stale_action_map)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.review_timeline_ids_by_required_operator_action" and
                 &1["message"] ==
                   "must equal row-derived review_timeline_ids_by_required_operator_action")
           )

    invalid_action_map_id =
      put_in(
        summary,
        ["review_timeline_ids_by_required_operator_action", "review_added_activity"],
        ["bad timeline"]
      )

    assert {:error, validation_report} = Schema.validate_artifact(invalid_action_map_id)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] ==
                 "$.review_timeline_ids_by_required_operator_action.review_added_activity[0]" and
                 &1["message"] =~ "stable ID")
           )
  end

  test "validates checked-in timeline diff summary fixture" do
    summary = read_json!("study_results/timeline_diff_summary_v1.json")

    source = [
      %{
        id: :obs_1,
        type: :observe,
        scenario_id: :leo_1,
        spacecraft_id: :leo_1,
        target_id: :target_a,
        source_window_id: :target_a_window_1,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        status: :approved,
        approval_status: :approved,
        metadata: %{timeline_id: :"timeline:obs_1"}
      },
      %{
        id: :dl_removed,
        type: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :leo_1,
        ground_station_id: :dss_14,
        source_window_id: :dss_14_pass_removed,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        metadata: %{timeline_id: :"timeline:dl_removed"}
      }
    ]

    replacement = [
      %{
        id: :obs_1b,
        type: :observe,
        scenario_id: :leo_1,
        spacecraft_id: :leo_1,
        target_id: :target_a,
        source_window_id: :target_a_window_1,
        starts_at_s: 12.0,
        ends_at_s: 22.0,
        status: :planned,
        approval_status: :pending,
        metadata: %{timeline_id: :"timeline:obs_1"}
      },
      %{
        id: :cmd_added,
        type: :command,
        scenario_id: :leo_1,
        spacecraft_id: :leo_1,
        ground_station_id: :dss_14,
        source_window_id: :dss_14_pass_added,
        starts_at_s: 50.0,
        ends_at_s: 55.0,
        metadata: %{timeline_id: :"timeline:cmd_added"}
      }
    ]

    generated_summary =
      OrbitalDynamics.timeline_diff_summary(source, replacement, source: "repair.activities")

    assert generated_summary == summary

    assert {:ok, %{"schema_contract" => "timeline_diff_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert %{
             "schema_contract" => "timeline_diff_summary.v1",
             "model" => "artifact_only_timeline_diff_summary",
             "validation_level" => "artifact_contract",
             "source_artifact_type" => "timeline_diff_report.v1",
             "source" => "repair.activities",
             "source_activity_count" => 2,
             "replacement_activity_count" => 2,
             "row_count" => 3,
             "added_count" => 1,
             "removed_count" => 1,
             "changed_count" => 1,
             "unchanged_count" => 0,
             "review_required_count" => 3,
             "diff_status_counts" => %{"added" => 1, "changed" => 1, "removed" => 1},
             "transition_decision_counts" => %{"preserve_source" => 1, "review" => 2},
             "required_operator_action_counts" => %{
               "review_added_activity" => 1,
               "review_changed_protected_activity" => 1,
               "review_removed_activity" => 1
             },
             "status_transition_category_counts" => %{
               "status_added" => 1,
               "status_changed" => 1,
               "status_removed" => 1
             },
             "approval_transition_category_counts" => %{
               "approval_regressed" => 1,
               "approval_removed" => 1,
               "approval_review_required" => 1
             },
             "changed_field_counts" => %{
               "activity_id" => 1,
               "approval_status" => 1,
               "ends_at_s" => 1,
               "starts_at_s" => 1,
               "status" => 1,
               "timeline_presence" => 2
             },
             "added_timeline_ids" => ["timeline:cmd_added"],
             "removed_timeline_ids" => ["timeline:dl_removed"],
             "changed_timeline_ids" => ["timeline:obs_1"],
             "unchanged_timeline_ids" => [],
             "review_timeline_ids" => [
               "timeline:cmd_added",
               "timeline:dl_removed",
               "timeline:obs_1"
             ],
             "review_timeline_ids_by_required_operator_action" => %{
               "review_added_activity" => ["timeline:cmd_added"],
               "review_changed_protected_activity" => ["timeline:obs_1"],
               "review_removed_activity" => ["timeline:dl_removed"]
             },
             "review_timeline_ids_by_status_transition_category" => %{
               "status_added" => ["timeline:cmd_added"],
               "status_changed" => ["timeline:obs_1"],
               "status_removed" => ["timeline:dl_removed"]
             },
             "review_timeline_ids_by_approval_transition_category" => %{
               "approval_regressed" => ["timeline:obs_1"],
               "approval_removed" => ["timeline:dl_removed"],
               "approval_review_required" => ["timeline:cmd_added"]
             },
             "timeline_ids_by_changed_field" => %{
               "activity_id" => ["timeline:obs_1"],
               "approval_status" => ["timeline:obs_1"],
               "ends_at_s" => ["timeline:obs_1"],
               "starts_at_s" => ["timeline:obs_1"],
               "status" => ["timeline:obs_1"],
               "timeline_presence" => ["timeline:cmd_added", "timeline:dl_removed"]
             },
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "operator_authority" => "not_granted_by_summary"
             }
           } = summary

    assert Enum.map(summary["review_rows"], & &1["timeline_id"]) == [
             "timeline:cmd_added",
             "timeline:dl_removed",
             "timeline:obs_1"
           ]

    assert summary["model_limits"] == OrbitalDynamics.Timeline.model_limits()
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
