defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGate

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateDirectAcceptedStateReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateDirectMissionStateReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateDirectRootReports

  def reports(refresh) do
    refresh
    |> source_entries()
    |> Enum.flat_map(fn {path, report_or_reports} ->
      QualityGate.entries(path, report_or_reports)
    end)
  end

  defp source_entries(refresh) do
    ReadinessQualityGateDirectAcceptedStateReports.entries(refresh) ++
      ReadinessQualityGateDirectMissionStateReports.entries(refresh) ++
      ReadinessQualityGateDirectRootReports.entries(refresh)
  end
end
