defmodule OrbitalDynamics.Policy.DecisionBuilder do
  @moduledoc false

  alias OrbitalDynamics.Policy.BlockedRiskMatcher

  def build(
        raw_rule_matches,
        approval_requirements,
        risk_indicators,
        policy,
        model_limits,
        escalation_fields
      ) do
    rule_matches =
      raw_rule_matches
      |> Enum.map(&add_policy_bundle_provenance_fields(&1, policy["policy_bundle_provenance"]))
      |> Enum.sort_by(&rule_match_sort_key/1)

    enriched_requirements =
      Enum.map(approval_requirements, fn requirement ->
        matches =
          Enum.filter(rule_matches, fn match ->
            cond do
              not is_nil(match["activity_id"]) ->
                match["activity_id"] == requirement["activity_id"]

              not is_nil(match["action"]) ->
                match["action"] == requirement["action"]

              true ->
                false
            end
          end)

        case matches do
          [] ->
            requirement

          _matches ->
            requirement
            |> Map.put("approval_rule_matches", matches)
            |> Map.put("policy_classification", strongest_classification(matches))
        end
      end)

    status =
      cond do
        Enum.any?(rule_matches, &(&1["classification"] == "blocked_by_policy")) ->
          "blocked_by_policy"

        Enum.any?(rule_matches, &(&1["classification"] == "operator_review_required")) ->
          "operator_review_required"

        approval_requirements != [] and
          Enum.all?(
            enriched_requirements,
            &(&1["policy_classification"] == "auto_approvable")
          ) and
            length(risk_indicators) <= policy["auto_approvable_risk_limit"] ->
          "auto_approvable"

        true ->
          fallback_status(enriched_requirements, risk_indicators, policy)
      end

    decision =
      %{
        "schema_contract" => "policy_decision.v1",
        "classification" => status,
        "model_limits" => model_limits,
        "rule_matches" => rule_matches,
        "escalations" => non_empty_list(escalation_summaries(rule_matches, escalation_fields)),
        "approval_requirement_count" =>
          policy_decision_approval_requirement_count(rule_matches, approval_requirements),
        "risk_count" => policy_decision_risk_count(rule_matches, risk_indicators),
        "policy_bundle_id" => policy["policy_bundle_id"],
        "policy_bundle_provenance" => policy["policy_bundle_provenance"],
        "fallback_policy" => %{
          "auto_approvable_risk_limit" => policy["auto_approvable_risk_limit"],
          "auto_approvable_approval_count_limit" =>
            policy["auto_approvable_approval_count_limit"],
          "operator_review_risk_limit" => policy["operator_review_risk_limit"],
          "blocked_risk_types" => policy["blocked_risk_types"]
        }
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    {status, enriched_requirements, rule_matches, decision}
  end

  defp policy_decision_approval_requirement_count(rule_matches, _approval_requirements)
       when is_list(rule_matches) and rule_matches != [] do
    Enum.count(rule_matches, &(&1["classification"] == "operator_review_required"))
  end

  defp policy_decision_approval_requirement_count(_rule_matches, approval_requirements),
    do: length(approval_requirements)

  defp policy_decision_risk_count(rule_matches, _risk_indicators)
       when is_list(rule_matches) and rule_matches != [] do
    Enum.count(rule_matches, &is_binary(&1["risk_type"]))
  end

  defp policy_decision_risk_count(_rule_matches, risk_indicators), do: length(risk_indicators)

  defp add_policy_bundle_provenance_fields(match, provenance) when is_map(provenance) do
    match
    |> maybe_put("policy_bundle_provenance_source", provenance["source"])
    |> maybe_put("policy_bundle_adapter", provenance["adapter"])
    |> maybe_put("policy_bundle_organization_id", provenance["organization_id"])
    |> maybe_put("policy_bundle_policy_source", provenance["policy_source"])
    |> maybe_put("policy_bundle_trust_boundary", provenance["trust_boundary"])
  end

  defp add_policy_bundle_provenance_fields(match, _provenance), do: match

  defp rule_match_sort_key(match) do
    {
      match["rule_id"] || "",
      match["activity_id"] || "",
      match["action"] || "",
      match["activity_type"] || "",
      match["requirement_type"] || "",
      match["risk_type"] || "",
      match["event_type"] || "",
      match["feasibility_status"] || "",
      match["ground_station_id"] || "",
      match["spacecraft_id"] || "",
      match["target_id"] || "",
      match["resource_scope"] || "",
      match["resolution_status"] || "",
      match["resolution_issue"] || "",
      match["allocation_status"] || "",
      match["effective_allocation_status"] || "",
      match["allocation_reason"] || "",
      match["selection_reason"] || "",
      match["selected_priority_source"] || "",
      match["station_contention_status"] || "",
      match["station_reservation_id"] || "",
      match["station_reserved_by"] || "",
      stable_sort_values(match["station_reserved_bys"]),
      match["station_reservation_status"] || "",
      stable_sort_values(match["station_reservation_statuses"]),
      match["station_reservation_match_status"] || "",
      stable_sort_values(match["station_reservation_match_statuses"]),
      match["station_calendar_entry_id"] || "",
      stable_sort_values(match["station_calendar_entry_ids"]),
      stable_sort_values(match["station_calendar_provider_ids"]),
      stable_sort_values(match["station_calendar_provider_entry_ids"]),
      match["station_calendar_status"] || "",
      stable_sort_values(match["station_calendar_statuses"]),
      stable_sort_values(match["station_calendar_reservation_ids"]),
      stable_sort_values(match["station_calendar_reservation_expires_at_s"]),
      match["risk_reason"] || "",
      match["reason"] || ""
    }
  end

  defp stable_sort_values(values) when is_list(values) do
    values
    |> Enum.map(&to_string/1)
    |> Enum.sort()
    |> Enum.join("|")
  end

  defp stable_sort_values(value) when is_binary(value), do: value
  defp stable_sort_values(_value), do: ""

  defp strongest_classification(matches) do
    cond do
      Enum.any?(matches, &(&1["classification"] == "blocked_by_policy")) ->
        "blocked_by_policy"

      Enum.any?(matches, &(&1["classification"] == "operator_review_required")) ->
        "operator_review_required"

      true ->
        "auto_approvable"
    end
  end

  defp escalation_summaries(rule_matches, escalation_fields) do
    rule_matches
    |> Enum.map(fn match ->
      escalation_fields
      |> Enum.reduce(
        %{"rule_id" => match["rule_id"], "classification" => match["classification"]},
        fn
          field, acc ->
            case Map.fetch(match, field) do
              {:ok, value} -> Map.put(acc, field, value)
              :error -> acc
            end
        end
      )
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()
    end)
    |> Enum.filter(&(map_size(&1) > 2))
    |> Enum.uniq()
    |> Enum.sort_by(&{&1["escalation_level"] || "", &1["rule_id"] || ""})
  end

  defp fallback_status(approval_requirements, risk_indicators, policy) do
    risk_count = length(risk_indicators)
    approval_count = length(approval_requirements)

    cond do
      Enum.any?(risk_indicators, &blocked_risk_indicator?(&1, policy["blocked_risk_types"])) ->
        "blocked_by_policy"

      risk_count <= policy["auto_approvable_risk_limit"] and
          approval_count <= policy["auto_approvable_approval_count_limit"] ->
        "auto_approvable"

      risk_count <= policy["operator_review_risk_limit"] ->
        "operator_review_required"

      true ->
        "blocked_by_policy"
    end
  end

  defp blocked_risk_indicator?(risk, blocked_risk_types),
    do: BlockedRiskMatcher.blocked?(risk, blocked_risk_types)

  defp non_empty_list([]), do: nil
  defp non_empty_list(values), do: values

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
