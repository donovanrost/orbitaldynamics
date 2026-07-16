defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.RecommendationFields.BaseFields do
  @moduledoc false

  alias __MODULE__.Aggregates
  alias __MODULE__.DirectionFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Recommendation

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "row_count" => sum_report_count(reports, &Recommendation.row_count/1),
      "conflict_group_count" =>
        sum_report_count(reports, &numeric_report_count(&1, "conflict_group_count")),
      "recommendation_count" => sum_report_count(reports, &Recommendation.recommendation_count/1),
      "recommendation_group_ids" =>
        Aggregates.sorted_field_values(reports, "recommendation_group_ids"),
      "deferred_contact_count" =>
        sum_report_count(reports, &Recommendation.deferred_contact_count/1),
      "resolution_status_counts" =>
        Aggregates.count_map(reports, &Recommendation.status_counts/1),
      "selection_reason_counts" =>
        Aggregates.count_map(reports, &Recommendation.selection_reason_counts/1),
      "resource_scope_counts" => Aggregates.count_map_field(reports, "resource_scope_counts")
    }
    |> Map.merge(DirectionFields.fields(reports))
  end
end
