defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.CountFields.AnalysisModeFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.CountFields.AnalysisModes

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1
    ]

  def fields(reports) do
    %{
      "analysis_mode_counts" =>
        reports
        |> Enum.map(&AnalysisModes.counts/1)
        |> merge_count_maps()
    }
  end
end
