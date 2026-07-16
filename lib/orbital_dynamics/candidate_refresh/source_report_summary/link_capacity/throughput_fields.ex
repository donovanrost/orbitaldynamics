defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.ThroughputFields do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.LineageFields
  alias __MODULE__.ValueFields

  def fields(reports) do
    reports
    |> CountFields.fields()
    |> Map.merge(ValueFields.fields(reports))
    |> Map.merge(LineageFields.fields(reports))
  end
end
