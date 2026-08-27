defmodule OrbitalDynamics.CandidateRefresh.ObservationCandidate do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.CandidateActivityFields
  alias OrbitalDynamics.CandidateRefresh.CollectionLatencyObjectives
  alias OrbitalDynamics.CandidateRefresh.ObservationObjectives
  alias OrbitalDynamics.CandidateRefresh.ObservationQuality
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common
  alias OrbitalDynamics.CandidateRefresh.TargetLookup
  alias OrbitalDynamics.CandidateRefresh.TargetPriority
  alias OrbitalDynamics.AccessEventResultAdmission
  alias OrbitalDynamics.EventDetectors.Eclipses

  @max_eclipse_intervals 10_000
  @safe_number_limit 1.0e15

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
    with {:ok, result, event} <- AccessEventResultAdmission.admit_observation_input(result, event),
         starts_at_s = CandidateActivityFields.epoch_seconds(event.starts_at),
         ends_at_s = CandidateActivityFields.epoch_seconds(event.ends_at),
         target_id = event.metadata.target_id,
         {:ok, duration_s} <- duration_seconds(starts_at_s, ends_at_s),
         {:ok, eclipse_overlap_s} <- overlap_duration({starts_at_s, ends_at_s}, eclipse_intervals),
         :ok <- validate_lighting_inputs(duration_s, eclipse_overlap_s),
         {:ok, lighting_summary} <- lighting_summary(duration_s, eclipse_overlap_s) do
      build_valid(
        result,
        event,
        index,
        refresh,
        policy,
        operational_feedback_fun,
        numeric_value_fun,
        refresh_objectives_fun,
        starts_at_s,
        ends_at_s,
        target_id,
        duration_s,
        eclipse_overlap_s,
        lighting_summary
      )
    else
      {:error, reason} -> {:error, {:invalid_observation_lighting, reason}}
    end
  end

  defp build_valid(
         result,
         event,
         index,
         refresh,
         policy,
         operational_feedback_fun,
         numeric_value_fun,
         refresh_objectives_fun,
         starts_at_s,
         ends_at_s,
         target_id,
         duration_s,
         eclipse_overlap_s,
         lighting_summary
       ) do
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

  defp duration_seconds(starts_at_s, ends_at_s) do
    with :ok <- validate_number(:starts_at_s, starts_at_s),
         :ok <- validate_number(:ends_at_s, ends_at_s) do
      duration_s = ends_at_s - starts_at_s

      cond do
        not finite_number?(duration_s) -> {:error, {:invalid_option, :duration_s}}
        duration_s < 0.0 -> {:error, {:invalid_timing, :negative_duration_s}}
        true -> {:ok, duration_s}
      end
    end
  end

  defp lighting_summary(duration_s, eclipse_overlap_s) do
    case Eclipses.lighting_summary(duration_s, eclipse_overlap_s) do
      %{} = summary ->
        {:ok, summary}

      {:error, {:invalid_option, field}} when field in [:duration_s, :eclipse_overlap_s] ->
        {:error, {:invalid_option, field}}
    end
  end

  defp validate_lighting_inputs(duration_s, eclipse_overlap_s) do
    cond do
      eclipse_overlap_s < 0.0 ->
        {:error, {:invalid_timing, :negative_eclipse_overlap_s}}

      eclipse_overlap_s > duration_s ->
        {:error, {:invalid_timing, :eclipse_overlap_exceeds_duration_s}}

      true ->
        :ok
    end
  end

  defp overlap_duration(interval, intervals) do
    with {:ok, intervals} <-
           bounded_list_items(intervals, :eclipse_intervals, @max_eclipse_intervals) do
      Enum.reduce_while(intervals, {:ok, 0.0}, fn other, {:ok, total} ->
        case interval_overlap_duration(interval, other) do
          {:ok, overlap_s} ->
            next_total = total + overlap_s

            if finite_number?(next_total) do
              {:cont, {:ok, next_total}}
            else
              {:halt, {:error, {:invalid_option, :eclipse_overlap_s}}}
            end

          {:error, reason} ->
            {:halt, {:error, reason}}
        end
      end)
    end
  end

  defp interval_overlap_duration({left_start, left_end}, {right_start, right_end}) do
    with :ok <- validate_number(:eclipse_intervals, right_start),
         :ok <- validate_number(:eclipse_intervals, right_end) do
      interval_duration_s = right_end - right_start

      cond do
        not finite_number?(interval_duration_s) ->
          {:error, {:invalid_option, :eclipse_intervals}}

        interval_duration_s < 0.0 ->
          {:error, {:invalid_timing, :negative_eclipse_interval_duration_s}}

        true ->
          overlap_s = max(0.0, min(left_end, right_end) - max(left_start, right_start))

          if finite_number?(overlap_s) do
            {:ok, overlap_s}
          else
            {:error, {:invalid_option, :eclipse_overlap_s}}
          end
      end
    end
  end

  defp interval_overlap_duration(_interval, _other),
    do: {:error, {:invalid_option, :eclipse_intervals}}

  defp validate_number(field, value) when is_integer(value) or is_float(value) do
    if finite_number?(value) do
      :ok
    else
      {:error, {:invalid_option, field}}
    end
  end

  defp validate_number(field, _value), do: {:error, {:invalid_option, field}}

  defp bounded_list_items(list, field, limit) when is_list(list) do
    bounded_list_items(list, [], 0, field, limit)
  end

  defp bounded_list_items(_not_list, field, _limit), do: {:error, {:invalid_container, field}}

  defp bounded_list_items(_list, _acc, count, field, limit) when count > limit,
    do: {:error, {:container_limit_exceeded, field}}

  defp bounded_list_items([], acc, _count, _field, _limit), do: {:ok, Enum.reverse(acc)}

  defp bounded_list_items([head | tail], acc, count, field, limit) do
    bounded_list_items(tail, [head | acc], count + 1, field, limit)
  end

  defp bounded_list_items(_improper_tail, _acc, _count, field, _limit),
    do: {:error, {:invalid_container, field}}

  defp finite_number?(value) when is_integer(value), do: abs(value) <= @safe_number_limit

  defp finite_number?(value) when is_float(value) do
    value == value and value - value == 0.0 and abs(value) <= @safe_number_limit
  end
end
