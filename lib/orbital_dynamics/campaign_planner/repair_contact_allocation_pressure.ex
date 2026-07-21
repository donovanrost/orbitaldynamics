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

  defp viable_allocated_row?(row) do
    row
    |> Map.get("effective_allocation_status", Map.get(row, "allocation_status"))
    |> ScalarValues.normalized_status_token()
    |> Kernel.==("allocated")
  end
end
