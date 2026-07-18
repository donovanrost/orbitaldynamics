defmodule OrbitalDynamics.Timeline.IntegrityIdGroupingPolicy do
  @moduledoc false

  def timeline_row_ids(rows, field, sorted_uniq) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> sorted_uniq.()
  end

  def timeline_integrity_scope_ids(rows, issue_type_fragment, field, list_value, sorted_uniq) do
    rows
    |> Enum.filter(fn row ->
      row
      |> list_value.("timeline_integrity_issue_types")
      |> Enum.any?(&String.contains?(&1, issue_type_fragment))
    end)
    |> timeline_row_ids(field, sorted_uniq)
  end

  def timeline_integrity_ids_by_issue_type(rows, id_field, list_value, sorted_uniq) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> list_value.("timeline_integrity_issue_types")
      |> Enum.map(&{&1, row[id_field]})
    end)
    |> grouped_sorted_ids(sorted_uniq)
  end

  def timeline_integrity_ids_by_field(rows, group_field, id_field, sorted_uniq) do
    rows
    |> Enum.map(&{&1[group_field], &1[id_field]})
    |> grouped_sorted_ids(sorted_uniq)
  end

  defp grouped_sorted_ids(pairs, sorted_uniq) do
    pairs
    |> Enum.reject(fn {group, id} -> is_nil(group) or is_nil(id) end)
    |> Enum.group_by(fn {group, _id} -> group end, fn {_group, id} -> id end)
    |> Enum.sort_by(fn {group, _ids} -> group end)
    |> Map.new(fn {group, ids} -> {group, sorted_uniq.(ids)} end)
  end

  def timeline_integrity_row_list_ids(rows, field, list_value, sorted_uniq) do
    rows
    |> Enum.flat_map(&list_value.(&1, field))
    |> sorted_uniq.()
  end

  def timeline_diff_status_ids(rows, status, sorted_uniq) do
    rows
    |> Enum.filter(&(&1["diff_status"] == status))
    |> timeline_row_ids("timeline_id", sorted_uniq)
  end
end
