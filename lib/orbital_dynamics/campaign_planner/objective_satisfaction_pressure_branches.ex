defmodule OrbitalDynamics.CampaignPlanner.ObjectiveSatisfactionPressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ObjectiveActivityIdentifiers,
    ObjectivePressureRows,
    ObjectiveSatisfactionMetrics,
    ObjectiveSatisfactionTargets,
    ObjectiveTargetIdentifiers,
    ObservationFeedbackEvents,
    ObservationQualityValues,
    ProviderResultValues,
    ScalarValues,
    ScoreTermIdentifiers,
    ValueEncoding
  }

  alias OrbitalDynamics.CollectionLatencyObjectiveType
  alias OrbitalDynamics.TargetObservationObjectiveType
  require CollectionLatencyObjectiveType
  require TargetObservationObjectiveType

  def branch(row, source_path, index, callbacks \\ default_callbacks()) do
    row = normalize_row(row, callbacks)

    row
    |> pressure_events(source_path, callbacks)
    |> Enum.map(fn event ->
      objective_id = branch_identity(row, event, index)

      %{
        "id" => "derived_objective_satisfaction_#{branch_id_fragment(objective_id, callbacks)}",
        "label" => "Derived objective satisfaction pressure #{objective_id}",
        "events" => [event],
        "metadata" =>
          %{
            "derived_source" => source_path,
            "objective" => row["objective"],
            "objective_status" => row["status"],
            "source_objective_status" => row["_source_objective_status"]
          }
          |> compact_map(callbacks)
      }
    end)
  end

  def pressure_events(row, source_path, callbacks \\ default_callbacks())

  def pressure_events(%{"objective" => objective} = row, source_path, callbacks)
      when objective in ["downlink_completion", "required_downlink_completion"] do
    required_contacts = required_contacts(row, callbacks)
    planned_contacts = planned_contacts(row, callbacks)
    required_downlink_mb = required_downlink_mb(row, callbacks)
    planned_downlink_mb = planned_downlink_mb(row, callbacks)

    contact_gap? =
      is_number(required_contacts) and required_contacts > planned_contacts

    volume_gap? =
      is_number(required_downlink_mb) and required_downlink_mb > planned_downlink_mb

    if gap_status?(row["status"], callbacks) and (contact_gap? or volume_gap?) do
      [
        %{
          "type" => "downlink_completion_gap",
          "objective_id" => row["id"],
          "objective_type" => row["objective"],
          "scenario_id" => scenario_id(row, callbacks),
          "ground_station_id" => station_id(row, callbacks),
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
          "required_contacts" => required_contacts,
          "planned_contacts" => planned_contacts,
          "required_downlink_mb" => required_downlink_mb,
          "planned_downlink_mb" => planned_downlink_mb,
          "source_activity_ids" => source_contact_ids(row, callbacks),
          "derivation_reasons" => pressure_reasons(row, contact_gap?, volume_gap?, callbacks),
          "feedback_source" => source_path,
          "feedback_scope" => "objective_satisfaction",
          "objective_status" => row["status"],
          "source_objective_status" => row["_source_objective_status"],
          "trust_boundary" => trust_boundary(row, callbacks)
        }
        |> compact_map(callbacks)
      ]
    else
      []
    end
  end

  def pressure_events(%{"objective" => objective} = row, source_path, callbacks)
      when TargetObservationObjectiveType.is_supported(objective) or
             objective in [
               "target_coverage",
               "coverage",
               "priority_commitment",
               "target_revisit"
             ] do
    if gap_status?(row["status"], callbacks) do
      row
      |> gap_target_ids(callbacks)
      |> Enum.map(&target_event(row, source_path, &1, callbacks))
    else
      []
    end
  end

  def pressure_events(%{"objective" => objective} = row, source_path, callbacks)
      when CollectionLatencyObjectiveType.is_supported(objective) do
    if gap_status?(row["status"], callbacks) do
      [
        row
        |> collection_latency_event(source_path, callbacks)
        |> compact_map(callbacks)
      ]
    else
      []
    end
  end

  def pressure_events(%{"objective" => objective} = row, source_path, callbacks)
      when objective in ["observation_success", "observation_quality", "image_quality"] do
    if gap_status?(row["status"], callbacks) do
      row
      |> observation_quality_event(source_path, callbacks)
      |> case do
        nil -> []
        event -> [event]
      end
    else
      []
    end
  end

  def pressure_events(_row, _source_path, _callbacks), do: []

  def normalize_row(row, callbacks \\ default_callbacks()) do
    row
    |> ObjectivePressureRows.normalize_satisfaction_status(callbacks)
    |> ObjectivePressureRows.normalize()
  end

  defp default_callbacks,
    do: [
      compact_map: &ValueEncoding.compact_map/1,
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      gap_status?: &ObjectivePressureRows.gap_status?/1,
      scenario_id: &ScoreTermIdentifiers.scenario_id/1,
      spacecraft_id: &ScoreTermIdentifiers.spacecraft_id/1,
      station_id: &ScoreTermIdentifiers.station_id/1,
      collection_id: &ScoreTermIdentifiers.collection_id/1,
      collection_ids: &ScoreTermIdentifiers.collection_ids/1,
      product_id: &ScoreTermIdentifiers.product_id/1,
      product_ids: &ScoreTermIdentifiers.product_ids/1,
      payload_id: &ScoreTermIdentifiers.payload_id/1,
      payload_ids: &ScoreTermIdentifiers.payload_ids/1,
      instrument_id: &ScoreTermIdentifiers.instrument_id/1,
      instrument_ids: &ScoreTermIdentifiers.instrument_ids/1,
      json_boolean_value: &ScalarValues.json_boolean_value/1,
      window_start_s: &ObjectiveSatisfactionMetrics.window_start_s/1,
      window_end_s: &ObjectiveSatisfactionMetrics.window_end_s/1,
      required_contacts: &ObjectiveSatisfactionMetrics.required_contacts/1,
      planned_contacts: &ObjectiveSatisfactionMetrics.planned_contacts/1,
      required_downlink_mb: &ObjectiveSatisfactionMetrics.required_downlink_mb/1,
      planned_downlink_mb: &ObjectiveSatisfactionMetrics.planned_downlink_mb/1,
      source_contact_ids: &ObjectiveSatisfactionMetrics.source_contact_ids/1,
      pressure_reasons: &ObjectiveSatisfactionMetrics.pressure_reasons/3,
      trust_boundary: &ObjectiveSatisfactionMetrics.trust_boundary/1,
      gap_target_ids: &ObjectiveSatisfactionTargets.gap_target_ids/1,
      primary_target_id: &ScoreTermIdentifiers.primary_target_id/1,
      observation_success_factor: &ObjectiveSatisfactionMetrics.observation_success_factor/1,
      image_quality_score_value: &ObservationQualityValues.image_quality_score/1,
      image_quality_status_value: &ObservationQualityValues.image_quality_status/1,
      image_quality_source_value: &ObservationQualityValues.image_quality_source/1,
      cloud_cover_fraction_value: &ObservationQualityValues.cloud_cover_fraction/1,
      blur_score_value: &ObservationQualityValues.blur_score/1,
      observation_quality_feedback_factor: &ObservationFeedbackEvents.quality_factor/4,
      target_priority: &ObjectiveSatisfactionTargets.target_priority/2,
      required_target_observations: &ObjectiveSatisfactionTargets.required_target_observations/1,
      source_activity_id: &ObjectiveActivityIdentifiers.source_activity_id/1,
      source_activity_ids: &ObjectiveActivityIdentifiers.source_activity_ids/1,
      observation_quality_reasons: &ObjectiveSatisfactionMetrics.observation_quality_reasons/6,
      quality_feedback_source: &ObjectiveSatisfactionMetrics.quality_feedback_source/1,
      latency_window_start_s: &ObjectiveSatisfactionMetrics.latency_window_start_s/1,
      latency_window_end_s: &ObjectiveSatisfactionMetrics.latency_window_end_s/1,
      required_collection_latency_contacts:
        &ObjectiveSatisfactionMetrics.required_collection_latency_contacts/1,
      max_latency_s: &ObjectiveSatisfactionMetrics.max_latency_s/1,
      planned_latency_s: &ObjectiveSatisfactionMetrics.planned_latency_s/1,
      missed_downlink_activity_id: &ObjectiveActivityIdentifiers.missed_downlink_activity_id/1,
      missed_downlink_activity_ids: &ObjectiveActivityIdentifiers.missed_downlink_activity_ids/1,
      provider_result_artifact_value: &ProviderResultValues.artifact_value/1,
      collection_latency_reasons: &ObjectiveSatisfactionMetrics.collection_latency_reasons/1,
      target_spec: &ObjectiveTargetIdentifiers.target_spec/2,
      target_objective_type: &ObjectiveSatisfactionTargets.target_objective_type/1,
      target_number: &ObjectiveSatisfactionTargets.target_number/3,
      candidate_windows: &ObjectiveSatisfactionTargets.candidate_windows/1,
      allowed_scenario_ids: &ObjectiveSatisfactionTargets.allowed_scenario_ids/1,
      coverage_objective_id: &ObjectiveSatisfactionTargets.coverage_objective_id/1,
      planned_target_observations: &ObjectiveSatisfactionTargets.planned_target_observations/2,
      source_observation_ids: &ObjectiveActivityIdentifiers.source_observation_ids/1,
      target_reasons: &ObjectiveSatisfactionTargets.target_reasons/1
    ]

  defp branch_identity(row, event, index) do
    base = Map.get(row, "id") || Map.get(row, "objective") || index

    case {row["objective"], event["target_id"], event["source_activity_id"]} do
      {objective, target_id, _source_activity_id}
      when objective in ["target_coverage", "coverage"] and target_id not in [nil, ""] ->
        "#{base}:#{target_id}"

      {"collection_latency", _target_id, source_activity_id}
      when source_activity_id not in [nil, ""] ->
        "#{base}:#{source_activity_id}"

      {objective, target_id, _source_activity_id}
      when objective in ["observation_success", "observation_quality", "image_quality"] and
             target_id not in [nil, ""] ->
        "#{base}:#{target_id}"

      {_objective, _target_id, _source_activity_id} ->
        base
    end
  end

  defp observation_quality_event(row, source_path, callbacks) do
    target_id = primary_target_id(row, callbacks)
    explicit_factor = observation_success_factor(row, callbacks)
    image_quality_score = image_quality_score_value(row, callbacks)
    image_quality_status = image_quality_status_value(row, callbacks)
    image_quality_source = image_quality_source_value(row, callbacks)
    cloud_cover_fraction = cloud_cover_fraction_value(row, callbacks)
    blur_score = blur_score_value(row, callbacks)

    quality_evidence? =
      is_number(image_quality_score) or image_quality_status not in [nil, ""] or
        is_number(cloud_cover_fraction) or is_number(blur_score)

    {quality_factor, quality_feedback_source} =
      observation_quality_feedback_factor(
        image_quality_score,
        image_quality_status,
        cloud_cover_fraction,
        blur_score,
        callbacks
      )

    factor = explicit_factor || if(quality_evidence?, do: quality_factor)

    if stable_id_string?(target_id, callbacks) and is_number(factor) do
      %{
        "type" => "observation_success_feedback",
        "objective_id" => row["id"] || row["objective_id"],
        "objective_type" => row["objective"],
        "target_id" => target_id,
        "scenario_id" => scenario_id(row, callbacks),
        "spacecraft_id" => spacecraft_id(row, callbacks),
        "starts_at_s" => window_start_s(row, callbacks),
        "ends_at_s" => window_end_s(row, callbacks),
        "priority" => target_priority(row, %{}, callbacks),
        "required_observations" => required_target_observations(row, callbacks),
        "observation_success_factor" => factor,
        "image_quality_score" => image_quality_score,
        "image_quality_status" => image_quality_status,
        "image_quality_source" => image_quality_source,
        "cloud_cover_fraction" => cloud_cover_fraction,
        "blur_score" => blur_score,
        "source_activity_id" => source_activity_id(row, callbacks),
        "source_activity_ids" => source_activity_ids(row, callbacks),
        "derivation_reasons" =>
          observation_quality_reasons(
            row,
            explicit_factor,
            image_quality_score,
            image_quality_status,
            cloud_cover_fraction,
            blur_score,
            callbacks
          ),
        "feedback_source" => source_path,
        "feedback_scope" => "objective_satisfaction",
        "quality_feedback_source" => quality_feedback_source(quality_feedback_source, callbacks),
        "objective_status" => row["status"],
        "source_objective_status" => row["_source_objective_status"],
        "trust_boundary" => trust_boundary(row, callbacks)
      }
      |> compact_map(callbacks)
    end
  end

  defp collection_latency_event(row, source_path, callbacks) do
    required_downlink_mb = required_downlink_mb(row, callbacks)
    planned_downlink_mb = planned_downlink_mb(row, callbacks)

    %{
      "type" => "downlink_completion_gap",
      "objective_id" => row["id"] || row["objective_id"],
      "objective_type" => CollectionLatencyObjectiveType.canonical(row["objective"]),
      "latency_objective" => true,
      "target_id" => primary_target_id(row, callbacks),
      "scenario_id" => scenario_id(row, callbacks),
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
      "required_contacts" => required_collection_latency_contacts(row, callbacks),
      "planned_contacts" => planned_contacts(row, callbacks),
      "required_downlink_mb" => required_downlink_mb,
      "planned_downlink_mb" => planned_downlink_mb,
      "max_latency_s" => max_latency_s(row, callbacks),
      "planned_latency_s" => planned_latency_s(row, callbacks),
      "source_activity_id" => source_activity_id(row, callbacks),
      "source_activity_ids" => source_activity_ids(row, callbacks),
      "missed_downlink_activity_id" => missed_downlink_activity_id(row, callbacks),
      "missed_downlink_activity_ids" => missed_downlink_activity_ids(row, callbacks),
      "realized_status" => row["realized_status"],
      "contact_result" => provider_result_artifact_value(row["contact_result"], callbacks),
      "derivation_reasons" => collection_latency_reasons(row, callbacks),
      "feedback_source" => source_path,
      "feedback_scope" => "objective_satisfaction",
      "objective_status" => row["status"],
      "source_objective_status" => row["_source_objective_status"],
      "trust_boundary" => trust_boundary(row, callbacks)
    }
  end

  defp target_event(row, source_path, target_id, callbacks) do
    target_spec = target_spec(row, target_id, callbacks)

    %{
      "type" => "urgent_target",
      "objective_id" => row["id"],
      "objective_type" => target_objective_type(row["objective"], callbacks),
      "target_id" => target_id,
      "scenario_id" => scenario_id(row, callbacks),
      "spacecraft_id" => spacecraft_id(row, callbacks),
      "starts_at_s" => window_start_s(row, callbacks),
      "ends_at_s" => window_end_s(row, callbacks),
      "priority" => target_priority(row, target_spec, callbacks),
      "latitude_deg" => target_number(row, target_spec, "latitude_deg", callbacks),
      "longitude_deg" => target_number(row, target_spec, "longitude_deg", callbacks),
      "minimum_elevation_deg" =>
        target_number(row, target_spec, "minimum_elevation_deg", callbacks),
      "candidate_windows" => candidate_windows(row, callbacks),
      "allowed_scenario_ids" => allowed_scenario_ids(row, callbacks),
      "spacecraft_constraints" => allowed_scenario_ids(row, callbacks),
      "coverage_objective_id" => coverage_objective_id(row, callbacks),
      "planned_observations" => planned_target_observations(row, target_id, callbacks),
      "required_observations" => required_target_observations(row, callbacks),
      "source_activity_ids" => source_observation_ids(row, callbacks),
      "derivation_reason" => "objective_satisfaction_#{row["status"]}",
      "derivation_reasons" => target_reasons(row, callbacks),
      "feedback_source" => source_path,
      "feedback_scope" => "objective_satisfaction",
      "objective_status" => row["status"],
      "source_objective_status" => row["_source_objective_status"],
      "trust_boundary" => trust_boundary(row, callbacks)
    }
    |> compact_map(callbacks)
  end

  defp callback(callbacks, name, args) do
    callbacks
    |> Keyword.fetch!(name)
    |> then(&apply(&1, args))
  end

  defp compact_map(map, callbacks), do: callback(callbacks, :compact_map, [map])
  defp branch_id_fragment(value, callbacks), do: callback(callbacks, :branch_id_fragment, [value])
  defp stable_id_string?(value, callbacks), do: callback(callbacks, :stable_id_string?, [value])
  defp gap_status?(status, callbacks), do: callback(callbacks, :gap_status?, [status])
  defp scenario_id(row, callbacks), do: callback(callbacks, :scenario_id, [row])
  defp spacecraft_id(row, callbacks), do: callback(callbacks, :spacecraft_id, [row])
  defp station_id(row, callbacks), do: callback(callbacks, :station_id, [row])
  defp collection_id(row, callbacks), do: callback(callbacks, :collection_id, [row])
  defp collection_ids(row, callbacks), do: callback(callbacks, :collection_ids, [row])
  defp product_id(row, callbacks), do: callback(callbacks, :product_id, [row])
  defp product_ids(row, callbacks), do: callback(callbacks, :product_ids, [row])
  defp payload_id(row, callbacks), do: callback(callbacks, :payload_id, [row])
  defp payload_ids(row, callbacks), do: callback(callbacks, :payload_ids, [row])
  defp instrument_id(row, callbacks), do: callback(callbacks, :instrument_id, [row])
  defp instrument_ids(row, callbacks), do: callback(callbacks, :instrument_ids, [row])
  defp window_start_s(row, callbacks), do: callback(callbacks, :window_start_s, [row])
  defp window_end_s(row, callbacks), do: callback(callbacks, :window_end_s, [row])
  defp required_contacts(row, callbacks), do: callback(callbacks, :required_contacts, [row])
  defp planned_contacts(row, callbacks), do: callback(callbacks, :planned_contacts, [row])
  defp required_downlink_mb(row, callbacks), do: callback(callbacks, :required_downlink_mb, [row])
  defp planned_downlink_mb(row, callbacks), do: callback(callbacks, :planned_downlink_mb, [row])
  defp source_contact_ids(row, callbacks), do: callback(callbacks, :source_contact_ids, [row])

  defp pressure_reasons(row, contact_gap?, volume_gap?, callbacks),
    do: callback(callbacks, :pressure_reasons, [row, contact_gap?, volume_gap?])

  defp trust_boundary(row, callbacks), do: callback(callbacks, :trust_boundary, [row])
  defp gap_target_ids(row, callbacks), do: callback(callbacks, :gap_target_ids, [row])
  defp primary_target_id(row, callbacks), do: callback(callbacks, :primary_target_id, [row])

  defp observation_success_factor(row, callbacks),
    do: callback(callbacks, :observation_success_factor, [row])

  defp image_quality_score_value(row, callbacks),
    do: callback(callbacks, :image_quality_score_value, [row])

  defp image_quality_status_value(row, callbacks),
    do: callback(callbacks, :image_quality_status_value, [row])

  defp image_quality_source_value(row, callbacks),
    do: callback(callbacks, :image_quality_source_value, [row])

  defp cloud_cover_fraction_value(row, callbacks),
    do: callback(callbacks, :cloud_cover_fraction_value, [row])

  defp blur_score_value(row, callbacks), do: callback(callbacks, :blur_score_value, [row])

  defp observation_quality_feedback_factor(score, status, cloud, blur, callbacks),
    do: callback(callbacks, :observation_quality_feedback_factor, [score, status, cloud, blur])

  defp target_priority(row, target_spec, callbacks),
    do: callback(callbacks, :target_priority, [row, target_spec])

  defp required_target_observations(row, callbacks),
    do: callback(callbacks, :required_target_observations, [row])

  defp source_activity_id(row, callbacks), do: callback(callbacks, :source_activity_id, [row])
  defp source_activity_ids(row, callbacks), do: callback(callbacks, :source_activity_ids, [row])

  defp observation_quality_reasons(
         row,
         explicit,
         image_score,
         image_status,
         cloud,
         blur,
         callbacks
       ),
       do:
         callback(callbacks, :observation_quality_reasons, [
           row,
           explicit,
           image_score,
           image_status,
           cloud,
           blur
         ])

  defp quality_feedback_source(source, callbacks),
    do: callback(callbacks, :quality_feedback_source, [source])

  defp latency_window_start_s(row, callbacks),
    do: callback(callbacks, :latency_window_start_s, [row])

  defp latency_window_end_s(row, callbacks), do: callback(callbacks, :latency_window_end_s, [row])

  defp required_collection_latency_contacts(row, callbacks),
    do: callback(callbacks, :required_collection_latency_contacts, [row])

  defp max_latency_s(row, callbacks), do: callback(callbacks, :max_latency_s, [row])
  defp planned_latency_s(row, callbacks), do: callback(callbacks, :planned_latency_s, [row])

  defp missed_downlink_activity_id(row, callbacks),
    do: callback(callbacks, :missed_downlink_activity_id, [row])

  defp missed_downlink_activity_ids(row, callbacks),
    do: callback(callbacks, :missed_downlink_activity_ids, [row])

  defp provider_result_artifact_value(value, callbacks),
    do: callback(callbacks, :provider_result_artifact_value, [value])

  defp collection_latency_reasons(row, callbacks),
    do: callback(callbacks, :collection_latency_reasons, [row])

  defp target_spec(row, target_id, callbacks),
    do: callback(callbacks, :target_spec, [row, target_id])

  defp target_objective_type(objective, callbacks),
    do: callback(callbacks, :target_objective_type, [objective])

  defp target_number(row, target_spec, field, callbacks),
    do: callback(callbacks, :target_number, [row, target_spec, field])

  defp candidate_windows(row, callbacks), do: callback(callbacks, :candidate_windows, [row])
  defp allowed_scenario_ids(row, callbacks), do: callback(callbacks, :allowed_scenario_ids, [row])

  defp coverage_objective_id(row, callbacks),
    do: callback(callbacks, :coverage_objective_id, [row])

  defp planned_target_observations(row, target_id, callbacks),
    do: callback(callbacks, :planned_target_observations, [row, target_id])

  defp source_observation_ids(row, callbacks),
    do: callback(callbacks, :source_observation_ids, [row])

  defp target_reasons(row, callbacks), do: callback(callbacks, :target_reasons, [row])
end
