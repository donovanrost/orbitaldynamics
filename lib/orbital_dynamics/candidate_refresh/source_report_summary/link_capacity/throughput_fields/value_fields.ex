defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.ThroughputFields.ValueFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Throughput.Report,
    as: ThroughputReport

  alias __MODULE__.GroundStationFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sum_report_numeric_values: 2]

  def fields(reports) do
    %{
      "capacity_adjusted_throughput_mb_total" =>
        numeric_total_sum(reports, "capacity_adjusted_throughput_mb"),
      "selected_capacity_adjusted_throughput_mb_total" =>
        numeric_total_sum(reports, "selected_capacity_adjusted_throughput_mb"),
      "unused_capacity_adjusted_throughput_mb_total" =>
        numeric_total_sum(reports, "unused_capacity_adjusted_throughput_mb")
    }
    |> Map.merge(GroundStationFields.fields(reports))
  end

  defp numeric_total_sum(reports, field) do
    sum_report_numeric_values(reports, &ThroughputReport.numeric_total(&1, field))
  end
end
