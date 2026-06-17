defmodule OrbitalDynamics.Schema.ReviewImportHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "exports dependency-impact handoff fields on review and import row schemas" do
    stable_id_pattern = Schema.identity_policy()["stable_id_pattern"]

    for contract <- ["operator_review_package.v1", "cadence_import_manifest.v1"] do
      assert {:ok, schema} = Schema.json_schema(contract)
      row_properties = get_in(schema, ["properties", "rows", "items", "properties"])

      assert get_in(row_properties, ["dependency_impact_scope", "enum"]) == [
               "source",
               "replacement"
             ]

      Enum.each(
        [
          "changed_source_activity_count",
          "changed_source_timeline_count",
          "dependent_activity_count",
          "source_dependent_activity_count",
          "replacement_dependent_activity_count"
        ],
        fn field ->
          assert Map.get(row_properties, field) == %{"type" => "integer", "minimum" => 0}
        end
      )

      Enum.each(
        [
          "impacted_source_activity_ids",
          "impacted_source_timeline_ids",
          "dependent_activity_ids",
          "dependent_timeline_ids",
          "source_dependent_activity_ids",
          "source_dependent_timeline_ids",
          "replacement_dependent_activity_ids",
          "replacement_dependent_timeline_ids",
          "dependency_activity_ids",
          "dependency_timeline_ids",
          "exclusive_with_activity_ids",
          "exclusive_with_timeline_ids",
          "impacted_dependency_activity_ids",
          "impacted_dependency_timeline_ids",
          "impacted_exclusive_with_activity_ids",
          "impacted_exclusive_with_timeline_ids"
        ],
        fn field ->
          assert get_in(row_properties, [field, "items", "pattern"]) == stable_id_pattern
        end
      )

      assert get_in(row_properties, ["source_timeline_dependency_impact", "type"]) == "object"

      assert get_in(row_properties, [
               "source_timeline_dependency_impact",
               "properties",
               "scope",
               "enum"
             ]) == ["source", "replacement"]

      assert get_in(row_properties, [
               "source_timeline_dependency_impact",
               "properties",
               "dependency_impact_status",
               "enum"
             ]) == ["review_required"]

      assert get_in(row_properties, [
               "source_timeline_dependency_impact",
               "properties",
               "impacted_dependency_activity_ids",
               "items",
               "pattern"
             ]) == stable_id_pattern

      assert get_in(row_properties, ["publication_id", "pattern"]) == stable_id_pattern
      assert get_in(row_properties, ["publication_sequence", "minimum"]) == 0

      assert get_in(row_properties, ["publication_status", "enum"]) == [
               "published",
               "published_with_downstream_invalidations",
               "review_required"
             ]

      assert get_in(row_properties, ["downstream_invalidation_status", "enum"]) == [
               "clear",
               "invalidated"
             ]

      assert get_in(row_properties, ["publication_authority", "pattern"]) == stable_id_pattern

      Enum.each(
        [
          "supersedes_artifact_ids",
          "downstream_product_ids",
          "invalidated_downstream_product_ids",
          "changed_timeline_ids",
          "review_timeline_ids"
        ],
        fn field ->
          assert get_in(row_properties, [field, "items", "pattern"]) == stable_id_pattern
        end
      )

      Enum.each(
        [
          "dependency_impact_row_count",
          "timeline_diff_row_count",
          "timeline_diff_changed_count",
          "timeline_diff_review_required_count"
        ],
        fn field ->
          assert Map.get(row_properties, field) == %{"type" => "integer", "minimum" => 0}
        end
      )

      assert get_in(row_properties, [
               "changed_field_counts",
               "additionalProperties",
               "minimum"
             ]) == 0

      assert get_in(row_properties, [
               "timeline_ids_by_changed_field",
               "additionalProperties",
               "items",
               "pattern"
             ]) == stable_id_pattern

      assert get_in(row_properties, ["source_timeline_publication_summary", "type"]) == "object"

      assert get_in(row_properties, [
               "source_timeline_publication_summary",
               "properties",
               "schema_contract",
               "const"
             ]) == "timeline_publication_summary.v1"
    end
  end

  test "exports operational timeline precondition handoff fields on review and import row schemas" do
    capabilities = OrbitalDynamics.Timeline.capabilities()

    assert_precondition_handoff_schema = fn properties ->
      assert get_in(properties, ["precondition_status", "enum"]) ==
               capabilities.activity_precondition_statuses

      assert Map.get(properties, "blocked_precondition_count") == %{
               "type" => "integer",
               "minimum" => 0
             }

      assert Map.get(properties, "review_precondition_count") == %{
               "type" => "integer",
               "minimum" => 0
             }

      assert get_in(properties, ["blocked_precondition_types", "items", "type"]) == "string"
      assert get_in(properties, ["review_precondition_types", "items", "type"]) == "string"

      assert get_in(properties, [
               "preconditions",
               "items",
               "properties",
               "type",
               "enum"
             ]) == capabilities.activity_precondition_types

      assert get_in(properties, [
               "preconditions",
               "items",
               "properties",
               "status",
               "enum"
             ]) == capabilities.activity_precondition_statuses

      assert get_in(properties, ["preconditions", "items", "required"]) == [
               "type",
               "status",
               "field",
               "reason"
             ]

      assert get_in(properties, [
               "preconditions",
               "items",
               "properties",
               "value",
               "type"
             ]) == ["string", "number", "boolean", "object"]
    end

    for contract <- ["operator_review_package.v1", "cadence_import_manifest.v1"] do
      assert {:ok, schema} = Schema.json_schema(contract)
      row_properties = get_in(schema, ["properties", "rows", "items", "properties"])

      assert_precondition_handoff_schema.(row_properties)

      source_operational_timeline_properties =
        get_in(row_properties, ["source_operational_timeline", "properties"])

      assert_precondition_handoff_schema.(source_operational_timeline_properties)
    end

    assert {:ok, cadence_schema} = Schema.json_schema("cadence_import_manifest.v1")

    source_review_row_properties =
      get_in(cadence_schema, [
        "properties",
        "rows",
        "items",
        "properties",
        "source_review_row",
        "properties"
      ])

    assert_precondition_handoff_schema.(source_review_row_properties)

    source_review_operational_timeline_properties =
      get_in(source_review_row_properties, ["source_operational_timeline", "properties"])

    assert_precondition_handoff_schema.(source_review_operational_timeline_properties)
  end

  test "exports command authority handoff fields on review and import row schemas" do
    string_fields = [
      "command_authority_status",
      "planned_command_authority_status",
      "realized_command_authority_status",
      "command_authority_status_match_status",
      "required_authority",
      "planned_required_authority",
      "realized_required_authority",
      "required_authority_match_status",
      "command_safety_status",
      "planned_command_safety_status",
      "realized_command_safety_status",
      "command_safety_status_match_status",
      "command_authorized_match_status",
      "command_safety_checked_match_status"
    ]

    boolean_fields = [
      "command_authorized",
      "planned_command_authorized",
      "realized_command_authorized",
      "command_safety_checked",
      "planned_command_safety_checked",
      "realized_command_safety_checked"
    ]

    operational_timeline_string_fields = [
      "command_authority_status",
      "required_authority",
      "command_safety_status"
    ]

    operational_timeline_boolean_fields = [
      "command_authorized",
      "command_safety_checked"
    ]

    for contract <- ["operator_review_package.v1", "cadence_import_manifest.v1"] do
      assert {:ok, schema} = Schema.json_schema(contract)
      row_properties = get_in(schema, ["properties", "rows", "items", "properties"])

      Enum.each(string_fields, fn field ->
        assert get_in(row_properties, [field, "type"]) == "string"
      end)

      Enum.each(boolean_fields, fn field ->
        assert get_in(row_properties, [field, "type"]) == "boolean"
      end)

      source_operational_timeline_properties =
        get_in(row_properties, ["source_operational_timeline", "properties"])

      Enum.each(operational_timeline_string_fields, fn field ->
        assert get_in(source_operational_timeline_properties, [field, "type"]) == "string"
      end)

      Enum.each(operational_timeline_boolean_fields, fn field ->
        assert get_in(source_operational_timeline_properties, [field, "type"]) == "boolean"
      end)
    end

    assert {:ok, cadence_schema} = Schema.json_schema("cadence_import_manifest.v1")

    source_review_row_properties =
      get_in(cadence_schema, [
        "properties",
        "rows",
        "items",
        "properties",
        "source_review_row",
        "properties"
      ])

    Enum.each(string_fields, fn field ->
      assert get_in(source_review_row_properties, [field, "type"]) == "string"
    end)

    Enum.each(boolean_fields, fn field ->
      assert get_in(source_review_row_properties, [field, "type"]) == "boolean"
    end)

    source_review_operational_timeline_properties =
      get_in(source_review_row_properties, ["source_operational_timeline", "properties"])

    Enum.each(operational_timeline_string_fields, fn field ->
      assert get_in(source_review_operational_timeline_properties, [field, "type"]) == "string"
    end)

    Enum.each(operational_timeline_boolean_fields, fn field ->
      assert get_in(source_review_operational_timeline_properties, [field, "type"]) == "boolean"
    end)
  end

  test "exports resource availability variance handoff schema fields" do
    string_fields = [
      "spacecraft_available_match_status",
      "payload_available_match_status",
      "antenna_available_match_status",
      "degraded_match_status",
      "mode",
      "planned_mode",
      "realized_mode",
      "mode_match_status"
    ]

    boolean_fields = [
      "spacecraft_available",
      "planned_spacecraft_available",
      "realized_spacecraft_available",
      "payload_available",
      "planned_payload_available",
      "realized_payload_available",
      "antenna_available",
      "planned_antenna_available",
      "realized_antenna_available",
      "degraded",
      "planned_degraded",
      "realized_degraded"
    ]

    for contract <- ["operator_review_package.v1", "cadence_import_manifest.v1"] do
      assert {:ok, schema} = Schema.json_schema(contract)
      row_properties = get_in(schema, ["properties", "rows", "items", "properties"])

      Enum.each(string_fields, fn field ->
        assert get_in(row_properties, [field, "type"]) == "string"
      end)

      Enum.each(boolean_fields, fn field ->
        assert get_in(row_properties, [field, "type"]) == "boolean"
      end)
    end

    assert {:ok, cadence_schema} = Schema.json_schema("cadence_import_manifest.v1")

    source_review_row_properties =
      get_in(cadence_schema, [
        "properties",
        "rows",
        "items",
        "properties",
        "source_review_row",
        "properties"
      ])

    Enum.each(string_fields, fn field ->
      assert get_in(source_review_row_properties, [field, "type"]) == "string"
    end)

    Enum.each(boolean_fields, fn field ->
      assert get_in(source_review_row_properties, [field, "type"]) == "boolean"
    end)
  end
end
