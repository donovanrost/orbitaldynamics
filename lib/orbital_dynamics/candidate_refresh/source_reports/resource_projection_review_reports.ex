defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionReviewReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionEmbeddedReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionReviewRows

  def operator_review_package_report(path, %{} = package) do
    rows =
      package
      |> Map.get("rows", [])
      |> Enum.map(&ResourceProjectionReviewRows.stringify_keys/1)
      |> Enum.filter(&(&1["review_type"] == "resource_projection_review"))
      |> Enum.map(&ResourceProjectionReviewRows.row_from_review_or_import_row/1)
      |> Enum.reject(&is_nil/1)

    ResourceProjectionEmbeddedReports.from_rows(
      "#{path}.rows.source_resource_projection",
      "operator_review_package.rows.source_resource_projection",
      rows,
      package
    )
  end

  def cadence_import_manifest_report(path, %{} = manifest) do
    rows =
      manifest
      |> Map.get("rows", [])
      |> Enum.map(&ResourceProjectionReviewRows.stringify_keys/1)
      |> Enum.filter(fn row ->
        row["source_review_type"] == "resource_projection_review" or
          row["import_action"] == "review_resource_projection"
      end)
      |> Enum.map(&ResourceProjectionReviewRows.row_from_review_or_import_row/1)
      |> Enum.reject(&is_nil/1)

    ResourceProjectionEmbeddedReports.from_rows(
      "#{path}.rows.source_resource_projection",
      "cadence_import_manifest.rows.source_resource_projection",
      rows,
      manifest
    )
  end
end
