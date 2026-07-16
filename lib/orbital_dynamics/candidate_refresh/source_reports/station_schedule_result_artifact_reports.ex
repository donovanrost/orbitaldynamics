defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationScheduleResultArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationCalendar
  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservation
  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationScheduleResultArtifactSources
  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationScheduleReviewArtifactEncoding

  def station_calendar_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = StationScheduleReviewArtifactEncoding.stringify_keys(artifact)

      path
      |> StationScheduleResultArtifactSources.station_calendar_sources(artifact)
      |> Enum.flat_map(fn {entry_path, report} ->
        StationCalendar.entries(
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(report, artifact)
        )
      end)
    end)
  end

  def station_reservation_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = StationScheduleReviewArtifactEncoding.stringify_keys(artifact)

      path
      |> StationScheduleResultArtifactSources.station_reservation_sources(artifact)
      |> Enum.flat_map(fn {entry_path, report} ->
        StationReservation.entries(
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(report, artifact)
        )
      end)
    end)
  end
end
