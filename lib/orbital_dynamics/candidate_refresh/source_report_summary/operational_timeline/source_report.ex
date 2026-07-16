defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.SourceReport do
  @moduledoc false

  alias __MODULE__.ReportFields

  def fields(%{} = report), do: ReportFields.fields(report)
end
