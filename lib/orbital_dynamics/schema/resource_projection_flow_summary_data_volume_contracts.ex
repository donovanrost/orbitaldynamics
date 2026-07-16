defmodule OrbitalDynamics.Schema.ResourceProjectionFlowSummaryDataVolumeContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionAggregation, only: [sorted_stable_values: 1]

  def evidence_count(flow_rows) do
    Enum.count(flow_rows, &is_number(Map.get(&1, "actual_data_volume_mb")))
  end

  def variance_activity_ids(flow_rows, variance) do
    flow_rows
    |> Enum.filter(&variance?(&1, variance))
    |> Enum.map(&Map.get(&1, "activity_id"))
    |> sorted_stable_values()
  end

  defp variance?(row, variance) do
    case Map.get(row, "data_volume_delta_mb") do
      delta when is_number(delta) and variance == :under_delivered -> delta < 0.0
      delta when is_number(delta) and variance == :over_delivered -> delta > 0.0
      delta when is_number(delta) and variance == :exact -> delta == 0.0
      _delta -> false
    end
  end
end
