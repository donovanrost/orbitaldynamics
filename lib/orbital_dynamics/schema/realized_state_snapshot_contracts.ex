defmodule OrbitalDynamics.Schema.RealizedStateSnapshotContracts do
  @moduledoc false

  def validate(issues, path, snapshot, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, snapshot, [
      "schema_contract",
      "activities",
      "spacecraft_states",
      "metadata"
    ])
    |> expect_equal(callbacks, path, snapshot, "schema_contract", "realized_state_snapshot.v1")
    |> expect_type(callbacks, path, snapshot, "activities", :list)
    |> expect_type(callbacks, path, snapshot, "spacecraft_states", :list)
    |> expect_type(callbacks, path, snapshot, "metadata", :map)
    |> expect_optional_list(callbacks, path, snapshot, "model_limits")
    |> validate_string_list_items(callbacks, path, snapshot, "model_limits")
    |> validate_metadata(callbacks, path <> ".metadata", Map.get(snapshot, "metadata", %{}))
    |> validate_model_limits(callbacks, path, snapshot)
    |> validate_rows(
      callbacks,
      path <> ".activities",
      Map.get(snapshot, "activities", []),
      fn acc, row_path, row -> validate_realized_activity(callbacks, acc, row_path, row) end
    )
    |> validate_rows(
      callbacks,
      path <> ".spacecraft_states",
      Map.get(snapshot, "spacecraft_states", []),
      fn acc, row_path, row ->
        OrbitalDynamics.Schema.RealizedSpacecraftStateContracts.validate(
          acc,
          row_path,
          row,
          callbacks
        )
      end
    )
    |> validate_counts(callbacks, path, snapshot)
  end

  defp validate_counts(issues, callbacks, path, snapshot) do
    activities = snapshot |> Map.get("activities", []) |> Enum.filter(&is_map/1)
    spacecraft_states = snapshot |> Map.get("spacecraft_states", []) |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(callbacks, path, snapshot, "activity_count", length(activities))
    |> expect_field_equals(
      callbacks,
      path,
      snapshot,
      "spacecraft_state_count",
      length(spacecraft_states)
    )
    |> expect_field_equals(
      callbacks,
      path,
      snapshot,
      "activity_status_counts",
      frequency_map(callbacks, activities, "status"),
      "must equal row-derived activity status counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      snapshot,
      "spacecraft_state_status_counts",
      frequency_map(callbacks, spacecraft_states, "status"),
      "must equal row-derived spacecraft state status counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      snapshot,
      "degraded_count",
      degraded_count(activities, spacecraft_states),
      "must equal row-derived degraded count"
    )
  end

  defp degraded_count(activities, spacecraft_states) do
    [activities, spacecraft_states]
    |> Enum.flat_map(& &1)
    |> Enum.count(&(Map.get(&1, "degraded") == true))
  end

  defp validate_metadata(issues, callbacks, path, metadata) do
    issues
    |> expect_optional_type(callbacks, path, metadata, "snapshot_id", :binary)
    |> expect_optional_type(callbacks, path, metadata, "mission_state_id", :binary)
    |> expect_optional_type(callbacks, path, metadata, "captured_at", :binary)
    |> expect_optional_type(callbacks, path, metadata, "source", :binary)
    |> expect_optional_type(callbacks, path, metadata, "feedback_boundary", :binary)
    |> expect_optional_type(callbacks, path, metadata, "provider", :binary)
    |> expect_optional_type(callbacks, path, metadata, "adapter", :binary)
    |> expect_optional_type(callbacks, path, metadata, "adapter_version", :binary)
    |> expect_optional_type(callbacks, path, metadata, "external_id", :binary)
    |> expect_optional_type(callbacks, path, metadata, "trust_boundary", :binary)
    |> expect_optional_type(callbacks, path, metadata, "received_at", :binary)
    |> expect_optional_type(callbacks, path, metadata, "ingested_at", :binary)
    |> expect_optional_type(
      callbacks,
      path,
      metadata,
      "dropped_identityless_spacecraft_state_count",
      :integer
    )
    |> expect_optional_type(
      callbacks,
      path,
      metadata,
      "dropped_invalid_identity_spacecraft_state_count",
      :integer
    )
    |> expect_optional_type(callbacks, path, metadata, "provenance", :map)
    |> validate_stable_ids(callbacks, path, metadata, ["external_id"])
    |> validate_non_negative_optional_integer(
      callbacks,
      path,
      metadata,
      "dropped_identityless_spacecraft_state_count"
    )
    |> validate_non_negative_optional_integer(
      callbacks,
      path,
      metadata,
      "dropped_invalid_identity_spacecraft_state_count"
    )
    |> require_metadata_trust_boundary(callbacks, path, metadata)
  end

  defp validate_model_limits(issues, callbacks, path, snapshot) do
    case Map.get(snapshot, "model_limits") do
      nil ->
        issues

      limits when is_list(limits) ->
        expected_limits = realized_state_snapshot_model_limits(callbacks)

        if Enum.sort(limits) == Enum.sort(expected_limits) do
          issues
        else
          [
            error(
              callbacks,
              path <> ".model_limits",
              "must match realized state snapshot model limits"
            )
            | issues
          ]
        end

      _other ->
        issues
    end
  end

  defp require_metadata_trust_boundary(issues, callbacks, path, metadata) do
    provider_context_fields = ["provider", "adapter", "adapter_version", "external_id"]

    has_provider_context? =
      Enum.any?(provider_context_fields, fn field ->
        value = Map.get(metadata, field)
        is_binary(value) and value != ""
      end)

    trust_boundary = Map.get(metadata, "trust_boundary")
    provenance_trust_boundary = get_in(metadata, ["provenance", "trust_boundary"])

    cond do
      not has_provider_context? ->
        issues

      is_binary(trust_boundary) and trust_boundary != "" ->
        issues

      is_binary(provenance_trust_boundary) and provenance_trust_boundary != "" ->
        issues

      true ->
        [
          error(
            callbacks,
            path <> ".trust_boundary",
            "realized_state_snapshot.v1 metadata requires trust_boundary or provenance.trust_boundary when provider context is present"
          )
          | issues
        ]
    end
  end

  defp validate_non_negative_optional_integer(issues, callbacks, path, map, field) do
    case Map.get(map, field) do
      value when is_integer(value) and value < 0 ->
        [error(callbacks, path <> ".#{field}", "must be greater than or equal to 0") | issues]

      _value ->
        issues
    end
  end

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp realized_state_snapshot_model_limits(callbacks),
    do: apply(require_callback(callbacks, :realized_state_snapshot_model_limits), [])

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :require_fields), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(require_callback(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(require_callback(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_optional_list(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_list), [issues, path, map, field])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(require_callback(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_realized_activity(callbacks, issues, path, activity),
    do: apply(require_callback(callbacks, :validate_realized_activity), [issues, path, activity])

  defp expect_field_equals(issues, callbacks, path, map, field, expected),
    do:
      apply(require_callback(callbacks, :expect_field_equals), [
        issues,
        path,
        map,
        field,
        expected
      ])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(require_callback(callbacks, :expect_field_equals_with_message), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp frequency_map(callbacks, rows, field),
    do: apply(require_callback(callbacks, :frequency_map), [rows, field])

  defp error(callbacks, path, message),
    do: apply(require_callback(callbacks, :error), [path, message])
end
