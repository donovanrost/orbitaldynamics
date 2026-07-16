defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportPreconditionSummaryFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportPreconditionRows

  def fields(rows) do
    preconditions =
      rows
      |> Enum.flat_map(&(Map.get(&1, "preconditions") || []))
      |> Enum.filter(&is_map/1)

    precondition_rows =
      TimelineActivityPreconditionReviewImportPreconditionRows.from_preconditions(preconditions)

    %{
      "precondition_status" =>
        TimelineActivityPreconditionReviewImportPreconditionRows.status(
          rows,
          precondition_rows
        ),
      "blocked_precondition_count" => embedded_rows_count(rows, precondition_rows, "blocked"),
      "review_precondition_count" =>
        embedded_rows_count(rows, precondition_rows, "review_required"),
      "blocked_precondition_types" => embedded_rows_types(rows, precondition_rows, "blocked"),
      "review_precondition_types" =>
        embedded_rows_types(rows, precondition_rows, "review_required"),
      "preconditions" => preconditions
    }
  end

  defp embedded_rows_count(rows, precondition_rows, status) do
    TimelineActivityPreconditionReviewImportPreconditionRows.count(
      rows,
      precondition_rows,
      status
    )
  end

  defp embedded_rows_types(rows, precondition_rows, status) do
    TimelineActivityPreconditionReviewImportPreconditionRows.types(
      rows,
      precondition_rows,
      status
    )
  end
end
