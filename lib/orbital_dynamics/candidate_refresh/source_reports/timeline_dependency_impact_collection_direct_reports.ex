defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactCollectionDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpact

  def reports(refresh) do
    [
      {"accepted_planning_state.source_timeline_dependency_impact_summary",
       get_in(refresh, ["accepted_planning_state", "source_timeline_dependency_impact_summary"])},
      {"accepted_planning_state.timeline_dependency_impact_summary",
       get_in(refresh, ["accepted_planning_state", "timeline_dependency_impact_summary"])},
      {"mission_state.source_timeline_dependency_impact_summary",
       get_in(refresh, ["mission_state", "source_timeline_dependency_impact_summary"])},
      {"mission_state.timeline_dependency_impact_summary",
       get_in(refresh, ["mission_state", "timeline_dependency_impact_summary"])},
      {"source_timeline_dependency_impact_summary",
       Map.get(refresh, "source_timeline_dependency_impact_summary")},
      {"timeline_dependency_impact_summary",
       Map.get(refresh, "timeline_dependency_impact_summary")}
    ]
    |> Enum.flat_map(fn {path, summary_or_summaries} ->
      TimelineDependencyImpact.entries(path, summary_or_summaries)
    end)
  end
end
