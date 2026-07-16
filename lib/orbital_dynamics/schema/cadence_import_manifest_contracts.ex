defmodule OrbitalDynamics.Schema.CadenceImportManifestContracts do
  @moduledoc false

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

  def validate(issues, path, manifest, supported_sources, model_limits, scalar_fields, callbacks)
      when is_list(supported_sources) and is_list(model_limits) and is_list(scalar_fields) and
             is_list(callbacks) do
    rows = Map.get(manifest, "rows", [])

    issues
    |> expect_equal(path, manifest, "schema_contract", "cadence_import_manifest.v1", callbacks)
    |> expect_equal(path, manifest, "model", "artifact_only_cadence_import_manifest", callbacks)
    |> validate_stable_ids(path, manifest, ["manifest_id", "source_artifact_id"], callbacks)
    |> validate_scalar_counts(path, manifest, scalar_fields, callbacks)
    |> validate_optional_count_map_types(path, manifest, callbacks)
    |> expect_optional_type(path, manifest, "station_reservation_ids", :list, callbacks)
    |> validate_optional_stable_id_list(path, manifest, "station_reservation_ids", callbacks)
    |> expect_optional_type(path, manifest, "station_reserved_bys", :list, callbacks)
    |> validate_string_list_items(path, manifest, "station_reserved_bys", callbacks)
    |> expect_optional_type(path, manifest, "station_reservation_statuses", :list, callbacks)
    |> validate_string_list_items(path, manifest, "station_reservation_statuses", callbacks)
    |> validate_contact_allocation_expiration_handoff_summary(path, manifest, callbacks)
    |> validate_quality_gate_handoff_summary(path, manifest, callbacks)
    |> expect_optional_type(path, manifest, "model_limits", :list, callbacks)
    |> validate_string_list_items(path, manifest, "model_limits", callbacks)
    |> validate_optional_exact_model_limits(
      path,
      manifest,
      model_limits,
      "must match Cadence import manifest model limits",
      callbacks
    )
    |> validate_assumptions(path, manifest, callbacks)
    |> expect_type(path, manifest, "rows", :list, callbacks)
    |> validate_rows(path <> ".rows", rows, :validate_cadence_import_row, callbacks)
    |> validate_suppression_duplicate_handoff_groups(path, rows, callbacks)
    |> validate_count_maps(path, manifest, callbacks)
    |> validate_contact_allocation_expiration_handoff_summary(path, manifest, callbacks)
    |> validate_derived_counts(path, manifest, rows, callbacks)
    |> expect_optional_one_of(
      path,
      manifest,
      "source_artifact_type",
      supported_sources,
      callbacks
    )
  end

  defp validate_scalar_counts(issues, path, manifest, scalar_fields, callbacks) do
    Enum.reduce(scalar_fields, issues, fn field, acc ->
      expect_non_negative_integer(acc, path, manifest, field, callbacks)
    end)
  end

  defp validate_optional_count_map_types(issues, path, manifest, callbacks) do
    Enum.reduce(@optional_count_maps, issues, fn field, acc ->
      expect_optional_type(acc, path, manifest, field, :map, callbacks)
    end)
  end

  defp validate_assumptions(issues, path, manifest, callbacks) do
    case Map.get(manifest, "assumptions") do
      %{} = assumptions ->
        Enum.reduce(@assumption_expectations, issues, fn {field, expected}, acc ->
          if Map.has_key?(assumptions, field) and Map.get(assumptions, field) != expected do
            [
              error("#{path}.assumptions.#{field}", "must equal #{inspect(expected)}", callbacks)
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

  defp validate_count_maps(issues, path, manifest, callbacks) do
    Enum.reduce(@optional_count_maps, issues, fn field, acc ->
      validate_non_negative_integer_count_map(
        acc,
        path <> ".#{field}",
        Map.get(manifest, field),
        callbacks
      )
    end)
  end

  defp validate_derived_counts(issues, path, manifest, rows, callbacks) do
    map_rows = Enum.filter(rows, &is_map/1)

    issues
    |> expect_field_equals(
      path,
      manifest,
      "row_count",
      if(is_list(rows), do: length(rows), else: nil),
      callbacks
    )
    |> expect_field_equals(
      path,
      manifest,
      "ready_count",
      Enum.count(map_rows, &(Map.get(&1, "import_status") == "ready_for_import")),
      callbacks
    )
    |> expect_field_equals(
      path,
      manifest,
      "review_required_count",
      Enum.count(map_rows, &(Map.get(&1, "import_status") == "review_required_before_import")),
      callbacks
    )
    |> expect_field_equals(
      path,
      manifest,
      "blocked_count",
      Enum.count(map_rows, &(Map.get(&1, "import_status") == "blocked_missing_cadence_import")),
      callbacks
    )
    |> expect_field_equals(
      path,
      manifest,
      "missing_import_count",
      Enum.count(map_rows, &(Map.get(&1, "cadence_import_status") == "missing")),
      callbacks
    )
    |> expect_field_equals(
      path,
      manifest,
      "import_action_counts",
      frequency_map(map_rows, "import_action"),
      "must equal row-derived import_action_counts",
      callbacks
    )
    |> expect_field_equals(
      path,
      manifest,
      "import_status_counts",
      frequency_map(map_rows, "import_status"),
      "must equal row-derived import_status_counts",
      callbacks
    )
    |> expect_field_equals(
      path,
      manifest,
      "cadence_import_status_counts",
      frequency_map(map_rows, "cadence_import_status"),
      "must equal row-derived cadence_import_status_counts",
      callbacks
    )
    |> expect_field_equals(
      path,
      manifest,
      "source_review_type_counts",
      frequency_map(map_rows, "source_review_type"),
      "must equal row-derived source_review_type_counts",
      callbacks
    )
    |> expect_field_equals(
      path,
      manifest,
      "source_review_action_counts",
      frequency_map(map_rows, "source_review_action"),
      "must equal row-derived source_review_action_counts",
      callbacks
    )
    |> expect_field_equals(
      path,
      manifest,
      "source_review_queue_counts",
      frequency_map(map_rows, "source_review_queue_key"),
      "must equal row-derived source_review_queue_counts",
      callbacks
    )
  end

  defp frequency_map(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp expect_equal(issues, path, map, field, expected, callbacks),
    do: apply(require_callback(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp validate_stable_ids(issues, path, map, fields, callbacks),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_non_negative_integer(issues, path, map, field, callbacks),
    do:
      apply(require_callback(callbacks, :expect_non_negative_integer), [issues, path, map, field])

  defp expect_optional_type(issues, path, map, field, type, callbacks),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp validate_optional_stable_id_list(issues, path, map, field, callbacks),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        map,
        field
      ])

  defp validate_string_list_items(issues, path, map, field, callbacks),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [
        issues,
        path,
        map,
        field
      ])

  defp validate_contact_allocation_expiration_handoff_summary(issues, path, manifest, callbacks),
    do:
      apply(
        require_callback(callbacks, :validate_contact_allocation_expiration_handoff_summary),
        [
          issues,
          path,
          manifest
        ]
      )

  defp validate_quality_gate_handoff_summary(issues, path, manifest, callbacks),
    do:
      apply(require_callback(callbacks, :validate_quality_gate_handoff_summary), [
        issues,
        path,
        manifest
      ])

  defp validate_optional_exact_model_limits(issues, path, map, expected, message, callbacks),
    do:
      apply(require_callback(callbacks, :validate_optional_exact_model_limits), [
        issues,
        path,
        map,
        expected,
        message
      ])

  defp expect_type(issues, path, map, field, type, callbacks),
    do: apply(require_callback(callbacks, :expect_type), [issues, path, map, field, type])

  defp validate_rows(issues, path, rows, validator_name, callbacks),
    do:
      apply(require_callback(callbacks, :validate_rows), [
        issues,
        path,
        rows,
        require_callback(callbacks, validator_name)
      ])

  defp validate_suppression_duplicate_handoff_groups(issues, path, rows, callbacks),
    do:
      apply(require_callback(callbacks, :validate_suppression_duplicate_handoff_groups), [
        issues,
        path,
        rows
      ])

  defp validate_non_negative_integer_count_map(issues, path, counts, callbacks),
    do:
      apply(require_callback(callbacks, :validate_non_negative_integer_count_map), [
        issues,
        path,
        counts
      ])

  defp expect_field_equals(issues, path, map, field, expected, callbacks),
    do:
      apply(require_callback(callbacks, :expect_field_equals), [
        issues,
        path,
        map,
        field,
        expected
      ])

  defp expect_field_equals(issues, path, map, field, expected, message, callbacks),
    do:
      apply(require_callback(callbacks, :expect_field_equals_with_message), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp expect_optional_one_of(issues, path, map, field, allowed, callbacks),
    do:
      apply(require_callback(callbacks, :expect_optional_one_of), [
        issues,
        path,
        map,
        field,
        allowed
      ])

  defp error(path, message, callbacks),
    do: apply(require_callback(callbacks, :error), [path, message])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
