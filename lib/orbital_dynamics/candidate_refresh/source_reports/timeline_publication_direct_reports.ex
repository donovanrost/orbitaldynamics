defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublication

  def reports(refresh) do
    [
      {"accepted_planning_state.source_timeline_publication_summary",
       get_in(refresh, ["accepted_planning_state", "source_timeline_publication_summary"])},
      {"accepted_planning_state.timeline_publication_summary",
       get_in(refresh, ["accepted_planning_state", "timeline_publication_summary"])},
      {"mission_state.source_timeline_publication_summary",
       get_in(refresh, ["mission_state", "source_timeline_publication_summary"])},
      {"mission_state.timeline_publication_summary",
       get_in(refresh, ["mission_state", "timeline_publication_summary"])},
      {"source_timeline_publication_summary",
       Map.get(refresh, "source_timeline_publication_summary")},
      {"timeline_publication_summary", Map.get(refresh, "timeline_publication_summary")}
    ]
    |> Enum.flat_map(fn {path, summary_or_summaries} ->
      TimelinePublication.entries(path, summary_or_summaries)
    end)
  end
end
