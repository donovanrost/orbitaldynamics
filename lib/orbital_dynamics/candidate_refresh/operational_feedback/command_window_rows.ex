defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.CommandWindowRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.RowValues

  def command_window_report_feedback(%{} = report) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&RowValues.stringify_keys/1)
    |> Enum.reduce(%{}, fn row, feedback ->
      if command_window_feedback_row?(row) do
        merge_command_window_feedback(row, feedback)
      else
        feedback
      end
    end)
    |> RowValues.compact_nonempty()
  end

  def command_window_report_feedback(_report), do: %{}

  def command_window_feedback_row?(%{} = row) do
    command_window_feedback_key(row) not in [nil, ""] and
      is_number(command_window_success_factor(row))
  end

  def command_window_feedback_key(row) do
    RowValues.stable_id_or_nil(
      row["activity_id"] ||
        row["command_window_id"] ||
        get_in(row, ["activity_context", "activity_id"]) ||
        get_in(row, ["source_activity_context", "activity_id"]) ||
        get_in(row, ["activity_context", "command_window_id"]) ||
        get_in(row, ["source_activity_context", "command_window_id"]) ||
        row["id"] ||
        row["timeline_id"]
    )
  end

  def command_window_success_factor(row) do
    case RowValues.first_number(row, [
           "command_success_factor",
           ["activity_context", "command_success_factor"],
           ["source_activity_context", "command_success_factor"],
           ["import_activity_context", "command_success_factor"]
         ]) do
      factor when is_number(factor) -> RowValues.unit_interval(factor)
      _factor -> command_window_result_factor(row)
    end
  end

  def merge_command_window_feedback(row, feedback) do
    command_key = command_window_feedback_key(row)
    factor = command_window_success_factor(row)

    update_in(feedback, ["command_success_rate"], fn values ->
      values
      |> RowValues.ensure_map()
      |> Map.update(command_key, factor, &min(&1, factor))
    end)
  end

  defp command_window_result_factor(row) do
    cond do
      false in [
        row["command_success"],
        get_in(row, ["activity_context", "command_success"]),
        get_in(row, ["source_activity_context", "command_success"]),
        get_in(row, ["import_activity_context", "command_success"])
      ] ->
        0.0

      RowValues.failure_token?(
        row["command_result"] ||
          get_in(row, ["activity_context", "command_result"]) ||
          get_in(row, ["source_activity_context", "command_result"]) ||
            get_in(row, ["import_activity_context", "command_result"])
      ) ->
        0.0

      true ->
        nil
    end
  end
end
