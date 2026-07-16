defmodule OrbitalDynamics.Schema.ResourceProjectionFlowSummaryIgnoredContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionAggregation,
    only: [sorted_stable_values: 1, stable_values_by_key: 1]

  def rows(flow_rows) do
    Enum.filter(flow_rows, &(Map.get(&1, "resource_effect_status") == "ignored"))
  end

  def activity_ids(rows) do
    rows
    |> Enum.map(&Map.get(&1, "activity_id"))
    |> sorted_stable_values()
  end

  def reason_counts(rows) do
    rows
    |> Enum.map(&Map.get(&1, "resource_effect_reason"))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  def activity_ids_by_reason(rows) do
    rows
    |> Enum.map(&{Map.get(&1, "resource_effect_reason"), Map.get(&1, "activity_id")})
    |> stable_values_by_key()
  end
end
