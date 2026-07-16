defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.ActivityIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  alias __MODULE__.RowValues
  alias __MODULE__.StableValues

  def source_activity_ids(row) do
    row = EncodedValue.stringify_keys(row)

    row
    |> RowValues.values()
    |> StableValues.ids()
  end
end
