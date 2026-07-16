defmodule OrbitalDynamics.CandidateRefresh.CandidateActivityContext do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common
  alias OrbitalDynamics.Timeline

  @objective_context_fields [
    "observation_objective_count",
    "observation_objective_ids",
    "observation_objective_source",
    "observation_objective_types",
    "collection_latency_objective_count",
    "collection_latency_objective_ids",
    "collection_latency_objective_source",
    "collection_latency_objective_types",
    "collection_id",
    "product_id",
    "product_ids",
    "payload_id",
    "instrument_id",
    "max_latency_s",
    "required_downlink_mb",
    "downlink_completion_objective_count",
    "source_capacity_adjusted_throughput_mb",
    "source_selected_capacity_adjusted_throughput_mb",
    "source_unused_capacity_adjusted_throughput_mb",
    "required_observations",
    "source_target",
    "source_target_id",
    "target_latitude_deg",
    "target_longitude_deg",
    "target_minimum_elevation_deg"
  ]

  def attach(candidates) do
    Enum.map(candidates, &attach_context/1)
  end

  defp attach_context(candidate) do
    context = Timeline.activity_context(candidate)

    context =
      context
      |> Map.merge(objective_context(candidate))
      |> Map.merge(%{
        "activity_id" => Map.get(candidate, "id"),
        "activity_type" => Map.get(candidate, "type"),
        "timeline_id" => get_in(context, ["timeline_identity", "timeline_id"])
      })
      |> Common.compact_map()

    Map.put(candidate, "activity_context", context)
  end

  defp objective_context(candidate), do: Map.take(candidate, @objective_context_fields)
end
