defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.ProviderContentionFields.Aggregates do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.EntryIdMaps

  def fields(reports) do
    reports
    |> CountFields.fields()
    |> Map.merge(EntryIdMaps.fields(reports))
  end
end
