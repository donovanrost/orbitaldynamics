defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.SourceReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.{
    CandidateCommandReports,
    ContactNetworkReports,
    ObjectiveResourceReports,
    ReadinessValidationReports,
    TimelineReports
  }

  def reports(refresh, source) do
    cond do
      TimelineReports.source?(source) ->
        TimelineReports.reports(refresh, source)

      ReadinessValidationReports.source?(source) ->
        ReadinessValidationReports.reports(refresh, source)

      ObjectiveResourceReports.source?(source) ->
        ObjectiveResourceReports.reports(refresh, source)

      CandidateCommandReports.source?(source) ->
        CandidateCommandReports.reports(refresh, source)

      ContactNetworkReports.source?(source) ->
        ContactNetworkReports.reports(refresh, source)
    end
  end
end
