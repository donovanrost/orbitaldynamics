defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ManeuverReview do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ManeuverReviewPackageRows
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ManeuverReviewRowReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ManeuverReviewValues

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      report = ManeuverReviewValues.stringify_keys(entry_value)

      if report?(report) do
        {entry_path, report}
      end
    end)
  end

  def operator_review_entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      operator_review_package_report(entry_path, ManeuverReviewValues.stringify_keys(entry_value))
    end)
  end

  def cadence_import_entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      cadence_import_manifest_report(entry_path, ManeuverReviewValues.stringify_keys(entry_value))
    end)
  end

  def report?(report), do: ManeuverReviewValues.report?(report)

  defp operator_review_package_report(path, %{} = package) do
    ManeuverReviewRowReports.from_rows(
      "#{path}.rows.source_maneuver_review",
      "operator_review_package.rows.source_maneuver_review",
      ManeuverReviewPackageRows.operator_review_rows(package),
      package
    )
  end

  defp cadence_import_manifest_report(path, %{} = manifest) do
    ManeuverReviewRowReports.from_rows(
      "#{path}.rows.source_maneuver_review",
      "cadence_import_manifest.rows.source_maneuver_review",
      ManeuverReviewPackageRows.cadence_import_rows(manifest),
      manifest
    )
  end
end
