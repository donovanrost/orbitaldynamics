defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateOperationalReadinessDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalReadiness

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateOperationalReadinessDirectReportSourceFields

  def reports(refresh) do
    refresh
    |> ReadinessQualityGateOperationalReadinessDirectReportSourceFields.sources()
    |> Enum.flat_map(fn {path, report_or_reports} ->
      OperationalReadiness.entries(path, report_or_reports)
    end)
  end
end
