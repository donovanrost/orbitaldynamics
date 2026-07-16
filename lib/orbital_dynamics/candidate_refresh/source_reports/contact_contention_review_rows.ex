defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionReviewReportFields
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionReviewRowSources

  def operator_review_package_report(path, %{} = package) do
    rows =
      package
      |> Map.get("rows", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.filter(&(&1["review_type"] == "contact_contention_review"))
      |> Enum.map(&ContactContentionReviewRowSources.row_from_review_or_import_row/1)
      |> Enum.reject(&is_nil/1)

    ContactContentionReviewReportFields.report_from_embedded_rows(
      "#{path}.rows.source_contact_contention",
      "operator_review_package.rows.source_contact_contention",
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
        row["source_review_type"] == "contact_contention_review" or
          row["import_action"] == "review_contact_contention"
      end)
      |> Enum.map(&ContactContentionReviewRowSources.row_from_review_or_import_row/1)
      |> Enum.reject(&is_nil/1)

    ContactContentionReviewReportFields.report_from_embedded_rows(
      "#{path}.rows.source_contact_contention",
      "cadence_import_manifest.rows.source_contact_contention",
      rows,
      manifest
    )
  end

  def stringify_keys(value), do: ContactContentionEncoding.stringify_keys(value)
end
