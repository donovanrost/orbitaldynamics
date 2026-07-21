defmodule OrbitalDynamics.CampaignPlanner.RepairStationPressure do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    RepairContactAllocationPressure,
    StationCalendarPressureBranches
  }

  @allocation_source "campaign_repair.source_contact_allocation_report.rows"
  @calendar_source "campaign_repair.source_station_calendar_report.affected_contacts"

  def sources_by_candidate_id(station_calendar_report, contact_allocation_report) do
    %{}
    |> add_source(
      RepairContactAllocationPressure.candidate_ids(contact_allocation_report),
      @allocation_source
    )
    |> add_source(station_calendar_candidate_ids(station_calendar_report), @calendar_source)
    |> Map.new(fn {candidate_id, sources} ->
      {candidate_id, sources |> Enum.uniq() |> Enum.sort()}
    end)
  end

  defp station_calendar_candidate_ids(%{"affected_contacts" => rows}) when is_list(rows) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.filter(&StationCalendarPressureBranches.pressure?/1)
    |> Enum.map(&Map.get(&1, "contact_id"))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> MapSet.new()
  end

  defp station_calendar_candidate_ids(_report), do: MapSet.new()

  defp add_source(sources_by_candidate_id, candidate_ids, source) do
    Enum.reduce(candidate_ids, sources_by_candidate_id, fn candidate_id, acc ->
      Map.update(acc, candidate_id, [source], &[source | &1])
    end)
  end
end
