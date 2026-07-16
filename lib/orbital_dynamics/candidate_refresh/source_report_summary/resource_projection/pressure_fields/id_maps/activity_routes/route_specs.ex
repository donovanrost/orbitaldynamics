defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs do
  @moduledoc false

  alias __MODULE__.FieldDispatch
  alias __MODULE__.SpecValues

  def specs, do: SpecValues.values()

  def field(route_spec), do: FieldDispatch.from_spec(route_spec)
end
