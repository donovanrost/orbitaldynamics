defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.StationReservationFields.ExpirationFields.StatusMaps do
  @moduledoc false

  alias __MODULE__.ValueLists

  def counts(summary), do: Map.get(summary, "station_reservation_expiration_status_counts")

  def contact_ids(summary) do
    string_list_map(summary, "station_reservation_contact_ids_by_expiration_status")
  end

  def reservation_ids(summary) do
    string_list_map(summary, "station_reservation_ids_by_expiration_status")
  end

  defp string_list_map(summary, field) do
    summary
    |> Map.get(field)
    |> ValueLists.from_map()
  end
end
