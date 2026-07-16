defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.ActivityIds.ObjectiveSatisfactionIds do
  @moduledoc false

  alias __MODULE__.FieldNames

  def values(row) do
    row
    |> Map.take(FieldNames.activity_ids())
    |> Map.values()
  end
end
