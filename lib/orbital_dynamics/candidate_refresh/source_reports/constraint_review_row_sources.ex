defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ConstraintReviewRowSources do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ConstraintEncoding

  def row_from_review_or_import_row(%{} = row) do
    embedded =
      row
      |> embedded_source_row()
      |> stringify_embedded_source_row()

    row
    |> Map.drop(["source_review_row"])
    |> Map.merge(embedded)
    |> Map.put_new("constraint_id", row["constraint_id"] || row["subject_id"] || row["id"])
    |> Map.put_new("status", row["constraint_status"] || row["status"])
    |> Map.put_new("metric", row["metric"])
    |> Map.put_new("value", row["value"])
    |> compact_map()
  end

  defp embedded_source_row(row) do
    cond do
      is_map(row["source_constraint_row"]) ->
        row["source_constraint_row"]

      is_map(get_in(row, ["source_review_row", "source_constraint_row"])) ->
        get_in(row, ["source_review_row", "source_constraint_row"])

      true ->
        %{}
    end
  end

  defp stringify_embedded_source_row(%{} = source_row) do
    ConstraintEncoding.stringify_keys(source_row)
  end

  defp stringify_embedded_source_row(_source_row), do: %{}
end
