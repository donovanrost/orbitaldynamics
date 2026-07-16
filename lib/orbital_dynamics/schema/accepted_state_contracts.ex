defmodule OrbitalDynamics.Schema.AcceptedStateContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation,
    only: [validate_optional_rows: 4, validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_number: 4,
      expect_number_vector: 3,
      expect_optional_number: 4,
      expect_optional_number_vector: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      require_nested: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  @import_context_fields [
    "input_format",
    "import_adapter",
    "provider",
    "adapter",
    "adapter_version"
  ]

  def validate_planning_state(issues, path, artifact, required_fields) do
    issues
    |> require_fields(path, artifact, required_fields)
    |> validate_stable_ids(path, artifact, ["snapshot_id"])
    |> expect_equal(path, artifact, "schema_version", 1)
    |> expect_equal(path, artifact, "artifact_type", "accepted_planning_state")
    |> expect_type(path, artifact, "spacecraft_states", :list)
    |> expect_type(path, artifact, "source", :map)
    |> expect_type(path, artifact, "quality", :map)
    |> expect_type(path, artifact, "provenance", :map)
    |> require_import_trust_boundary(path, artifact)
    |> validate_rows(
      path <> ".spacecraft_states",
      Map.get(artifact, "spacecraft_states", []),
      &validate_spacecraft_state_estimate/3
    )
    |> validate_optional_rows(
      path <> ".maneuver_execution_deltas",
      Map.get(artifact, "maneuver_execution_deltas"),
      &validate_maneuver_execution_delta/3
    )
    |> validate_planning_state_counts(path, artifact)
  end

  def validate_spacecraft_state_estimate(issues, path, state) do
    issues
    |> require_fields(path, state, [
      "spacecraft_id",
      "scenario_id",
      "epoch",
      "frame",
      "state_vector",
      "source",
      "quality"
    ])
    |> validate_stable_ids(path, state, ["spacecraft_id", "scenario_id"])
    |> expect_type(path, state, "epoch", :map)
    |> expect_type(path, state, "state_vector", :map)
    |> expect_type(path, state, "source", :map)
    |> expect_type(path, state, "quality", :map)
    |> expect_optional_type(path, state, "trust_boundary", :binary)
    |> expect_optional_type(path, state, "provenance", :map)
    |> require_nested(path <> ".epoch", Map.get(state, "epoch", %{}), [
      "seconds_since_j2000",
      "time_scale"
    ])
    |> expect_number(
      path <> ".epoch",
      Map.get(state, "epoch", %{}),
      "seconds_since_j2000"
    )
    |> require_nested(path <> ".state_vector", Map.get(state, "state_vector", %{}), [
      "position_km",
      "velocity_km_s"
    ])
    |> expect_number_vector(
      path <> ".state_vector.position_km",
      get_in(state, ["state_vector", "position_km"])
    )
    |> expect_number_vector(
      path <> ".state_vector.velocity_km_s",
      get_in(state, ["state_vector", "velocity_km_s"])
    )
    |> validate_spacecraft_state_estimate_quality(path, state)
    |> require_row_trust_boundary(path, state, "spacecraft_state_estimate.v1")
  end

  def validate_maneuver_execution_delta(issues, path, delta) do
    issues
    |> require_fields(path, delta, ["activity_id", "status", "source", "quality"])
    |> validate_stable_ids(path, delta, ["activity_id"])
    |> expect_type(path, delta, "source", :map)
    |> expect_type(path, delta, "quality", :map)
    |> expect_optional_type(path, delta, "trust_boundary", :binary)
    |> expect_optional_type(path, delta, "provenance", :map)
    |> expect_optional_type(path, delta, "metadata", :map)
    |> expect_optional_number(path, delta, "epoch_s")
    |> expect_optional_number_vector(path, delta, "delta_v_km_s")
    |> validate_maneuver_execution_delta_quality(path, delta)
    |> require_row_trust_boundary(path, delta, "maneuver_execution_delta.v1")
  end

  defp validate_spacecraft_state_estimate_quality(
         issues,
         path,
         %{"quality" => %{} = quality}
       ) do
    issues
    |> expect_optional_type(path <> ".quality", quality, "level", :binary)
    |> expect_optional_number_vector(path <> ".quality", quality, "position_sigma_km")
    |> expect_optional_number_vector(
      path <> ".quality",
      quality,
      "velocity_sigma_km_s"
    )
    |> expect_optional_type(
      path <> ".quality",
      quality,
      "covariance_reference_frame",
      :binary
    )
    |> expect_optional_type(path <> ".quality", quality, "covariance_status", :binary)
  end

  defp validate_spacecraft_state_estimate_quality(issues, _path, _state),
    do: issues

  defp validate_maneuver_execution_delta_quality(
         issues,
         path,
         %{"quality" => %{} = quality}
       ) do
    expect_optional_type(issues, path <> ".quality", quality, "level", :binary)
  end

  defp validate_maneuver_execution_delta_quality(issues, _path, _delta),
    do: issues

  defp require_row_trust_boundary(issues, path, row, contract_name) do
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
            path <> ".trust_boundary",
            "#{contract_name} requires trust_boundary or provenance.trust_boundary"
          )
          | issues
        ]
    end
  end

  defp validate_planning_state_counts(issues, path, artifact) do
    spacecraft_states =
      artifact
      |> Map.get("spacecraft_states", [])
      |> case do
        rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
        _rows -> []
      end

    expect_field_equals(
      issues,
      path <> ".provenance",
      Map.get(artifact, "provenance", %{}),
      "state_estimate_count",
      length(spacecraft_states),
      "must equal row-derived spacecraft state count"
    )
  end

  defp require_import_trust_boundary(issues, path, artifact) do
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
            path <> ".provenance.trust_boundary",
            "accepted_planning_state.v1 import provenance requires trust_boundary"
          )
          | issues
        ]
    end
  end
end
