defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.RowFields.RouteSpecs.StationCalendarSpecs.SpecPairs do
  @moduledoc false

  def for_id_family(field_prefix, ids_fun) when is_function(ids_fun, 1) do
    [
      {"#{field_prefix}_by_status", :status, ids_fun},
      {"#{field_prefix}_by_type", :type, ids_fun}
    ]
  end
end
