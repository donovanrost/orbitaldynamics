defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.ActivityRoutes.RouteSpecs.FieldValues.FieldPairs do
  @moduledoc false

  def from_fun(field, values_fun) when is_function(values_fun, 1), do: {field, values_fun}
end
