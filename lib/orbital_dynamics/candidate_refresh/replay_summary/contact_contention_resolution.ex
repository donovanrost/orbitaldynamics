defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields
  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.Summary

  def replay(refresh_or_artifact, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_resolution_summary =
      source_report_summary_branch_family.(
        refresh_or_artifact,
        "contact_contention_resolution_report"
      )

    resolution_summary =
      branch_resolution_summary ||
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "contact_contention_resolution_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_resolution_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_contention_resolution_report",
          "contact_contention_resolution_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.contact_contention_resolution_report",
          "contact_contention_resolution_source_report_provenance_only"
        }
      end

    summary(resolution_summary, summary_source, replay_scope)
  end

  def source_report_fields(refresh_or_artifact, source_reports, callbacks) do
    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_resolution_summary =
      source_report_summary_branch_family.(
        refresh_or_artifact,
        "contact_contention_resolution_report"
      )

    resolution_summary =
      branch_resolution_summary ||
        Map.get(source_reports, "contact_contention_resolution_report", %{})

    {summary_source, replay_scope} =
      if branch_resolution_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_contention_resolution_report",
          "contact_contention_resolution_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.contact_contention_resolution_report",
          "contact_contention_resolution_source_report_provenance_only"
        }
      end

    summary = summary(resolution_summary, summary_source, replay_scope)

    source_reports
    |> SourceReportFields.source_report_fields()
    |> Map.merge(%{
      "source_report_contact_contention_resolution_branch_local_contact_contention_resolution_pressure" =>
        Map.get(summary, "branch_local_contact_contention_resolution_pressure"),
      "source_report_contact_contention_resolution_branch_local_deferred_contact_pressure" =>
        Map.get(summary, "branch_local_deferred_contact_pressure"),
      "source_report_contact_contention_resolution_branch_local_capacity_pack_pressure" =>
        Map.get(summary, "branch_local_capacity_pack_pressure"),
      "source_report_contact_contention_resolution_branch_local_action_pressure" =>
        Map.get(summary, "branch_local_contact_contention_resolution_action_pressure")
    })
    |> compact_map()
  end

  def summary(resolution_summary, summary_source, replay_scope) do
    Summary.summary(resolution_summary, summary_source, replay_scope)
  end

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
