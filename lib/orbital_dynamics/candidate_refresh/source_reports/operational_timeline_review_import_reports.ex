defmodule OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineReviewImportReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineRowReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineReviewRows

  def operator_review_package_report(path, %{} = package) do
    rows =
      package
      |> Map.get("rows", [])
      |> OperationalTimelineReviewRows.operator_review_rows()

    OperationalTimelineRowReports.from_rows(
      "#{path}.rows.source_operational_timeline",
      "operator_review_package.rows.source_operational_timeline",
      rows,
      package
    )
  end

  def cadence_import_manifest_report(path, %{} = manifest) do
    rows =
      manifest
      |> Map.get("rows", [])
      |> OperationalTimelineReviewRows.cadence_import_rows()

    OperationalTimelineRowReports.from_rows(
      "#{path}.rows.source_operational_timeline",
      "cadence_import_manifest.rows.source_operational_timeline",
      rows,
      manifest
    )
  end
end
