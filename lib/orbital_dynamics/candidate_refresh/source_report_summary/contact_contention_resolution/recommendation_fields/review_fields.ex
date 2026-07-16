defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.RecommendationFields.ReviewFields do
  @moduledoc false

  alias __MODULE__.Aggregates

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Recommendation

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "review_recommendation_count" =>
        sum_report_count(reports, &numeric_report_count(&1, "review_recommendation_count")),
      "review_group_ids" => Aggregates.sorted_field_values(reports, "review_group_ids"),
      "ambiguous_group_ids" => Aggregates.sorted_field_values(reports, "ambiguous_group_ids"),
      "ambiguous_duplicate_contact_ids" =>
        Aggregates.sorted_field_values(reports, "ambiguous_duplicate_contact_ids"),
      "ambiguous_duplicate_contact_ids_by_group_id" =>
        Aggregates.string_list_map_field(
          reports,
          "ambiguous_duplicate_contact_ids_by_group_id"
        ),
      "required_operator_action_counts" =>
        Aggregates.count_map(reports, &Recommendation.required_action_counts/1),
      "review_contact_ids_by_action" =>
        Aggregates.string_list_map_field(reports, "review_contact_ids_by_action")
    }
  end
end
