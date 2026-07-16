defmodule OrbitalDynamics.Validation.ArtifactObservations.OperationalQualityGateUnavailableResourceSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    unavailable_counts = Map.get(artifact, "unavailable_resource_reason_counts") || %{}
    station_counts = Map.get(artifact, "station_availability_reason_counts") || %{}
    quality_gate_row_ids_by_status = Map.get(artifact, "quality_gate_row_ids_by_status") || %{}

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "source_artifact_id" => Map.get(artifact, "source_artifact_id"),
      "source_quality_gate_report_id" => Map.get(artifact, "source_quality_gate_report_id"),
      "source_readiness_report_id" => Map.get(artifact, "source_readiness_report_id"),
      "resource_availability_row_count" => Map.get(artifact, "resource_availability_row_count"),
      "row_derived_resource_availability_row_count" =>
        count_grouped_values(quality_gate_row_ids_by_status),
      "unavailable_resource_row_count" => Map.get(artifact, "unavailable_resource_row_count"),
      "unavailable_resource_pressure_count" =>
        Map.get(artifact, "unavailable_resource_pressure_count"),
      "row_derived_unavailable_resource_pressure_count" => count_map_values(unavailable_counts),
      "unavailable_resource_reason_counts" => unavailable_counts,
      "unavailable_resource_reason_keys" =>
        artifact
        |> list_values("unavailable_resource_reason_ids")
        |> Enum.join("|"),
      "station_availability_reason_counts" => station_counts,
      "station_availability_reason_keys" =>
        artifact
        |> list_values("station_availability_reason_ids")
        |> Enum.join("|"),
      "resource_blocking_dimension_counts" =>
        Map.get(artifact, "resource_blocking_dimension_counts") || %{},
      "blocked_contact_ids_by_blocking_dimension" =>
        Map.get(artifact, "blocked_contact_ids_by_blocking_dimension") || %{},
      "blocked_contact_ids_by_spacecraft_id" =>
        Map.get(artifact, "blocked_contact_ids_by_spacecraft_id") || %{},
      "blocked_contact_ids_by_status" =>
        Map.get(artifact, "blocked_contact_ids_by_status") || %{},
      "quality_gate_row_ids_by_status" => quality_gate_row_ids_by_status,
      "quality_gate_ids_by_status" => Map.get(artifact, "quality_gate_ids_by_status") || %{},
      "review_required_quality_gate_row_keys" =>
        artifact
        |> list_values("review_required_quality_gate_row_ids")
        |> Enum.join("|"),
      "blocked_quality_gate_row_keys" =>
        artifact
        |> list_values("blocked_quality_gate_row_ids")
        |> Enum.join("|"),
      "resource_availability_gate_keys" =>
        artifact
        |> list_values("resource_availability_gate_ids")
        |> Enum.join("|"),
      "row_derived_review_required_quality_gate_row_count" =>
        artifact
        |> list_values("review_required_quality_gate_row_ids")
        |> length(),
      "row_derived_blocked_quality_gate_row_count" =>
        artifact
        |> list_values("blocked_quality_gate_row_ids")
        |> length(),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "operator_authority" => get_in(artifact, ["assumptions", "operator_authority"]),
      "cadence_write" => get_in(artifact, ["assumptions", "cadence_write"]),
      "command_execution" => get_in(artifact, ["assumptions", "command_execution"]),
      "model_limit_count" => count(artifact, "model_limits")
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp count_grouped_values(grouped_values) when is_map(grouped_values) do
    grouped_values
    |> Map.values()
    |> Enum.reduce(0, fn
      values, acc when is_list(values) -> acc + length(values)
      _values, acc -> acc
    end)
  end

  defp count_grouped_values(_grouped_values), do: 0

  defp count_map_values(values) when is_map(values) do
    values
    |> Map.values()
    |> Enum.filter(&is_integer/1)
    |> Enum.sum()
  end

  defp count_map_values(_values), do: 0

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _values -> []
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), stringify_keys(value)}
      {key, value} when is_binary(key) -> {key, stringify_keys(value)}
      {key, value} -> {key, stringify_keys(value)}
    end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)

  defp stringify_keys(value), do: value
end
