defmodule OrbitalDynamics.Schema.CadenceImportManifestContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_ids: 4]

  alias OrbitalDynamics.Schema.{ContactAllocationHandoffContracts, QualityGateHandoffContracts}

  @optional_count_maps [
    "import_action_counts",
    "import_status_counts",
    "cadence_import_status_counts",
    "source_review_type_counts",
    "source_review_action_counts",
    "source_review_queue_counts",
    "calendar_entry_trust_boundary_status_counts",
    "station_reservation_match_status_counts"
  ]

  @assumption_expectations [
    {"execution_boundary", "artifact_only_no_cadence_api_writes"},
    {"authorization_boundary", "operator_review_or_cadence_adapter_must_authorize_import"}
  ]

  def validate(
        issues,
        path,
        manifest,
        supported_sources,
        model_limits,
        scalar_fields,
        row_validator,
        expiration_handoff_validator,
        suppression_group_validator
      )
      when is_list(supported_sources) and is_list(model_limits) and is_list(scalar_fields) and
             is_function(row_validator, 3) and is_function(expiration_handoff_validator, 3) and
             is_function(suppression_group_validator, 3) do
    rows = Map.get(manifest, "rows", [])

    issues
    |> expect_equal(path, manifest, "schema_contract", "cadence_import_manifest.v1")
    |> expect_equal(path, manifest, "model", "artifact_only_cadence_import_manifest")
    |> validate_stable_ids(path, manifest, ["manifest_id", "source_artifact_id"])
    |> validate_scalar_counts(path, manifest, scalar_fields)
    |> validate_optional_count_map_types(path, manifest)
    |> expect_optional_type(path, manifest, "station_reservation_ids", :list)
    |> validate_optional_stable_id_list(path, manifest, "station_reservation_ids")
    |> expect_optional_type(path, manifest, "station_pressure_contact_ids", :list)
    |> validate_optional_stable_id_list(path, manifest, "station_pressure_contact_ids")
    |> ContactAllocationHandoffContracts.validate_station_pressure_identity_summary(
      path,
      manifest
    )
    |> expect_optional_type(path, manifest, "station_reserved_bys", :list)
    |> validate_string_list_items(path, manifest, "station_reserved_bys")
    |> expect_optional_type(path, manifest, "station_reservation_statuses", :list)
    |> validate_string_list_items(path, manifest, "station_reservation_statuses")
    |> expiration_handoff_validator.(path, manifest)
    |> QualityGateHandoffContracts.validate_summary(path, manifest)
    |> expect_optional_type(path, manifest, "model_limits", :list)
    |> validate_string_list_items(path, manifest, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      manifest,
      model_limits,
      "must match Cadence import manifest model limits"
    )
    |> validate_assumptions(path, manifest)
    |> expect_type(path, manifest, "rows", :list)
    |> validate_rows(path <> ".rows", rows, row_validator)
    |> suppression_group_validator.(path, rows)
    |> validate_count_maps(path, manifest)
    |> validate_derived_counts(path, manifest, rows)
    |> expect_optional_one_of(
      path,
      manifest,
      "source_artifact_type",
      supported_sources
    )
  end

  defp validate_scalar_counts(issues, path, manifest, scalar_fields) do
    Enum.reduce(scalar_fields, issues, fn field, acc ->
      expect_non_negative_integer(acc, path, manifest, field)
    end)
  end

  defp validate_optional_count_map_types(issues, path, manifest) do
    Enum.reduce(@optional_count_maps, issues, fn field, acc ->
      expect_optional_type(acc, path, manifest, field, :map)
    end)
  end

  defp validate_assumptions(issues, path, manifest) do
    case Map.get(manifest, "assumptions") do
      %{} = assumptions ->
        Enum.reduce(@assumption_expectations, issues, fn {field, expected}, acc ->
          if Map.has_key?(assumptions, field) and Map.get(assumptions, field) != expected do
            [
              error("#{path}.assumptions.#{field}", "must equal #{inspect(expected)}")
              | acc
            ]
          else
            acc
          end
        end)

      _assumptions ->
        issues
    end
  end

  defp validate_count_maps(issues, path, manifest) do
    Enum.reduce(@optional_count_maps, issues, fn field, acc ->
      validate_non_negative_integer_count_map(
        acc,
        path <> ".#{field}",
        Map.get(manifest, field)
      )
    end)
  end

  defp validate_derived_counts(issues, path, manifest, rows) do
    map_rows = Enum.filter(rows, &is_map/1)

    issues
    |> expect_field_equals(
      path,
      manifest,
      "row_count",
      if(is_list(rows), do: length(rows), else: nil)
    )
    |> expect_field_equals(
      path,
      manifest,
      "ready_count",
      Enum.count(map_rows, &(Map.get(&1, "import_status") == "ready_for_import"))
    )
    |> expect_field_equals(
      path,
      manifest,
      "review_required_count",
      Enum.count(map_rows, &(Map.get(&1, "import_status") == "review_required_before_import"))
    )
    |> expect_field_equals(
      path,
      manifest,
      "blocked_count",
      Enum.count(map_rows, &(Map.get(&1, "import_status") == "blocked_missing_cadence_import"))
    )
    |> expect_field_equals(
      path,
      manifest,
      "missing_import_count",
      Enum.count(map_rows, &(Map.get(&1, "cadence_import_status") == "missing"))
    )
    |> expect_field_equals(
      path,
      manifest,
      "import_action_counts",
      frequency_map(map_rows, "import_action"),
      "must equal row-derived import_action_counts"
    )
    |> expect_field_equals(
      path,
      manifest,
      "import_status_counts",
      frequency_map(map_rows, "import_status"),
      "must equal row-derived import_status_counts"
    )
    |> expect_field_equals(
      path,
      manifest,
      "cadence_import_status_counts",
      frequency_map(map_rows, "cadence_import_status"),
      "must equal row-derived cadence_import_status_counts"
    )
    |> expect_field_equals(
      path,
      manifest,
      "source_review_type_counts",
      frequency_map(map_rows, "source_review_type"),
      "must equal row-derived source_review_type_counts"
    )
    |> expect_field_equals(
      path,
      manifest,
      "source_review_action_counts",
      frequency_map(map_rows, "source_review_action"),
      "must equal row-derived source_review_action_counts"
    )
    |> expect_field_equals(
      path,
      manifest,
      "source_review_queue_counts",
      frequency_map(map_rows, "source_review_queue_key"),
      "must equal row-derived source_review_queue_counts"
    )
  end

  defp frequency_map(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp expect_field_equals(issues, path, map, field, nil),
    do: expect_field_equals(issues, path, map, field, nil, nil)

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")
end
