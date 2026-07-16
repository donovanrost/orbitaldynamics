defmodule OrbitalDynamics.CampaignPlanner.MissionStateResourceSources do
  @moduledoc false

  alias OrbitalDynamics.ResourceSummary

  alias OrbitalDynamics.CampaignPlanner.{
    OperationalFeedbackNormalization,
    ScalarValues,
    ValueEncoding
  }

  def summaries(mission_state), do: summaries(mission_state, callbacks())

  def summaries(mission_state, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    resources =
      mission_state
      |> Map.get("resources", %{})
      |> stringify_keys.()

    resources
    |> summary_sources(mission_state, callbacks)
    |> ResourceSummary.to_maps()
  end

  def summary_inputs(mission_state), do: summary_inputs(mission_state, callbacks())

  def summary_inputs(mission_state, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    case Map.get(mission_state, "resource_summaries") do
      summaries when is_list(summaries) and summaries != [] ->
        summaries

      _other ->
        summaries(mission_state, callbacks)
    end
    |> Enum.map(&stringify_keys.(&1))
  end

  def source_path(mission_state, field) do
    if explicit_summaries?(mission_state) do
      "mission_state.resource_summaries.#{field}"
    else
      "mission_state.resources.#{field}"
    end
  end

  def explicit_summaries?(mission_state) do
    case Map.get(mission_state, "resource_summaries") do
      summaries when is_list(summaries) and summaries != [] -> true
      _other -> false
    end
  end

  def unavailable_sources(mission_state, field),
    do: unavailable_sources(mission_state, field, callbacks())

  def unavailable_sources(mission_state, field, callbacks) do
    mission_state
    |> summary_inputs(callbacks)
    |> Enum.map(&normalize_availability_source(&1, mission_state, callbacks))
    |> Enum.filter(&(&1[field] == false and &1["spacecraft_id"] not in [nil, ""]))
    |> Enum.sort_by(& &1["spacecraft_id"])
  end

  def lowest_margin_source(mission_state, field),
    do: lowest_margin_source(mission_state, field, callbacks())

  def lowest_margin_source(mission_state, field, callbacks) do
    source =
      mission_state
      |> margin_sources(field, callbacks)
      |> List.first()

    source || raw_margin_source(mission_state, field, callbacks)
  end

  def margin_sources(mission_state, field), do: margin_sources(mission_state, field, callbacks())

  def margin_sources(mission_state, field, callbacks) do
    mission_state
    |> metric_sources(callbacks)
    |> Enum.filter(&(is_number(&1[field]) and &1["spacecraft_id"] not in [nil, ""]))
    |> Enum.sort_by(&{&1[field], &1["spacecraft_id"]})
    |> case do
      [] ->
        case raw_margin_source(mission_state, field, callbacks) do
          nil -> []
          source -> [source]
        end

      sources ->
        sources
    end
  end

  def metric_sources(mission_state), do: metric_sources(mission_state, callbacks())

  def metric_sources(mission_state, callbacks) do
    mission_state
    |> summary_inputs(callbacks)
    |> Enum.map(&normalize_metric_source(&1, mission_state, callbacks))
  end

  def spacecraft_id(mission_state), do: spacecraft_id(mission_state, callbacks())

  def spacecraft_id(mission_state, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    mission_state
    |> Map.get("spacecraft_states", [])
    |> Enum.map(&stringify_keys.(&1))
    |> Enum.find_value(fn state ->
      Map.get(state, "scenario_id") || Map.get(state, "spacecraft_id") || Map.get(state, "id")
    end) || "mission_state_resources"
  end

  defp normalize_availability_source(summary, mission_state, callbacks) do
    normalize_resource_availability_aliases =
      Keyword.fetch!(callbacks, :normalize_resource_availability_aliases)

    summary
    |> normalize_metric_source(mission_state, callbacks)
    |> normalize_resource_availability_aliases.()
  end

  defp normalize_metric_source(summary, mission_state, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    summary =
      summary
      |> stringify_keys.()
      |> Map.put_new(
        "spacecraft_id",
        Map.get(stringify_keys.(summary), "scenario_id") ||
          spacecraft_id(mission_state, callbacks)
      )

    summary
    |> List.wrap()
    |> ResourceSummary.to_maps()
    |> List.first()
  rescue
    ArgumentError ->
      summary
  end

  defp raw_margin_source(mission_state, field, callbacks) do
    if explicit_summaries?(mission_state) do
      nil
    else
      stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
      numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

      resources =
        mission_state
        |> Map.get("resources", %{})
        |> stringify_keys.()

      value =
        Map.get(resources, field) ||
          if(field == "downlink_margin", do: Map.get(resources, "downlink_capacity_margin"))

      case numeric_or_nil.(value) do
        margin when is_number(margin) ->
          %{
            "spacecraft_id" => spacecraft_id(mission_state, callbacks),
            field => margin,
            "source_quality" => "operator_supplied",
            "provenance" => %{"source" => "mission_state.resources"}
          }

        _value ->
          nil
      end
    end
  end

  defp summary_sources(resources, mission_state, callbacks) when is_list(resources) do
    resources
    |> Enum.map(&summary_source(&1, mission_state, "mission_state.resources", callbacks))
    |> Enum.reject(&is_nil/1)
  end

  defp summary_sources(resources, mission_state, callbacks) when is_map(resources) do
    nested_sources =
      resources
      |> nested_sources()
      |> Enum.map(&summary_source(&1, mission_state, "mission_state.resources", callbacks))
      |> Enum.reject(&is_nil/1)

    case {nested_sources, summary_source?(resources, callbacks)} do
      {[], true} ->
        [
          summary_source(
            resources,
            mission_state,
            "mission_state.resources",
            callbacks
          )
        ]
        |> Enum.reject(&is_nil/1)

      {sources, _single_source?} ->
        sources
    end
  end

  defp summary_sources(_resources, _mission_state, _callbacks), do: []

  def nested_sources(resources) do
    [
      Map.get(resources, "spacecraft"),
      Map.get(resources, "spacecraft_resources")
    ]
    |> Enum.flat_map(fn
      values when is_list(values) -> values
      %{} = value -> [value]
      _other -> []
    end)
  end

  defp summary_source(source, mission_state, provenance_source, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    normalize_resource_margin_aliases =
      Keyword.fetch!(callbacks, :normalize_resource_margin_aliases)

    normalize_resource_availability_aliases =
      Keyword.fetch!(callbacks, :normalize_resource_availability_aliases)

    source =
      source
      |> stringify_keys.()
      |> normalize_resource_margin_aliases.()
      |> normalize_resource_availability_aliases.()

    if summary_source?(source, callbacks) do
      source
      |> Map.take(source_fields())
      |> Map.put_new(
        "spacecraft_id",
        Map.get(source, "scenario_id") ||
          Map.get(source, "id") ||
          spacecraft_id(mission_state, callbacks)
      )
      |> Map.delete("scenario_id")
      |> Map.put("source_quality", "operator_supplied")
      |> Map.put("assumptions", %{"model" => "mission_state_resources_summary"})
      |> Map.put("provenance", %{"source" => provenance_source})
    end
  end

  defp source_fields do
    [
      "spacecraft_id",
      "scenario_id",
      "mode",
      "fuel_margin",
      "power_margin",
      "battery_capacity_wh",
      "battery_energy_used_wh",
      "battery_state_of_charge",
      "storage_capacity_mb",
      "storage_used_mb",
      "storage_margin",
      "downlink_capacity_mb",
      "downlink_margin",
      "thermal_margin_c",
      "spacecraft_available",
      "payload_available",
      "antenna_available",
      "degraded"
    ]
  end

  defp summary_source?(resources, callbacks) when is_map(resources) do
    normalize_resource_margin_aliases =
      Keyword.fetch!(callbacks, :normalize_resource_margin_aliases)

    normalize_resource_availability_aliases =
      Keyword.fetch!(callbacks, :normalize_resource_availability_aliases)

    resources
    |> normalize_resource_margin_aliases.()
    |> normalize_resource_availability_aliases.()
    |> Map.take(value_fields())
    |> map_size()
    |> Kernel.>(0)
  end

  defp summary_source?(_resources, _callbacks), do: false

  defp value_fields do
    source_fields() -- ["spacecraft_id", "scenario_id"]
  end

  defp callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      normalize_resource_margin_aliases:
        &OperationalFeedbackNormalization.normalize_resource_margin_aliases/1,
      normalize_resource_availability_aliases:
        &OperationalFeedbackNormalization.normalize_resource_availability_aliases/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1
    ]
  end
end
