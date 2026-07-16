defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilterReviewRows do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.{
    ResourceFilterReviewRowEncoding,
    ResourceFilterReviewRowSources
  }

  def split_embedded_rows(rows) do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.reduce({[], []}, fn row, {suppressed, invalid_summaries} ->
      if invalid_summary_row?(row) do
        {suppressed, [row | invalid_summaries]}
      else
        {[row | suppressed], invalid_summaries}
      end
    end)
    |> then(fn {suppressed, invalid_summaries} ->
      {Enum.reverse(suppressed), Enum.reverse(invalid_summaries)}
    end)
  end

  def row_from_review_or_import_row(%{} = row) do
    embedded = ResourceFilterReviewRowSources.embedded_suppression(row)

    row
    |> Map.drop(["source_review_row"])
    |> Map.merge(embedded)
    |> Map.put_new("id", row["activity_id"] || row["subject_id"] || row["id"])
    |> Map.put_new("spacecraft_id", row["spacecraft_id"])
    |> Map.put_new("suppressed_reason", row["suppressed_reason"] || row["reason"])
    |> compact_map()
  end

  def row_from_review_or_import_row(_row), do: nil

  def invalid_summary_row?(row) do
    row["invalid_resource_summary_input"] == true or
      row["required_operator_action"] == "review_invalid_resource_filter_summary" or
      row["action"] == "review_invalid_resource_filter_summary"
  end

  def normalized_source_report_token(value) do
    ResourceFilterReviewRowEncoding.normalized_source_report_token(value)
  end

  def stringify_keys(value), do: ResourceFilterReviewRowEncoding.stringify_keys(value)
end
