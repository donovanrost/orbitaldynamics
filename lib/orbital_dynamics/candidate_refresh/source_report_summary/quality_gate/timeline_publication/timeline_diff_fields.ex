defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.TimelinePublication.TimelineDiffFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.TimelinePublication.FieldGroups

  def fields(reports) do
    %{
      "timeline_diff_row_count" => FieldGroups.row_count(reports, "timeline_diff_row_count"),
      "timeline_diff_changed_count" =>
        FieldGroups.row_count(reports, "timeline_diff_changed_count"),
      "timeline_diff_review_required_count" =>
        FieldGroups.row_count(reports, "timeline_diff_review_required_count"),
      "changed_field_counts" => FieldGroups.count_map(reports, "changed_field_counts"),
      "changed_timeline_ids" => FieldGroups.string_values(reports, "changed_timeline_ids"),
      "review_timeline_ids" => FieldGroups.string_values(reports, "review_timeline_ids"),
      "timeline_ids_by_changed_field" =>
        FieldGroups.string_list_map(reports, "timeline_ids_by_changed_field")
    }
  end
end
