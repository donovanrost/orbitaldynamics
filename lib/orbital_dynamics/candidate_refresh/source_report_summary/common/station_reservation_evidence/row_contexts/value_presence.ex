defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StationReservationEvidence.RowContexts.ValuePresence do
  @moduledoc false

  def present?(values) when is_list(values), do: Enum.any?(values, &present?/1)

  def present?(%{} = value), do: map_size(value) > 0

  def present?(value), do: value not in [nil, ""]
end
