defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportEmbeddedPaths do
  @moduledoc false

  def operator_review(path, rows) do
    {
      embedded_path(
        rows,
        "#{path}.rows.source_timeline_diff",
        "#{path}.rows.source_timeline_application"
      ),
      embedded_path(
        rows,
        "operator_review_package.rows.source_timeline_diff",
        "operator_review_package.rows.source_timeline_application"
      )
    }
  end

  def cadence_import(path, rows) do
    {
      embedded_path(
        rows,
        "#{path}.rows.source_timeline_diff",
        "#{path}.rows.source_review_row.source_timeline_application"
      ),
      embedded_path(
        rows,
        "cadence_import_manifest.rows.source_timeline_diff",
        "cadence_import_manifest.rows.source_review_row.source_timeline_application"
      )
    }
  end

  defp embedded_path(rows, default_path, application_path) do
    if Enum.any?(rows, &Map.has_key?(&1, "source_timeline_application")) do
      application_path
    else
      default_path
    end
  end
end
