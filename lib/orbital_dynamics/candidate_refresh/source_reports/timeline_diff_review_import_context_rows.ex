defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportContextRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportRows

  def operator_review_rows(%{} = package) do
    package
    |> Map.get("rows", [])
    |> rows_from(&operator_review_row?/1)
  end

  def cadence_import_rows(%{} = manifest) do
    manifest
    |> Map.get("rows", [])
    |> rows_from(&cadence_import_row?/1)
  end

  defp rows_from(rows, predicate) do
    rows
    |> Enum.map(&TimelineDiffReviewImportRows.stringify_keys/1)
    |> Enum.filter(predicate)
    |> Enum.map(&TimelineDiffReviewImportRows.row_from_review_or_import_row/1)
    |> Enum.reject(&is_nil/1)
  end

  defp operator_review_row?(row), do: row["review_type"] == "timeline_diff_review"

  defp cadence_import_row?(row) do
    row["source_review_type"] == "timeline_diff_review" or
      row["import_action"] == "review_timeline_diff"
  end
end
