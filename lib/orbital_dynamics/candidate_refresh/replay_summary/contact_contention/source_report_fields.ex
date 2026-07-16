defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContention.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance

  alias __MODULE__.Flattened
  alias __MODULE__.Pressure
  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContention.Summary

  def source_report_summary_fields(refresh_or_artifact, source_reports) do
    branch_contention_summary = source_report_summary_branch_family(refresh_or_artifact)

    contention_summary =
      branch_contention_summary || Map.get(source_reports, "contact_contention_report", %{})

    {summary_source, replay_scope} =
      if branch_contention_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_contention_report",
          "contact_contention_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.contact_contention_report",
          "contact_contention_source_report_provenance_only"
        }
      end

    contention_summary
    |> Summary.summary(summary_source, replay_scope)
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

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "contact_contention_report",
      &InputProvenance.build/1
    )
  end
end
