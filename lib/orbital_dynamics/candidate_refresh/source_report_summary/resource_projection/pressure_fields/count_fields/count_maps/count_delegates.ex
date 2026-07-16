defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.CountFields.CountMaps.CountDelegates do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.CountFields.CountMaps.IdentityCounts

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.CountFields.CountMaps.PressureCounts

  def status_counts(report), do: PressureCounts.status_counts(report)

  def ground_station_counts(report), do: IdentityCounts.ground_station_counts(report)

  def spacecraft_counts(report), do: IdentityCounts.spacecraft_counts(report)

  def activity_id_counts(report), do: IdentityCounts.activity_id_counts(report)

  def type_counts(report), do: PressureCounts.type_counts(report)
end
