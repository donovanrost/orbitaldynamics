defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.ThroughputFields.LineageFields do
  @moduledoc false

  alias __MODULE__.ActualFields
  alias __MODULE__.SelectedFields

  def fields(reports) do
    reports
    |> SelectedFields.fields()
    |> Map.merge(ActualFields.fields(reports))
  end
end
