defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.RouteMaps.KeyFunctions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting.PressureRows

  def pressure_status, do: &PressureRows.pressure_status/1
  def pressure_types, do: &PressureRows.pressure_types/1
end
