defmodule OrbitalDynamics.Validation.ArtifactObservations.LinkCapacitySummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    model_limits = list_values(artifact, "model_limits")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "station_count" => Map.get(artifact, "station_count"),
      "contact_count" => Map.get(artifact, "contact_count"),
      "effective_contact_count" => Map.get(artifact, "effective_contact_count"),
      "ignored_contact_count" => Map.get(artifact, "ignored_contact_count"),
      "selected_contact_count" => Map.get(artifact, "selected_contact_count"),
      "ignored_selected_contact_count" => Map.get(artifact, "ignored_selected_contact_count"),
      "required_downlink_contact_count" => Map.get(artifact, "required_downlink_contact_count"),
      "actual_throughput_contact_count" => Map.get(artifact, "actual_throughput_contact_count"),
      "actual_completion_contact_count" => Map.get(artifact, "actual_completion_contact_count"),
      "invalid_contact_input_count" => Map.get(artifact, "invalid_contact_input_count"),
      "invalid_selected_contact_input_count" =>
        Map.get(artifact, "invalid_selected_contact_input_count"),
      "invalid_policy_required_downlink_station_count" =>
        Map.get(artifact, "invalid_policy_required_downlink_station_count"),
      "downlink_requirement_status" => Map.get(artifact, "downlink_requirement_status"),
      "actual_downlink_requirement_status" =>
        Map.get(artifact, "actual_downlink_requirement_status"),
      "selection_utilization_status" => Map.get(artifact, "selection_utilization_status"),
      "selected_downlink_shortfall_mb" => Map.get(artifact, "selected_downlink_shortfall_mb"),
      "actual_downlink_shortfall_mb" => Map.get(artifact, "actual_downlink_shortfall_mb"),
      "capacity_adjusted_throughput_mb" => Map.get(artifact, "capacity_adjusted_throughput_mb"),
      "selected_capacity_adjusted_throughput_mb" =>
        Map.get(artifact, "selected_capacity_adjusted_throughput_mb"),
      "unused_capacity_adjusted_throughput_mb" =>
        Map.get(artifact, "unused_capacity_adjusted_throughput_mb"),
      "contact_ids" =>
        artifact
        |> list_values("contact_ids")
        |> Enum.join("|"),
      "selected_contact_ids" =>
        artifact
        |> list_values("selected_contact_ids")
        |> Enum.join("|"),
      "actual_throughput_contact_ids" =>
        artifact
        |> list_values("actual_throughput_contact_ids")
        |> Enum.join("|"),
      "actual_completion_contact_ids" =>
        artifact
        |> list_values("actual_completion_contact_ids")
        |> Enum.join("|"),
      "ground_station_ids" =>
        artifact
        |> list_values("ground_station_ids")
        |> Enum.join("|"),
      "selected_contact_ids_by_ground_station_id" =>
        Map.get(artifact, "selected_contact_ids_by_ground_station_id") || %{},
      "actual_throughput_contact_ids_by_ground_station_id" =>
        Map.get(artifact, "actual_throughput_contact_ids_by_ground_station_id") || %{},
      "actual_completion_contact_ids_by_ground_station_id" =>
        Map.get(artifact, "actual_completion_contact_ids_by_ground_station_id") || %{},
      "capacity_adjusted_throughput_mb_by_ground_station_id" =>
        Map.get(artifact, "capacity_adjusted_throughput_mb_by_ground_station_id") || %{},
      "selected_capacity_adjusted_throughput_mb_by_ground_station_id" =>
        Map.get(artifact, "selected_capacity_adjusted_throughput_mb_by_ground_station_id") ||
          %{},
      "unused_capacity_adjusted_throughput_mb_by_ground_station_id" =>
        Map.get(artifact, "unused_capacity_adjusted_throughput_mb_by_ground_station_id") ||
          %{},
      "model_limit_count" => length(model_limits),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "assumption_source" => get_in(artifact, ["assumptions", "source"]),
      "operator_authority" => get_in(artifact, ["assumptions", "operator_authority"]),
      "no_provider_reservation" => "no_provider_reservation" in model_limits,
      "no_schedule_mutation" => "no_schedule_mutation" in model_limits,
      "no_link_budget_model" => "no_link_budget_model" in model_limits
    }
  end

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _values -> []
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
