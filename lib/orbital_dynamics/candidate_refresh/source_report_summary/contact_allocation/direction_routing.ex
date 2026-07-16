defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.DirectionRouting do
  @moduledoc false

  alias __MODULE__.InputFields
  alias __MODULE__.RouteMap

  def fields(reports) do
    reports
    |> InputFields.values()
    |> RouteMap.route_values()
  end
end
