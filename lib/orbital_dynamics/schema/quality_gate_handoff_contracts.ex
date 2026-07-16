defmodule OrbitalDynamics.Schema.QualityGateHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_optional_non_negative_integer: 4,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      validate_non_negative_integer_count_map: 3
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_optional_stable_id_list: 4,
      validate_optional_stable_ids: 4,
      validate_stable_id_array_map: 3
    ]

  alias OrbitalDynamics.Schema.PrimitiveValidation

  @source_report_identity_field_pairs [
    {"quality_gate_report_id", "report_id"},
    {"source_artifact_type", "source_artifact_type"},
    {"source_artifact_id", "source_artifact_id"},
    {"readiness_level", "readiness_level"}
  ]
  @row_handoff_source_field_pairs [
    {"gate_id", "gate_id"},
    {"readiness_gate_id", "gate_id"},
    {"quality_gate_id", "gate_id"},
    {"status", "status"},
    {"readiness_gate_status", "status"},
    {"quality_gate_status", "status"},
    {"classification", "classification"},
    {"readiness_gate_classification", "classification"},
    {"quality_gate_classification", "classification"},
    {"reason", "reason"},
    {"readiness_gate_reason", "reason"},
    {"quality_gate_reason", "reason"},
    {"analysis_mode", "analysis_mode"},
    {"analysis_mode_source", "analysis_mode_source"},
    {"resource_availability_pressure_count", "resource_availability_pressure_count"},
    {"resource_availability_reason_counts", "resource_availability_reason_counts"},
    {"resource_availability_reason_ids", "resource_availability_reason_ids"},
    {"station_availability_reason_ids", "station_availability_reason_ids"},
    {"station_availability_reason_counts", "station_availability_reason_counts"},
    {"unavailable_resource_reason_ids", "unavailable_resource_reason_ids"},
    {"resource_blocking_dimension_counts", "resource_blocking_dimension_counts"},
    {"resource_blocked_contact_ids_by_blocking_dimension",
     "resource_blocked_contact_ids_by_blocking_dimension"},
    {"resource_blocked_contact_ids_by_spacecraft_id",
     "resource_blocked_contact_ids_by_spacecraft_id"},
    {"resource_source_quality_counts", "resource_source_quality_counts"},
    {"resource_trust_boundary_status_counts", "resource_trust_boundary_status_counts"}
  ]

  def validate_summary(issues, path, artifact) do
    capability = OrbitalDynamics.OperationalReadiness.capabilities()

    issues
    |> validate_optional_stable_ids(path, artifact, ["source_readiness_report_id"])
    |> expect_optional_one_of(
      path,
      artifact,
      "readiness_level",
      capability.readiness_levels
    )
    |> expect_optional_one_of(
      path,
      artifact,
      "import_classification",
      capability.import_classifications
    )
    |> expect_optional_one_of(path, artifact, "status", capability.gate_statuses)
    |> expect_optional_non_negative_integer(path, artifact, "gate_count")
    |> expect_optional_non_negative_integer(path, artifact, "passed_gate_count")
    |> expect_optional_non_negative_integer(path, artifact, "review_gate_count")
    |> expect_optional_non_negative_integer(path, artifact, "analysis_gate_count")
    |> expect_optional_non_negative_integer(path, artifact, "blocked_gate_count")
    |> expect_optional_type(path, artifact, "gate_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".gate_status_counts",
      Map.get(artifact, "gate_status_counts")
    )
    |> expect_optional_type(path, artifact, "gate_classification_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".gate_classification_counts",
      Map.get(artifact, "gate_classification_counts")
    )
    |> validate_optional_stable_id_array_map(path, artifact, "gate_ids_by_status")
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "gate_ids_by_classification"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "quality_gate_row_ids_by_status"
    )
    |> validate_optional_stable_id_array_map(
      path,
      artifact,
      "quality_gate_row_ids_by_classification"
    )
    |> expect_optional_type(path, artifact, "passed_gate_ids", :list)
    |> validate_optional_stable_id_list(path, artifact, "passed_gate_ids")
    |> expect_optional_type(path, artifact, "review_required_gate_ids", :list)
    |> validate_optional_stable_id_list(path, artifact, "review_required_gate_ids")
    |> expect_optional_type(path, artifact, "analysis_only_gate_ids", :list)
    |> validate_optional_stable_id_list(path, artifact, "analysis_only_gate_ids")
    |> expect_optional_type(path, artifact, "blocked_gate_ids", :list)
    |> validate_optional_stable_id_list(path, artifact, "blocked_gate_ids")
  end

  def validate_row_matches_source(
        issues,
        path,
        %{"source_quality_gate_row" => %{} = source_row} = row
      ) do
    validate_nested_source_pairs(
      issues,
      path,
      row,
      source_row,
      @row_handoff_source_field_pairs,
      "source_quality_gate_row"
    )
  end

  def validate_row_matches_source(issues, _path, _row), do: issues

  def validate_report_matches_source(
        issues,
        path,
        %{"source_quality_gate_report" => %{} = source_report} = row
      ) do
    validate_nested_source_pairs(
      issues,
      path,
      row,
      source_report,
      @source_report_identity_field_pairs,
      "source_quality_gate_report"
    )
  end

  def validate_report_matches_source(issues, _path, _row), do: issues

  defp validate_nested_source_pairs(issues, path, row, source_row, pairs, source_key) do
    Enum.reduce(pairs, issues, fn {row_field, source_field}, acc ->
      row_value = Map.get(row, row_field)
      source_value = Map.get(source_row, source_field)

      if not is_nil(row_value) and not is_nil(source_value) and row_value != source_value do
        [
          PrimitiveValidation.error(
            "#{path}.#{source_key}.#{source_field}",
            "must match #{row_field} on handoff row"
          )
          | acc
        ]
      else
        acc
      end
    end)
  end

  defp validate_optional_stable_id_array_map(issues, path, map, field) do
    issues
    |> expect_optional_type(path, map, field, :map)
    |> validate_stable_id_array_map("#{path}.#{field}", Map.get(map, field))
  end
end
