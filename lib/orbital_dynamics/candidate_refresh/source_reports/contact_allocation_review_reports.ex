defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactAllocationReviewReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactAllocationReviewReportFields
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactAllocationReviewRows
  alias OrbitalDynamics.CandidateRefresh.SourceReports.EmbeddedRowFallbacks

  def operator_review_package_report(path, %{} = package) do
    rows =
      package
      |> Map.get("rows", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.filter(&(&1["review_type"] == "contact_allocation_review"))
      |> Enum.map(&ContactAllocationReviewRows.row_from_review_or_import_row/1)
      |> Enum.reject(&is_nil/1)

    report_from_embedded_rows(
      "#{path}.rows.source_contact_allocation",
      "operator_review_package.rows.source_contact_allocation",
      rows,
      package
    )
  end

  def cadence_import_manifest_report(path, %{} = manifest) do
    rows =
      manifest
      |> Map.get("rows", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.filter(fn row ->
        row["source_review_type"] == "contact_allocation_review" or
          row["import_action"] == "review_contact_allocation"
      end)
      |> Enum.map(&ContactAllocationReviewRows.row_from_review_or_import_row/1)
      |> Enum.reject(&is_nil/1)

    report_from_embedded_rows(
      "#{path}.rows.source_contact_allocation",
      "cadence_import_manifest.rows.source_contact_allocation",
      rows,
      manifest
    )
  end

  def report_from_embedded_rows(path, source, rows, artifact) do
    EmbeddedRowFallbacks.report_from_embedded_rows(
      path,
      source,
      rows,
      artifact,
      &ContactAllocationReviewReportFields.from_embedded_rows/4
    )
  end

  defp stringify_keys(value), do: ContactAllocationReviewRows.stringify_keys(value)
end
