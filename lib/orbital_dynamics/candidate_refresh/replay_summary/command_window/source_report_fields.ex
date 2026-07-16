defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.CommandWindow.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.CommandWindow.Summary
  alias __MODULE__.Flattened
  alias __MODULE__.Pressure

  def source_report_fields(source_reports) do
    source_reports
    |> Map.get("command_window_report", %{})
    |> Summary.summary(
      "candidate_refresh.source_report_provenance.command_window_report",
      "command_window_source_report_provenance_only"
    )
    |> then(&source_report_fields(source_reports, &1))
  end

  def source_report_fields(source_reports, summary) do
    summary
    |> Pressure.source_report_fields()
    |> Map.merge(Flattened.source_report_fields(source_reports))
  end
end
