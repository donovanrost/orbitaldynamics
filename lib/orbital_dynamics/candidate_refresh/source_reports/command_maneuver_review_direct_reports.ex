defmodule OrbitalDynamics.CandidateRefresh.SourceReports.CommandManeuverReviewDirectReports do
  @moduledoc false

  def reports(refresh, source_module, source_key, report_key) do
    [
      {"accepted_planning_state.#{source_key}",
       get_in(refresh, ["accepted_planning_state", source_key])},
      {"accepted_planning_state.#{report_key}",
       get_in(refresh, ["accepted_planning_state", report_key])},
      {"mission_state.#{source_key}", get_in(refresh, ["mission_state", source_key])},
      {"mission_state.#{report_key}", get_in(refresh, ["mission_state", report_key])},
      {source_key, Map.get(refresh, source_key)},
      {report_key, Map.get(refresh, report_key)}
    ]
    |> Enum.flat_map(fn {path, report_or_reports} ->
      apply(source_module, :entries, [path, report_or_reports])
    end)
  end
end
