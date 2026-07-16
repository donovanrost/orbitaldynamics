defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityState.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityState.Summary

  alias __MODULE__.Flattened
  alias __MODULE__.Pressure

  def source_report_summary_fields(source_reports) do
    source_reports
    |> Map.get("timeline_activity_state", %{})
    |> Summary.summary(
      "candidate_refresh.source_report_provenance.timeline_activity_state",
      "timeline_activity_state_source_report_provenance_only"
    )
    |> then(&source_report_fields(source_reports, &1))
  end

  def source_report_fields(source_reports, summary) do
    source_reports
    |> Flattened.source_report_fields()
    |> Map.merge(Pressure.source_report_fields(summary))
    |> compact_map()
  end

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
