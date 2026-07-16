defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.CommandWindow.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(summary) do
    %{
      "source_report_command_window_branch_local_command_window_pressure" =>
        Map.get(summary, "branch_local_command_window_pressure"),
      "source_report_command_window_branch_local_command_feedback_pressure" =>
        Map.get(summary, "branch_local_command_feedback_pressure"),
      "source_report_command_window_branch_local_command_window_action_pressure" =>
        Map.get(summary, "branch_local_command_window_action_pressure")
    }
  end
end
