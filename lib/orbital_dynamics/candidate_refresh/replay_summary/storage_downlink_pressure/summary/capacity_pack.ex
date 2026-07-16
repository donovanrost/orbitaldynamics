defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StorageDownlinkPressure.Summary.CapacityPack do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  alias __MODULE__.ContactCount
  alias __MODULE__.Pressure

  def fields(allocation_summary) do
    %{
      "capacity_pack_status_counts" =>
        Map.get(allocation_summary, "capacity_pack_status_counts", %{}),
      "capacity_pack_contact_status_counts" =>
        Map.get(allocation_summary, "capacity_pack_contact_status_counts", %{}),
      "capacity_pack_required_capacity_fraction" =>
        numeric_value(Map.get(allocation_summary, "capacity_pack_required_capacity_fraction")) ||
          0.0,
      "capacity_pack_selected_required_capacity_fraction" =>
        numeric_value(
          Map.get(allocation_summary, "capacity_pack_selected_required_capacity_fraction")
        ) ||
          0.0,
      "capacity_pack_deferred_required_capacity_fraction" =>
        numeric_value(
          Map.get(allocation_summary, "capacity_pack_deferred_required_capacity_fraction")
        ) ||
          0.0,
      "capacity_pack_required_capacity_fraction_by_ground_station" =>
        Map.get(
          allocation_summary,
          "capacity_pack_required_capacity_fraction_by_ground_station",
          %{}
        ),
      "capacity_pack_required_capacity_fraction_by_status" =>
        Map.get(allocation_summary, "capacity_pack_required_capacity_fraction_by_status", %{}),
      "capacity_pack_required_capacity_fraction_by_direction" =>
        Map.get(allocation_summary, "capacity_pack_required_capacity_fraction_by_direction", %{}),
      "capacity_pack_selected_required_capacity_fraction_by_ground_station" =>
        Map.get(
          allocation_summary,
          "capacity_pack_selected_required_capacity_fraction_by_ground_station",
          %{}
        ),
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station" =>
        Map.get(
          allocation_summary,
          "capacity_pack_deferred_required_capacity_fraction_by_ground_station",
          %{}
        ),
      "capacity_pack_selected_required_capacity_fraction_by_direction" =>
        Map.get(
          allocation_summary,
          "capacity_pack_selected_required_capacity_fraction_by_direction",
          %{}
        ),
      "capacity_pack_deferred_required_capacity_fraction_by_direction" =>
        Map.get(
          allocation_summary,
          "capacity_pack_deferred_required_capacity_fraction_by_direction",
          %{}
        ),
      "capacity_pack_contact_count" => ContactCount.count(allocation_summary),
      "capacity_pack_contact_ids_by_ground_station" =>
        Map.get(allocation_summary, "capacity_pack_contact_ids_by_ground_station", %{}),
      "capacity_pack_contact_ids_by_direction" =>
        Map.get(allocation_summary, "capacity_pack_contact_ids_by_direction", %{}),
      "capacity_pack_contact_ids_by_status" =>
        Map.get(allocation_summary, "capacity_pack_contact_ids_by_status", %{}),
      "capacity_pack_selected_contact_ids_by_ground_station" =>
        Map.get(allocation_summary, "capacity_pack_selected_contact_ids_by_ground_station", %{}),
      "capacity_pack_deferred_contact_ids_by_ground_station" =>
        Map.get(allocation_summary, "capacity_pack_deferred_contact_ids_by_ground_station", %{}),
      "capacity_pack_selected_contact_ids_by_direction" =>
        Map.get(allocation_summary, "capacity_pack_selected_contact_ids_by_direction", %{}),
      "capacity_pack_deferred_contact_ids_by_direction" =>
        Map.get(allocation_summary, "capacity_pack_deferred_contact_ids_by_direction", %{}),
      "reduced_capacity_packed_contact_ids" =>
        Map.get(allocation_summary, "reduced_capacity_packed_contact_ids"),
      "reduced_capacity_deferred_contact_ids" =>
        Map.get(allocation_summary, "reduced_capacity_deferred_contact_ids"),
      "reduced_capacity_pack_group_count" =>
        count_or_nil(allocation_summary, "reduced_capacity_pack_group_count"),
      "reduced_capacity_pack_status_counts" =>
        Map.get(allocation_summary, "reduced_capacity_pack_status_counts"),
      "capacity_pack_group_ids" => Map.get(allocation_summary, "capacity_pack_group_ids"),
      "capacity_pack_group_ids_by_status" =>
        Map.get(allocation_summary, "capacity_pack_group_ids_by_status"),
      "required_capacity_fraction_source_counts" =>
        Map.get(allocation_summary, "required_capacity_fraction_source_counts", %{}),
      "required_capacity_fraction_contact_ids_by_source" =>
        Map.get(allocation_summary, "required_capacity_fraction_contact_ids_by_source", %{})
    }
  end

  def pressure?(replay) do
    Pressure.pressure?(replay)
  end

  defp count_or_nil(allocation_summary, field) do
    case summary_integer(allocation_summary, field) do
      0 -> nil
      count -> count
    end
  end

  defp summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(String.trim(value)) do
          {integer, ""} -> integer
          _parse -> 0
        end

      _value ->
        0
    end
  end

  defp summary_integer(_summary, _field), do: 0

  defp numeric_value(value), do: ValueEncoding.numeric_value(value)
end
