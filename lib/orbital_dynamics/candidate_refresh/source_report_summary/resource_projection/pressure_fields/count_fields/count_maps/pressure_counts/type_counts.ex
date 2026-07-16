defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.CountFields.CountMaps.PressureCounts.TypeCounts do
  @moduledoc false

  alias __MODULE__.TypeValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def from_report(report) do
    report
    |> TypeValues.from_report()
    |> count_source_report_values()
  end
end
