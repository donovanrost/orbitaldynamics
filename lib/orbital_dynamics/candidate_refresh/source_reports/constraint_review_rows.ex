defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ConstraintReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ConstraintEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ConstraintReviewReportFields
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ConstraintReviewRowSources

  def operator_review_package_report(path, %{} = package) do
    rows =
      package
      |> Map.get("rows", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.filter(&(&1["review_type"] == "constraint_review"))
      |> Enum.map(&ConstraintReviewRowSources.row_from_review_or_import_row/1)
      |> Enum.reject(&is_nil/1)

    ConstraintReviewReportFields.report_from_embedded_rows(
      "#{path}.rows.source_constraint_row",
      "operator_review_package.rows.source_constraint_row",
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
        row["source_review_type"] == "constraint_review" or
          row["import_action"] == "review_constraint"
      end)
      |> Enum.map(&ConstraintReviewRowSources.row_from_review_or_import_row/1)
      |> Enum.reject(&is_nil/1)

    ConstraintReviewReportFields.report_from_embedded_rows(
      "#{path}.rows.source_constraint_row",
      "cadence_import_manifest.rows.source_constraint_row",
      rows,
      manifest
    )
  end

  def stringify_keys(value), do: ConstraintEncoding.stringify_keys(value)
end
