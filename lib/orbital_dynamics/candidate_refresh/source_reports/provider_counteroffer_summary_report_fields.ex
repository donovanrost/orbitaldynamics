defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferSummaryReportFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sorted_string_values: 1
    ]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowValues
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferSummaryBaseFields
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferSummaryReviewFields

  def review_fields(%{} = summary) do
    ProviderCounterofferSummaryReviewFields.review_fields(summary)
  end

  def plan_impact_fields(%{} = summary) do
    rows =
      summary
      |> Map.get("impact_rows", [])
      |> Enum.filter(&is_map/1)
      |> Enum.map(&ProviderCounterofferImportReadinessRowValues.stringify_keys/1)

    summary
    |> ProviderCounterofferSummaryBaseFields.fields(
      rows,
      "preserved_provider_counteroffer_plan_impact_summary"
    )
    |> Map.merge(%{
      "counteroffer_status_counts" =>
        ProviderCounterofferImportReadinessRowValues.count_rows(
          rows,
          "provider_counteroffer_status"
        ),
      "required_operator_action_counts" =>
        ProviderCounterofferImportReadinessRowValues.count_rows(
          rows,
          "required_operator_action"
        ),
      "plan_impact_status" => Map.get(summary, "plan_impact_status"),
      "affected_station_calendar_entry_ids" =>
        sorted_string_values(Map.get(summary, "affected_station_calendar_entry_ids", [])),
      "affected_provider_entry_ids" =>
        sorted_string_values(Map.get(summary, "affected_provider_entry_ids", [])),
      "impact_counteroffer_ids" =>
        sorted_string_values(Map.get(summary, "impact_counteroffer_ids", [])),
      "timing_shift_counteroffer_ids" =>
        sorted_string_values(Map.get(summary, "timing_shift_counteroffer_ids", [])),
      "cost_delta_counteroffer_ids" =>
        sorted_string_values(Map.get(summary, "cost_delta_counteroffer_ids", []))
    })
  end
end
