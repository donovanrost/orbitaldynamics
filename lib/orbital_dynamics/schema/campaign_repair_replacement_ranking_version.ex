defmodule OrbitalDynamics.Schema.CampaignRepairReplacementRankingVersion do
  @moduledoc false

  @current_row_fields [
    "contact_intent_pressure_penalty",
    "contact_contention_resolution_pressure_penalty",
    "link_capacity_pressure_required_downlink_mb",
    "link_capacity_pressure_selected_capacity_adjusted_throughput_mb"
  ]

  def current?(rows) when is_list(rows) do
    Enum.any?(rows, fn
      %{} = row ->
        Enum.any?(@current_row_fields, &Map.has_key?(row, &1)) or
          current_resource_indicator?(row)

      _row ->
        false
    end)
  end

  def current?(_rows), do: false

  defp current_resource_indicator?(row) do
    case Map.get(row, "resource_projection_pressure_risk_indicators") do
      indicators when is_list(indicators) ->
        Enum.any?(indicators, &(is_map(&1) and Map.has_key?(&1, "candidate_id")))

      _indicators ->
        false
    end
  end
end
