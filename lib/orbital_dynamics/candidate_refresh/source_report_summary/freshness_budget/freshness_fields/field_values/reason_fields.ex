defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.FreshnessBudget.FreshnessFields.FieldValues.ReasonFields do
  @moduledoc false

  alias __MODULE__.ReasonValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_source_report_values: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    stale_reasons = ReasonValues.stale_reasons(reports)
    unknown_reasons = ReasonValues.unknown_reasons(reports)

    %{
      "stale_reason_count" => sum_report_count(reports, &ReasonValues.stale_reason_count/1),
      "stale_reasons" => ReasonValues.sorted_or_nil(stale_reasons),
      "stale_reason_counts" => count_source_report_values(stale_reasons),
      "unknown_reason_count" => sum_report_count(reports, &ReasonValues.unknown_reason_count/1),
      "unknown_reasons" => ReasonValues.sorted_or_nil(unknown_reasons),
      "unknown_reason_counts" => count_source_report_values(unknown_reasons)
    }
  end
end
