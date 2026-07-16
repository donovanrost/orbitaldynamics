defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.CountFields.IdentityFields do
  @moduledoc false

  alias __MODULE__.CountMaps

  def fields(summaries) do
    %{
      "activity_id_counts" => CountMaps.id(summaries, "activity_id"),
      "timeline_id_counts" => CountMaps.id(summaries, "timeline_id"),
      "dependency_activity_id_counts" => CountMaps.list(summaries, "dependency_activity_ids"),
      "dependency_timeline_id_counts" => CountMaps.list(summaries, "dependency_timeline_ids"),
      "exclusive_with_activity_id_counts" =>
        CountMaps.list(summaries, "exclusive_with_activity_ids"),
      "exclusive_with_timeline_id_counts" =>
        CountMaps.list(summaries, "exclusive_with_timeline_ids"),
      "duplicate_dependency_activity_id_counts" =>
        CountMaps.list(summaries, "duplicate_dependency_activity_ids"),
      "duplicate_dependency_timeline_id_counts" =>
        CountMaps.list(summaries, "duplicate_dependency_timeline_ids"),
      "duplicate_exclusivity_activity_id_counts" =>
        CountMaps.list(summaries, "duplicate_exclusivity_activity_ids"),
      "duplicate_exclusivity_timeline_id_counts" =>
        CountMaps.list(summaries, "duplicate_exclusivity_timeline_ids")
    }
  end
end
