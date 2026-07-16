defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ActivityIds do
  @moduledoc false

  alias __MODULE__.{Paths, RowValues}

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [source_rows: 1]

  def source_counts(report) do
    counts(report, "source_activity_id_counts", Paths.source())
  end

  def replacement_counts(report) do
    counts(
      report,
      "replacement_activity_id_counts",
      Paths.replacement()
    )
  end

  defp counts(report, fallback_field, paths) do
    counts_from_rows_or_fallback(report, fallback_field, fn rows ->
      RowValues.counts(rows, paths)
    end)
  end

  defp counts_from_rows_or_fallback(report, fallback_field, row_fun) do
    case source_rows(report) do
      [] -> Map.get(report, fallback_field)
      rows -> row_fun.(rows)
    end
  end
end
