defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.IdentityCountValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def count(rows, values_fun) do
    rows
    |> values_fun.()
    |> count_source_report_values()
  end
end
