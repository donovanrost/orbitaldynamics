defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.RowFields.RouteSpecs.StationCalendarSpecs do
  @moduledoc false

  alias __MODULE__.IdFamilies
  alias __MODULE__.SpecPairs

  def values do
    IdFamilies.values()
    |> Enum.flat_map(fn {field_prefix, ids_fun} ->
      SpecPairs.for_id_family(field_prefix, ids_fun)
    end)
  end
end
