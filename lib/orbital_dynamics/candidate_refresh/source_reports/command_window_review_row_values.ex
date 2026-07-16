defmodule OrbitalDynamics.CandidateRefresh.SourceReports.CommandWindowReviewRowValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback
  alias OrbitalDynamics.CandidateRefresh.SourceReports.CommandWindowReviewRowEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.CommandWindowReviewRowSources

  def row_from_review_or_import_row(%{} = row) do
    row
    |> Map.drop(["source_review_row"])
    |> Map.merge(CommandWindowReviewRowSources.embedded_command_window(row))
    |> Map.put_new("activity_id", row["activity_id"] || row["subject_id"])
    |> Map.put_new("timeline_id", row["timeline_id"])
    |> Map.put_new("activity_type", row["activity_type"])
    |> Map.put_new("command_success", row["command_success"])
    |> Map.put_new("command_result", row["command_result"])
    |> Map.put_new("command_success_factor", row["command_success_factor"])
    |> Map.put_new("command_success_factor_source", row["command_success_factor_source"])
    |> Map.put_new(
      "activity_context",
      row["source_activity_context"] || row["import_activity_context"]
    )
    |> compact_map()
    |> command_window_feedback_row()
  end

  def stringify_keys(value), do: CommandWindowReviewRowEncoding.stringify_keys(value)

  defp command_window_feedback_row(%{} = command_window_row) do
    if OperationalFeedback.command_window_feedback_key(command_window_row) not in [nil, ""] do
      command_window_row
    end
  end

  defp command_window_feedback_row(_command_window_row), do: nil
end
