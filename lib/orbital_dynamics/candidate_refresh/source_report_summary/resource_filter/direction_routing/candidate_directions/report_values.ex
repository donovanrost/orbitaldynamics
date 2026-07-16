defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.DirectionRouting.CandidateDirections.ReportValues do
  @moduledoc false

  alias __MODULE__.GroupedDirectionCounts

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.DirectionRouting.CandidateDirections.PairMaps

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.ValueMaps,
    as: ResourceValueMaps

  def direction_counts(report) do
    report
    |> PairMaps.direction_candidate_pairs()
    |> case do
      [] ->
        report
        |> Map.get("direction_counts")
        |> GroupedDirectionCounts.from_map()

      pairs ->
        PairMaps.counts_from_pairs(pairs)
    end
  end

  def candidate_ids_by_direction(report) do
    report
    |> PairMaps.direction_candidate_pairs()
    |> case do
      [] ->
        report
        |> Map.get("candidate_ids_by_direction")
        |> ResourceValueMaps.map_value_lists()

      pairs ->
        PairMaps.ids_from_pairs(pairs)
    end
  end
end
