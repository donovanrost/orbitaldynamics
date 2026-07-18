defmodule OrbitalDynamics.Timeline.IntegrityCountPolicy do
  @moduledoc false

  def timeline_integrity_issue_count(rows) do
    Enum.reduce(rows, 0, &(&2 + Map.get(&1, "timeline_integrity_issue_count", 0)))
  end

  def timeline_integrity_issue_types(rows, list_value) do
    rows
    |> Enum.flat_map(&list_value.(&1, "timeline_integrity_issue_types"))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def timeline_integrity_issue_type_counts(rows, list_value, sort_count_map) do
    rows
    |> Enum.flat_map(&list_value.(&1, "timeline_integrity_issues"))
    |> Enum.map(&Map.get(&1, "type"))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> sort_count_map.()
  end

  def dependency_issue_count(rows, list_value) do
    rows
    |> Enum.flat_map(&list_value.(&1, "timeline_integrity_issues"))
    |> Enum.count(fn issue ->
      is_map(issue) and
        issue
        |> Map.get("type")
        |> dependency_issue_type?()
    end)
  end

  def exclusivity_issue_count(rows, list_value) do
    rows
    |> Enum.flat_map(&list_value.(&1, "timeline_integrity_issues"))
    |> Enum.count(fn issue ->
      is_map(issue) and
        issue
        |> Map.get("type")
        |> exclusivity_issue_type?()
    end)
  end

  defp dependency_issue_type?(type) when is_binary(type), do: String.contains?(type, "dependency")
  defp dependency_issue_type?(_type), do: false

  defp exclusivity_issue_type?(type) when is_binary(type),
    do: String.contains?(type, "exclusivity")

  defp exclusivity_issue_type?(_type), do: false
end
