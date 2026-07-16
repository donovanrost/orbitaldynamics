defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.InputSummary.SourceReports do
  @moduledoc false

  def values(sources) do
    Enum.map(sources, fn {_path, report} -> report end)
  end
end
