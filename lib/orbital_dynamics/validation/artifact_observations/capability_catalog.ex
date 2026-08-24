defmodule OrbitalDynamics.Validation.ArtifactObservations.CapabilityCatalog do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    candidate_refresh = get_in(artifact, ["planning", "candidate_refresh"]) || %{}
    candidate_refresh_source_report_inputs = candidate_refresh_source_report_inputs(artifact)

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "schema_version" => Map.get(artifact, "schema_version"),
      "model" => Map.get(artifact, "model"),
      "top_level_family_count" =>
        artifact
        |> Map.drop(["schema_contract", "schema_version", "model"])
        |> map_size(),
      "planning_capability_count" => count_collection(artifact, "planning"),
      "operations_capability_count" => count_collection(artifact, "operations"),
      "validation_family_count" => count_collection(artifact, "validation"),
      "artifact_contract_count" =>
        get_in(artifact, ["validation", "schema", "artifact_contract_count"]),
      "artifact_contract_list_count" =>
        count(get_in(artifact, ["validation", "schema"]) || %{}, "artifact_contracts"),
      "compatibility_policy_version" =>
        get_in(artifact, ["validation", "schema", "compatibility_policy_version"]),
      "identity_policy_version" =>
        get_in(artifact, ["validation", "schema", "identity_policy_version"]),
      "public_validation_facade_count" =>
        count(get_in(artifact, ["validation", "models"]) || %{}, "public_facades"),
      "optimizer_model" =>
        get_in(artifact, ["planning", "optimizer", "models"])
        |> List.wrap()
        |> List.first(),
      "optimizer_contract" => get_in(artifact, ["planning", "optimizer", "artifact_contract"]),
      "optimizer_public_facades" =>
        artifact
        |> get_in(["planning", "optimizer", "public_facades"])
        |> List.wrap()
        |> Enum.join("|"),
      "local_search_optimization_certificate_contract" =>
        get_in(artifact, [
          "planning",
          "optimizer",
          "local_search_optimization_certificate",
          "artifact_contract"
        ]),
      "local_search_optimization_certificate_global_optimality_claimed" =>
        get_in(artifact, [
          "planning",
          "optimizer",
          "local_search_optimization_certificate",
          "global_optimality_claimed"
        ]),
      "cadence_import_contract" =>
        get_in(artifact, ["operations", "cadence_import", "artifact_contract"]),
      "operational_readiness_contract" =>
        get_in(artifact, ["operations", "operational_readiness", "artifact_contract"]),
      "station_calendar_reservation_contract" =>
        get_in(artifact, ["operations", "station_calendar", "reservation_artifact_contract"]),
      "candidate_refresh_input_count" => count(candidate_refresh, "inputs"),
      "candidate_refresh_source_report_input_count" =>
        length(candidate_refresh_source_report_inputs),
      "candidate_refresh_source_report_input_order" =>
        Enum.join(candidate_refresh_source_report_inputs, "|"),
      "candidate_refresh_source_report_helper_count" =>
        count(candidate_refresh, "source_report_helpers")
    }
  end

  defp candidate_refresh_source_report_inputs(artifact) do
    artifact
    |> get_in(["planning", "candidate_refresh", "inputs"])
    |> List.wrap()
    |> Enum.filter(&is_binary/1)
    |> Enum.filter(&String.ends_with?(&1, ["_report", "_summary"]))
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp count_collection(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      values when is_map(values) -> map_size(values)
      _value -> 0
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
