defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance do
  @moduledoc false

  alias __MODULE__.CandidateCommandReports
  alias __MODULE__.ContactNetworkReports
  alias __MODULE__.ObjectiveResourceReports
  alias __MODULE__.ReadinessValidationReports
  alias __MODULE__.Summary
  alias __MODULE__.TimelineReports

  def build(refresh) do
    TimelineReports.build(refresh)
    |> Map.merge(ReadinessValidationReports.build(refresh))
    |> Map.merge(ContactNetworkReports.build(refresh))
    |> Map.merge(CandidateCommandReports.build(refresh))
    |> Map.merge(ObjectiveResourceReports.build(refresh))
    |> Summary.compact()
  end
end
