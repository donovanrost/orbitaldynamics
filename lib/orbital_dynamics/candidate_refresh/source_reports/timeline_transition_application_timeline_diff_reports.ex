defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationTimelineDiffReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationTimelineDiffEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationTimelineDiffReportFields

  def entries(path, value, row_builder) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      timeline_diff_report(
        entry_path,
        TimelineTransitionApplicationTimelineDiffEncoding.stringify_keys(entry_value),
        row_builder
      )
    end)
  end

  defp timeline_diff_report(path, %{} = report, row_builder) do
    rows =
      report
      |> Map.get("applications", [])
      |> Enum.map(&TimelineTransitionApplicationTimelineDiffEncoding.stringify_keys/1)
      |> Enum.map(row_builder)
      |> Enum.reject(&is_nil/1)

    TimelineTransitionApplicationTimelineDiffReportFields.report_from_embedded_rows(
      "#{path}.applications.source_timeline_diff",
      "timeline_transition_application_report.applications.source_timeline_diff",
      rows,
      report
    )
  end
end
