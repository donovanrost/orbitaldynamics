defmodule OrbitalDynamics.Schema.ResourceProjectionReportContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation,
    only: [validate_optional_rows: 4, validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_non_negative_integer: 4,
      expect_one_of: 5,
      expect_optional_non_negative_integer: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_id_array_map: 3]

  def validate(
        issues,
        path,
        report,
        models,
        model_limits,
        subsystem_assumptions_validator,
        invalid_resource_summary_validator,
        invalid_activity_validator,
        projected_resource_validator,
        counts_validator
      )
      when is_list(models) and is_list(model_limits) and
             is_function(subsystem_assumptions_validator, 3) and
             is_function(invalid_resource_summary_validator, 3) and
             is_function(invalid_activity_validator, 3) and
             is_function(projected_resource_validator, 3) and
             is_function(counts_validator, 3) do
    issues
    |> require_fields(path, report, [
      "schema_contract",
      "model",
      "input_resource_summary_count",
      "activity_count",
      "projected_resources",
      "assumptions"
    ])
    |> expect_equal(path, report, "schema_contract", "resource_projection_report.v1")
    |> expect_one_of(
      path,
      report,
      "model",
      models
    )
    |> expect_optional_type(path, report, "source", :binary)
    |> expect_non_negative_integer(path, report, "input_resource_summary_count")
    |> expect_non_negative_integer(path, report, "activity_count")
    |> expect_optional_non_negative_integer(
      path,
      report,
      "valid_resource_summary_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "invalid_resource_summary_input_count"
    )
    |> expect_optional_type(path, report, "invalid_resource_summary_input_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      report,
      "invalid_resource_summary_input_ids"
    )
    |> expect_optional_non_negative_integer(path, report, "valid_activity_count")
    |> expect_optional_non_negative_integer(
      path,
      report,
      "invalid_activity_input_count"
    )
    |> expect_optional_type(path, report, "invalid_activity_input_ids", :list)
    |> validate_optional_stable_id_list(path, report, "invalid_activity_input_ids")
    |> expect_optional_type(path, report, "invalid_activity_inputs", :list)
    |> expect_optional_type(path, report, "resource_source_quality_counts", :map)
    |> expect_optional_type(
      path,
      report,
      "resource_spacecraft_ids_by_source_quality",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".resource_spacecraft_ids_by_source_quality",
      Map.get(report, "resource_spacecraft_ids_by_source_quality")
    )
    |> expect_optional_type(
      path,
      report,
      "resource_trust_boundary_status_counts",
      :map
    )
    |> expect_optional_type(
      path,
      report,
      "resource_spacecraft_ids_by_trust_boundary_status",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".resource_spacecraft_ids_by_trust_boundary_status",
      Map.get(report, "resource_spacecraft_ids_by_trust_boundary_status")
    )
    |> expect_optional_non_negative_integer(path, report, "resource_pressure_count")
    |> expect_optional_type(path, report, "resource_pressure_types", :list)
    |> validate_string_list_items(path, report, "resource_pressure_types")
    |> expect_optional_type(path, report, "resource_pressure_spacecraft_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      report,
      "resource_pressure_spacecraft_ids"
    )
    |> expect_optional_type(
      path,
      report,
      "resource_pressure_spacecraft_ids_by_type",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".resource_pressure_spacecraft_ids_by_type",
      Map.get(report, "resource_pressure_spacecraft_ids_by_type")
    )
    |> expect_optional_type(
      path,
      report,
      "resource_pressure_activity_ids_by_type",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".resource_pressure_activity_ids_by_type",
      Map.get(report, "resource_pressure_activity_ids_by_type")
    )
    |> expect_optional_type(path, report, "warnings", :list)
    |> expect_optional_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      report,
      model_limits,
      "must match resource projection model limits"
    )
    |> expect_type(path, report, "projected_resources", :list)
    |> expect_type(path, report, "assumptions", :map)
    |> subsystem_assumptions_validator.(path, report)
    |> validate_optional_rows(
      path <> ".invalid_resource_summary_inputs",
      Map.get(report, "invalid_resource_summary_inputs"),
      fn acc, row_path, row ->
        invalid_resource_summary_validator.(acc, row_path, row)
      end
    )
    |> validate_optional_rows(
      path <> ".invalid_activity_inputs",
      Map.get(report, "invalid_activity_inputs"),
      fn acc, row_path, row -> invalid_activity_validator.(acc, row_path, row) end
    )
    |> validate_rows(
      path <> ".projected_resources",
      Map.get(report, "projected_resources", []),
      fn acc, row_path, row -> projected_resource_validator.(acc, row_path, row) end
    )
    |> counts_validator.(path, report)
  end
end
