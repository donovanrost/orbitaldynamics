defmodule OrbitalDynamics.TimelineFeedback.DownlinkDemandFeedback do
  @moduledoc false

  alias OrbitalDynamics.TimelineFeedback.{
    ArtifactValue,
    ExecutionUncertainty,
    FeedbackAggregation,
    OutcomeValue,
    SuccessFactor,
    Throughput
  }

  def demand(rows) do
    rows
    |> Enum.reject(&excluded?/1)
    |> Enum.reduce(%{}, fn row, demands ->
      case downlink_demand_feedback_entry(row) do
        {key, demand_mb} when is_binary(key) and is_number(demand_mb) and demand_mb > 0.0 ->
          weight = average_weight(row)
          weighted_demand_mb = demand_mb * weight

          if weight > 0.0 and weighted_demand_mb > 0.0 do
            Map.update(demands, key, weighted_demand_mb, &(&1 + weighted_demand_mb))
          else
            demands
          end

        _entry ->
          demands
      end
    end)
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Map.new()
  end

  defp downlink_demand_feedback_entry(%{"feedback_kind" => "observation"} = row) do
    actual_data_volume_mb = numeric_value(row["actual_data_volume_mb"])
    planned_data_volume_mb = numeric_value(row["planned_data_volume_mb"])
    completed_fraction = unit_interval_number_or_nil(row["completed_fraction"])

    cond do
      is_number(actual_data_volume_mb) ->
        {"default", max(actual_data_volume_mb, 0.0)}

      is_number(planned_data_volume_mb) and is_number(completed_fraction) ->
        {"default", planned_data_volume_mb * completed_fraction}

      true ->
        nil
    end
  end

  defp downlink_demand_feedback_entry(%{"feedback_kind" => "contact"} = row) do
    station_key = downlink_demand_station_key(row)

    case contact_downlink_demand_mb(row) do
      demand_mb when is_binary(station_key) and is_number(demand_mb) and demand_mb > 0.0 ->
        {station_key, demand_mb}

      _demand ->
        nil
    end
  end

  defp downlink_demand_feedback_entry(_row), do: nil

  def trust_key(row) do
    case downlink_demand_feedback_entry(row) do
      {key, demand_mb} when is_binary(key) and is_number(demand_mb) and demand_mb > 0.0 ->
        key

      _entry ->
        nil
    end
  end

  def trust_value(row) do
    if excluded?(row) do
      nil
    else
      case downlink_demand_feedback_entry(row) do
        {_key, demand_mb} when is_number(demand_mb) and demand_mb > 0.0 ->
          weight = average_weight(row)

          if weight > 0.0 and demand_mb * weight > 0.0 do
            demand_mb * weight
          end

        _entry ->
          nil
      end
    end
  end

  def sources_trust_value(row) do
    case trust_value(row) do
      value when is_number(value) ->
        case downlink_demand_feedback_sources(row) do
          [] -> nil
          sources -> sources
        end

      _value ->
        nil
    end
  end

  defp downlink_demand_station_key(row) do
    case Map.get(row, "ground_station_id") do
      value when value in [nil, ""] -> "default"
      value -> stable_identifier(value)
    end
  end

  def sources(rows) do
    rows
    |> Enum.reject(&excluded?/1)
    |> Enum.reduce(%{}, fn row, sources ->
      case downlink_demand_feedback_entry(row) do
        {key, demand_mb} when is_binary(key) and is_number(demand_mb) and demand_mb > 0.0 ->
          weight = average_weight(row)
          weighted_demand_mb = demand_mb * weight
          row_sources = downlink_demand_feedback_sources(row)

          if weight > 0.0 and weighted_demand_mb > 0.0 and row_sources != [] do
            Map.update(sources, key, row_sources, fn existing ->
              existing
              |> Kernel.++(row_sources)
              |> Enum.uniq()
              |> Enum.sort()
            end)
          else
            sources
          end

        _entry ->
          sources
      end
    end)
    |> Enum.sort_by(fn {key, _sources} -> key end)
    |> Map.new()
  end

  defp downlink_demand_feedback_sources(row) do
    row
    |> downlink_demand_feedback_source_values()
    |> Enum.map(&stringify_scalar/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp downlink_demand_feedback_source_values(%{"feedback_kind" => "contact"} = row) do
    [
      timeline_feedback_demand_source(
        "timeline_feedback.contact.required_downlink_mb",
        row["activity_id"] || row["id"]
      ),
      row["realized_activity_id"] &&
        timeline_feedback_demand_source(
          "timeline_feedback.realized_activity",
          row["realized_activity_id"]
        )
    ]
  end

  defp downlink_demand_feedback_source_values(%{"feedback_kind" => "observation"} = row) do
    [
      timeline_feedback_demand_source(
        "timeline_feedback.observation.data_volume",
        row["activity_id"] || row["id"]
      ),
      row["realized_activity_id"] &&
        timeline_feedback_demand_source(
          "timeline_feedback.realized_activity",
          row["realized_activity_id"]
        )
    ]
  end

  defp downlink_demand_feedback_source_values(row) do
    [timeline_feedback_demand_source("timeline_feedback.row", row["id"])]
  end

  defp timeline_feedback_demand_source(_prefix, id) when id in [nil, ""], do: nil

  defp timeline_feedback_demand_source(prefix, id) do
    "#{prefix}:#{id}"
  end

  defp contact_downlink_demand_mb(%{"required_downlink_mb" => raw_required_downlink_mb} = row) do
    case numeric_value(raw_required_downlink_mb) do
      required_downlink_mb when is_number(required_downlink_mb) and required_downlink_mb > 0.0 ->
        actual_throughput_mb = actual_throughput_mb(row)
        completed_fraction = unit_interval_number_or_nil(row["completed_fraction"])

        cond do
          is_number(actual_throughput_mb) ->
            max(required_downlink_mb - actual_throughput_mb, 0.0)

          is_number(completed_fraction) ->
            required_downlink_mb * (1.0 - completed_fraction)

          row["realized_status"] in [
            "missed",
            "failed",
            "delayed",
            "partial",
            "canceled",
            "cancelled",
            "rejected"
          ] ->
            required_downlink_mb

          row["contact_success"] == false ->
            required_downlink_mb

          true ->
            nil
        end

      _required_downlink_mb ->
        nil
    end
  end

  defp contact_downlink_demand_mb(_row), do: nil

  defp excluded?(row), do: FeedbackAggregation.excluded?(row)
  defp average_weight(row), do: OutcomeValue.average_weight(row)
  defp numeric_value(value), do: ExecutionUncertainty.numeric_value(value)
  defp actual_throughput_mb(row), do: Throughput.actual_throughput_mb(row)

  defp unit_interval_number_or_nil(value),
    do: SuccessFactor.unit_interval_number_or_nil(value)

  defp stable_identifier(value), do: FeedbackAggregation.stable_identifier(value)
  defp stringify_scalar(value), do: ArtifactValue.stringify_scalar(value)
end
