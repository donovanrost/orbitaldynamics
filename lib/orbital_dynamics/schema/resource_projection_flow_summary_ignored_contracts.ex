defmodule OrbitalDynamics.Schema.ResourceProjectionFlowSummaryIgnoredContracts do
  @moduledoc false

  def rows(flow_rows) do
    Enum.filter(flow_rows, &(Map.get(&1, "resource_effect_status") == "ignored"))
  end

  def activity_ids(rows, callbacks) when is_list(callbacks) do
    rows
    |> Enum.map(&Map.get(&1, "activity_id"))
    |> sorted_stable_values(callbacks)
  end

  def reason_counts(rows) do
    rows
    |> Enum.map(&Map.get(&1, "resource_effect_reason"))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  def activity_ids_by_reason(rows, callbacks) when is_list(callbacks) do
    rows
    |> Enum.map(&{Map.get(&1, "resource_effect_reason"), Map.get(&1, "activity_id")})
    |> stable_values_by_key(callbacks)
  end

  defp sorted_stable_values(values, callbacks),
    do: apply(require_callback(callbacks, :sorted_stable_values), [values])

  defp stable_values_by_key(pairs, callbacks),
    do: apply(require_callback(callbacks, :stable_values_by_key), [pairs])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
