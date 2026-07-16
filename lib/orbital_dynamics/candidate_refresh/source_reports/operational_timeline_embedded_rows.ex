defmodule OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineEmbeddedRows do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback
  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineEmbeddedRowSource

  def row_from_review_or_import_row(%{} = row) do
    embedded = OperationalTimelineEmbeddedRowSource.source_row(row)

    row
    |> Map.drop(["source_review_row"])
    |> Map.merge(embedded)
    |> Map.put_new("activity_id", row["activity_id"] || row["subject_id"])
    |> Map.put_new("timeline_id", row["timeline_id"] || row["subject_id"])
    |> Map.put_new("activity_type", row["activity_type"])
    |> Map.put_new("operational_kind", row["operational_kind"])
    |> Map.put_new("direction", row["direction"])
    |> Map.put_new("ground_station_id", row["ground_station_id"])
    |> Map.put_new("target_id", row["target_id"])
    |> Map.put_new("contact_success_factor", row["contact_success_factor"])
    |> Map.put_new("command_success_factor", row["command_success_factor"])
    |> Map.put_new("maneuver_success_factor", row["maneuver_success_factor"])
    |> Map.put_new("observation_success_factor", row["observation_success_factor"])
    |> Map.put_new("throughput_completion_fraction", row["throughput_completion_fraction"])
    |> Map.put_new(
      "activity_context",
      row["source_activity_context"] || row["import_activity_context"]
    )
    |> compact_map()
    |> case do
      timeline_row when is_map(timeline_row) ->
        if OperationalFeedback.operational_timeline_feedback_key(timeline_row) not in [nil, ""] do
          timeline_row
        end

      _timeline_row ->
        nil
    end
  end
end
