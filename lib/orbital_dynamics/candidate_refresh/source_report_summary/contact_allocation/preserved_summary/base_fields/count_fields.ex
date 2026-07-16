defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.BaseFields.CountFields do
  @moduledoc false

  alias __MODULE__.StatusMaps

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2
    ]

  def fields(summary, rows, review_rows) do
    %{
      "row_count" => summary_count(summary, "input_contact_count", length(rows)),
      "review_row_count" => summary_count(summary, "review_row_count", length(review_rows)),
      "allocated_contact_count" => numeric_report_count(summary, "allocated_contact_count"),
      "returned_allocated_contact_count" =>
        numeric_report_count(summary, "returned_allocated_contact_count"),
      "policy_blocked_allocated_contact_count" =>
        numeric_report_count(summary, "policy_blocked_allocated_contact_count"),
      "deferred_contact_count" => numeric_report_count(summary, "deferred_contact_count"),
      "blocked_contact_count" => numeric_report_count(summary, "blocked_contact_count"),
      "invalid_contact_input_count" =>
        numeric_report_count(summary, "invalid_contact_input_count"),
      "status_blocked_contact_count" =>
        numeric_report_count(summary, "status_blocked_contact_count"),
      "resource_blocked_contact_count" =>
        numeric_report_count(summary, "resource_blocked_contact_count"),
      "duplicate_contact_id_count" => numeric_report_count(summary, "duplicate_contact_id_count")
    }
    |> Map.merge(StatusMaps.fields(summary))
  end

  defp summary_count(summary, field, fallback_count) do
    case numeric_report_count(summary, field) do
      0 -> fallback_count
      count -> count
    end
  end
end
