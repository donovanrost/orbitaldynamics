defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineIntegrityCollectionDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineIntegrity

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineIntegrityCollectionDirectReportSources

  def reports(refresh) do
    refresh
    |> TimelineIntegrityCollectionDirectReportSources.sources()
    |> Enum.flat_map(fn {path, report_or_reports} ->
      TimelineIntegrity.entries(path, report_or_reports)
    end)
  end
end
