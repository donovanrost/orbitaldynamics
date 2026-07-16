defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.StationReservationSummary do
  @moduledoc false

  alias __MODULE__.{ExpirationFields, ReservationFields}

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def fields(reports) do
    ReservationFields.fields(reports)
    |> Map.merge(ExpirationFields.fields(reports))
    |> compact_map()
  end
end
