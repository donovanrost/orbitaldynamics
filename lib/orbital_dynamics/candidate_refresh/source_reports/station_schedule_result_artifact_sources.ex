defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationScheduleResultArtifactSources do
  @moduledoc false

  def station_calendar_sources(path, artifact) do
    [
      {"#{path}", artifact},
      {"#{path}.source_station_calendar_report",
       Map.get(artifact, "source_station_calendar_report")},
      {"#{path}.station_calendar_report", Map.get(artifact, "station_calendar_report")},
      {"#{path}.source_station_calendar_precedence_summary",
       Map.get(artifact, "source_station_calendar_precedence_summary")},
      {"#{path}.station_calendar_precedence_summary",
       Map.get(artifact, "station_calendar_precedence_summary")}
    ]
  end

  def station_reservation_sources(path, artifact) do
    [
      {"#{path}", artifact},
      {"#{path}.source_station_reservation_report",
       Map.get(artifact, "source_station_reservation_report")},
      {"#{path}.station_reservation_report", Map.get(artifact, "station_reservation_report")},
      {"#{path}.source_station_reservation_review_summary",
       Map.get(artifact, "source_station_reservation_review_summary")},
      {"#{path}.station_reservation_review_summary",
       Map.get(artifact, "station_reservation_review_summary")},
      {"#{path}.source_station_reservation_hold_summary",
       Map.get(artifact, "source_station_reservation_hold_summary")},
      {"#{path}.station_reservation_hold_summary",
       Map.get(artifact, "station_reservation_hold_summary")},
      {"#{path}.source_station_reservation_hold_import_readiness_summary",
       Map.get(artifact, "source_station_reservation_hold_import_readiness_summary")},
      {"#{path}.station_reservation_hold_import_readiness_summary",
       Map.get(artifact, "station_reservation_hold_import_readiness_summary")}
    ]
  end
end
