defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactAllocationSummarySourceTypes do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactAllocationProviderReservationRequestSummarySource

  @standard_summary_models [
    "artifact_only_contact_allocation_summary",
    "artifact_only_contact_allocation_station_pressure_summary",
    "artifact_only_contact_allocation_reservation_conflict_summary",
    "artifact_only_contact_allocation_capacity_pack_summary"
  ]

  def builder(%{} = summary) do
    cond do
      standard_summary_source?(summary) ->
        :summary

      ContactAllocationProviderReservationRequestSummarySource.source?(summary) ->
        :provider_reservation_request_summary

      true ->
        nil
    end
  end

  defp standard_summary_source?(%{} = summary) do
    model(summary) in @standard_summary_models and is_list(value(summary, "rows", :rows))
  end

  defp model(summary), do: value(summary, "model", :model)

  defp value(map, string_key, atom_key), do: Map.get(map, string_key) || Map.get(map, atom_key)
end
