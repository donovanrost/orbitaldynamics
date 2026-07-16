defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Measurements do
  @moduledoc false

  alias __MODULE__.ReportValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "counteroffer_cost_delta_count" =>
        sum_report_count(reports, &ReportValues.cost_delta_count/1),
      "counteroffer_cost_delta_total" =>
        reports
        |> Enum.map(&ReportValues.cost_delta_total/1)
        |> Enum.sum(),
      "counteroffer_timing_shift_count" =>
        sum_report_count(reports, &ReportValues.timing_shift_count/1),
      "counteroffer_start_delta_count" =>
        timing_delta_count(reports, "provider_counteroffer_start_delta_s"),
      "counteroffer_end_delta_count" =>
        timing_delta_count(reports, "provider_counteroffer_end_delta_s"),
      "counteroffer_duration_delta_count" =>
        timing_delta_count(reports, "provider_counteroffer_duration_delta_s"),
      "counteroffer_lock_deadline_count" =>
        sum_report_count(reports, &ReportValues.lock_deadline_count/1),
      "earliest_counteroffer_lock_deadline_s" => ReportValues.earliest_lock_deadline_s(reports)
    }
  end

  defp timing_delta_count(reports, field),
    do: sum_report_count(reports, &ReportValues.timing_delta_count(&1, field))
end
