defmodule OrbitalDynamics.CandidateRefresh.CollectionLatencyObjectives do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common, only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.ObservationObjectives
  alias OrbitalDynamics.CandidateRefresh.ObjectiveMatching
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue
  alias OrbitalDynamics.CollectionLatencyObjectiveType

  def objectives(refresh, refresh_objectives) do
    refresh
    |> refresh_objectives.()
    |> Enum.filter(fn
      %{"type" => type} ->
        CollectionLatencyObjectiveType.supported?(type)

      _objective ->
        false
    end)
  end

  def observation_context(
        refresh,
        scenario_id,
        target_id,
        policy,
        refresh_objectives,
        policy_number,
        numeric_value
      ) do
    objectives =
      refresh
      |> objectives(refresh_objectives)
      |> Enum.filter(fn objective ->
        ObservationObjectives.matches_candidate?(
          objective,
          refresh,
          scenario_id,
          target_id,
          &ObjectiveMatching.matches_spacecraft?/3,
          &encode_value/1
        )
      end)

    if objectives == [] do
      {%{}, %{}}
    else
      objective_ids =
        objectives
        |> Enum.map(&ObjectiveMatching.id/1)
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> Enum.sort()

      objective_types =
        objectives
        |> Enum.map(&Map.get(&1, "type"))
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> Enum.sort()

      required_downlink_mb =
        objectives
        |> Enum.map(&ObjectiveMatching.required_downlink_mb/1)
        |> Enum.filter(&(is_number(&1) and &1 > 0.0))
        |> Enum.sum()

      max_latency_s =
        objectives
        |> Enum.map(&limit_s(&1, numeric_value))
        |> Enum.filter(&(is_number(&1) and &1 >= 0.0))
        |> Enum.min(fn -> nil end)

      weight =
        policy_number.(
          policy,
          "collection_latency_observation_weight",
          20.0
        )

      context =
        %{
          "collection_latency_objective_count" => length(objectives),
          "collection_latency_objective_ids" => objective_ids,
          "collection_latency_objective_types" => objective_types,
          "collection_latency_objective_source" =>
            "candidate_refresh.objectives.collection_latency",
          "collection_id" => identity_value(objectives, "collection_id"),
          "product_id" => identity_value(objectives, "product_id"),
          "product_ids" => product_ids(objectives),
          "payload_id" => identity_value(objectives, "payload_id"),
          "instrument_id" => identity_value(objectives, "instrument_id"),
          "max_latency_s" => max_latency_s,
          "required_downlink_mb" => if(required_downlink_mb > 0.0, do: required_downlink_mb)
        }
        |> compact_map()

      {context, %{"collection_latency_observation_value" => length(objectives) * weight}}
    end
  end

  defp limit_s(objective, numeric_value) do
    Enum.find_value(["max_latency_s", "required_latency_s", "target_latency_s"], fn field ->
      case numeric_value.(Map.get(objective, field)) do
        value when is_number(value) -> value
        _value -> nil
      end
    end)
  end

  defp identity_value(objectives, field) do
    objectives
    |> Enum.flat_map(&identity_selector_values(&1, identity_aliases(field)))
    |> Enum.uniq()
    |> Enum.sort()
    |> List.first()
  end

  defp product_ids(objectives) do
    values =
      objectives
      |> Enum.flat_map(&identity_selector_values(&1, ["product_ids", "data_product_ids"]))
      |> Enum.uniq()
      |> Enum.sort()

    if values == [], do: nil, else: values
  end

  defp identity_aliases("collection_id"), do: ["collection_id", "collection"]
  defp identity_aliases("product_id"), do: ["product_id", "data_product_id"]
  defp identity_aliases("payload_id"), do: ["payload_id", "payload"]
  defp identity_aliases("instrument_id"), do: ["instrument_id", "instrument"]

  defp identity_selector_values(row, keys) when is_map(row) do
    keys
    |> Enum.flat_map(fn key ->
      case Map.get(row, key) do
        values when is_list(values) -> values
        nil -> []
        value -> [value]
      end
    end)
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp identity_selector_values(_row, _keys), do: []

  defp encode_value(value), do: EncodedValue.value_with_keyword_maps(value)
end
