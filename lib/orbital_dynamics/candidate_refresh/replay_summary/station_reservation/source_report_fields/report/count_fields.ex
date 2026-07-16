defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.CountFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows,
    only: [
      evidence_row?: 1,
      expiration_evidence_row?: 1,
      non_empty?: 1,
      numeric_report_count: 2,
      report_count: 1,
      report_rows: 1,
      single_value_count: 1,
      stringify_keys: 1
    ]

  def row_count(report),
    do: affected_contact_count(report) + provider_calendar_contention_group_count(report)

  def affected_contact_count(report), do: length(Map.get(report, "affected_contacts", []))

  def provider_calendar_contention_group_count(report),
    do: length(Map.get(report, "provider_calendar_contention_groups", []))

  def review_count(report) do
    report
    |> report_rows()
    |> Enum.count(fn row ->
      row = stringify_keys(row)

      non_empty?(row["required_operator_action"]) or
        non_empty?(row["station_reservation_match_status"]) or
        non_empty?(row["provider_calendar_contention_status"])
    end)
  end

  def optional_count_sum(reports, field) do
    if Enum.any?(reports, &Map.has_key?(&1, field)) do
      reports
      |> Enum.map(&numeric_report_count(&1, field))
      |> Enum.sum()
      |> report_count()
    end
  end

  def import_readiness_status_counts(report) do
    report
    |> Map.get("import_readiness_status")
    |> single_value_count()
  end

  def import_classification_counts(report) do
    report
    |> Map.get("import_classification")
    |> single_value_count()
  end

  def evidence_count(report) do
    report
    |> report_rows()
    |> Enum.count(&evidence_row?/1)
  end

  def expiration_evidence_count(report) do
    report
    |> report_rows()
    |> Enum.count(&expiration_evidence_row?/1)
  end
end
