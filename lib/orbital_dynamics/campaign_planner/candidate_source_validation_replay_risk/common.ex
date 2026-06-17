defmodule OrbitalDynamics.CampaignPlanner.CandidateSourceValidationReplayRisk.Common do
  @moduledoc false

  def readiness_pressure_risk_severity(event) do
    blocked_values = ["blocked", "blocked_by_policy", "review_blocked_operational_readiness"]

    if Enum.any?(
         [
           event["readiness_level"],
           event["import_classification"],
           event["operational_readiness_status"],
           event["readiness_gate_status"],
           event["readiness_gate_classification"],
           event["quality_gate_status"],
           event["gate_status"],
           event["gate_classification"],
           event["required_operator_action"]
         ],
         &(&1 in blocked_values)
       ) do
      "high"
    else
      "medium"
    end
  end

  def pressure_risk_severity(event) do
    high_values = [
      "blocked",
      "fail",
      "error",
      "invalid",
      "review_blocked_validation_safety_case"
    ]

    if Enum.any?(
         [
           event["validation_status"],
           event["issue_severity"],
           event["model_acceptance_status"],
           event["model_status"],
           event["validation_safety_case_status"],
           event["evidence_status"],
           event["freshness_status"],
           event["state_quality_status"],
           event["refresh_budget_status"],
           event["candidate_limit_status"],
           event["required_operator_action"]
         ],
         &(&1 in high_values)
       ) do
      "high"
    else
      "medium"
    end
  end

  def validation_refresh_pressure_risk_severity(event), do: pressure_risk_severity(event)

  def pressure_priority_value(values) do
    priority = [
      "blocked",
      "blocked_by_policy",
      "review_blocked_operational_readiness",
      "review_required",
      "review_only",
      "operator_review",
      "analysis_only"
    ]

    Enum.find(priority, &(&1 in values)) || List.first(values)
  end

  def summary_positive?(summary, field) do
    case numeric_or_nil(Map.get(summary, field)) do
      value when is_number(value) -> value > 0
      _value -> false
    end
  end

  def map_keys(%{} = map), do: map |> Map.keys() |> sorted_encoded_values()
  def map_keys(_map), do: []

  def sorted_encoded_values(values) do
    values
    |> List.wrap()
    |> List.flatten()
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  def numeric_or_nil(nil), do: nil
  def numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  def numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  def numeric_or_nil(_value), do: nil

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
