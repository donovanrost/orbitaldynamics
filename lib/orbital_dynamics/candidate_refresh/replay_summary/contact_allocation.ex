defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields
  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.Summary

  def replay(refresh_or_artifact, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_allocation_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "contact_allocation_report")

    allocation_summary =
      branch_allocation_summary ||
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "contact_allocation_report"]) ||
        %{}

    {summary_source, replay_scope} =
      if branch_allocation_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_allocation_report",
          "contact_allocation_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.contact_allocation_report",
          "contact_allocation_source_report_provenance_only"
        }
      end

    summary(allocation_summary, summary_source, replay_scope)
  end

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("contact_allocation_report", %{})
      |> summary(
        "candidate_refresh.source_report_provenance.contact_allocation_report",
        "contact_allocation_source_report_provenance_only"
      )

    %{
      "source_report_contact_allocation_branch_local_contact_allocation_pressure" =>
        Map.get(summary, "branch_local_contact_allocation_pressure"),
      "source_report_contact_allocation_branch_local_blocked_allocation_pressure" =>
        Map.get(summary, "branch_local_blocked_allocation_pressure"),
      "source_report_contact_allocation_branch_local_deferred_allocation_pressure" =>
        Map.get(summary, "branch_local_deferred_allocation_pressure"),
      "source_report_contact_allocation_branch_local_station_pressure" =>
        Map.get(summary, "branch_local_station_pressure"),
      "source_report_contact_allocation_branch_local_capacity_pack_pressure" =>
        Map.get(summary, "branch_local_capacity_pack_pressure"),
      "source_report_contact_allocation_branch_local_reservation_conflict_pressure" =>
        Map.get(summary, "branch_local_reservation_conflict_pressure"),
      "source_report_contact_allocation_branch_local_station_reservation_pressure" =>
        Map.get(summary, "branch_local_station_reservation_pressure"),
      "source_report_contact_allocation_branch_local_provider_reservation_request_pressure" =>
        Map.get(summary, "branch_local_provider_reservation_request_pressure")
    }
  end

  def source_report_summary_fields(source_reports) do
    SourceReportFields.source_report_summary_fields(source_reports, &source_report_fields/1)
  end

  def source_report_identity_fields(source_reports) do
    SourceReportFields.source_report_identity_fields(source_reports)
  end

  def source_report_station_pressure_fields(source_reports) do
    SourceReportFields.source_report_station_pressure_fields(source_reports)
  end

  def source_report_capacity_pack_fields(source_reports) do
    SourceReportFields.source_report_capacity_pack_fields(source_reports)
  end

  def source_report_allocation_fields(source_reports) do
    SourceReportFields.source_report_allocation_fields(source_reports)
  end

  def source_report_station_reservation_fields(source_reports) do
    SourceReportFields.source_report_station_reservation_fields(source_reports)
  end

  def source_report_reservation_conflict_fields(source_reports) do
    SourceReportFields.source_report_reservation_conflict_fields(source_reports)
  end

  def source_report_provider_reservation_fields(source_reports) do
    SourceReportFields.source_report_provider_reservation_fields(source_reports)
  end

  def summary(allocation_summary, summary_source, replay_scope) do
    Summary.summary(allocation_summary, summary_source, replay_scope)
  end
end
