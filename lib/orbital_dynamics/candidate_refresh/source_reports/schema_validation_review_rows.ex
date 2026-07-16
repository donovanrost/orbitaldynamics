defmodule OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationReportValues
  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationReviewEmbeddedReports

  def operator_review_package_report(path, %{} = package) do
    rows =
      package
      |> Map.get("rows", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.filter(&(&1["review_type"] == "schema_validation_review"))

    report_from_rows(
      "#{path}.rows.source_schema_validation_report",
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
        row["source_review_type"] == "schema_validation_review" or
          row["import_action"] == "review_schema_validation"
      end)

    report_from_rows(
      "#{path}.rows.source_schema_validation_report",
      rows,
      manifest
    )
  end

  defp report_from_rows(path, rows, artifact) do
    SchemaValidationReviewEmbeddedReports.from_rows(path, rows, artifact)
  end

  defp stringify_keys(value), do: SchemaValidationReportValues.stringify_keys(value)
end
