defmodule OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineRowReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineValues

  def operator_review_rows(rows) do
    rows
    |> rows_from(&operator_review_row?/1)
  end

  def cadence_import_rows(rows) do
    rows
    |> rows_from(&cadence_import_row?/1)
  end

  defp rows_from(rows, row?) do
    rows
    |> Enum.map(&OperationalTimelineValues.stringify_keys/1)
    |> Enum.filter(row?)
    |> Enum.map(&OperationalTimelineRowReports.row_from_review_or_import_row/1)
    |> Enum.reject(&is_nil/1)
  end

  defp operator_review_row?(row) do
    row["review_type"] == "operational_timeline_review"
  end

  defp cadence_import_row?(row) do
    row["source_review_type"] == "operational_timeline_review" or
      row["import_action"] == "review_operational_timeline"
  end
end
