defmodule OrbitalDynamics.CandidateRefresh.ObservationCandidate do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.CandidateActivityFields
  alias OrbitalDynamics.CandidateRefresh.CollectionLatencyObjectives
  alias OrbitalDynamics.CandidateRefresh.ObservationObjectives
  alias OrbitalDynamics.CandidateRefresh.ObservationQuality
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common
  alias OrbitalDynamics.CandidateRefresh.TargetLookup
  alias OrbitalDynamics.CandidateRefresh.TargetPriority
  alias OrbitalDynamics.EventDetectors.Eclipses

  def build(
        result,
        {event, index},
        refresh,
        eclipse_intervals,
        policy,
        operational_feedback_fun,
        numeric_value_fun,
        refresh_objectives_fun
      ) do
    starts_at_s = CandidateActivityFields.epoch_seconds(event.starts_at)
    ends_at_s = CandidateActivityFields.epoch_seconds(event.ends_at)
    target_id = event.metadata.target_id

    target = TargetLookup.by_id(refresh, target_id, refresh_objectives_fun)

    {target_priority, target_priority_context} =
      TargetPriority.resolve(
        refresh,
        result.scenario_id,
        target_id,
        target,
        event.metadata.target_priority || 1.0,
        numeric_value_fun,
        operational_feedback_fun,
        refresh_objectives_fun
      )

    {observation_success_score_factor, observation_success_factor, observation_success_source} =
      ObservationQuality.success_factor(
        refresh,
        target_id,
        target,
        operational_feedback_fun,
        numeric_value_fun
      )

    observation_quality_context =
      ObservationQuality.quality_context(
        refresh,
        target_id,
        target,
        operational_feedback_fun,
        numeric_value_fun
      )

    target_metadata_context =
      ObservationQuality.target_metadata_context(target, numeric_value_fun)

    {observation_objective_context, observation_objective_score_terms} =
      ObservationObjectives.context(
        refresh,
        result.scenario_id,
        target_id,
        policy,
        refresh_objectives_fun,
        &CandidateActivityFields.policy_number/3,
        numeric_value_fun
      )

    {collection_latency_context, collection_latency_score_terms} =
      CollectionLatencyObjectives.observation_context(
        refresh,
        result.scenario_id,
        target_id,
        policy,
        refresh_objectives_fun,
        &CandidateActivityFields.policy_number/3,
        numeric_value_fun
      )

    priority = target_priority * observation_success_score_factor
    duration_s = ends_at_s - starts_at_s

    eclipse_overlap_s = overlap_duration({starts_at_s, ends_at_s}, eclipse_intervals)

    lighting_summary = Eclipses.lighting_summary(duration_s, eclipse_overlap_s)

    source_window_id =
      CandidateActivityFields.window_id(result.scenario_id, "target_visibility", target_id, index)

    id = CandidateActivityFields.activity_id(result.scenario_id, "observe", target_id, index)

    score_terms =
      %{
        "target_value" =>
          priority * duration_s *
            CandidateActivityFields.policy_number(policy, "target_value_weight", 1.0),
        "eclipse_penalty" =>
          eclipse_overlap_s *
            CandidateActivityFields.policy_number(policy, "eclipse_penalty_weight", 1.0) *
            -1.0
      }
      |> Map.merge(observation_objective_score_terms)
      |> Map.merge(collection_latency_score_terms)

    %{
      "id" => id,
      "type" => "observe",
      "scenario_id" => encode_value(result.scenario_id),
      "target_id" => encode_value(target_id),
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "duration_s" => duration_s,
      "score" => CandidateActivityFields.score(score_terms),
      "score_terms" => score_terms,
      "target_priority" => priority,
      "observation_success_factor" => observation_success_factor,
      "observation_success_factor_source" => observation_success_source,
      "eclipse_overlap_s" => eclipse_overlap_s,
      "source_window_id" => source_window_id,
      "source_window" =>
        %{
          "id" => source_window_id,
          "type" => "target_visibility",
          "max_elevation_deg" => event.metadata.max_elevation_deg,
          "minimum_elevation_deg" => event.metadata.minimum_elevation_deg
        }
        |> Map.merge(CandidateActivityFields.event_timing_metadata(event.metadata)),
      "cadence_import" => %{
        "activity_type" => "observation",
        "external_id" => id
      }
    }
    |> Map.merge(target_priority_context)
    |> Map.merge(target_metadata_context)
    |> Map.merge(observation_quality_context)
    |> Map.merge(observation_objective_context)
    |> Map.merge(collection_latency_context)
    |> Map.merge(lighting_summary)
    |> Common.compact_map()
  end

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp overlap_duration(interval, intervals) do
    intervals
    |> Enum.map(fn other -> interval_overlap_duration(interval, other) end)
    |> Enum.sum()
  end

  defp interval_overlap_duration({left_start, left_end}, {right_start, right_end}) do
    max(0.0, min(left_end, right_end) - max(left_start, right_start))
  end
end
