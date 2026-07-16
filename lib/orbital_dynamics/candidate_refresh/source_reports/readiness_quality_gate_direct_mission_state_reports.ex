defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateDirectMissionStateReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateReportSources

  def entries(refresh) do
    ReadinessQualityGateReportSources.scoped_entries(refresh, "mission_state")
  end
end
