defmodule OrbitalDynamics.Schema.AcceptedStateContracts do
  @moduledoc false

  @import_context_fields [
    "input_format",
    "import_adapter",
    "provider",
    "adapter",
    "adapter_version"
  ]

  def validate_planning_state(issues, path, artifact, required_fields, callbacks)
      when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, artifact, required_fields)
    |> validate_stable_ids(callbacks, path, artifact, ["snapshot_id"])
    |> expect_equal(callbacks, path, artifact, "schema_version", 1)
    |> expect_equal(callbacks, path, artifact, "artifact_type", "accepted_planning_state")
    |> expect_type(callbacks, path, artifact, "spacecraft_states", :list)
    |> expect_type(callbacks, path, artifact, "source", :map)
    |> expect_type(callbacks, path, artifact, "quality", :map)
    |> expect_type(callbacks, path, artifact, "provenance", :map)
    |> require_import_trust_boundary(path, artifact, callbacks)
    |> validate_rows(
      callbacks,
      path <> ".spacecraft_states",
      Map.get(artifact, "spacecraft_states", []),
      &validate_spacecraft_state_estimate(&1, &2, &3, callbacks)
    )
    |> validate_optional_rows(
      callbacks,
      path <> ".maneuver_execution_deltas",
      Map.get(artifact, "maneuver_execution_deltas"),
      &validate_maneuver_execution_delta(&1, &2, &3, callbacks)
    )
    |> validate_planning_state_counts(callbacks, path, artifact)
  end

  def validate_spacecraft_state_estimate(issues, path, state, callbacks)
      when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, state, [
      "spacecraft_id",
      "scenario_id",
      "epoch",
      "frame",
      "state_vector",
      "source",
      "quality"
    ])
    |> validate_stable_ids(callbacks, path, state, ["spacecraft_id", "scenario_id"])
    |> expect_type(callbacks, path, state, "epoch", :map)
    |> expect_type(callbacks, path, state, "state_vector", :map)
    |> expect_type(callbacks, path, state, "source", :map)
    |> expect_type(callbacks, path, state, "quality", :map)
    |> expect_optional_type(callbacks, path, state, "trust_boundary", :binary)
    |> expect_optional_type(callbacks, path, state, "provenance", :map)
    |> require_nested(callbacks, path <> ".epoch", Map.get(state, "epoch", %{}), [
      "seconds_since_j2000",
      "time_scale"
    ])
    |> expect_number(
      callbacks,
      path <> ".epoch",
      Map.get(state, "epoch", %{}),
      "seconds_since_j2000"
    )
    |> require_nested(callbacks, path <> ".state_vector", Map.get(state, "state_vector", %{}), [
      "position_km",
      "velocity_km_s"
    ])
    |> expect_number_vector(
      callbacks,
      path <> ".state_vector.position_km",
      get_in(state, ["state_vector", "position_km"])
    )
    |> expect_number_vector(
      callbacks,
      path <> ".state_vector.velocity_km_s",
      get_in(state, ["state_vector", "velocity_km_s"])
    )
    |> validate_spacecraft_state_estimate_quality(callbacks, path, state)
    |> require_row_trust_boundary(callbacks, path, state, "spacecraft_state_estimate.v1")
  end

  def validate_maneuver_execution_delta(issues, path, delta, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, delta, ["activity_id", "status", "source", "quality"])
    |> validate_stable_ids(callbacks, path, delta, ["activity_id"])
    |> expect_type(callbacks, path, delta, "source", :map)
    |> expect_type(callbacks, path, delta, "quality", :map)
    |> expect_optional_type(callbacks, path, delta, "trust_boundary", :binary)
    |> expect_optional_type(callbacks, path, delta, "provenance", :map)
    |> expect_optional_type(callbacks, path, delta, "metadata", :map)
    |> expect_optional_number(callbacks, path, delta, "epoch_s")
    |> expect_optional_number_vector(callbacks, path, delta, "delta_v_km_s")
    |> validate_maneuver_execution_delta_quality(callbacks, path, delta)
    |> require_row_trust_boundary(callbacks, path, delta, "maneuver_execution_delta.v1")
  end

  defp validate_spacecraft_state_estimate_quality(
         issues,
         callbacks,
         path,
         %{"quality" => %{} = quality}
       ) do
    issues
    |> expect_optional_type(callbacks, path <> ".quality", quality, "level", :binary)
    |> expect_optional_number_vector(callbacks, path <> ".quality", quality, "position_sigma_km")
    |> expect_optional_number_vector(
      callbacks,
      path <> ".quality",
      quality,
      "velocity_sigma_km_s"
    )
    |> expect_optional_type(
      callbacks,
      path <> ".quality",
      quality,
      "covariance_reference_frame",
      :binary
    )
    |> expect_optional_type(callbacks, path <> ".quality", quality, "covariance_status", :binary)
  end

  defp validate_spacecraft_state_estimate_quality(issues, _callbacks, _path, _state),
    do: issues

  defp validate_maneuver_execution_delta_quality(
         issues,
         callbacks,
         path,
         %{"quality" => %{} = quality}
       ) do
    expect_optional_type(issues, callbacks, path <> ".quality", quality, "level", :binary)
  end

  defp validate_maneuver_execution_delta_quality(issues, _callbacks, _path, _delta),
    do: issues

  defp require_row_trust_boundary(issues, callbacks, path, row, contract_name) do
    trust_boundary = Map.get(row, "trust_boundary")
    provenance_trust_boundary = get_in(row, ["provenance", "trust_boundary"])

    cond do
      is_binary(trust_boundary) and trust_boundary != "" ->
        issues

      is_binary(provenance_trust_boundary) and provenance_trust_boundary != "" ->
        issues

      true ->
        [
          error(
            callbacks,
            path <> ".trust_boundary",
            "#{contract_name} requires trust_boundary or provenance.trust_boundary"
          )
          | issues
        ]
    end
  end

  defp validate_planning_state_counts(issues, callbacks, path, artifact) do
    spacecraft_states =
      artifact
      |> Map.get("spacecraft_states", [])
      |> case do
        rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
        _rows -> []
      end

    expect_field_equals(
      issues,
      callbacks,
      path <> ".provenance",
      Map.get(artifact, "provenance", %{}),
      "state_estimate_count",
      length(spacecraft_states),
      "must equal row-derived spacecraft state count"
    )
  end

  defp require_import_trust_boundary(issues, path, artifact, callbacks) do
    provenance = Map.get(artifact, "provenance")

    has_import_context? =
      is_map(provenance) and
        Enum.any?(@import_context_fields, fn field ->
          value = Map.get(provenance, field)
          is_binary(value) and value != ""
        end)

    trust_boundary = if is_map(provenance), do: Map.get(provenance, "trust_boundary")

    cond do
      not has_import_context? ->
        issues

      is_binary(trust_boundary) and trust_boundary != "" ->
        issues

      true ->
        [
          error(
            callbacks,
            path <> ".provenance.trust_boundary",
            "accepted_planning_state.v1 import provenance requires trust_boundary"
          )
          | issues
        ]
    end
  end

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :require_fields), [issues, path, map, fields])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_equals_with_message), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_number(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_number), [issues, path, map, field])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_number), [issues, path, map, field])

  defp expect_number_vector(issues, callbacks, path, value),
    do: apply(Keyword.fetch!(callbacks, :expect_number_vector), [issues, path, value])

  defp expect_optional_number_vector(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :expect_optional_number_vector), [issues, path, map, field])

  defp require_nested(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :require_nested), [issues, path, map, fields])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_optional_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_optional_rows), [issues, path, rows, validator])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
