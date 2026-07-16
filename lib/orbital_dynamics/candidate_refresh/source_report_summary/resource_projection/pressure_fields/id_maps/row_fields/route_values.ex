defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.PressureFields.IdMaps.RowFields.RouteValues do
  @moduledoc false

  alias __MODULE__.ReportFunctions

  def pressure_ids(reports, :status, row_ids_fun, field) do
    ReportFunctions.by_status(reports, row_ids_fun, field)
  end

  def pressure_ids(reports, :type, row_ids_fun, field) do
    ReportFunctions.by_type(reports, row_ids_fun, field)
  end
end
