defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.BaseFields.SourcePaths do
  @moduledoc false

  def values(sources) do
    Enum.map(sources, fn {path, _report} -> path end)
  end
end
