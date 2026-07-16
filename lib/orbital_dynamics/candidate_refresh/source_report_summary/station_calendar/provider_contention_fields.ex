defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.ProviderContentionFields do
  @moduledoc false

  alias __MODULE__.CapacityFields
  alias __MODULE__.CountFields
  alias __MODULE__.IdentityFields

  def fields(reports) do
    reports
    |> CountFields.fields()
    |> Map.merge(IdentityFields.fields(reports))
    |> Map.merge(CapacityFields.fields(reports))
  end
end
