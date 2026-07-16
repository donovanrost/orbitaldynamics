defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.ProviderReservationSummary.ContactFields.RouteFields do
  @moduledoc false

  alias __MODULE__.FieldGroups

  def fields(reports) do
    %{}
    |> Map.merge(FieldGroups.station_fields(reports))
    |> Map.merge(FieldGroups.direction_fields(reports))
    |> Map.merge(FieldGroups.nested_direction_station_fields(reports))
  end
end
