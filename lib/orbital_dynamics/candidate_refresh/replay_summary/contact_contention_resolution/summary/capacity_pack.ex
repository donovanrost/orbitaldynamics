defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.Summary.CapacityPack do
  @moduledoc false

  def fields(resolution_summary) do
    %{
      "capacity_pack_required_capacity_fraction" =>
        numeric_value(Map.get(resolution_summary, "capacity_pack_required_capacity_fraction")) ||
          0.0,
      "capacity_pack_selected_required_capacity_fraction" =>
        numeric_value(
          Map.get(resolution_summary, "capacity_pack_selected_required_capacity_fraction")
        ) || 0.0,
      "capacity_pack_deferred_required_capacity_fraction" =>
        numeric_value(
          Map.get(resolution_summary, "capacity_pack_deferred_required_capacity_fraction")
        ) || 0.0,
      "capacity_pack_required_capacity_fraction_by_ground_station" =>
        Map.get(
          resolution_summary,
          "capacity_pack_required_capacity_fraction_by_ground_station",
          %{}
        ),
      "capacity_pack_selected_required_capacity_fraction_by_ground_station" =>
        Map.get(
          resolution_summary,
          "capacity_pack_selected_required_capacity_fraction_by_ground_station",
          %{}
        ),
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station" =>
        Map.get(
          resolution_summary,
          "capacity_pack_deferred_required_capacity_fraction_by_ground_station",
          %{}
        ),
      "capacity_pack_required_capacity_fraction_by_status" =>
        non_empty_map(
          Map.get(resolution_summary, "capacity_pack_required_capacity_fraction_by_status", %{})
        ),
      "required_capacity_fraction_source_counts" =>
        non_empty_map(
          Map.get(resolution_summary, "required_capacity_fraction_source_counts", %{})
        ),
      "required_capacity_fraction_contact_ids_by_source" =>
        non_empty_map(
          Map.get(resolution_summary, "required_capacity_fraction_contact_ids_by_source", %{})
        )
    }
  end

  def pressure?(fields) do
    Map.fetch!(fields, "capacity_pack_required_capacity_fraction") +
      Map.fetch!(fields, "capacity_pack_selected_required_capacity_fraction") +
      Map.fetch!(fields, "capacity_pack_deferred_required_capacity_fraction") > 0.0 or
      map_size(Map.fetch!(fields, "capacity_pack_required_capacity_fraction_by_ground_station")) >
        0 or
      map_size(
        Map.fetch!(fields, "capacity_pack_selected_required_capacity_fraction_by_ground_station")
      ) >
        0 or
      map_size(
        Map.fetch!(fields, "capacity_pack_deferred_required_capacity_fraction_by_ground_station")
      ) >
        0 or
      map_size(Map.get(fields, "capacity_pack_required_capacity_fraction_by_status") || %{}) > 0 or
      map_size(Map.get(fields, "required_capacity_fraction_source_counts") || %{}) > 0 or
      map_size(Map.get(fields, "required_capacity_fraction_contact_ids_by_source") || %{}) > 0
  end

  def deferred_pressure?(fields) do
    Map.fetch!(fields, "capacity_pack_deferred_required_capacity_fraction") > 0.0 or
      map_size(
        Map.fetch!(fields, "capacity_pack_deferred_required_capacity_fraction_by_ground_station")
      ) >
        0
  end

  defp numeric_value(value) when is_number(value), do: value * 1.0

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _parse -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
