defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateDirectRootReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateReportSources

  def entries(refresh) do
    ReadinessQualityGateReportSources.root_entries(refresh)
  end
end
