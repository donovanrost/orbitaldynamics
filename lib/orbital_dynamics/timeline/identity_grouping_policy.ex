defmodule OrbitalDynamics.Timeline.IdentityGroupingPolicy do
  @moduledoc false

  def normalized_activity_groups(activities, opts, normalize_activities) do
    activities
    |> normalize_activities.(opts)
    |> Enum.group_by(& &1["timeline_id"])
  end

  def unique_timeline_activity(groups, timeline_id) do
    case Map.get(groups, timeline_id, []) do
      [activity] -> activity
      _duplicates_or_missing -> nil
    end
  end

  def rows_by_timeline_id(rows) do
    rows
    |> Enum.group_by(& &1["timeline_id"])
    |> Map.new(fn {timeline_id, matches} ->
      {timeline_id, Enum.sort_by(matches, & &1["activity_id"])}
    end)
  end

  def application_timeline_ids(applications, predicate, sorted_uniq)
      when is_list(applications) do
    applications
    |> Enum.filter(predicate)
    |> Enum.map(& &1["timeline_id"])
    |> sorted_uniq.()
  end

  def application_activity_ids(applications, predicate, sorted_uniq)
      when is_list(applications) do
    applications
    |> Enum.filter(predicate)
    |> Enum.flat_map(&[&1["source_activity_id"], &1["replacement_activity_id"]])
    |> sorted_uniq.()
  end

  def timeline_ids_by(rows, key_fun, predicate, sorted_uniq) when is_list(rows) do
    rows
    |> Enum.filter(predicate)
    |> Enum.reduce(%{}, fn row, grouped ->
      key = key_fun.(row)
      timeline_id = row["timeline_id"]

      if key in [nil, ""] or timeline_id in [nil, ""] do
        grouped
      else
        Map.update(grouped, key, [timeline_id], &[timeline_id | &1])
      end
    end)
    |> Enum.map(fn {key, timeline_ids} -> {key, sorted_uniq.(timeline_ids)} end)
    |> Enum.sort_by(fn {key, _timeline_ids} -> key end)
    |> Map.new()
  end

  def timeline_ids_by_each(rows, values_fun, predicate, sorted_uniq) when is_list(rows) do
    rows
    |> Enum.filter(predicate)
    |> Enum.reduce(%{}, fn row, grouped ->
      timeline_id = row["timeline_id"]

      if timeline_id in [nil, ""] do
        grouped
      else
        row
        |> values_fun.()
        |> List.wrap()
        |> Enum.reject(&(&1 in [nil, ""]))
        |> Enum.reduce(grouped, fn key, nested ->
          Map.update(nested, key, [timeline_id], &[timeline_id | &1])
        end)
      end
    end)
    |> Enum.map(fn {key, timeline_ids} -> {key, sorted_uniq.(timeline_ids)} end)
    |> Enum.sort_by(fn {key, _timeline_ids} -> key end)
    |> Map.new()
  end
end
