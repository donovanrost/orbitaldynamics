defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ProviderReservationRequest.RowData.PreparedRows.NormalizedRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def values(summary, field) do
    summary
    |> Map.get(field, [])
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&EncodedValue.stringify_keys_with_keyword_maps/1)
  end
end
