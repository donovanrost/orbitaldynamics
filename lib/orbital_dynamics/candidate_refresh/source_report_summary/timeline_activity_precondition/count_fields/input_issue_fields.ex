defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.CountFields.InputIssueFields do
  @moduledoc false

  alias __MODULE__.AllowOverlapInputs
  alias __MODULE__.InvalidActivityInputs

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      sum_report_count: 2
    ]

  def fields(summaries) do
    %{
      "invalid_activity_input_count" =>
        sum_report_count(summaries, &InvalidActivityInputs.count/1),
      "invalid_activity_input_reasons" => InvalidActivityInputs.reasons(summaries),
      "invalid_activity_input_reason_counts" =>
        count_map(summaries, &InvalidActivityInputs.reason_counts/1),
      "allow_overlap_counts" => count_map(summaries, &AllowOverlapInputs.counts/1)
    }
  end

  defp count_map(summaries, extractor) do
    summaries
    |> Enum.map(extractor)
    |> merge_count_maps()
  end
end
