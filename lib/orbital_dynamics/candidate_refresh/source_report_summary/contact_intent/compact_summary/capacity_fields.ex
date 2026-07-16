defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.CapacityFields do
  @moduledoc false

  alias __MODULE__.CapacityMaps
  alias __MODULE__.RequiredCapacityField

  def from_compact_summaries(summaries) do
    RequiredCapacityField.field(summaries)
    |> Map.merge(CapacityMaps.compact_capacity_fields(summaries))
  end

  def from_input_summaries(summaries) do
    RequiredCapacityField.field(summaries)
    |> Map.merge(CapacityMaps.input_capacity_fields(summaries))
  end
end
