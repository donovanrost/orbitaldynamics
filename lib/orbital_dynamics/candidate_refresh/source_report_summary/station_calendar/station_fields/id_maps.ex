defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.StationFields.IdMaps do
  @moduledoc false

  alias __MODULE__.FieldSpecs
  alias __MODULE__.ReportMaps

  def fields(reports) do
    Map.new(FieldSpecs.all(), fn {field, accessor} ->
      {field, ReportMaps.string_list(reports, accessor)}
    end)
  end
end
