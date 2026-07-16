defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ContactNetworkReports do
  @moduledoc false

  alias __MODULE__.Definitions
  alias __MODULE__.ReportSources
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.Summary

  def build(refresh) do
    Summary.from_definitions(refresh, Definitions.definitions())
  end

  def source?(source), do: ReportSources.source?(source)

  def reports(refresh, source), do: ReportSources.reports(refresh, source)
end
