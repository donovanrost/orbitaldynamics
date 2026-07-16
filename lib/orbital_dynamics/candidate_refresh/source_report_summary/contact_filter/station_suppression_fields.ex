defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactFilter.StationSuppressionFields do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.IdMaps

  def fields(reports) do
    reports
    |> CountFields.fields()
    |> Map.merge(IdMaps.fields(reports))
  end
end
