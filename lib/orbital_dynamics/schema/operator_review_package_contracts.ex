defmodule OrbitalDynamics.Schema.OperatorReviewPackageContracts do
  @moduledoc false

  @optional_count_maps [
    "review_type_counts",
    "review_queue_counts",
    "approval_status_counts",
    "required_operator_action_counts",
    "cadence_import_status_counts",
    "source_cadence_import_status_counts",
    "replacement_cadence_import_status_counts",
    "calendar_entry_trust_boundary_status_counts",
    "station_reservation_match_status_counts"
  ]

  def validate(
        issues,
        path,
        package,
        source_artifact_types,
        model_limits,
        field_groups,
        callbacks
      )
      when is_list(source_artifact_types) and is_list(model_limits) and is_list(field_groups) and
             is_list(callbacks) do
    issues
    |> expect_equal(path, package, "schema_contract", "operator_review_package.v1", callbacks)
    |> expect_equal(path, package, "model", "artifact_only_operator_review_package", callbacks)
    |> expect_one_of(
      path,
      package,
      "source_artifact_type",
      source_artifact_types,
      callbacks
    )
    |> validate_stable_ids(path, package, ["source_artifact_id"], callbacks)
    |> validate_scalar_counts(path, package, field_groups, callbacks)
    |> validate_optional_count_map_types(path, package, callbacks)
    |> expect_optional_type(path, package, "station_reservation_ids", :list, callbacks)
    |> validate_optional_stable_id_list(path, package, "station_reservation_ids", callbacks)
    |> expect_optional_type(path, package, "station_reserved_bys", :list, callbacks)
    |> validate_string_list_items(path, package, "station_reserved_bys", callbacks)
    |> expect_optional_type(path, package, "station_reservation_statuses", :list, callbacks)
    |> validate_string_list_items(path, package, "station_reservation_statuses", callbacks)
    |> validate_contact_allocation_expiration_handoff_summary(path, package, callbacks)
    |> validate_quality_gate_handoff_summary(path, package, callbacks)
    |> expect_optional_type(path, package, "model_limits", :list, callbacks)
    |> validate_string_list_items(path, package, "model_limits", callbacks)
    |> validate_optional_exact_model_limits(
      path,
      package,
      model_limits,
      "must match operator review package model limits",
      callbacks
    )
    |> validate_assumptions(path, package, callbacks)
    |> expect_type(path, package, "rows", :list, callbacks)
    |> expect_type(path, package, "provenance", :map, callbacks)
    |> expect_type(path, package, "assumptions", :map, callbacks)
    |> validate_rows(
      path <> ".rows",
      Map.get(package, "rows", []),
      :validate_operator_review_row,
      callbacks
    )
    |> validate_suppression_duplicate_handoff_groups(
      path,
      Map.get(package, "rows", []),
      callbacks
    )
    |> validate_counts(path, package, callbacks)
  end

  defp validate_scalar_counts(issues, path, package, field_groups, callbacks) do
    issues =
      field_groups
      |> Keyword.fetch!(:required_scalar_count_fields)
      |> Enum.reduce(issues, fn field, acc ->
        expect_non_negative_integer(acc, path, package, field, callbacks)
      end)

    field_groups
    |> Keyword.fetch!(:optional_scalar_count_fields)
    |> Enum.reduce(issues, fn field, acc ->
      expect_optional_non_negative_integer(acc, path, package, field, callbacks)
    end)
  end

  defp validate_optional_count_map_types(issues, path, package, callbacks) do
    Enum.reduce(@optional_count_maps, issues, fn field, acc ->
      expect_optional_type(acc, path, package, field, :map, callbacks)
    end)
  end

  defp validate_assumptions(issues, path, package, callbacks) do
    case Map.get(package, "assumptions") do
      %{} = assumptions ->
        if Map.has_key?(assumptions, "boundary") and
             Map.get(assumptions, "boundary") != "artifact_only_no_api_or_database_writes" do
          [
            error(
              path <> ".assumptions.boundary",
              "must equal \"artifact_only_no_api_or_database_writes\"",
              callbacks
            )
            | issues
          ]
        else
          issues
        end

      _assumptions ->
        issues
    end
  end

  defp validate_counts(issues, path, package, callbacks) do
    rows =
      package
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(path, package, "review_count", length(rows), callbacks)
    |> validate_count_maps(path, package, callbacks)
    |> validate_contact_allocation_expiration_handoff_summary(path, package, callbacks)
    |> expect_field_equals(
      path,
      package,
      "review_type_counts",
      frequency_map(rows, "review_type"),
      "must equal row-derived review_type_counts",
      callbacks
    )
    |> expect_field_equals(
      path,
      package,
      "review_queue_counts",
      frequency_map(rows, "review_queue_key"),
      "must equal row-derived review_queue_counts",
      callbacks
    )
    |> expect_field_equals(
      path,
      package,
      "approval_status_counts",
      frequency_map(rows, "approval_status"),
      "must equal row-derived approval_status_counts",
      callbacks
    )
    |> expect_field_equals(
      path,
      package,
      "required_operator_action_counts",
      frequency_map(rows, "required_operator_action"),
      "must equal row-derived required_operator_action_counts",
      callbacks
    )
    |> expect_field_equals(
      path,
      package,
      "cadence_import_status_counts",
      frequency_map(rows, "cadence_import_status"),
      "must equal row-derived cadence_import_status_counts",
      callbacks
    )
    |> expect_field_equals(
      path,
      package,
      "source_cadence_import_status_counts",
      frequency_map(rows, "source_cadence_import_status"),
      "must equal row-derived source_cadence_import_status_counts",
      callbacks
    )
    |> expect_field_equals(
      path,
      package,
      "replacement_cadence_import_status_counts",
      frequency_map(rows, "replacement_cadence_import_status"),
      "must equal row-derived replacement_cadence_import_status_counts",
      callbacks
    )
    |> expect_field_equals(
      path,
      package,
      "contention_recommendation_count",
      Enum.count(rows, &(Map.get(&1, "review_type") == "contact_contention_recommendation")),
      callbacks
    )
  end

  defp validate_count_maps(issues, path, package, callbacks) do
    Enum.reduce(@optional_count_maps, issues, fn field, acc ->
      validate_non_negative_integer_count_map(
        acc,
        path <> ".#{field}",
        Map.get(package, field),
        callbacks
      )
    end)
  end

  defp frequency_map(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp expect_equal(issues, path, map, field, expected, callbacks),
    do: apply(require_callback(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, path, map, field, allowed, callbacks),
    do: apply(require_callback(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp validate_stable_ids(issues, path, map, fields, callbacks),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_non_negative_integer(issues, path, map, field, callbacks),
    do:
      apply(require_callback(callbacks, :expect_non_negative_integer), [issues, path, map, field])

  defp expect_optional_non_negative_integer(issues, path, map, field, callbacks),
    do:
      apply(require_callback(callbacks, :expect_optional_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

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

  defp validate_contact_allocation_expiration_handoff_summary(issues, path, package, callbacks),
    do:
      apply(
        require_callback(callbacks, :validate_contact_allocation_expiration_handoff_summary),
        [
          issues,
          path,
          package
        ]
      )

  defp validate_quality_gate_handoff_summary(issues, path, package, callbacks),
    do:
      apply(require_callback(callbacks, :validate_quality_gate_handoff_summary), [
        issues,
        path,
        package
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

  defp error(path, message, callbacks),
    do: apply(require_callback(callbacks, :error), [path, message])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
