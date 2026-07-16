defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.RowFields.RouteValues.ReportFunctions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureIdRouting

  alias __MODULE__.RouteMerges

  def by_status(reports, row_ids_fun, field) do
    RouteMerges.from_reports(reports, &PressureIdRouting.row_ids_by_status/3, row_ids_fun, field)
  end

  def by_type(reports, row_ids_fun, field) do
    RouteMerges.from_reports(reports, &PressureIdRouting.row_ids_by_type/3, row_ids_fun, field)
  end
end
