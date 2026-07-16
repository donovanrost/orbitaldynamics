defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveCollectionDirectSources do
  @moduledoc false

  def sources(refresh, report_name) do
    source_report_name = "source_#{report_name}"

    [
      {"accepted_planning_state.#{source_report_name}",
       get_in(refresh, ["accepted_planning_state", source_report_name])},
      {"accepted_planning_state.#{report_name}",
       get_in(refresh, ["accepted_planning_state", report_name])},
      {"mission_state.#{source_report_name}",
       get_in(refresh, ["mission_state", source_report_name])},
      {"mission_state.#{report_name}", get_in(refresh, ["mission_state", report_name])},
      {source_report_name, Map.get(refresh, source_report_name)},
      {report_name, Map.get(refresh, report_name)}
    ]
  end
end
