defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactAllocationReviewRows do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactAllocationReviewRowEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactAllocationReviewRowSources

  def row_from_review_or_import_row(%{} = row) do
    row
    |> Map.drop(["source_review_row"])
    |> Map.merge(ContactAllocationReviewRowSources.embedded_allocation(row))
    |> Map.put_new("contact_id", row["contact_id"] || row["activity_id"] || row["subject_id"])
    |> Map.put_new("type", row["activity_type"])
    |> Map.put_new("allocation_status", row["allocation_status"])
    |> Map.put_new("effective_allocation_status", row["effective_allocation_status"])
    |> Map.put_new("review_status", row["review_status"])
    |> Map.put_new("approval_status", row["approval_status"])
    |> compact_map()
  end

  def stringify_keys(value), do: ContactAllocationReviewRowEncoding.stringify_keys(value)

  def count_contact_allocation_rows(rows, field) do
    rows
    |> Enum.map(&normalized_source_report_token(Map.get(&1, field)))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end

  defp normalized_source_report_token(value) do
    value
    |> ContactAllocationReviewRowEncoding.encode_value()
    |> case do
      nil ->
        nil

      value ->
        value
        |> String.trim()
        |> String.downcase()
        |> String.replace(~r/[\s-]+/, "_")
        |> String.trim("_")
    end
  end
end
