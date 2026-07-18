defmodule OrbitalDynamics.Timeline.CountSummaryPolicy do
  @moduledoc false

  def duplicate_group_count(groups) do
    groups
    |> Map.values()
    |> Enum.count(&(length(&1) > 1))
  end

  def duplicate_activity_count(groups) do
    groups
    |> Map.values()
    |> Enum.filter(&(length(&1) > 1))
    |> Enum.map(&length/1)
    |> Enum.sum()
  end

  def count_by(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> sort_count_map()
  end

  def changed_field_counts(rows, list_value) do
    rows
    |> Enum.flat_map(&list_value.(&1, "changed_fields"))
    |> Enum.frequencies()
    |> sort_count_map()
  end

  def transition_counts(rows, field) do
    rows
    |> Enum.map(&get_in(&1, [field, "transition_type"]))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> sort_count_map()
  end

  def transition_category_counts(rows, field) do
    rows
    |> Enum.map(&get_in(&1, [field, "transition_category"]))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> sort_count_map()
  end

  def sort_count_map(counts) do
    counts
    |> Enum.sort_by(fn {key, _count} -> key end)
    |> Map.new()
  end
end
