defmodule OrbitalDynamics.CampaignPlanner.ScoreTermPressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ObjectivePressureContexts
  alias OrbitalDynamics.CampaignPlanner.ObjectivePressureRows
  alias OrbitalDynamics.CampaignPlanner.ObjectiveTargetIdentifiers
  alias OrbitalDynamics.CampaignPlanner.ScalarValues
  alias OrbitalDynamics.CampaignPlanner.ScoreTermIdentifiers
  alias OrbitalDynamics.CampaignPlanner.ScoreTermPressureMetrics
  alias OrbitalDynamics.CampaignPlanner.ScoreTermValues
  alias OrbitalDynamics.CampaignPlanner.ValueEncoding

  @target_id_fields [
    "target_id",
    "target",
    "target_ids",
    "targets",
    "target_specs",
    "required_target",
    "required_targets",
    "committed_target",
    "committed_targets",
    "priority_target",
    "priority_targets",
    "candidate_target",
    "candidate_targets",
    "uncovered_target",
    "uncovered_targets",
    "unsatisfied_target",
    "unsatisfied_targets",
    "missing_target",
    "missing_targets",
    "missed_target",
    "missed_targets",
    "missed_observation_target",
    "missed_observation_targets",
    "revisit_target",
    "revisit_targets",
    "required_revisit_target",
    "required_revisit_targets",
    "missing_revisit_target",
    "missing_revisit_targets",
    "coverage_target",
    "coverage_targets",
    "required_coverage_target",
    "required_coverage_targets",
    "missing_coverage_target",
    "missing_coverage_targets",
    "target_gap_target",
    "target_gap_targets",
    "missed_target_ids",
    "missed_observation_target_ids",
    "required_target_ids",
    "candidate_target_ids",
    "uncovered_target_ids",
    "unsatisfied_target_ids",
    "missing_target_ids",
    "revisit_target_ids",
    "required_revisit_target_ids",
    "missing_revisit_target_ids",
    "coverage_target_ids",
    "required_coverage_target_ids",
    "missing_coverage_target_ids",
    "target_gap_ids"
  ]

  def branch(row, source_path, index), do: branch(row, source_path, index, callbacks())

  def branch(row, source_path, index, callbacks) do
    row = normalize_row(row)
    events = pressure_events(row, source_path, callbacks)

    case events do
      [] ->
        []

      events ->
        identity =
          row["id"] || row["branch_id"] || row["scenario_id"] ||
            event_identity(events) || index

        [
          %{
            "id" => "derived_score_term_pressure_#{branch_id_fragment(identity, callbacks)}",
            "label" => "Derived score-term pressure #{identity}",
            "events" => events,
            "metadata" =>
              %{
                "derived_source" => source_path,
                "score_term_key" => row["term_key"],
                "score_term_value" => score_term_value(row, callbacks),
                "score_term_selected" => row["selected"]
              }
              |> compact_map(callbacks)
          }
        ]
    end
  end

  def pressure_events(row, source_path, callbacks) do
    row = normalize_row(row)

    []
    |> Kernel.++(collection_latency_gap_events(row, source_path, callbacks))
    |> Kernel.++(downlink_gap_events(row, source_path, callbacks))
    |> Kernel.++(target_gap_events(row, source_path, callbacks))
  end

  def normalize_row(row) do
    row
    |> normalize_field("term_key")
    |> ObjectivePressureRows.normalize()
  end

  defp normalize_field(row, field) do
    case Map.get(row, field) do
      value when value in [nil, ""] -> row
      value -> Map.put(row, field, ScoreTermValues.key(value))
    end
  end

  defp event_identity(events) do
    Enum.find_value(events, fn event ->
      event["ground_station_id"] || event["target_id"] || event["objective_id"]
    end)
  end

  defp collection_latency_gap_events(row, source_path, callbacks) do
    max_latency_s = max_latency_s(row, callbacks)
    planned_latency_s = planned_latency_s(row, callbacks)
    latency_gap = latency_gap(row, callbacks)

    latency_gap? =
      collection_latency_objective?(row, callbacks) and
        (positive_number?(latency_gap, callbacks) or
           (is_number(max_latency_s) and
              (is_nil(planned_latency_s) or planned_latency_s > max_latency_s)))

    if latency_gap? and collection_latency_routed?(row, callbacks) do
      planned_downlink_mb = planned_downlink_mb(row, callbacks)
      downlink_gap = downlink_gap(row, callbacks)

      [
        %{
          "type" => "downlink_completion_gap",
          "objective_id" => row["objective_id"] || row["id"],
          "objective_type" => row["objective"] || row["objective_type"] || "collection_latency",
          "latency_objective" => true,
          "target_id" => primary_target_id(row, callbacks),
          "scenario_id" => scenario_id(row, callbacks),
          "branch_id" => row["branch_id"],
          "ground_station_id" => station_id(row, callbacks),
          "collection_id" => collection_id(row, callbacks),
          "collection_ids" => collection_ids(row, callbacks),
          "product_id" => product_id(row, callbacks),
          "product_ids" => product_ids(row, callbacks),
          "payload_id" => payload_id(row, callbacks),
          "payload_ids" => payload_ids(row, callbacks),
          "instrument_id" => instrument_id(row, callbacks),
          "instrument_ids" => instrument_ids(row, callbacks),
          "starts_at_s" => latency_window_start_s(row, callbacks),
          "ends_at_s" => latency_window_end_s(row, callbacks),
          "required_contacts" => required_contacts(row, contact_gap(row, callbacks), callbacks),
          "planned_contacts" => planned_contacts(row, callbacks),
          "required_downlink_mb" => required_downlink_mb(row, downlink_gap, callbacks),
          "planned_downlink_mb" => planned_downlink_mb,
          "max_latency_s" => max_latency_s,
          "planned_latency_s" => planned_latency_s,
          "source_activity_id" => source_activity_id(row, callbacks),
          "source_activity_ids" => source_activity_ids(row, callbacks),
          "score_term_key" => row["term_key"],
          "score_term_value" => score_term_value(row, callbacks),
          "timeline_score" => numeric_or_nil(row["timeline_score"], callbacks),
          "score_terms" => row["score_terms"],
          "downlink_demand_sources" => [downlink_source(row, callbacks)],
          "downlink_completion_sources" => [downlink_source(row, callbacks)],
          "derivation_reasons" => latency_reasons(row, latency_gap, callbacks),
          "feedback_source" => source_path,
          "feedback_scope" => "score_term",
          "trust_boundary" => trust_boundary(row, callbacks)
        }
        |> compact_map(callbacks)
      ]
    else
      []
    end
  end

  defp downlink_gap_events(row, source_path, callbacks) do
    station_id = station_id(row, callbacks)
    downlink_gap = downlink_gap(row, callbacks)
    contact_gap = contact_gap(row, callbacks)

    cond do
      not stable_id_string?(station_id, callbacks) ->
        []

      not (positive_number?(downlink_gap, callbacks) or positive_number?(contact_gap, callbacks)) ->
        []

      true ->
        planned_downlink_mb = planned_downlink_mb(row, callbacks)
        planned_contacts = planned_contacts(row, callbacks)

        [
          %{
            "type" => "downlink_completion_gap",
            "objective_id" => row["objective_id"] || row["id"],
            "objective_type" => row["objective"] || row["objective_type"] || "score_term_gap",
            "scenario_id" => scenario_id(row, callbacks),
            "branch_id" => row["branch_id"],
            "ground_station_id" => station_id,
            "collection_id" => collection_id(row, callbacks),
            "collection_ids" => collection_ids(row, callbacks),
            "product_id" => product_id(row, callbacks),
            "product_ids" => product_ids(row, callbacks),
            "payload_id" => payload_id(row, callbacks),
            "payload_ids" => payload_ids(row, callbacks),
            "instrument_id" => instrument_id(row, callbacks),
            "instrument_ids" => instrument_ids(row, callbacks),
            "starts_at_s" => window_start_s(row, callbacks),
            "ends_at_s" => window_end_s(row, callbacks),
            "required_contacts" => required_contacts(row, contact_gap, callbacks),
            "planned_contacts" => planned_contacts,
            "required_downlink_mb" => required_downlink_mb(row, downlink_gap, callbacks),
            "planned_downlink_mb" => planned_downlink_mb,
            "source_activity_ids" => source_activity_ids(row, callbacks),
            "score_term_key" => row["term_key"],
            "score_term_value" => score_term_value(row, callbacks),
            "timeline_score" => numeric_or_nil(row["timeline_score"], callbacks),
            "score_terms" => row["score_terms"],
            "downlink_demand_sources" => [downlink_source(row, callbacks)],
            "downlink_completion_sources" => [downlink_source(row, callbacks)],
            "derivation_reasons" => downlink_reasons(row, contact_gap, downlink_gap, callbacks),
            "feedback_source" => source_path,
            "feedback_scope" => "score_term",
            "trust_boundary" => trust_boundary(row, callbacks)
          }
          |> compact_map(callbacks)
        ]
    end
  end

  defp target_gap_events(row, source_path, callbacks) do
    target_gap = target_gap(row, callbacks)

    if positive_number?(target_gap, callbacks) do
      row
      |> gap_target_ids(callbacks)
      |> Enum.map(fn target_id ->
        target_spec = target_spec(row, target_id, callbacks)

        %{
          "type" => "urgent_target",
          "objective_id" => row["objective_id"] || row["id"],
          "objective_type" =>
            row["objective"] || row["objective_type"] || "score_term_target_gap",
          "target_id" => target_id,
          "scenario_id" => scenario_id(row, callbacks),
          "branch_id" => row["branch_id"],
          "starts_at_s" => window_start_s(row, callbacks),
          "ends_at_s" => window_end_s(row, callbacks),
          "priority" => target_priority(row, target_spec, callbacks),
          "latitude_deg" => target_number(row, target_spec, "latitude_deg", callbacks),
          "longitude_deg" => target_number(row, target_spec, "longitude_deg", callbacks),
          "minimum_elevation_deg" =>
            target_number(row, target_spec, "minimum_elevation_deg", callbacks),
          "required_observations" => required_observations(row, target_gap, callbacks),
          "planned_observations" => planned_observations(row, callbacks),
          "source_activity_ids" => source_activity_ids(row, callbacks),
          "score_term_key" => row["term_key"],
          "score_term_value" => score_term_value(row, callbacks),
          "timeline_score" => numeric_or_nil(row["timeline_score"], callbacks),
          "score_terms" => row["score_terms"],
          "derivation_reason" => "score_term_target_gap",
          "derivation_reasons" => target_reasons(row, callbacks),
          "feedback_source" => source_path,
          "feedback_scope" => "score_term",
          "trust_boundary" => trust_boundary(row, callbacks)
        }
        |> compact_map(callbacks)
      end)
    else
      []
    end
  end

  defp collection_latency_routed?(row, callbacks) do
    stable_id_string?(source_activity_id(row, callbacks), callbacks) or
      stable_id_string?(station_id(row, callbacks), callbacks) or
      stable_id_string?(primary_target_id(row, callbacks), callbacks) or
      stable_id_string?(collection_id(row, callbacks), callbacks) or
      stable_id_string?(product_id(row, callbacks), callbacks) or
      stable_id_string?(payload_id(row, callbacks), callbacks) or
      stable_id_string?(instrument_id(row, callbacks), callbacks)
  end

  defp callbacks do
    [
      compact_map: &ValueEncoding.compact_map/1,
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1,
      positive_number?: &ScalarValues.positive_number?/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      scenario_id: &scenario_id/1,
      score_term_value: &ScoreTermValues.value/1,
      downlink_gap: &ScoreTermPressureMetrics.downlink_gap/1,
      contact_gap: &ScoreTermPressureMetrics.contact_gap/1,
      target_gap: &ScoreTermPressureMetrics.target_gap/1,
      latency_gap: &ScoreTermPressureMetrics.latency_gap/1,
      collection_latency_objective?: &ScoreTermPressureMetrics.collection_latency_objective?/1,
      planned_downlink_mb: &ScoreTermPressureMetrics.planned_downlink_mb/1,
      required_downlink_mb: &ScoreTermPressureMetrics.required_downlink_mb/2,
      planned_contacts: &ScoreTermPressureMetrics.planned_contacts/1,
      required_contacts: &ScoreTermPressureMetrics.required_contacts/2,
      planned_observations: &ScoreTermPressureMetrics.planned_observations/1,
      required_observations: &ScoreTermPressureMetrics.required_observations/2,
      max_latency_s: &ScoreTermPressureMetrics.max_latency_s/1,
      planned_latency_s: &ScoreTermPressureMetrics.planned_latency_s/1,
      window_start_s: &ScoreTermPressureMetrics.window_start_s/1,
      window_end_s: &ScoreTermPressureMetrics.window_end_s/1,
      latency_window_start_s: &ScoreTermPressureMetrics.latency_window_start_s/1,
      latency_window_end_s: &ScoreTermPressureMetrics.latency_window_end_s/1,
      primary_target_id: &primary_target_id/1,
      gap_target_ids: &gap_target_ids/1,
      target_spec: &target_spec/2,
      target_priority: &ScoreTermPressureMetrics.target_priority/2,
      target_number: &ScoreTermPressureMetrics.target_number/3,
      station_id: &ScoreTermIdentifiers.station_id/1,
      collection_id: &ScoreTermIdentifiers.collection_id/1,
      collection_ids: &ScoreTermIdentifiers.collection_ids/1,
      product_id: &ScoreTermIdentifiers.product_id/1,
      product_ids: &ScoreTermIdentifiers.product_ids/1,
      payload_id: &ScoreTermIdentifiers.payload_id/1,
      payload_ids: &ScoreTermIdentifiers.payload_ids/1,
      instrument_id: &ScoreTermIdentifiers.instrument_id/1,
      instrument_ids: &ScoreTermIdentifiers.instrument_ids/1,
      source_activity_id: &ScoreTermIdentifiers.source_activity_id/1,
      source_activity_ids: &ScoreTermIdentifiers.source_activity_ids/1,
      downlink_source: &ScoreTermPressureMetrics.downlink_source/1,
      downlink_reasons: &ScoreTermPressureMetrics.downlink_reasons/3,
      target_reasons: &ScoreTermPressureMetrics.target_reasons/1,
      latency_reasons: &ScoreTermPressureMetrics.latency_reasons/2,
      trust_boundary: &ScoreTermPressureMetrics.trust_boundary/1
    ]
  end

  def primary_target_id(row) do
    row
    |> gap_target_ids()
    |> List.first()
  end

  defp scenario_id(row) do
    [
      row["scenario_id"],
      ObjectivePressureContexts.observation_context_value(row, [
        "scenario_id",
        "spacecraft_id",
        "satellite_id"
      ]),
      row["spacecraft_id"],
      row["satellite_id"]
    ]
    |> Enum.find(&ScalarValues.stable_id_string?/1)
  end

  defp gap_target_ids(row) do
    row
    |> ObjectiveTargetIdentifiers.target_id_values(@target_id_fields)
    |> Kernel.++(ObjectivePressureContexts.gap_context_target_ids(row))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp target_spec(row, target_id) do
    ObjectiveTargetIdentifiers.target_spec_from_fields(row, target_id, target_spec_fields(row))
  end

  defp target_spec_fields(row) do
    [
      row["target"],
      row["targets"],
      row["target_specs"],
      row["required_target"],
      row["required_targets"],
      row["committed_target"],
      row["committed_targets"],
      row["priority_target"],
      row["priority_targets"],
      row["candidate_target"],
      row["candidate_targets"],
      row["uncovered_target"],
      row["uncovered_targets"],
      row["unsatisfied_target"],
      row["unsatisfied_targets"],
      row["missing_target"],
      row["missing_targets"],
      row["missed_target"],
      row["missed_targets"],
      row["missed_observation_target"],
      row["missed_observation_targets"],
      row["revisit_target"],
      row["revisit_targets"],
      row["required_revisit_target"],
      row["required_revisit_targets"],
      row["missing_revisit_target"],
      row["missing_revisit_targets"],
      row["coverage_target"],
      row["coverage_targets"],
      row["required_coverage_target"],
      row["required_coverage_targets"],
      row["missing_coverage_target"],
      row["missing_coverage_targets"],
      row["target_gap_target"],
      row["target_gap_targets"]
    ]
  end

  defp callback(callbacks, name, args) do
    callbacks
    |> Keyword.fetch!(name)
    |> then(&apply(&1, args))
  end

  defp compact_map(map, callbacks), do: callback(callbacks, :compact_map, [map])
  defp branch_id_fragment(value, callbacks), do: callback(callbacks, :branch_id_fragment, [value])
  defp positive_number?(value, callbacks), do: callback(callbacks, :positive_number?, [value])
  defp stable_id_string?(value, callbacks), do: callback(callbacks, :stable_id_string?, [value])
  defp numeric_or_nil(value, callbacks), do: callback(callbacks, :numeric_or_nil, [value])
  defp scenario_id(row, callbacks), do: callback(callbacks, :scenario_id, [row])
  defp score_term_value(row, callbacks), do: callback(callbacks, :score_term_value, [row])
  defp downlink_gap(row, callbacks), do: callback(callbacks, :downlink_gap, [row])
  defp contact_gap(row, callbacks), do: callback(callbacks, :contact_gap, [row])
  defp target_gap(row, callbacks), do: callback(callbacks, :target_gap, [row])
  defp latency_gap(row, callbacks), do: callback(callbacks, :latency_gap, [row])

  defp collection_latency_objective?(row, callbacks),
    do: callback(callbacks, :collection_latency_objective?, [row])

  defp planned_downlink_mb(row, callbacks), do: callback(callbacks, :planned_downlink_mb, [row])

  defp required_downlink_mb(row, downlink_gap, callbacks),
    do: callback(callbacks, :required_downlink_mb, [row, downlink_gap])

  defp planned_contacts(row, callbacks), do: callback(callbacks, :planned_contacts, [row])

  defp required_contacts(row, contact_gap, callbacks),
    do: callback(callbacks, :required_contacts, [row, contact_gap])

  defp planned_observations(row, callbacks), do: callback(callbacks, :planned_observations, [row])

  defp required_observations(row, target_gap, callbacks),
    do: callback(callbacks, :required_observations, [row, target_gap])

  defp max_latency_s(row, callbacks), do: callback(callbacks, :max_latency_s, [row])
  defp planned_latency_s(row, callbacks), do: callback(callbacks, :planned_latency_s, [row])
  defp window_start_s(row, callbacks), do: callback(callbacks, :window_start_s, [row])
  defp window_end_s(row, callbacks), do: callback(callbacks, :window_end_s, [row])

  defp latency_window_start_s(row, callbacks),
    do: callback(callbacks, :latency_window_start_s, [row])

  defp latency_window_end_s(row, callbacks), do: callback(callbacks, :latency_window_end_s, [row])
  defp primary_target_id(row, callbacks), do: callback(callbacks, :primary_target_id, [row])
  defp gap_target_ids(row, callbacks), do: callback(callbacks, :gap_target_ids, [row])

  defp target_spec(row, target_id, callbacks),
    do: callback(callbacks, :target_spec, [row, target_id])

  defp target_priority(row, target_spec, callbacks),
    do: callback(callbacks, :target_priority, [row, target_spec])

  defp target_number(row, target_spec, field, callbacks),
    do: callback(callbacks, :target_number, [row, target_spec, field])

  defp station_id(row, callbacks), do: callback(callbacks, :station_id, [row])
  defp collection_id(row, callbacks), do: callback(callbacks, :collection_id, [row])
  defp collection_ids(row, callbacks), do: callback(callbacks, :collection_ids, [row])
  defp product_id(row, callbacks), do: callback(callbacks, :product_id, [row])
  defp product_ids(row, callbacks), do: callback(callbacks, :product_ids, [row])
  defp payload_id(row, callbacks), do: callback(callbacks, :payload_id, [row])
  defp payload_ids(row, callbacks), do: callback(callbacks, :payload_ids, [row])
  defp instrument_id(row, callbacks), do: callback(callbacks, :instrument_id, [row])
  defp instrument_ids(row, callbacks), do: callback(callbacks, :instrument_ids, [row])
  defp source_activity_id(row, callbacks), do: callback(callbacks, :source_activity_id, [row])
  defp source_activity_ids(row, callbacks), do: callback(callbacks, :source_activity_ids, [row])
  defp downlink_source(row, callbacks), do: callback(callbacks, :downlink_source, [row])

  defp downlink_reasons(row, contact_gap, downlink_gap, callbacks),
    do: callback(callbacks, :downlink_reasons, [row, contact_gap, downlink_gap])

  defp target_reasons(row, callbacks), do: callback(callbacks, :target_reasons, [row])

  defp latency_reasons(row, latency_gap, callbacks),
    do: callback(callbacks, :latency_reasons, [row, latency_gap])

  defp trust_boundary(row, callbacks), do: callback(callbacks, :trust_boundary, [row])
end
