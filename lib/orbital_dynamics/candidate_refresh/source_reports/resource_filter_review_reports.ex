defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilterReviewReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilterReviewReportFields
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilterReviewRows

  def operator_review_package_report(path, %{} = package) do
    rows =
      package
      |> Map.get("rows", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.filter(&(&1["review_type"] == "resource_suppression"))
      |> Enum.map(&ResourceFilterReviewRows.row_from_review_or_import_row/1)
      |> Enum.reject(&is_nil/1)

    ResourceFilterReviewReportFields.report_from_embedded_rows(
      "#{path}.rows.source_resource_suppression",
      "operator_review_package.rows.source_resource_suppression",
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
        row["source_review_type"] == "resource_suppression" or
          row["import_action"] == "review_resource_suppression"
      end)
      |> Enum.map(&ResourceFilterReviewRows.row_from_review_or_import_row/1)
      |> Enum.reject(&is_nil/1)

    ResourceFilterReviewReportFields.report_from_embedded_rows(
      "#{path}.rows.source_resource_suppression",
      "cadence_import_manifest.rows.source_resource_suppression",
      rows,
      manifest
    )
  end

  defp stringify_keys(value), do: ResourceFilterReviewRows.stringify_keys(value)
end
