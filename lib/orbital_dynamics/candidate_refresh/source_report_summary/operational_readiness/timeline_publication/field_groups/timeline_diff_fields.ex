defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.TimelinePublication.FieldGroups.TimelineDiffFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.Evidence

  def values(reports) do
    %{
      "timeline_diff_row_count" => Evidence.count_sum(reports, "timeline_diff_row_count"),
      "timeline_diff_changed_count" => Evidence.count_sum(reports, "timeline_diff_changed_count"),
      "timeline_diff_review_required_count" =>
        Evidence.count_sum(reports, "timeline_diff_review_required_count"),
      "changed_field_counts" => Evidence.count_map_merge(reports, "changed_field_counts"),
      "changed_timeline_ids" => Evidence.string_values(reports, "changed_timeline_ids"),
      "review_timeline_ids" => Evidence.string_values(reports, "review_timeline_ids"),
      "timeline_ids_by_changed_field" =>
        Evidence.string_list_map_merge(reports, "timeline_ids_by_changed_field")
    }
  end
end
