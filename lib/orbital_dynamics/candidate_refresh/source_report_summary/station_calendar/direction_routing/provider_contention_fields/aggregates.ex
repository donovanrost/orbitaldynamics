defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.DirectionRouting.ProviderContentionFields.Aggregates do
  @moduledoc false

  alias __MODULE__.IdentityFields
  alias __MODULE__.MetricFields

  def fields(reports) do
    reports
    |> MetricFields.fields()
    |> Map.merge(IdentityFields.fields(reports))
  end
end
