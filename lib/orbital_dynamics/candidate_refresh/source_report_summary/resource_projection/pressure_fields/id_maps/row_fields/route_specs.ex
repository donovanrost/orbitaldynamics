defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.RowFields.RouteSpecs do
  @moduledoc false

  alias __MODULE__.BaseSpecs
  alias __MODULE__.StationCalendarSpecs

  def values do
    BaseSpecs.values() ++ StationCalendarSpecs.values()
  end
end
