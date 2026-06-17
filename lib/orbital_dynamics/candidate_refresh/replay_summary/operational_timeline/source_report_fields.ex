defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.OperationalTimeline.SourceReportFields do
  @moduledoc false

  alias __MODULE__.Flattened

  def source_report_fields(source_reports, summary) do
    %{
      "source_report_operational_timeline_branch_local_operational_timeline_pressure" =>
        Map.get(summary, "branch_local_operational_timeline_pressure"),
      "source_report_operational_timeline_branch_local_feedback_pressure" =>
        Map.get(summary, "branch_local_feedback_pressure"),
      "source_report_operational_timeline_branch_local_activity_routing_pressure" =>
        Map.get(summary, "branch_local_activity_routing_pressure"),
      "source_report_operational_timeline_branch_local_integrity_pressure" =>
        Map.get(summary, "branch_local_integrity_pressure"),
      "source_report_operational_timeline_branch_local_station_reservation_pressure" =>
        Map.get(summary, "branch_local_station_reservation_pressure")
    }
    |> Map.merge(Flattened.fields(source_reports))
  end
end
