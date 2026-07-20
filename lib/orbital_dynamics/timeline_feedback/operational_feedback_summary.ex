defmodule OrbitalDynamics.TimelineFeedback.OperationalFeedbackSummary do
  @moduledoc false

  alias OrbitalDynamics.TimelineFeedback.{
    ArtifactValue,
    DownlinkDemandFeedback,
    ExecutionUncertainty,
    FeedbackAggregation,
    OutcomeValue,
    ResourceFeedback
  }

  def build(rows, config) do
    rows = Enum.map(rows, &ArtifactValue.stringify_keys/1)

    %{
      "contact_success_rate" =>
        average_by(rows, & &1["ground_station_id"], &contact_success_value(&1, config)),
      "station_throughput_factor" =>
        average_by(rows, & &1["ground_station_id"], &station_throughput_value/1),
      "observation_success_rate" =>
        average_by(rows, & &1["target_id"], &observation_success_value(&1, config)),
      "image_quality_score" => average_by(rows, & &1["target_id"], &image_quality_score_value/1),
      "image_quality_status" => text_by(rows, & &1["target_id"], &image_quality_status_value/1),
      "image_quality_source" => text_by(rows, & &1["target_id"], &image_quality_source_value/1),
      "cloud_cover_fraction" => average_by(rows, & &1["target_id"], &cloud_cover_value/1),
      "blur_score" => average_by(rows, & &1["target_id"], &blur_score_value/1),
      "downlink_demand_mb" => DownlinkDemandFeedback.demand(rows),
      "downlink_demand_sources" => DownlinkDemandFeedback.sources(rows),
      "target_priority_overrides" => target_priority_feedback(rows),
      "resource_margin_overrides" => ResourceFeedback.margin_overrides(rows),
      "resource_availability_overrides" => ResourceFeedback.availability_overrides(rows),
      "maneuver_success_rate" =>
        average_by(rows, & &1["activity_id"], &maneuver_success_value(&1, config)),
      "maneuver_execution_uncertainty" => maneuver_execution_uncertainty_feedback(rows),
      "command_success_rate" =>
        average_by(rows, & &1["activity_id"], &command_success_value(&1, config))
    }
  end

  def trust_specs(config) do
    [
      {"contact_success_rate", & &1["ground_station_id"], &contact_success_value(&1, config)},
      {"station_throughput_factor", & &1["ground_station_id"], &station_throughput_value/1},
      {"observation_success_rate", & &1["target_id"], &observation_success_value(&1, config)},
      {"image_quality_score", & &1["target_id"], &image_quality_score_value/1},
      {"cloud_cover_fraction", & &1["target_id"], &cloud_cover_value/1},
      {"blur_score", & &1["target_id"], &blur_score_value/1},
      {"target_priority_overrides", & &1["target_id"], &target_priority_value/1},
      {"maneuver_success_rate", & &1["activity_id"], &maneuver_success_value(&1, config)},
      {"command_success_rate", & &1["activity_id"], &command_success_value(&1, config)},
      {"downlink_demand_mb", &DownlinkDemandFeedback.trust_key/1,
       &DownlinkDemandFeedback.trust_value/1},
      {"downlink_demand_sources", &DownlinkDemandFeedback.trust_key/1,
       &DownlinkDemandFeedback.sources_trust_value/1},
      {"resource_margin_overrides", &ResourceFeedback.spacecraft_id/1,
       &ResourceFeedback.margin_trust_value/1},
      {"resource_availability_overrides", &ResourceFeedback.spacecraft_id/1,
       &ResourceFeedback.availability_trust_value/1}
    ]
  end

  defp average_by(rows, key_fun, value_fun),
    do: FeedbackAggregation.average_by(rows, key_fun, value_fun)

  defp text_by(rows, key_fun, value_fun),
    do: FeedbackAggregation.text_by(rows, key_fun, value_fun)

  defp target_priority_feedback(rows) do
    rows
    |> Enum.reject(&FeedbackAggregation.excluded?/1)
    |> Enum.reduce(%{}, fn row, grouped ->
      key = FeedbackAggregation.stable_identifier(row["target_id"])
      value = target_priority_value(row)
      weight = feedback_average_weight(row)

      if is_binary(key) and key != "" and is_number(value) and is_number(weight) and
           weight > 0.0 do
        Map.update(
          grouped,
          key,
          [{max(value, 0.0), weight}],
          &[
            {max(value, 0.0), weight} | &1
          ]
        )
      else
        grouped
      end
    end)
    |> Enum.map(fn {key, weighted_values} ->
      {key, OutcomeValue.weighted_average(weighted_values)}
    end)
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Map.new()
  end

  defp target_priority_value(%{"feedback_kind" => "observation"} = row) do
    first_target_priority_number(row, [
      ["realized_activity_context", "target_priority"],
      ["source_activity_context", "target_priority"],
      "realized_target_priority",
      "target_priority"
    ])
  end

  defp target_priority_value(_row), do: nil

  defp maneuver_execution_uncertainty_feedback(rows) do
    rows
    |> Enum.reject(&FeedbackAggregation.excluded?/1)
    |> Enum.reduce(%{}, fn row, feedback ->
      key = FeedbackAggregation.stable_identifier(row["activity_id"])
      entry = maneuver_execution_uncertainty_feedback_entry(row)

      if is_binary(key) and key != "" and entry != %{} do
        Map.put(feedback, key, entry)
      else
        feedback
      end
    end)
    |> sort_nested_feedback_map()
  end

  defp maneuver_execution_uncertainty_feedback_entry(row) do
    %{
      "execution_uncertainty_status" => row["execution_uncertainty_status"],
      "execution_uncertainty" => row["execution_uncertainty"],
      "timing_3sigma_s" => ExecutionUncertainty.numeric_value(row["timing_3sigma_s"]),
      "delta_v_3sigma_km_s" => ExecutionUncertainty.numeric_triplet(row["delta_v_3sigma_km_s"]),
      "delta_v_3sigma_magnitude_km_s" =>
        ExecutionUncertainty.numeric_value(row["delta_v_3sigma_magnitude_km_s"]),
      "execution_uncertainty_source" => row["execution_uncertainty_source"]
    }
    |> ArtifactValue.compact_map()
    |> case do
      %{"execution_uncertainty_status" => status} = entry
      when status in ["declared", "missing"] ->
        entry

      _entry ->
        %{}
    end
  end

  defp sort_nested_feedback_map(feedback) do
    feedback
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Map.new(fn {key, value} ->
      {key,
       value
       |> Enum.sort_by(fn {field, _field_value} -> field end)
       |> Map.new()}
    end)
  end

  defp first_target_priority_number(row, fields) do
    Enum.find_value(fields, fn field ->
      value =
        case field do
          path when is_list(path) -> get_in(row, path)
          field -> Map.get(row, field)
        end

      ExecutionUncertainty.numeric_value(value)
    end)
  end

  defp contact_success_value(%{"feedback_kind" => "contact"} = row, config) do
    OutcomeValue.contact_success(
      row,
      Map.fetch!(config, :realized_completion_statuses),
      Map.fetch!(config, :realized_failure_statuses)
    )
  end

  defp contact_success_value(_row, _config), do: nil

  defp station_throughput_value(%{"feedback_kind" => "contact"} = row) do
    OutcomeValue.station_throughput(row)
  end

  defp station_throughput_value(_row), do: nil

  defp observation_success_value(%{"feedback_kind" => "observation"} = row, config) do
    OutcomeValue.observation_success(
      row,
      Map.fetch!(config, :provider_result_map_value_keys),
      Map.fetch!(config, :realized_completion_statuses),
      Map.fetch!(config, :realized_failure_statuses)
    )
  end

  defp observation_success_value(_row, _config), do: nil

  defp image_quality_score_value(%{"feedback_kind" => "observation"} = row) do
    OutcomeValue.image_quality_score(row)
  end

  defp image_quality_score_value(_row), do: nil

  defp cloud_cover_value(%{"feedback_kind" => "observation"} = row) do
    OutcomeValue.cloud_cover(row)
  end

  defp cloud_cover_value(_row), do: nil

  defp blur_score_value(%{"feedback_kind" => "observation"} = row) do
    OutcomeValue.blur_score(row)
  end

  defp blur_score_value(_row), do: nil

  defp image_quality_status_value(%{"feedback_kind" => "observation"} = row) do
    OutcomeValue.image_quality_status(row)
  end

  defp image_quality_status_value(_row), do: nil

  defp image_quality_source_value(%{"feedback_kind" => "observation"} = row) do
    OutcomeValue.image_quality_source(row)
  end

  defp image_quality_source_value(_row), do: nil

  defp maneuver_success_value(%{"feedback_kind" => "maneuver"} = row, config) do
    OutcomeValue.maneuver_success(
      row,
      Map.fetch!(config, :realized_completion_statuses),
      Map.fetch!(config, :realized_failure_statuses)
    )
  end

  defp maneuver_success_value(_row, _config), do: nil

  defp command_success_value(%{"feedback_kind" => kind} = row, config)
       when kind in ["command", "health_check"] do
    OutcomeValue.command_success(
      row,
      Map.fetch!(config, :realized_completion_statuses),
      Map.fetch!(config, :realized_failure_statuses)
    )
  end

  defp command_success_value(_row, _config), do: nil

  defp feedback_average_weight(%{"feedback_weight" => weight}) do
    OutcomeValue.average_weight(%{"feedback_weight" => weight})
  end

  defp feedback_average_weight(_row), do: 1.0
end
