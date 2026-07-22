defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.Summary.CapacityPack do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def fields(resolution_summary) do
    required_fraction =
      numeric_value(Map.get(resolution_summary, "capacity_pack_required_capacity_fraction")) ||
        0.0

    selected_required_fraction =
      numeric_value(
        Map.get(resolution_summary, "capacity_pack_selected_required_capacity_fraction")
      ) || 0.0

    deferred_required_fraction =
      numeric_value(
        Map.get(resolution_summary, "capacity_pack_deferred_required_capacity_fraction")
      ) || 0.0

    source_counts =
      map_or_empty(Map.get(resolution_summary, "required_capacity_fraction_source_counts"))

    allowed_contact_ids =
      List.wrap(Map.get(resolution_summary, "selected_contact_ids")) ++
        List.wrap(Map.get(resolution_summary, "deferred_contact_ids"))

    contact_ids_by_source =
      filter_contact_ids(
        Map.get(resolution_summary, "required_capacity_fraction_contact_ids_by_source"),
        source_counts,
        allowed_contact_ids
      )

    %{
      "capacity_pack_required_capacity_fraction" => required_fraction,
      "capacity_pack_selected_required_capacity_fraction" => selected_required_fraction,
      "capacity_pack_deferred_required_capacity_fraction" => deferred_required_fraction,
      "capacity_pack_required_capacity_fraction_by_ground_station" =>
        correlated_numeric_map(
          Map.get(
            resolution_summary,
            "capacity_pack_required_capacity_fraction_by_ground_station"
          ),
          required_fraction
        ),
      "capacity_pack_selected_required_capacity_fraction_by_ground_station" =>
        correlated_numeric_map(
          resolution_summary,
          "capacity_pack_selected_required_capacity_fraction_by_ground_station",
          selected_required_fraction
        ),
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station" =>
        correlated_numeric_map(
          resolution_summary,
          "capacity_pack_deferred_required_capacity_fraction_by_ground_station",
          deferred_required_fraction
        ),
      "capacity_pack_required_capacity_fraction_by_status" =>
        correlated_capacity_status(
          Map.get(resolution_summary, "capacity_pack_required_capacity_fraction_by_status"),
          required_fraction,
          selected_required_fraction,
          deferred_required_fraction
        ),
      "required_capacity_fraction_source_counts" => non_empty_map(source_counts),
      "required_capacity_fraction_contact_ids_by_source" => non_empty_map(contact_ids_by_source)
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

  defp numeric_value(value), do: ValueEncoding.numeric_value(value)

  defp correlated_numeric_map(summary, field, total),
    do: correlated_numeric_map(Map.get(summary, field), total)

  defp correlated_numeric_map(values, total) do
    values = normalize_numeric_map(values, :all_keys)

    if numeric_map_sum(values) == total, do: values, else: %{}
  end

  defp correlated_capacity_status(values, total, selected_total, deferred_total) do
    values = normalize_numeric_map(values, ["selected", "deferred"])

    if numeric_map_sum(values) == total and
         Map.get(values, "selected", 0) == selected_total and
         Map.get(values, "deferred", 0) == deferred_total do
      non_empty_map(values)
    else
      nil
    end
  end

  defp normalize_numeric_map(%{} = values, allowed_keys) do
    Enum.reduce(values, %{}, fn {key, value}, normalized ->
      value = numeric_value(value)

      if (allowed_keys == :all_keys or key in allowed_keys) and is_number(value) and value >= 0 do
        Map.put(normalized, key, value)
      else
        normalized
      end
    end)
  end

  defp normalize_numeric_map(_values, _allowed_keys), do: %{}

  defp numeric_map_sum(values), do: values |> Map.values() |> Enum.sum()

  defp filter_contact_ids(%{} = values_by_source, %{} = source_counts, allowed_contact_ids) do
    allowed_contact_ids = MapSet.new(allowed_contact_ids)

    source_counts
    |> Enum.filter(fn {_source, count} -> is_integer(count) and count > 0 end)
    |> Enum.reduce(%{}, fn {source, _count}, filtered ->
      contact_ids =
        values_by_source
        |> Map.get(source, [])
        |> List.wrap()
        |> Enum.filter(&MapSet.member?(allowed_contact_ids, &1))

      case contact_ids do
        [] -> filtered
        contact_ids -> Map.put(filtered, source, contact_ids)
      end
    end)
  end

  defp filter_contact_ids(_values_by_source, _source_counts, _allowed_contact_ids), do: %{}

  defp map_or_empty(%{} = map), do: map
  defp map_or_empty(_map), do: %{}

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
