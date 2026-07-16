defmodule OrbitalDynamics.CandidateRefresh.SourceReports.FreshnessBudgetDirectReports do
  @moduledoc false

  def reports(refresh, source_module, report_key) do
    [
      {"accepted_planning_state.source_#{report_key}",
       get_in(refresh, ["accepted_planning_state", "source_#{report_key}"])},
      {"accepted_planning_state.#{report_key}",
       get_in(refresh, ["accepted_planning_state", report_key])},
      {"mission_state.source_#{report_key}",
       get_in(refresh, ["mission_state", "source_#{report_key}"])},
      {"mission_state.#{report_key}", get_in(refresh, ["mission_state", report_key])},
      {"source_#{report_key}", Map.get(refresh, "source_#{report_key}")},
      {report_key, Map.get(refresh, report_key)}
    ]
    |> Enum.flat_map(fn {path, report_or_reports} ->
      source_module.entries(path, report_or_reports)
    end)
  end
end
