defmodule OrbitalDynamics.CandidateRefresh.DownlinkDemand do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common, only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.CollectionLatencyObjectives
  alias OrbitalDynamics.CandidateRefresh.DownlinkCompletionObjectives
  alias OrbitalDynamics.CandidateRefresh.ObjectiveMatching
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue
  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def context(refresh, ground_station_id, operational_feedback) do
    feedback = operational_feedback.(refresh)
    station_id = encode_value(ground_station_id)

    feedback
    |> Map.get("downlink_demand_context", %{})
    |> case do
      %{} = contexts -> Map.get(contexts, station_id) || Map.get(contexts, "default")
      _contexts -> nil
    end
    |> case do
      %{} = context ->
        context
        |> stringify_keys()
        |> Map.take([
          "collection_id",
          "product_id",
          "product_ids",
          "payload_id",
          "instrument_id",
          "target_id",
          "source_activity_id",
          "source_activity_ids",
          "missed_downlink_activity_id",
          "missed_downlink_activity_ids",
          "objective_id",
          "objective_type",
          "latency_objective",
          "max_latency_s",
          "planned_latency_s",
          "feedback_source",
          "feedback_scope",
          "trust_boundary"
        ])
        |> compact_map()

      _context ->
        %{}
    end
  end

  def required_mb(
        refresh,
        scenario_id,
        ground_station_id,
        refresh_objectives,
        operational_feedback
      ) do
    aggregate_required_downlink_mb([
      required_downlink_mb_from_feedback(
        refresh,
        ground_station_id,
        operational_feedback
      ),
      required_downlink_mb_from_objectives(
        refresh,
        scenario_id,
        ground_station_id,
        refresh_objectives,
        operational_feedback
      )
    ]) ||
      requirement_with_sources(required_downlink_mb_from_policy(refresh))
  end

  defp aggregate_required_downlink_mb(requirements) do
    requirements =
      requirements
      |> Enum.map(&requirement_with_sources/1)
      |> Enum.filter(
        &match?({value, _source, _sources} when is_number(value) and value > 0.0, &1)
      )

    case requirements do
      [] ->
        nil

      [{required_downlink_mb, source, sources}] ->
        {required_downlink_mb, source, sources}

      requirements ->
        required_downlink_mb =
          requirements
          |> Enum.map(fn {value, _source, _sources} -> value end)
          |> Enum.sum()

        sources =
          requirements
          |> Enum.map(fn {_value, source, _sources} -> source end)
          |> Enum.map(&required_downlink_source_category/1)
          |> Enum.uniq()
          |> Enum.sort()

        exact_sources =
          requirements
          |> Enum.flat_map(fn {_value, _source, exact_sources} -> exact_sources end)
          |> Enum.uniq()
          |> Enum.sort()

        {required_downlink_mb,
         "candidate_refresh.downlink_demand." <> Enum.join(sources, "_and_"), exact_sources}
    end
  end

  defp requirement_with_sources({required_downlink_mb, source, sources})
       when is_list(sources) do
    {required_downlink_mb, source, sources}
  end

  defp requirement_with_sources({required_downlink_mb, source}) when is_binary(source) do
    {required_downlink_mb, source, [source]}
  end

  defp requirement_with_sources(_requirement), do: nil

  defp required_downlink_source_category("operational_feedback." <> _suffix),
    do: "operational_feedback"

  defp required_downlink_source_category("candidate_refresh.objectives." <> _suffix),
    do: "objectives"

  defp required_downlink_source_category("candidate_refresh.scoring_policy." <> _suffix),
    do: "scoring_policy"

  defp required_downlink_source_category(source), do: source

  defp required_downlink_mb_from_feedback(
         refresh,
         ground_station_id,
         operational_feedback
       ) do
    feedback = operational_feedback.(refresh)
    demands = Map.get(feedback, "downlink_demand_mb")

    case demands do
      %{} ->
        station_id = encode_value(ground_station_id)

        cond do
          is_number(Map.get(demands, station_id)) ->
            {demands |> Map.get(station_id) |> max(0.0),
             "operational_feedback.downlink_demand_mb.station",
             feedback_downlink_demand_sources(
               feedback,
               station_id,
               "operational_feedback.downlink_demand_mb.station"
             )}

          is_number(Map.get(demands, "default")) ->
            {demands |> Map.get("default") |> max(0.0),
             "operational_feedback.downlink_demand_mb.default",
             feedback_downlink_demand_sources(
               feedback,
               "default",
               "operational_feedback.downlink_demand_mb.default"
             )}

          true ->
            nil
        end

      _demands ->
        nil
    end
  end

  defp feedback_downlink_demand_sources(feedback, key, fallback_source) do
    feedback
    |> Map.get("downlink_demand_sources", %{})
    |> case do
      %{} = source_map -> Map.get(source_map, key)
      _source_map -> nil
    end
    |> List.wrap()
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> [fallback_source]
      sources -> sources
    end
  end

  defp required_downlink_mb_from_objectives(
         refresh,
         scenario_id,
         ground_station_id,
         refresh_objectives,
         operational_feedback
       ) do
    feedback_source_paths =
      downlink_demand_feedback_source_paths(
        refresh,
        ground_station_id,
        operational_feedback
      )

    downlink_completion_mb =
      refresh
      |> DownlinkCompletionObjectives.objectives(refresh_objectives)
      |> Enum.filter(fn objective ->
        ObjectiveMatching.matches_downlink_candidate?(
          objective,
          refresh,
          scenario_id,
          ground_station_id
        ) and
          not duplicate_downlink_demand_feedback_objective?(
            objective,
            feedback_source_paths
          )
      end)
      |> Enum.map(&ObjectiveMatching.required_downlink_mb/1)
      |> Enum.filter(&(is_number(&1) and &1 > 0.0))
      |> Enum.sum()

    collection_latency_mb =
      refresh
      |> CollectionLatencyObjectives.objectives(refresh_objectives)
      |> Enum.filter(fn objective ->
        ObjectiveMatching.matches_downlink_candidate?(
          objective,
          refresh,
          scenario_id,
          ground_station_id
        ) and
          not duplicate_downlink_demand_feedback_objective?(
            objective,
            feedback_source_paths
          )
      end)
      |> Enum.map(&ObjectiveMatching.required_downlink_mb/1)
      |> Enum.filter(&(is_number(&1) and &1 > 0.0))
      |> Enum.sum()

    required_downlink_mb = downlink_completion_mb + collection_latency_mb

    cond do
      required_downlink_mb <= 0.0 ->
        nil

      downlink_completion_mb > 0.0 and collection_latency_mb > 0.0 ->
        {required_downlink_mb, "candidate_refresh.objectives.downlink_completion_and_latency",
         [
           "candidate_refresh.objectives.collection_latency",
           "candidate_refresh.objectives.downlink_completion"
         ]}

      collection_latency_mb > 0.0 ->
        {required_downlink_mb, "candidate_refresh.objectives.collection_latency"}

      true ->
        {required_downlink_mb, "candidate_refresh.objectives.downlink_completion"}
    end
  end

  defp downlink_demand_feedback_source_paths(
         refresh,
         ground_station_id,
         operational_feedback
       ) do
    refresh
    |> context(ground_station_id, operational_feedback)
    |> Map.take(["feedback_source", "source_path"])
    |> Map.values()
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp duplicate_downlink_demand_feedback_objective?(_objective, []), do: false

  defp duplicate_downlink_demand_feedback_objective?(objective, source_paths) do
    objective
    |> Map.get("source_path")
    |> encode_value()
    |> then(&(&1 in source_paths))
  end

  defp required_downlink_mb_from_policy(%{"scoring_policy" => %{} = policy}) do
    case ValueEncoding.numeric_value(Map.get(policy, "required_downlink_mb")) do
      value when is_number(value) and value > 0.0 ->
        {value, "candidate_refresh.scoring_policy.required_downlink_mb"}

      _value ->
        nil
    end
  end

  defp required_downlink_mb_from_policy(_refresh), do: nil

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(value), do: EncodedValue.value_with_keyword_maps(value)
end
