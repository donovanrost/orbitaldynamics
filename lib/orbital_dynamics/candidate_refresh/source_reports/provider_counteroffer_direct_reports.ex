defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounteroffer
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferDirectReportSources

  def reports(refresh) do
    refresh
    |> ProviderCounterofferDirectReportSources.sources()
    |> Enum.flat_map(fn {path, report_or_reports} ->
      ProviderCounteroffer.entries(path, report_or_reports)
    end)
  end
end
