defmodule OrbitalDynamics.CampaignPlanner.ObjectiveTradeoffPressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ObjectiveActivityIdentifiers,
    ObjectivePressureRows,
    ObjectiveTargetIdentifiers,
    ObjectiveTradeoffMetrics,
    ObjectiveTradeoffTargets,
    ScalarValues,
    ScoreTermIdentifiers,
    ValueEncoding
  }

  def branch(row, source_path, index, callbacks \\ default_callbacks()) do
    row = normalize_row(row, callbacks)

    row
    |> pressure_events(source_path, callbacks)
    |> case do
      [] ->
        []

      events ->
        identity = row["branch_id"] || row["scenario_id"] || row["id"] || index

        [
          %{
            "id" =>
              "derived_objective_tradeoff_pressure_#{branch_id_fragment(identity, callbacks)}",
            "label" => "Derived objective tradeoff pressure #{identity}",
            "events" => events,
            "metadata" =>
              %{
                "derived_source" => source_path,
                "objective_tradeoff_rank" => row["rank"],
                "objective_tradeoff_selected" => row["selected"],
                "score_delta_from_selected" => row["score_delta_from_selected"]
              }
              |> compact_map(callbacks)
          }
        ]
    end
  end

  def pressure_events(row, source_path, callbacks \\ default_callbacks()) do
    []
    |> Kernel.++(downlink_gap_events(row, source_path, callbacks))
    |> Kernel.++(target_gap_events(row, source_path, callbacks))
  end

  def normalize_row(row, callbacks \\ default_callbacks()) do
    row
    |> normalize_selected(callbacks)
    |> ObjectivePressureRows.normalize()
  end

  defp normalize_selected(%{"selected" => selected} = row, callbacks) do
    case json_boolean_value(selected, callbacks) do
      value when is_boolean(value) -> Map.put(row, "selected", value)
      _value -> row
    end
  end

  defp normalize_selected(row, _callbacks), do: row

  defp downlink_gap_events(row, source_path, callbacks) do
    required_downlink_mb = required_downlink_mb(row, callbacks)
    planned_downlink_mb = planned_downlink_mb(row, callbacks)
    required_contacts = required_contacts(row, callbacks)
    planned_contacts = planned_contacts(row, callbacks)
    latency_gap? = collection_latency_gap?(row, callbacks)

    volume_gap? =
      is_number(required_downlink_mb) and required_downlink_mb > planned_downlink_mb

    contact_gap? =
      downlink_objective?(row, callbacks) and is_number(required_contacts) and
        required_contacts > planned_contacts

    if volume_gap? or contact_gap? or latency_gap? do
      [
        %{
          "type" => "downlink_completion_gap",
          "objective_id" => row["id"] || row["objective_id"],
          "objective_type" => row["objective"] || row["objective_type"],
          "latency_objective" => if(collection_latency_objective?(row, callbacks), do: true),
          "target_id" => primary_target_id(row, callbacks),
          "scenario_id" => scenario_id(row, callbacks),
          "branch_id" => row["branch_id"],
          "ground_station_id" => station_id(row, callbacks),
          "collection_id" => collection_id(row, callbacks),
          "product_id" => product_id(row, callbacks),
          "product_ids" => product_ids(row, callbacks),
          "payload_id" => payload_id(row, callbacks),
          "instrument_id" => instrument_id(row, callbacks),
          "required_contacts" => required_contacts || 1,
          "planned_contacts" => planned_contacts,
          "required_downlink_mb" => required_downlink_mb,
          "planned_downlink_mb" => planned_downlink_mb,
          "starts_at_s" => latency_window_start_s(row, callbacks),
          "ends_at_s" => latency_window_end_s(row, callbacks),
          "max_latency_s" => max_latency_s(row, callbacks),
          "planned_latency_s" => planned_latency_s(row, callbacks),
          "source_activity_id" => source_activity_id(row, callbacks),
          "source_activity_ids" => source_activity_ids(row, callbacks),
          "score" => numeric_or_nil(row["score"], callbacks),
          "score_delta_from_selected" =>
            numeric_or_nil(row["score_delta_from_selected"], callbacks),
          "score_terms" => row["score_terms"],
          "derivation_reasons" =>
            downlink_reasons(row, contact_gap?, volume_gap?, latency_gap?, callbacks),
          "feedback_source" => source_path,
          "feedback_scope" => "objective_tradeoff",
          "trust_boundary" => trust_boundary(row, callbacks)
        }
        |> compact_map(callbacks)
      ]
    else
      []
    end
  end

  defp target_gap_events(row, source_path, callbacks) do
    target_ids = gap_target_ids(row, callbacks)
    required_observations = required_observations(row, callbacks)
    planned_observations = planned_observations(row, callbacks)

    target_gap? =
      target_ids != [] and
        (has_missed_targets?(row, callbacks) or
           (is_number(required_observations) and required_observations > planned_observations))

    if target_gap? do
      Enum.map(target_ids, fn target_id ->
        target_spec = target_spec(row, target_id, callbacks)

        %{
          "type" => "urgent_target",
          "objective_id" => row["id"] || row["objective_id"],
          "objective_type" =>
            row["objective"] || row["objective_type"] || "objective_tradeoff_target_gap",
          "target_id" => target_id,
          "scenario_id" => scenario_id(row, callbacks),
          "branch_id" => row["branch_id"],
          "priority" => target_priority(row, target_spec, callbacks),
          "latitude_deg" => target_number(row, target_spec, "latitude_deg", callbacks),
          "longitude_deg" => target_number(row, target_spec, "longitude_deg", callbacks),
          "minimum_elevation_deg" =>
            target_number(row, target_spec, "minimum_elevation_deg", callbacks),
          "required_observations" => required_observations || 1,
          "planned_observations" => planned_observations,
          "source_activity_ids" => source_activity_ids(row, callbacks),
          "score" => numeric_or_nil(row["score"], callbacks),
          "score_delta_from_selected" =>
            numeric_or_nil(row["score_delta_from_selected"], callbacks),
          "score_terms" => row["score_terms"],
          "derivation_reason" => "objective_tradeoff_target_gap",
          "derivation_reasons" => target_reasons(row, callbacks),
          "feedback_source" => source_path,
          "feedback_scope" => "objective_tradeoff",
          "trust_boundary" => trust_boundary(row, callbacks)
        }
        |> compact_map(callbacks)
      end)
    else
      []
    end
  end

  defp callback(callbacks, name, args) do
    callbacks
    |> Keyword.fetch!(name)
    |> then(&apply(&1, args))
  end

  defp json_boolean_value(value, callbacks), do: callback(callbacks, :json_boolean_value, [value])
  defp compact_map(map, callbacks), do: callback(callbacks, :compact_map, [map])
  defp branch_id_fragment(value, callbacks), do: callback(callbacks, :branch_id_fragment, [value])
  defp numeric_or_nil(value, callbacks), do: callback(callbacks, :numeric_or_nil, [value])
  defp scenario_id(row, callbacks), do: callback(callbacks, :scenario_id, [row])
  defp required_downlink_mb(row, callbacks), do: callback(callbacks, :required_downlink_mb, [row])
  defp planned_downlink_mb(row, callbacks), do: callback(callbacks, :planned_downlink_mb, [row])
  defp required_contacts(row, callbacks), do: callback(callbacks, :required_contacts, [row])
  defp planned_contacts(row, callbacks), do: callback(callbacks, :planned_contacts, [row])
  defp downlink_objective?(row, callbacks), do: callback(callbacks, :downlink_objective?, [row])

  defp collection_latency_objective?(row, callbacks),
    do: callback(callbacks, :collection_latency_objective?, [row])

  defp collection_latency_gap?(row, callbacks),
    do: callback(callbacks, :collection_latency_gap?, [row])

  defp primary_target_id(row, callbacks), do: callback(callbacks, :primary_target_id, [row])
  defp station_id(row, callbacks), do: callback(callbacks, :station_id, [row])
  defp collection_id(row, callbacks), do: callback(callbacks, :collection_id, [row])
  defp product_id(row, callbacks), do: callback(callbacks, :product_id, [row])
  defp product_ids(row, callbacks), do: callback(callbacks, :product_ids, [row])
  defp payload_id(row, callbacks), do: callback(callbacks, :payload_id, [row])
  defp instrument_id(row, callbacks), do: callback(callbacks, :instrument_id, [row])

  defp latency_window_start_s(row, callbacks),
    do: callback(callbacks, :latency_window_start_s, [row])

  defp latency_window_end_s(row, callbacks), do: callback(callbacks, :latency_window_end_s, [row])
  defp max_latency_s(row, callbacks), do: callback(callbacks, :max_latency_s, [row])
  defp planned_latency_s(row, callbacks), do: callback(callbacks, :planned_latency_s, [row])
  defp source_activity_id(row, callbacks), do: callback(callbacks, :source_activity_id, [row])
  defp source_activity_ids(row, callbacks), do: callback(callbacks, :source_activity_ids, [row])

  defp downlink_reasons(row, contact_gap?, volume_gap?, latency_gap?, callbacks),
    do: callback(callbacks, :downlink_reasons, [row, contact_gap?, volume_gap?, latency_gap?])

  defp trust_boundary(row, callbacks), do: callback(callbacks, :trust_boundary, [row])
  defp gap_target_ids(row, callbacks), do: callback(callbacks, :gap_target_ids, [row])

  defp required_observations(row, callbacks),
    do: callback(callbacks, :required_observations, [row])

  defp planned_observations(row, callbacks), do: callback(callbacks, :planned_observations, [row])
  defp has_missed_targets?(row, callbacks), do: callback(callbacks, :has_missed_targets?, [row])

  defp target_spec(row, target_id, callbacks),
    do: callback(callbacks, :target_spec, [row, target_id])

  defp target_priority(row, target_spec, callbacks),
    do: callback(callbacks, :target_priority, [row, target_spec])

  defp target_number(row, target_spec, field, callbacks),
    do: callback(callbacks, :target_number, [row, target_spec, field])

  defp target_reasons(row, callbacks), do: callback(callbacks, :target_reasons, [row])

  defp default_callbacks do
    [
      compact_map: &ValueEncoding.compact_map/1,
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      json_boolean_value: &ScalarValues.json_boolean_value/1,
      scenario_id: &ScoreTermIdentifiers.scenario_id/1,
      required_downlink_mb: &ObjectiveTradeoffMetrics.required_downlink_mb/1,
      planned_downlink_mb: &ObjectiveTradeoffMetrics.planned_downlink_mb/1,
      required_contacts: &ObjectiveTradeoffMetrics.required_contacts/1,
      planned_contacts: &ObjectiveTradeoffMetrics.planned_contacts/1,
      downlink_objective?: &ObjectiveTradeoffMetrics.downlink_objective?/1,
      collection_latency_objective?: &ObjectiveTradeoffMetrics.collection_latency_objective?/1,
      collection_latency_gap?: &ObjectiveTradeoffMetrics.collection_latency_gap?/1,
      primary_target_id: &ScoreTermIdentifiers.primary_target_id/1,
      station_id: &ScoreTermIdentifiers.station_id/1,
      collection_id: &ScoreTermIdentifiers.collection_id/1,
      product_id: &ScoreTermIdentifiers.product_id/1,
      product_ids: &ScoreTermIdentifiers.product_ids/1,
      payload_id: &ScoreTermIdentifiers.payload_id/1,
      instrument_id: &ScoreTermIdentifiers.instrument_id/1,
      latency_window_start_s: &ObjectiveTradeoffMetrics.latency_window_start_s/1,
      latency_window_end_s: &ObjectiveTradeoffMetrics.latency_window_end_s/1,
      max_latency_s: &ObjectiveTradeoffMetrics.max_latency_s/1,
      planned_latency_s: &ObjectiveTradeoffMetrics.planned_latency_s/1,
      source_activity_id: &ObjectiveActivityIdentifiers.tradeoff_source_activity_id/1,
      source_activity_ids: &ObjectiveActivityIdentifiers.tradeoff_source_activity_ids/1,
      downlink_reasons: &ObjectiveTradeoffMetrics.downlink_reasons/4,
      trust_boundary: &ObjectiveTradeoffMetrics.trust_boundary/1,
      gap_target_ids: &ObjectiveTradeoffTargets.gap_target_ids/1,
      required_observations: &ObjectiveTradeoffTargets.required_observations/1,
      planned_observations: &ObjectiveTradeoffTargets.planned_observations/1,
      has_missed_targets?: &ObjectiveTradeoffTargets.has_missed_targets?/1,
      target_spec: &ObjectiveTargetIdentifiers.target_spec/2,
      target_priority: &ObjectiveTradeoffTargets.target_priority/2,
      target_number: &ObjectiveTradeoffTargets.target_number/3,
      target_reasons: &ObjectiveTradeoffTargets.target_reasons/1
    ]
  end
end
