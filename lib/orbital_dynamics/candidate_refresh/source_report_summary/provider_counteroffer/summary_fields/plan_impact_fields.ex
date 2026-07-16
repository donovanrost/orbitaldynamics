defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.SummaryFields.PlanImpactFields do
  @moduledoc false

  alias __MODULE__.SummaryValues

  def fields(reports) do
    summaries = SummaryValues.reports(reports)

    %{
      "plan_impact_summary_count" => length(summaries),
      "plan_impact_status_counts" =>
        SummaryValues.single_value_counts(summaries, "plan_impact_status")
    }
    |> Map.merge(id_fields(summaries))
    |> SummaryValues.reject_empty_fields()
  end

  defp id_fields(summaries) do
    %{
      "affected_station_calendar_entry_ids" =>
        SummaryValues.sorted_string_list(summaries, "affected_station_calendar_entry_ids"),
      "affected_provider_entry_ids" =>
        SummaryValues.sorted_string_list(summaries, "affected_provider_entry_ids"),
      "impact_counteroffer_ids" =>
        SummaryValues.sorted_string_list(summaries, "impact_counteroffer_ids"),
      "timing_shift_counteroffer_ids" =>
        SummaryValues.sorted_string_list(summaries, "timing_shift_counteroffer_ids"),
      "cost_delta_counteroffer_ids" =>
        SummaryValues.sorted_string_list(summaries, "cost_delta_counteroffer_ids")
    }
  end
end
