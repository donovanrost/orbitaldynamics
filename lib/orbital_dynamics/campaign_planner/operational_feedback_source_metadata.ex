defmodule OrbitalDynamics.CampaignPlanner.OperationalFeedbackSourceMetadata do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    FeedbackNumericValues,
    OperationalFeedbackNormalization,
    OperationalFeedbackInputValidation,
    RealizedFeedbackTrustBoundaries,
    ScalarValues,
    ValueEncoding
  }

  def source(source, feedback), do: source(source, feedback, %{})

  def source(source, feedback, extra), do: source(source, feedback, extra, default_callbacks())

  def source(source, feedback, extra, callbacks)

  def source(_source, nil, _extra, _callbacks), do: nil

  def source(source, feedback, extra, callbacks) when not is_map(feedback) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    compact_map = Keyword.fetch!(callbacks, :compact_map)

    extra
    |> Map.merge(%{
      "source" => source,
      "input_keys" => ["invalid_operational_feedback_input"],
      "invalid_operational_feedback_input" => true,
      "invalid_operational_feedback_input_reason" =>
        "strategy_operational_feedback_must_be_object",
      "source_operational_feedback" => %{"invalid_feedback_shape" => stringify_keys.(feedback)}
    })
    |> compact_map.()
  end

  def source(source, feedback, extra, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    compact_map = Keyword.fetch!(callbacks, :compact_map)

    feedback = stringify_keys.(feedback)
    input_keys = data_keys(feedback, callbacks)

    invalid_feedback_sections =
      (invalid_sections(feedback, callbacks) ++
         Map.get(extra, "invalid_operational_feedback_sections", []))
      |> Enum.uniq()

    if input_keys == [] and invalid_feedback_sections == [] do
      nil
    else
      feedback
      |> trust_boundary_summary(callbacks)
      |> Map.merge(extra)
      |> Map.merge(%{
        "source" => source,
        "input_keys" => input_keys
      })
      |> maybe_put_invalid_sections(invalid_feedback_sections)
      |> compact_map.()
    end
  end

  def replay_source(source, feedback, extra, rows, callbacks) do
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    invalid_sections = replay_invalid_sections(rows, callbacks)

    source(source, feedback, extra, callbacks)
    |> case do
      nil when invalid_sections == [] ->
        nil

      nil ->
        extra
        |> Map.merge(%{"source" => source, "input_keys" => []})
        |> put_invalid_sections(invalid_sections)
        |> compact_map.()

      source_map when invalid_sections == [] ->
        source_map

      source_map ->
        source_map
        |> put_invalid_sections(invalid_sections)
        |> compact_map.()
    end
  end

  def replay_source(source, feedback, extra, rows) do
    replay_source(source, feedback, extra, rows, default_callbacks())
  end

  def resolution(sources, input_keys) do
    input_key_set = MapSet.new(input_keys)

    Enum.reduce(sources, {%{}, %{}}, fn source, {effective_sources, overridden_sources} ->
      source_name = source["source"]

      source
      |> Map.get("input_keys", [])
      |> Enum.reduce({effective_sources, overridden_sources}, fn key,
                                                                 {effective_sources,
                                                                  overridden_sources} ->
        cond do
          not is_binary(source_name) or not MapSet.member?(input_key_set, key) ->
            {effective_sources, overridden_sources}

          previous_source = effective_sources[key] ->
            {
              Map.put(effective_sources, key, source_name),
              Map.update(overridden_sources, key, [previous_source], fn sources ->
                Enum.uniq(sources ++ [previous_source])
              end)
            }

          true ->
            {Map.put(effective_sources, key, source_name), overridden_sources}
        end
      end)
    end)
  end

  def replay_invalid_sections(rows, callbacks) do
    OperationalFeedbackInputValidation.replay_sections(rows, callbacks)
  end

  def trust_boundary_context(provenance) do
    RealizedFeedbackTrustBoundaries.provenance_context(provenance)
  end

  def trust_boundary_context(%{} = provenance, callbacks) do
    RealizedFeedbackTrustBoundaries.provenance_context(provenance, callbacks)
  end

  def trust_boundary_context(_provenance, _callbacks), do: %{}

  def feedback_event_trust_boundary(trust_boundary, field, key) do
    RealizedFeedbackTrustBoundaries.event_boundary(trust_boundary, field, key)
  end

  def feedback_event_trust_boundary(trust_boundary, field, key, callbacks) do
    RealizedFeedbackTrustBoundaries.event_boundary(trust_boundary, field, key, callbacks)
  end

  def field_from_source("operational_feedback." <> field), do: field
  def field_from_source(field), do: field

  def override?(feedback), do: override?(feedback, default_callbacks())

  def override?(nil, _callbacks), do: false
  def override?(feedback, _callbacks) when not is_map(feedback), do: true

  def override?(feedback, callbacks) do
    data_keys(feedback, callbacks) != [] or invalid_sections(feedback, callbacks) != []
  end

  def put_invalid_sections(source, invalid_sections) do
    OperationalFeedbackInputValidation.put_sections(source, invalid_sections)
  end

  def invalid_sections(feedback, callbacks) when is_map(feedback) do
    OperationalFeedbackInputValidation.sections(feedback, callbacks)
  end

  def invalid_sections(_feedback, _callbacks), do: []

  def put_feedback_trust_boundary(boundaries, field, key, trust_boundaries) do
    RealizedFeedbackTrustBoundaries.put_boundary(boundaries, field, key, trust_boundaries)
  end

  def put_feedback_trust_boundary(boundaries, field, key, trust_boundaries, callbacks) do
    RealizedFeedbackTrustBoundaries.put_boundary(
      boundaries,
      field,
      key,
      trust_boundaries,
      callbacks
    )
  end

  def data_keys(feedback, callbacks) do
    normalize_operational_feedback = Keyword.fetch!(callbacks, :normalize_operational_feedback)

    feedback
    |> normalize_operational_feedback.()
    |> Enum.filter(fn {_key, value} -> value_present?(value) end)
    |> Enum.map(fn {key, _value} -> key end)
    |> Enum.sort()
  end

  def data_keys(feedback), do: data_keys(feedback, default_callbacks())

  def value_present?(%{} = value), do: map_size(value) > 0
  def value_present?(_value), do: false

  def trust_boundary_summary(%{} = source) do
    RealizedFeedbackTrustBoundaries.source_summary(source)
  end

  def trust_boundary_summary(%{} = source, callbacks) do
    RealizedFeedbackTrustBoundaries.source_summary(source, callbacks)
  end

  def inferred_feedback_trust_boundaries(feedback) do
    RealizedFeedbackTrustBoundaries.inferred_boundaries(feedback)
  end

  def inferred_feedback_trust_boundaries(%{} = feedback, callbacks) do
    RealizedFeedbackTrustBoundaries.inferred_boundaries(feedback, callbacks)
  end

  def inferred_feedback_trust_boundaries(_feedback, _callbacks), do: %{}

  def merge_feedback_trust_boundary_maps(boundary_maps) do
    RealizedFeedbackTrustBoundaries.merge_maps(boundary_maps)
  end

  def merge_feedback_trust_boundary_maps(boundary_maps, callbacks) do
    RealizedFeedbackTrustBoundaries.merge_maps(boundary_maps, callbacks)
  end

  defp maybe_put_invalid_sections(source, []), do: source

  defp maybe_put_invalid_sections(source, invalid_sections) do
    put_invalid_sections(source, invalid_sections)
  end

  defp default_callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      compact_map: &ValueEncoding.compact_map/1,
      normalize_operational_feedback: &OperationalFeedbackNormalization.normalize/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      operational_feedback_key?: &OperationalFeedbackNormalization.operational_feedback_key?/1,
      unit_interval_number_status: &FeedbackNumericValues.unit_interval_number_status/1,
      feedback_value_missing?: &feedback_value_missing?/1
    ]
  end

  defp feedback_value_missing?(nil), do: true
  defp feedback_value_missing?(""), do: true
  defp feedback_value_missing?(_value), do: false
end
