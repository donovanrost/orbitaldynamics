defmodule OrbitalDynamics.CampaignPlanner.RealizedFeedbackTrustBoundaries do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ContactThroughputFields,
    DownlinkActivityNormalization,
    ObservationQualityValues,
    OperationalFeedbackNormalization,
    RealizedActivitySuccessValues,
    RealizedDownlinkDemandFeedback,
    RealizedFeedbackContext,
    RealizedResourceFeedback
  }

  def activity_boundaries(%{} = activity) do
    [
      Map.get(activity, "trust_boundary"),
      Map.get(activity, "trust_boundaries"),
      get_in(activity, ["provenance", "trust_boundary"]),
      get_in(activity, ["provenance", "trust_boundaries"])
    ]
    |> List.flatten()
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
  end

  def activity_boundaries(_activity), do: []

  def source_summary(source), do: source_summary(source, callbacks())

  def source_summary(%{} = source, callbacks) do
    source = stringify_keys(source)

    trust_boundary =
      Map.get(source, "trust_boundary") || get_in(source, ["provenance", "trust_boundary"])

    feedback_trust_boundaries =
      case Map.get(source, "feedback_trust_boundaries") ||
             get_in(source, ["provenance", "feedback_trust_boundaries"]) do
        %{} = boundaries -> stringify_keys(boundaries)
        _boundaries -> nil
      end

    trust_boundaries =
      [
        trust_boundary,
        Map.get(source, "trust_boundaries"),
        get_in(source, ["provenance", "trust_boundaries"]),
        boundary_values(feedback_trust_boundaries, callbacks)
      ]
      |> List.flatten()
      |> Enum.filter(&(is_binary(&1) and &1 != ""))
      |> Enum.uniq()
      |> Enum.sort()

    singular_trust_boundary =
      case {trust_boundary, trust_boundaries} do
        {trust_boundary, _boundaries} when is_binary(trust_boundary) and trust_boundary != "" ->
          trust_boundary

        {_trust_boundary, [single_boundary]} ->
          single_boundary

        _trust_boundary ->
          nil
      end

    %{
      "trust_boundary_status" => if(trust_boundaries == [], do: "missing", else: "declared"),
      "trust_boundary" => singular_trust_boundary,
      "trust_boundaries" => if(trust_boundaries == [], do: nil, else: trust_boundaries),
      "feedback_trust_boundaries" => feedback_trust_boundaries
    }
  end

  def inferred_boundaries(feedback), do: inferred_boundaries(feedback, callbacks())

  def inferred_boundaries(%{} = feedback, callbacks) do
    normalize_operational_feedback = Keyword.fetch!(callbacks, :normalize_operational_feedback)

    feedback = stringify_keys(feedback)

    trust_boundary =
      Map.get(feedback, "trust_boundary") || get_in(feedback, ["provenance", "trust_boundary"])

    if is_binary(trust_boundary) and trust_boundary != "" do
      feedback
      |> normalize_operational_feedback.()
      |> Enum.reduce(%{}, fn {field, values}, boundaries ->
        if is_map(values) and map_size(values) > 0 do
          field_boundaries =
            values
            |> Map.keys()
            |> Map.new(fn key -> {key, [trust_boundary]} end)

          Map.put(boundaries, field, field_boundaries)
        else
          boundaries
        end
      end)
    else
      %{}
    end
  end

  def inferred_boundaries(_feedback, _callbacks), do: %{}

  def provenance_context(provenance), do: provenance_context(provenance, callbacks())

  def provenance_context(%{} = provenance, callbacks) do
    %{
      "default" => single_provenance_boundary(provenance, callbacks),
      "field_keys" => provenance_field_keys(provenance, callbacks)
    }
  end

  def provenance_context(_provenance, _callbacks), do: %{}

  def event_boundary(trust_boundary, field, key),
    do: event_boundary(trust_boundary, field, key, callbacks())

  def event_boundary(%{"field_keys" => field_keys, "default" => default}, field, key, _callbacks) do
    encoded_key = encode_value(key) || "default"

    case get_in(field_keys, [field, encoded_key]) do
      trust_boundary when is_binary(trust_boundary) and trust_boundary != "" -> trust_boundary
      _trust_boundary -> default
    end
  end

  def event_boundary(trust_boundary, _field, _key, _callbacks)
      when is_binary(trust_boundary) and trust_boundary != "",
      do: trust_boundary

  def event_boundary(_trust_boundary, _field, _key, _callbacks), do: nil

  def boundary_values(nil, _callbacks), do: []

  def boundary_values(%{} = feedback_trust_boundaries, _callbacks) do
    feedback_trust_boundaries
    |> stringify_keys()
    |> Enum.flat_map(fn
      {_field, %{} = key_boundaries} ->
        key_boundaries
        |> Enum.flat_map(fn {_key, trust_boundaries} -> List.wrap(trust_boundaries) end)

      {_field, trust_boundaries} ->
        List.wrap(trust_boundaries)
    end)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def boundary_values(_feedback_trust_boundaries, _callbacks), do: []

  def provenance_boundaries(provenance), do: provenance_boundaries(provenance, callbacks())

  def provenance_boundaries(%{} = provenance, _callbacks) do
    provenance = stringify_keys(provenance)

    direct_boundaries = [
      Map.get(provenance, "trust_boundary"),
      Map.get(provenance, "trust_boundaries")
    ]

    nested_boundaries =
      provenance
      |> Map.get("sources", [])
      |> List.wrap()
      |> Enum.flat_map(fn
        %{} = source ->
          source = stringify_keys(source)

          [
            source["trust_boundary"],
            source["trust_boundaries"]
          ]
          |> List.flatten()

        _source ->
          []
      end)

    (direct_boundaries ++ nested_boundaries)
    |> List.flatten()
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def provenance_boundaries(_provenance, _callbacks), do: []

  def merge_maps(boundary_maps), do: merge_maps(boundary_maps, callbacks())

  def merge_maps(boundary_maps, callbacks) do
    boundary_maps
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.reduce(%{}, fn boundaries, merged ->
      boundaries
      |> stringify_keys()
      |> Enum.reduce(merged, fn {field, key_boundaries}, merged ->
        if is_map(key_boundaries) do
          Enum.reduce(key_boundaries, merged, fn {key, trust_boundaries}, merged ->
            put_boundary(merged, field, key, List.wrap(trust_boundaries), callbacks)
          end)
        else
          merged
        end
      end)
    end)
  end

  def put_timeline_boundary(boundaries, field, key, trust_boundary, include?),
    do: put_timeline_boundary(boundaries, field, key, trust_boundary, include?, callbacks())

  def put_timeline_boundary(boundaries, _field, _key, _trust_boundary, false, _callbacks),
    do: boundaries

  def put_timeline_boundary(boundaries, _field, key, _trust_boundary, _include?, _callbacks)
      when key in [nil, ""],
      do: boundaries

  def put_timeline_boundary(boundaries, field, key, trust_boundary, _include?, callbacks) do
    put_boundary(boundaries, field, key, [trust_boundary], callbacks)
  end

  defp single_provenance_boundary(%{} = provenance, callbacks) do
    provenance
    |> provenance_boundaries(callbacks)
    |> case do
      [trust_boundary] -> trust_boundary
      _boundaries -> nil
    end
  end

  defp provenance_field_keys(%{} = provenance, callbacks) do
    effective_sources = Map.get(provenance, "effective_sources", %{})

    provenance
    |> Map.get("sources", [])
    |> Enum.reduce(%{}, fn source, field_keys ->
      source = stringify_keys(source)
      source_name = Map.get(source, "source")

      source
      |> source_boundaries(callbacks)
      |> Enum.reduce(field_keys, fn boundaries, field_keys ->
        merge_source_boundaries(field_keys, boundaries, source_name, effective_sources, callbacks)
      end)
    end)
  end

  defp source_boundaries(source, _callbacks) do
    direct =
      case Map.get(source, "feedback_trust_boundaries") do
        %{} = boundaries -> [boundaries]
        _boundaries -> []
      end

    provenance_direct =
      source
      |> Map.get("source_operational_feedback_provenance", %{})
      |> stringify_keys()
      |> Map.get("feedback_trust_boundaries")
      |> case do
        %{} = boundaries -> [boundaries]
        _boundaries -> []
      end

    nested =
      source
      |> Map.get("source_operational_feedback_provenance", %{})
      |> stringify_keys()
      |> Map.get("sources", [])
      |> Enum.flat_map(fn nested_source ->
        case nested_source |> stringify_keys() |> Map.get("feedback_trust_boundaries") do
          %{} = boundaries -> [boundaries]
          _boundaries -> []
        end
      end)

    direct ++ provenance_direct ++ nested
  end

  defp merge_source_boundaries(field_keys, boundaries, source_name, effective_sources, callbacks) do
    boundaries
    |> stringify_keys()
    |> Enum.reduce(field_keys, fn {field, key_boundaries}, field_keys ->
      if effective_source?(field, source_name, effective_sources) and is_map(key_boundaries) do
        normalized_key_boundaries =
          key_boundaries
          |> stringify_keys()
          |> Enum.reduce(%{}, fn {key, trust_boundaries}, normalized ->
            case unique_boundary(trust_boundaries, callbacks) do
              trust_boundary when is_binary(trust_boundary) ->
                Map.put(normalized, key, trust_boundary)

              _trust_boundary ->
                normalized
            end
          end)

        if map_size(normalized_key_boundaries) == 0 do
          field_keys
        else
          Map.update(field_keys, field, normalized_key_boundaries, fn existing ->
            Map.merge(existing, normalized_key_boundaries)
          end)
        end
      else
        field_keys
      end
    end)
  end

  defp effective_source?(_field, _source_name, effective_sources)
       when not is_map(effective_sources),
       do: true

  defp effective_source?(field, source_name, effective_sources) do
    case Map.get(effective_sources, field) do
      nil -> true
      ^source_name -> true
      _other_source -> false
    end
  end

  defp unique_boundary(trust_boundaries, _callbacks) do
    trust_boundaries
    |> List.wrap()
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> case do
      [trust_boundary] -> trust_boundary
      _trust_boundaries -> nil
    end
  end

  def put_boundary(boundaries, field, key, trust_boundaries),
    do: put_boundary(boundaries, field, key, trust_boundaries, callbacks())

  def put_boundary(boundaries, field, key, trust_boundaries, _callbacks) do
    encoded_key = encode_value(key) || "default"

    Map.update(boundaries, field, %{encoded_key => trust_boundaries}, fn field_boundaries ->
      Map.update(field_boundaries, encoded_key, trust_boundaries, fn existing ->
        (List.wrap(existing) ++ trust_boundaries)
        |> Enum.uniq()
        |> Enum.sort()
      end)
    end)
  end

  def feedback_boundaries(realized_activities),
    do: feedback_boundaries(realized_activities, callbacks())

  def feedback_boundaries(realized_activities, callbacks) do
    Enum.reduce(realized_activities, %{}, fn activity, boundaries ->
      activity_boundaries = activity_boundaries(activity)

      if activity_boundaries == [] do
        boundaries
      else
        boundaries
        |> put_contact_feedback(activity, activity_boundaries, callbacks)
        |> put_observation_feedback(activity, activity_boundaries, callbacks)
        |> put_maneuver_feedback(activity, activity_boundaries, callbacks)
        |> put_command_feedback(activity, activity_boundaries, callbacks)
        |> put_resource_feedback(activity, activity_boundaries, callbacks)
      end
    end)
  end

  defp put_contact_feedback(boundaries, activity, trust_boundaries, callbacks) do
    station_id = Map.get(activity, "ground_station_id") || Map.get(activity, "station_id")

    boundaries =
      if present_key?(station_id) and
           feedback_present?(callbacks, :contact_success_value, activity) do
        put_boundary(boundaries, "contact_success_rate", station_id, trust_boundaries, callbacks)
      else
        boundaries
      end

    boundaries =
      if present_key?(station_id) and
           feedback_present?(callbacks, :station_throughput_value, activity) do
        put_boundary(
          boundaries,
          "station_throughput_factor",
          station_id,
          trust_boundaries,
          callbacks
        )
      else
        boundaries
      end

    downlink_activity? = Keyword.fetch!(callbacks, :downlink_activity?)

    case {downlink_activity?.(activity), value(callbacks, :realized_downlink_demand_mb, activity)} do
      {true, demand} when is_number(demand) and demand > 0.0 ->
        put_boundary(
          boundaries,
          "downlink_demand_mb",
          station_id || "default",
          trust_boundaries,
          callbacks
        )

      _value ->
        boundaries
    end
  end

  defp put_observation_feedback(boundaries, activity, trust_boundaries, callbacks) do
    target_id = Map.get(activity, "target_id")

    boundaries =
      [
        {"observation_success_rate", value(callbacks, :observation_success_value, activity)},
        {"image_quality_score", value(callbacks, :image_quality_score_value, activity)},
        {"image_quality_status", value(callbacks, :image_quality_status_value, activity)},
        {"image_quality_source", value(callbacks, :image_quality_source_value, activity)},
        {"cloud_cover_fraction", value(callbacks, :cloud_cover_fraction_value, activity)},
        {"blur_score", value(callbacks, :blur_score_value, activity)},
        {"target_priority_overrides", value(callbacks, :target_priority_override_value, activity)}
      ]
      |> Enum.reduce(boundaries, fn {field, feedback_value}, boundaries ->
        if present_key?(target_id) and not is_nil(feedback_value) do
          put_boundary(boundaries, field, target_id, trust_boundaries, callbacks)
        else
          boundaries
        end
      end)

    case value(callbacks, :observation_downlink_demand_mb, activity) do
      demand when is_number(demand) and demand > 0.0 ->
        put_boundary(boundaries, "downlink_demand_mb", "default", trust_boundaries, callbacks)

      _value ->
        boundaries
    end
  end

  defp put_maneuver_feedback(boundaries, activity, trust_boundaries, callbacks) do
    activity_id = value(callbacks, :realized_feedback_activity_id, activity)

    if present_key?(activity_id) and
         feedback_present?(callbacks, :maneuver_success_value, activity) do
      put_boundary(boundaries, "maneuver_success_rate", activity_id, trust_boundaries, callbacks)
    else
      boundaries
    end
  end

  defp put_command_feedback(boundaries, activity, trust_boundaries, callbacks) do
    activity_id = value(callbacks, :realized_feedback_activity_id, activity)

    if present_key?(activity_id) and
         feedback_present?(callbacks, :command_success_value, activity) do
      put_boundary(boundaries, "command_success_rate", activity_id, trust_boundaries, callbacks)
    else
      boundaries
    end
  end

  defp put_resource_feedback(boundaries, activity, trust_boundaries, callbacks) do
    spacecraft_id = value(callbacks, :resource_feedback_spacecraft_id, activity)

    if spacecraft_id in [nil, ""] do
      boundaries
    else
      boundaries =
        if value(callbacks, :realized_activity_resource_margins, activity) == %{} do
          boundaries
        else
          put_boundary(
            boundaries,
            "resource_margin_overrides",
            spacecraft_id,
            trust_boundaries,
            callbacks
          )
        end

      if value(callbacks, :realized_activity_resource_availability, activity) == %{} do
        boundaries
      else
        put_boundary(
          boundaries,
          "resource_availability_overrides",
          spacecraft_id,
          trust_boundaries,
          callbacks
        )
      end
    end
  end

  defp feedback_present?(callbacks, key, activity),
    do: not is_nil(value(callbacks, key, activity))

  defp value(callbacks, key, activity) do
    callback = Keyword.fetch!(callbacks, key)
    callback.(activity)
  end

  defp present_key?(value), do: value not in [nil, ""]

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} ->
      {encode_value(key), stringify_keys(value)}
    end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values), do: Enum.map(values, &encode_value/1)
  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp callbacks do
    [
      normalize_operational_feedback: &OperationalFeedbackNormalization.normalize/1,
      contact_success_value: &RealizedActivitySuccessValues.contact/1,
      station_throughput_value: &ContactThroughputFields.station_throughput_value/1,
      downlink_activity?: &DownlinkActivityNormalization.downlink?/1,
      realized_downlink_demand_mb: &RealizedDownlinkDemandFeedback.realized_mb/1,
      observation_success_value: &RealizedActivitySuccessValues.observation/1,
      image_quality_score_value: &ObservationQualityValues.image_quality_score/1,
      image_quality_status_value: &ObservationQualityValues.image_quality_status/1,
      image_quality_source_value: &ObservationQualityValues.image_quality_source/1,
      cloud_cover_fraction_value: &ObservationQualityValues.cloud_cover_fraction/1,
      blur_score_value: &ObservationQualityValues.blur_score/1,
      target_priority_override_value: &target_priority_override_value/1,
      observation_downlink_demand_mb: &RealizedDownlinkDemandFeedback.observation_mb/1,
      realized_feedback_activity_id: &RealizedFeedbackContext.activity_id/1,
      maneuver_success_value: &RealizedActivitySuccessValues.maneuver/1,
      command_success_value: &RealizedActivitySuccessValues.command/1,
      resource_feedback_spacecraft_id: &RealizedResourceFeedback.spacecraft_id/1,
      realized_activity_resource_margins: &RealizedResourceFeedback.activity_resource_margins/1,
      realized_activity_resource_availability:
        &RealizedResourceFeedback.activity_resource_availability/1
    ]
  end

  defp target_priority_override_value(%{"__realized_target_priority" => value})
       when is_number(value),
       do: max(value, 0.0)

  defp target_priority_override_value(_activity), do: nil
end
