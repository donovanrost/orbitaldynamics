defmodule OrbitalDynamics.CampaignPlanner.RealizedDownlinkDemandFeedback do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ContactThroughputFields,
    DownlinkActivityNormalization,
    FeedbackNumericValues,
    ProviderResultValues,
    RealizedFeedbackWeights,
    ScalarValues,
    ValueEncoding
  }

  @completion_statuses ~w(completed executed)
  @failure_statuses ~w(missed failed canceled cancelled rejected)

  def observation_feedback(activities), do: observation_feedback(activities, callbacks())

  def observation_feedback(activities, callbacks) do
    demand_mb =
      activities
      |> Enum.map(fn activity ->
        case {observation_mb(activity, callbacks), usable_weight(activity, callbacks)} do
          {value, weight} when is_number(value) and value > 0.0 and is_number(weight) ->
            value * weight

          _value ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.sum()

    if demand_mb > 0.0, do: %{"default" => demand_mb}, else: %{}
  end

  def observation_sources(activities), do: observation_sources(activities, callbacks())

  def observation_sources(activities, callbacks) do
    activities
    |> Enum.reduce(%{}, fn activity, sources ->
      case {observation_mb(activity, callbacks), usable_weight(activity, callbacks)} do
        {value, weight} when is_number(value) and value > 0.0 and is_number(weight) ->
          weighted_value = value * weight
          activity_sources = demand_sources(activity, "observation", callbacks)

          if weighted_value > 0.0 and activity_sources != [] do
            Map.update(sources, "default", activity_sources, fn existing ->
              merge_source_values(existing, activity_sources, callbacks)
            end)
          else
            sources
          end

        _value ->
          sources
      end
    end)
  end

  def observation_mb(activity), do: observation_mb(activity, callbacks())

  def observation_mb(activity, callbacks) do
    actual_data_volume_mb =
      first_numeric_activity_value(
        activity,
        [
          "actual_data_volume_mb",
          "actual_storage_mb",
          "actual_downlink_mb",
          "delivered_data_mb",
          "received_data_mb"
        ],
        callbacks
      )

    planned_data_volume_mb =
      first_numeric_activity_value(
        activity,
        [
          "planned_data_volume_mb",
          "data_volume_mb",
          "estimated_data_volume_mb",
          "estimated_storage_mb",
          "estimated_downlink_mb"
        ],
        callbacks
      )

    completed_fraction = unit_interval_number_or_nil(activity["completed_fraction"], callbacks)

    cond do
      is_number(actual_data_volume_mb) ->
        max(actual_data_volume_mb, 0.0)

      is_number(planned_data_volume_mb) and is_number(completed_fraction) ->
        max(planned_data_volume_mb, 0.0) * completed_fraction

      true ->
        nil
    end
  end

  def station_feedback(activities), do: station_feedback(activities, callbacks())

  def station_feedback(activities, callbacks) do
    activities
    |> Enum.reduce(%{}, fn activity, demands ->
      if downlink_activity?(activity, callbacks) do
        station_id = Map.get(activity, "ground_station_id") || Map.get(activity, "station_id")

        case {realized_mb(activity, callbacks), usable_weight(activity, callbacks)} do
          {demand_mb, weight}
          when is_number(demand_mb) and demand_mb > 0.0 and is_number(weight) ->
            weighted_demand_mb = demand_mb * weight

            if weighted_demand_mb > 0.0 do
              Map.update(
                demands,
                station_id || "default",
                weighted_demand_mb,
                &(&1 + weighted_demand_mb)
              )
            else
              demands
            end

          _demand ->
            demands
        end
      else
        demands
      end
    end)
    |> Enum.sort_by(fn {station_id, _demand_mb} -> station_id end)
    |> Map.new()
  end

  def station_sources(activities), do: station_sources(activities, callbacks())

  def station_sources(activities, callbacks) do
    activities
    |> Enum.reduce(%{}, fn activity, sources ->
      if downlink_activity?(activity, callbacks) do
        station_id = Map.get(activity, "ground_station_id") || Map.get(activity, "station_id")

        case {realized_mb(activity, callbacks), usable_weight(activity, callbacks)} do
          {demand_mb, weight}
          when is_number(demand_mb) and demand_mb > 0.0 and is_number(weight) ->
            weighted_demand_mb = demand_mb * weight
            activity_sources = demand_sources(activity, "contact", callbacks)

            if weighted_demand_mb > 0.0 and activity_sources != [] do
              Map.update(sources, station_id || "default", activity_sources, fn existing ->
                merge_source_values(existing, activity_sources, callbacks)
              end)
            else
              sources
            end

          _demand ->
            sources
        end
      else
        sources
      end
    end)
    |> Enum.sort_by(fn {station_id, _sources} -> station_id end)
    |> Map.new()
  end

  def demand_sources(activity, kind), do: demand_sources(activity, kind, callbacks())

  def demand_sources(activity, kind, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    [
      primary_source(activity, kind),
      activity["realized_activity_id"] &&
        "mission_state.realized_activities.realized_activity:#{activity["realized_activity_id"]}"
    ]
    |> Enum.map(&encode_value.(&1))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def realized_mb(activity), do: realized_mb(activity, callbacks())

  def realized_mb(%{"required_downlink_mb" => raw_required_downlink_mb} = activity, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    case numeric_or_nil.(raw_required_downlink_mb) do
      required_downlink_mb when is_number(required_downlink_mb) and required_downlink_mb > 0.0 ->
        contact_shortfall(activity, required_downlink_mb, callbacks)

      _required_downlink_mb ->
        nil
    end
  end

  def realized_mb(_activity, _callbacks), do: nil

  def merge_feedback(left, right) do
    Map.merge(left, right, fn _key, left_value, right_value -> left_value + right_value end)
  end

  def merge_source_feedback(left, right), do: merge_source_feedback(left, right, callbacks())

  def merge_source_feedback(left, right, callbacks) do
    Map.merge(left, right, fn _key, left_sources, right_sources ->
      merge_source_values(left_sources, right_sources, callbacks)
    end)
  end

  def merge_source_values(left, right), do: merge_source_values(left, right, callbacks())

  def merge_source_values(left, right, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    left
    |> List.wrap()
    |> Kernel.++(List.wrap(right))
    |> Enum.map(&encode_value.(&1))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp contact_shortfall(activity, required_downlink_mb, callbacks) do
    failure_statuses = Keyword.fetch!(callbacks, :failure_statuses)
    completion_statuses = Keyword.fetch!(callbacks, :completion_statuses)

    actual_throughput_mb = actual_contact_throughput_mb(activity, callbacks)
    completed_fraction = unit_interval_number_or_nil(activity["completed_fraction"], callbacks)

    cond do
      is_number(actual_throughput_mb) ->
        max(required_downlink_mb - actual_throughput_mb, 0.0)

      is_number(completed_fraction) ->
        required_downlink_mb * (1.0 - completed_fraction)

      provider_downlink_failure_result?(activity, callbacks) ->
        required_downlink_mb

      provider_downlink_success_result?(activity, callbacks) ->
        nil

      activity["realized_status"] in ["delayed", "partial" | failure_statuses] ->
        required_downlink_mb

      activity["realized_status"] in completion_statuses ->
        nil

      activity["status"] in ["delayed", "partial" | failure_statuses] ->
        required_downlink_mb

      activity["contact_success"] == false ->
        required_downlink_mb

      true ->
        nil
    end
  end

  defp primary_source(activity, kind) do
    case activity["id"] || activity["activity_id"] do
      id when id not in [nil, ""] ->
        "mission_state.realized_activities.#{kind}.required_downlink_mb:#{id}"

      _id ->
        nil
    end
  end

  defp downlink_activity?(activity, callbacks),
    do: Keyword.fetch!(callbacks, :downlink_activity?).(activity)

  defp usable_weight(activity, callbacks),
    do: Keyword.fetch!(callbacks, :usable_feedback_weight).(activity)

  defp first_numeric_activity_value(activity, keys, callbacks) do
    FeedbackNumericValues.first_numeric_activity_value(
      activity,
      keys,
      feedback_numeric_callbacks(callbacks)
    )
  end

  defp unit_interval_number_or_nil(value, callbacks) do
    FeedbackNumericValues.unit_interval_number_or_nil(
      value,
      feedback_numeric_callbacks(callbacks)
    )
  end

  defp actual_contact_throughput_mb(activity, callbacks) do
    ContactThroughputFields.actual_contact_throughput_mb(
      activity,
      feedback_numeric_callbacks(callbacks)
    )
  end

  defp feedback_numeric_callbacks(callbacks),
    do: [
      numeric_or_nil: Keyword.fetch!(callbacks, :numeric_or_nil),
      feedback_value_missing?: Keyword.fetch!(callbacks, :feedback_value_missing?)
    ]

  defp provider_downlink_failure_result?(%{"contact_result" => result}, callbacks),
    do: Keyword.fetch!(callbacks, :provider_result_success_value).(result) == :failure

  defp provider_downlink_failure_result?(_activity, _callbacks), do: false

  defp provider_downlink_success_result?(%{"contact_result" => result}, callbacks),
    do: Keyword.fetch!(callbacks, :provider_result_success_value).(result) == :success

  defp provider_downlink_success_result?(_activity, _callbacks), do: false

  defp callbacks do
    [
      downlink_activity?: &DownlinkActivityNormalization.downlink?/1,
      encode_value: &ValueEncoding.encode_value/1,
      failure_statuses: @failure_statuses,
      feedback_value_missing?: &feedback_value_missing?/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      provider_result_success_value: &ProviderResultValues.success_value/1,
      usable_feedback_weight: &RealizedFeedbackWeights.usable/1,
      completion_statuses: @completion_statuses
    ]
  end

  defp feedback_value_missing?(nil), do: true
  defp feedback_value_missing?(""), do: true
  defp feedback_value_missing?(_value), do: false
end
