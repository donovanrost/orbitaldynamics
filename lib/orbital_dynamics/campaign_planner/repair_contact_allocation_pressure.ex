defmodule OrbitalDynamics.CampaignPlanner.RepairContactAllocationPressure do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ScalarValues,
    StationCalendarPressureBranches,
    ValueEncoding
  }

  def candidate_ids(%{"rows" => rows}) when is_list(rows) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.map(&ValueEncoding.stringify_keys/1)
    |> Enum.filter(&viable_allocated_row?/1)
    |> Enum.filter(&StationCalendarPressureBranches.reduced_capacity_pressure?/1)
    |> Enum.map(&Map.get(&1, "contact_id"))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> MapSet.new()
  end

  def candidate_ids(_report), do: MapSet.new()

  def unusable_count(report), do: unusable_count(report, default_callbacks())

  def unusable_count(%{"rows" => rows}, callbacks) when is_list(rows) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    normalize_row = Keyword.fetch!(callbacks, :normalize_row)
    unusable_candidate? = Keyword.fetch!(callbacks, :unusable_candidate?)

    rows
    |> Enum.filter(&is_map/1)
    |> Enum.map(stringify_keys)
    |> Enum.map(normalize_row)
    |> Enum.count(unusable_candidate?)
  end

  def unusable_count(%{"effective_allocation_status_counts" => %{} = counts}, _callbacks) do
    Enum.sum([
      numeric_count(Map.get(counts, "blocked")),
      numeric_count(Map.get(counts, "deferred")),
      numeric_count(Map.get(counts, "policy_blocked"))
    ])
  end

  def unusable_count(_report, _callbacks), do: 0

  def normalize_row(row) do
    row
    |> normalize_status_field("allocation_status")
    |> normalize_status_field("effective_allocation_status")
    |> normalize_status_field("review_status")
    |> normalize_status_field("approval_status")
    |> normalize_policy_decision()
  end

  def unusable_candidate?(row) do
    effective_status(row) in ["deferred", "blocked", "policy_blocked"]
  end

  defp viable_allocated_row?(row) do
    row
    |> Map.get("effective_allocation_status", Map.get(row, "allocation_status"))
    |> ScalarValues.normalized_status_token()
    |> Kernel.==("allocated")
  end

  defp normalize_status_field(row, field) do
    case Map.get(row, field) do
      value when value in [nil, ""] -> row
      value -> Map.put(row, field, ScalarValues.normalized_status_token(value))
    end
  end

  defp normalize_policy_decision(%{"policy_decision" => %{} = decision} = row) do
    decision =
      decision
      |> ValueEncoding.stringify_keys()
      |> normalize_status_field("classification")

    Map.put(row, "policy_decision", decision)
  end

  defp normalize_policy_decision(row), do: row

  defp effective_status(row) do
    Map.get(row, "effective_allocation_status") || Map.get(row, "allocation_status")
  end

  defp numeric_count(count) when is_number(count), do: trunc(count)
  defp numeric_count(_count), do: 0

  defp default_callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      normalize_row: &normalize_row/1,
      unusable_candidate?: &unusable_candidate?/1
    ]
  end
end
