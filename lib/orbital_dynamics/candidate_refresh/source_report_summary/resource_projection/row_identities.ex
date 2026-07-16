defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.ActivityIds

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.GroundStationIds

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.LineageIds

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.StableEntityIds

  defdelegate ground_station_ids(row), to: GroundStationIds, as: :values
  defdelegate source_window_ids(row), to: LineageIds
  defdelegate station_calendar_entry_ids(row), to: LineageIds
  defdelegate station_calendar_provider_ids(row), to: LineageIds
  defdelegate station_calendar_provider_entry_ids(row), to: LineageIds
  defdelegate station_id(row), to: StableEntityIds
  defdelegate spacecraft_id(row), to: StableEntityIds
  defdelegate source_activity_ids(row), to: ActivityIds
end
