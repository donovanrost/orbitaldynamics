defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.AllocationReportSummary.ContactFields do
  @moduledoc false

  alias __MODULE__.ContactIdFields
  alias __MODULE__.RouteFields

  def fields(reports) do
    ContactIdFields.fields(reports)
    |> Map.merge(RouteFields.fields(reports))
  end
end
