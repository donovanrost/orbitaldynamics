defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationScheduleArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationScheduleResultArtifactReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationScheduleReviewArtifactReports

  def station_calendar_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    StationScheduleResultArtifactReports.station_calendar_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    ) ++
      StationScheduleReviewArtifactReports.operator_review_station_calendar_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) ++
      StationScheduleReviewArtifactReports.cadence_import_station_calendar_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
  end

  def station_reservation_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    StationScheduleResultArtifactReports.station_reservation_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    )
  end
end
