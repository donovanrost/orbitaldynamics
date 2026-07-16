defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.Report.StatusFields.StatusContactFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.Report.Rows

  import Common, only: [numeric_report_count: 2]

  import Rows,
    only: [
      contact_ids_by_status: 3,
      contact_ids_by_status_and_station: 3,
      effective_status: 1,
      rows_for_summary: 1
    ]

  def allocated_contact_ids(report) do
    contact_ids_by_status(report, "allocated_contact_ids", [
      {"allocation_status", "allocated"}
    ])
  end

  def allocated_contact_count(report) do
    case rows_for_summary(report) do
      [] -> numeric_report_count(report, "allocated_contact_count")
      rows -> Enum.count(rows, &(&1["allocation_status"] == "allocated"))
    end
  end

  def allocated_contact_ids_by_station(report) do
    contact_ids_by_status_and_station(
      report,
      ["allocated_contact_ids_by_ground_station_id", "allocated_contact_ids_by_ground_station"],
      [{"allocation_status", "allocated"}]
    )
  end

  def returned_allocated_contact_ids(report) do
    contact_ids_by_status(report, "returned_allocated_contact_ids", [
      {"effective_allocation_status", "allocated"}
    ])
  end

  def returned_allocated_contact_count(report) do
    case rows_for_summary(report) do
      [] -> numeric_report_count(report, "returned_allocated_contact_count")
      rows -> Enum.count(rows, &(effective_status(&1) == "allocated"))
    end
  end

  def returned_allocated_contact_ids_by_station(report) do
    contact_ids_by_status_and_station(
      report,
      [
        "returned_allocated_contact_ids_by_ground_station_id",
        "returned_allocated_contact_ids_by_ground_station"
      ],
      [{"effective_allocation_status", "allocated"}]
    )
  end

  def deferred_contact_ids(report) do
    contact_ids_by_status(report, "deferred_contact_ids", [
      {"allocation_status", "deferred"}
    ])
  end

  def deferred_contact_count(report) do
    case rows_for_summary(report) do
      [] -> numeric_report_count(report, "deferred_contact_count")
      rows -> Enum.count(rows, &(&1["allocation_status"] == "deferred"))
    end
  end

  def deferred_contact_ids_by_station(report) do
    contact_ids_by_status_and_station(
      report,
      ["deferred_contact_ids_by_ground_station_id", "deferred_contact_ids_by_ground_station"],
      [{"allocation_status", "deferred"}]
    )
  end

  def blocked_contact_ids(report) do
    contact_ids_by_status(report, "blocked_contact_ids", [
      {"allocation_status", "blocked"}
    ])
  end

  def blocked_contact_count(report) do
    case rows_for_summary(report) do
      [] -> numeric_report_count(report, "blocked_contact_count")
      rows -> Enum.count(rows, &(&1["allocation_status"] == "blocked"))
    end
  end

  def blocked_contact_ids_by_station(report) do
    contact_ids_by_status_and_station(
      report,
      ["blocked_contact_ids_by_ground_station_id", "blocked_contact_ids_by_ground_station"],
      [{"allocation_status", "blocked"}]
    )
  end

  def policy_blocked_contact_ids(report) do
    contact_ids_by_status(report, "policy_blocked_contact_ids", [
      {"effective_allocation_status", "policy_blocked"},
      {"effective_allocation_status", "blocked_by_policy"}
    ])
  end

  def policy_blocked_allocated_contact_count(report) do
    case rows_for_summary(report) do
      [] ->
        numeric_report_count(report, "policy_blocked_allocated_contact_count")

      rows ->
        Enum.count(rows, &(effective_status(&1) in ["policy_blocked", "blocked_by_policy"]))
    end
  end

  def policy_blocked_contact_ids_by_station(report) do
    contact_ids_by_status_and_station(
      report,
      [
        "policy_blocked_contact_ids_by_ground_station_id",
        "policy_blocked_contact_ids_by_ground_station"
      ],
      [
        {"effective_allocation_status", "policy_blocked"},
        {"effective_allocation_status", "blocked_by_policy"}
      ]
    )
  end
end
