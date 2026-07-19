defmodule OrbitalDynamics.Communications.ContactContention.ResolutionSummaryValues do
  @moduledoc false

  def review_contact_ids(recommendations) do
    recommendations
    |> Enum.flat_map(fn recommendation ->
      [recommendation["selected_contact_id"]] ++
        List.wrap(recommendation["deferred_contact_ids"]) ++
        List.wrap(recommendation["duplicate_contact_ids"])
    end)
    |> compact_sorted_unique_list()
  end

  def values(recommendations, field) do
    recommendations
    |> Enum.map(& &1[field])
    |> compact_sorted_unique_list()
  end

  def list_values(recommendations, field) do
    recommendations
    |> Enum.flat_map(&List.wrap(&1[field]))
    |> compact_sorted_unique_list()
  end

  def values_by_field(recommendations, group_field, value_field) do
    recommendations
    |> Enum.group_by(& &1[group_field], & &1[value_field])
    |> compact_value_map()
  end

  def list_values_by_field(recommendations, group_field, value_field) do
    recommendations
    |> Enum.group_by(& &1[group_field], &List.wrap(&1[value_field]))
    |> Map.new(fn {group, values} -> {group, Enum.flat_map(values, & &1)} end)
    |> compact_value_map()
  end

  def review_contact_ids_by_field(recommendations, group_field) do
    recommendations
    |> Enum.group_by(& &1[group_field], fn recommendation ->
      [recommendation["selected_contact_id"]] ++
        List.wrap(recommendation["deferred_contact_ids"]) ++
        List.wrap(recommendation["duplicate_contact_ids"])
    end)
    |> Map.new(fn {group, values} -> {group, Enum.flat_map(values, & &1)} end)
    |> compact_value_map()
  end

  def count_by_field(recommendations, field) do
    recommendations
    |> Enum.map(& &1[field])
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  def compact_sorted_unique_list(values) do
    values
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp compact_value_map(values_by_group) do
    values_by_group
    |> Enum.reject(fn {group, values} ->
      is_nil(group) or Enum.all?(List.wrap(values), &is_nil/1)
    end)
    |> Map.new(fn {group, values} -> {group, compact_sorted_unique_list(List.wrap(values))} end)
  end
end
