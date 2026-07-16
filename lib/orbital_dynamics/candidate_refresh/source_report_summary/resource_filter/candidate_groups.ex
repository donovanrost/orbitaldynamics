defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.CandidateGroups do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.CandidateGroups.CountFields

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.CandidateGroups.GroupedIds

  def fields(reports) do
    CountFields.fields(reports)
    |> Map.merge(GroupedIds.fields(reports))
  end
end
