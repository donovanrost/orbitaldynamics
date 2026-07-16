defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.Summary
  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SummarySelection
  alias __MODULE__.Direction
  alias __MODULE__.Identity
  alias __MODULE__.Metadata
  alias __MODULE__.Precedence
  alias __MODULE__.Pressure
  alias __MODULE__.ProviderContention
  alias __MODULE__.ReservationCapacityStatus

  def source_report_summary_fields(refresh_or_artifact, source_reports) do
    source_report_fields(refresh_or_artifact, source_reports)
    |> Map.merge(Identity.source_report_identity_fields(source_reports))
    |> Map.merge(Metadata.source_report_metadata_fields(source_reports))
    |> Map.merge(ProviderContention.source_report_provider_contention_fields(source_reports))
    |> Map.merge(Direction.source_report_direction_fields(source_reports))
    |> Map.merge(
      ReservationCapacityStatus.source_report_reservation_capacity_status_fields(source_reports)
    )
    |> Map.merge(Precedence.source_report_precedence_fields(source_reports))
  end

  def source_report_fields(refresh_or_artifact, source_reports) do
    {station_summary, summary_source, replay_scope} =
      SummarySelection.selected_summary(refresh_or_artifact, source_reports)

    station_summary
    |> Summary.summary(summary_source, replay_scope)
    |> Pressure.source_report_pressure_fields()
  end
end
