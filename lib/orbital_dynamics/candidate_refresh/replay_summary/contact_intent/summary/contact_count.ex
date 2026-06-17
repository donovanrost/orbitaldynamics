defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactIntent.Summary.ContactCount do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactIntent.Summary.Values,
    only: [summary_integer: 2]

  def contact_count(summary, fallback_field) do
    flat_contact_id_maps =
      [
        Map.get(summary, "contact_ids_by_direction"),
        Map.get(summary, "contact_ids_by_ground_station_id"),
        Map.get(summary, "contact_ids_by_ground_station")
      ]
      |> Enum.filter(&is_map/1)

    nested_contact_id_maps =
      [
        Map.get(summary, "contact_ids_by_direction_and_ground_station_id"),
        Map.get(summary, "contact_ids_by_direction_and_ground_station")
      ]
      |> Enum.filter(&is_map/1)

    direction_routing = Map.get(summary, "direction_routing")

    cond do
      flat_contact_id_maps != [] or nested_contact_id_maps != [] ->
        flat_contact_ids =
          flat_contact_id_maps
          |> Enum.flat_map(&string_list_map_contact_ids/1)

        nested_contact_ids =
          nested_contact_id_maps
          |> Enum.flat_map(&nested_string_list_map_contact_ids/1)

        flat_contact_ids
        |> Kernel.++(nested_contact_ids)
        |> count_unique_contact_ids()

      is_map(direction_routing) ->
        direction_routing
        |> direction_routing_contact_ids("contact_ids")
        |> count_unique_contact_ids()

      true ->
        summary_integer(summary, fallback_field)
    end
  end

  def capacity_pack_contact_count(summary, fallback_field) do
    flat_contact_id_maps =
      [
        Map.get(summary, "capacity_pack_contact_ids_by_direction"),
        Map.get(summary, "capacity_pack_contact_ids_by_ground_station_id"),
        Map.get(summary, "capacity_pack_contact_ids_by_ground_station"),
        Map.get(summary, "required_capacity_fraction_contact_ids_by_source")
      ]
      |> Enum.filter(&is_map/1)

    nested_contact_id_maps =
      [
        Map.get(summary, "capacity_pack_contact_ids_by_direction_and_ground_station_id"),
        Map.get(summary, "capacity_pack_contact_ids_by_direction_and_ground_station")
      ]
      |> Enum.filter(&is_map/1)

    direction_routing = Map.get(summary, "direction_routing")

    cond do
      flat_contact_id_maps != [] or nested_contact_id_maps != [] ->
        flat_contact_ids =
          flat_contact_id_maps
          |> Enum.flat_map(&string_list_map_contact_ids/1)

        nested_contact_ids =
          nested_contact_id_maps
          |> Enum.flat_map(&nested_string_list_map_contact_ids/1)

        flat_contact_ids
        |> Kernel.++(nested_contact_ids)
        |> count_unique_contact_ids()

      is_map(direction_routing) ->
        direction_routing
        |> direction_routing_contact_ids("capacity_pack_contact_ids")
        |> count_unique_contact_ids()

      true ->
        summary_integer(summary, fallback_field)
    end
  end

  defp string_list_map_contact_ids(%{} = contact_ids_by_group) do
    contact_ids_by_group
    |> Enum.flat_map(fn {_group, contact_ids} -> list_value(contact_ids) end)
  end

  defp string_list_map_contact_ids(_contact_ids_by_group), do: []

  defp nested_string_list_map_contact_ids(%{} = contact_ids_by_outer_group) do
    contact_ids_by_outer_group
    |> Enum.flat_map(fn
      {_outer_group, %{} = contact_ids_by_inner_group} ->
        string_list_map_contact_ids(contact_ids_by_inner_group)

      {_outer_group, _contact_ids_by_inner_group} ->
        []
    end)
  end

  defp nested_string_list_map_contact_ids(_contact_ids_by_outer_group), do: []

  defp count_unique_contact_ids(contact_ids) do
    contact_ids
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> length()
  end

  defp direction_routing_contact_ids(%{} = direction_routing, contact_ids_field) do
    direction_routing
    |> Map.values()
    |> Enum.flat_map(fn
      %{} = route -> route |> Map.get(contact_ids_field, []) |> list_value()
      _route -> []
    end)
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
