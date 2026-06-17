defmodule OrbitalDynamics.Schema.CandidateRejectionContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "validates standalone candidate rejection report contracts" do
    report = %{
      "schema_contract" => "candidate_rejection_report.v1",
      "model" => "artifact_only_candidate_rejection_explanation",
      "source" => "operational_timeline.candidate_rows",
      "candidate_count" => 2,
      "row_count" => 2,
      "rejected_count" => 1,
      "not_rejected_count" => 1,
      "reviewable_count" => 1,
      "invalid_candidate_input_count" => 0,
      "rejection_reason_counts" => %{"station_unavailable" => 1},
      "model_limits" => [
        "artifact_only",
        "does_not_select_candidates",
        "does_not_mutate_schedules",
        "derived_reasons_use_declared_candidate_fields"
      ],
      "required_operator_action_counts" => %{
        "none" => 1,
        "review_candidate_rejection" => 1
      },
      "candidate_ids_by_required_operator_action" => %{
        "none" => ["candidate_2"],
        "review_candidate_rejection" => ["candidate_1"]
      },
      "rows" => [
        %{
          "id" => "candidate_rejection:candidate_1",
          "candidate_id" => "candidate_1",
          "rejection_status" => "rejected",
          "rejection_reasons" => ["station_unavailable"],
          "reason_count" => 1,
          "reviewable" => true,
          "required_operator_action" => "review_candidate_rejection",
          "activity_context" => %{"activity_id" => "candidate_1"}
        },
        %{
          "id" => "candidate_rejection:candidate_2",
          "candidate_id" => "candidate_2",
          "rejection_status" => "not_rejected",
          "rejection_reasons" => [],
          "reason_count" => 0,
          "reviewable" => false,
          "required_operator_action" => "none",
          "activity_context" => %{"activity_id" => "candidate_2"}
        }
      ],
      "assumptions" => %{"execution_boundary" => "artifact_only_no_schedule_mutation"}
    }

    assert {:ok, %{"schema_contract" => "candidate_rejection_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_model = Map.put(report, "model", "candidate_rejection_explanation")

    assert {:error, model_report} = Schema.validate_artifact(invalid_model)

    assert Enum.any?(
             model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"artifact_only_candidate_rejection_explanation\"")
           )

    stale_model_limits = Map.put(report, "model_limits", ["artifact_only"])

    assert {:error, model_limits_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match candidate rejection report model limits")
           )

    invalid_source = Map.put(report, "source", %{"id" => "candidate_rows"})

    assert {:error, source_report} = Schema.validate_artifact(invalid_source)

    assert Enum.any?(
             source_report["errors"],
             &(&1["path"] == "$.source" and &1["message"] == "must be a binary")
           )

    invalid_negative_count = Map.put(report, "candidate_count", -1)

    assert {:error, negative_count_report} = Schema.validate_artifact(invalid_negative_count)
    assert Enum.any?(negative_count_report["errors"], &(&1["path"] == "$.candidate_count"))

    invalid_float_count = Map.put(report, "reviewable_count", 1.0)

    assert {:error, float_count_report} = Schema.validate_artifact(invalid_float_count)
    assert Enum.any?(float_count_report["errors"], &(&1["path"] == "$.reviewable_count"))

    invalid_reason_count = put_in(report, ["rows", Access.at(0), "reason_count"], -1)

    assert {:error, reason_count_report} = Schema.validate_artifact(invalid_reason_count)
    assert Enum.any?(reason_count_report["errors"], &(&1["path"] == "$.rows[0].reason_count"))

    invalid_reason_counts =
      put_in(report, ["rejection_reason_counts"], %{"station_unavailable" => -1})

    assert {:error, reason_counts_report} = Schema.validate_artifact(invalid_reason_counts)

    assert Enum.any?(
             reason_counts_report["errors"],
             &(&1["path"] == "$.rejection_reason_counts.station_unavailable")
           )

    stale_action_ids =
      put_in(
        report,
        ["candidate_ids_by_required_operator_action", "review_candidate_rejection"],
        [
          "stale_candidate"
        ]
      )

    assert {:error, stale_action_ids_report} = Schema.validate_artifact(stale_action_ids)

    assert Enum.any?(
             stale_action_ids_report["errors"],
             &(&1["path"] == "$.candidate_ids_by_required_operator_action" and
                 &1["message"] ==
                   "must equal row-derived candidate_ids_by_required_operator_action")
           )

    invalid_action_ids =
      put_in(report, ["candidate_ids_by_required_operator_action", "unsupported_action"], [
        "candidate_1"
      ])

    assert {:error, invalid_action_ids_report} = Schema.validate_artifact(invalid_action_ids)

    assert Enum.any?(
             invalid_action_ids_report["errors"],
             &(&1["path"] == "$.candidate_ids_by_required_operator_action.unsupported_action" and
                 &1["message"] == "must use a supported candidate rejection action")
           )

    assert {:ok, schema} = Schema.json_schema("candidate_rejection_report.v1")

    assert get_in(schema, ["properties", "model", "const"]) ==
             "artifact_only_candidate_rejection_explanation"

    assert get_in(schema, ["properties", "source", "type"]) == "string"

    assert get_in(schema, ["properties", "model_limits", "const"]) == [
             "artifact_only",
             "does_not_select_candidates",
             "does_not_mutate_schedules",
             "derived_reasons_use_declared_candidate_fields"
           ]

    assert get_in(schema, ["properties", "model_limits", "items", "enum"]) == [
             "artifact_only",
             "does_not_select_candidates",
             "does_not_mutate_schedules",
             "derived_reasons_use_declared_candidate_fields"
           ]

    assert get_in(schema, ["properties", "candidate_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "row_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "invalid_candidate_input_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "rejection_reason_counts", "additionalProperties"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(schema, ["properties", "rejection_reason_counts", "propertyNames", "enum"]) ==
             OrbitalDynamics.Timeline.capabilities().candidate_rejection_reasons

    assert get_in(schema, [
             "properties",
             "required_operator_action_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().candidate_rejection_actions

    assert get_in(schema, [
             "properties",
             "candidate_ids_by_required_operator_action",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.Timeline.capabilities().candidate_rejection_actions

    assert get_in(schema, [
             "properties",
             "candidate_ids_by_required_operator_action",
             "additionalProperties",
             "items",
             "pattern"
           ]) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(schema, [
             "properties",
             "rows",
             "items",
             "properties",
             "activity_context",
             "properties",
             "capacity_pack_capacity_fraction"
           ]) == %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0}
  end
end
