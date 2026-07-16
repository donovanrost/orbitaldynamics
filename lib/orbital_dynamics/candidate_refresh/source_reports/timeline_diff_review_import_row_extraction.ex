defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportRowExtraction do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportRowSources

  def row_from_review_or_import_row(%{} = row) do
    source_application =
      TimelineDiffReviewImportRowSources.source_application_from_review_or_import_row(row)

    embedded = TimelineDiffReviewImportRowSources.embedded_timeline_diff(row, source_application)

    row
    |> Map.drop([
      "source_review_row",
      "source_timeline_application",
      "source_timeline_transition_application"
    ])
    |> Map.merge(embedded)
    |> Map.merge(Map.drop(source_application, ["source_timeline_diff"]))
    |> maybe_put_source_timeline_application(source_application)
    |> put_row_defaults(row)
    |> compact_map()
    |> require_diff_status()
  end

  defp maybe_put_source_timeline_application(row, application) when map_size(application) == 0,
    do: row

  defp maybe_put_source_timeline_application(row, application),
    do: Map.put(row, "source_timeline_application", application)

  defp put_row_defaults(row, source_row) do
    row
    |> Map.put_new("diff_status", source_row["diff_status"])
    |> Map.put_new("timeline_id", source_row["timeline_id"])
    |> Map.put_new("source_activity_id", source_row["source_activity_id"])
    |> Map.put_new("replacement_activity_id", source_row["replacement_activity_id"])
    |> Map.put_new("source_activity_type", source_row["source_activity_type"])
    |> Map.put_new("replacement_activity_type", source_row["replacement_activity_type"])
    |> Map.put_new("source_activity_context", source_row["source_activity_context"])
    |> Map.put_new("replacement_activity_context", source_row["replacement_activity_context"])
  end

  defp require_diff_status(%{} = diff_row) do
    if is_binary(Map.get(diff_row, "diff_status")), do: diff_row
  end

  defp require_diff_status(_diff_row), do: nil
end
