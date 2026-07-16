defmodule OrbitalDynamics.Validation.ArtifactObservations.StationCalendarPrecedenceSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    model_limits = list_values(artifact, "model_limits")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "source" => Map.get(artifact, "source"),
      "affected_contact_count" => Map.get(artifact, "affected_contact_count"),
      "precedence_review_status" => Map.get(artifact, "precedence_review_status"),
      "applied_availability_counts" => Map.get(artifact, "applied_availability_counts") || %{},
      "applied_status_counts" => Map.get(artifact, "applied_status_counts") || %{},
      "overlap_availability_counts" => Map.get(artifact, "overlap_availability_counts") || %{},
      "affected_contact_ids_by_applied_availability" =>
        Map.get(artifact, "affected_contact_ids_by_applied_availability") || %{},
      "affected_contact_ids_by_applied_status" =>
        Map.get(artifact, "affected_contact_ids_by_applied_status") || %{},
      "affected_contact_ids_by_overlap_availability" =>
        Map.get(artifact, "affected_contact_ids_by_overlap_availability") || %{},
      "reserved_under_higher_precedence_contact_count" =>
        Map.get(artifact, "reserved_under_higher_precedence_contact_count"),
      "reserved_under_higher_precedence_contact_ids" =>
        artifact
        |> list_values("reserved_under_higher_precedence_contact_ids")
        |> Enum.join("|"),
      "reserved_under_higher_precedence_contact_ids_by_applied_availability" =>
        Map.get(
          artifact,
          "reserved_under_higher_precedence_contact_ids_by_applied_availability"
        ) || %{},
      "reserved_under_higher_precedence_contact_ids_by_applied_status" =>
        Map.get(artifact, "reserved_under_higher_precedence_contact_ids_by_applied_status") ||
          %{},
      "unavailable_contact_ids" =>
        artifact
        |> list_values("unavailable_contact_ids")
        |> Enum.join("|"),
      "reserved_overlap_contact_ids" =>
        artifact
        |> list_values("reserved_overlap_contact_ids")
        |> Enum.join("|"),
      "reduced_capacity_contact_ids" =>
        artifact
        |> list_values("reduced_capacity_contact_ids")
        |> Enum.join("|"),
      "model_limit_count" => length(model_limits),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "scope" => get_in(artifact, ["assumptions", "scope"]),
      "operator_authority" => get_in(artifact, ["assumptions", "operator_authority"]),
      "no_network_calls" => "no_network_calls" in model_limits,
      "no_provider_reservation" => "no_provider_reservation" in model_limits,
      "no_schedule_mutation" => "no_schedule_mutation" in model_limits,
      "no_conflict_resolution" => "no_conflict_resolution" in model_limits
    }
  end

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
