defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateDirectAcceptedStateReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateReportSources

  def entries(refresh) do
    ReadinessQualityGateReportSources.scoped_entries(refresh, "accepted_planning_state")
  end
end
