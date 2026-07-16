defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.RoutingMaps.GroupedFields do
  @moduledoc false

  alias __MODULE__.{GroupedIds, RequirementStatusFields}

  def fields(reports) do
    GroupedIds.fields(reports)
    |> Map.merge(RequirementStatusFields.fields(reports))
  end
end
