defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.RowFields.SourceContext do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback

  def input_keys(reports) do
    reports
    |> Enum.flat_map(&report_input_keys/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def trust_boundaries(report_or_reports) do
    OperationalFeedback.source_operational_timeline_trust_boundaries(report_or_reports)
  end

  def trust_boundary_status(reports) do
    case trust_boundaries(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp report_input_keys(report) do
    report
    |> OperationalFeedback.operational_timeline_report_feedback()
    |> OperationalFeedback.data_keys()
  end
end
