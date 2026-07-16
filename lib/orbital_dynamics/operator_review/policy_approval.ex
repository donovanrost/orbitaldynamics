defmodule OrbitalDynamics.OperatorReview.PolicyApproval do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def policy_decision_package(decision) do
    {rows, source_artifact_id, provenance} = policy_decision_package_input(decision)

    build_package(rows, "policy_decision.v1", source_artifact_id, provenance)
  end

  def approval_requirement_package(requirement) do
    {rows, source_artifact_id, provenance} = approval_requirement_package_input(requirement)

    build_package(rows, "approval_requirement.v1", source_artifact_id, provenance)
  end

  def policy_decision_package_input(decision) do
    decision = stringify_keys(decision || %{})

    {
      policy_escalation_rows(decision, "policy_decision.escalations"),
      Map.get(decision, "id") || Map.get(decision, "policy_bundle_id") || "policy_decision",
      Map.get(decision, "provenance", %{})
    }
  end

  def approval_requirement_package_input(requirement) do
    requirement = stringify_keys(requirement || %{})

    {
      approval_rows([requirement], "approval_requirement"),
      Map.get(requirement, "id") || Map.get(requirement, "activity_id") ||
        "approval_requirement",
      Map.get(requirement, "provenance", %{})
    }
  end

  def approval_rows(requirements, source) do
    requirements
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {requirement, index} ->
      rule_match =
        requirement["approval_rule_matches"]
        |> first_map()
        |> stringify_keys()

      policy_decision = stringify_keys(requirement["policy_decision"] || %{})
      policy_escalation = requirement |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" =>
          review_id([
            "approval",
            source,
            requirement["activity_id"],
            requirement["action"],
            index
          ]),
        "review_type" => "approval_requirement",
        "source" => source,
        "subject_id" => requirement["activity_id"],
        "activity_id" => requirement["activity_id"],
        "activity_type" => requirement["activity_type"],
        "action" => requirement["action"],
        "required_operator_action" => requirement["action"],
        "approval_status" => requirement["policy_classification"] || "operator_review_required",
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || rule_match["required_authority"] ||
            policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "reason" => requirement["reason"],
        "approval_rule_matches" => requirement["approval_rule_matches"],
        "activity_context" => requirement["activity_context"],
        "candidate_diff" => requirement["candidate_diff"],
        "source_policy_decision" => requirement["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_requirement" => requirement
      }
      |> put_candidate_diff_fields(requirement["candidate_diff"])
      |> compact_map()
    end)
  end

  def policy_escalation_rows(nil, _source), do: []

  def policy_escalation_rows(%{} = decision, source) do
    decision = stringify_keys(decision)

    decision
    |> Map.get("escalations", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {escalation, index} ->
      rule_id = Map.get(escalation, "rule_id", "policy_escalation")

      %{
        "id" => review_id(["policy_escalation", source, rule_id, index]),
        "review_type" => "policy_escalation",
        "source" => source,
        "subject_id" => rule_id,
        "action" => "review_policy_escalation",
        "required_operator_action" => "review_policy_escalation",
        "approval_status" => Map.get(escalation, "classification", decision["classification"]),
        "reason" => policy_escalation_reason(escalation),
        "policy_bundle_id" => decision["policy_bundle_id"],
        "policy_bundle_provenance" => decision["policy_bundle_provenance"],
        "policy_bundle_provenance_source" =>
          get_in(decision, ["policy_bundle_provenance", "source"]),
        "policy_bundle_adapter" => get_in(decision, ["policy_bundle_provenance", "adapter"]),
        "policy_bundle_organization_id" =>
          get_in(decision, ["policy_bundle_provenance", "organization_id"]),
        "policy_bundle_policy_source" =>
          get_in(decision, ["policy_bundle_provenance", "policy_source"]),
        "rule_id" => rule_id,
        "escalation_level" => escalation["escalation_level"],
        "escalation_queue" => escalation["escalation_queue"],
        "escalation_role" => escalation["escalation_role"],
        "required_authority" => escalation["required_authority"],
        "sla_s" => escalation["sla_s"],
        "source_policy_escalation" => escalation,
        "source_policy_decision" => decision
      }
      |> compact_map()
    end)
  end

  def policy_escalation_rows(_decision, _source), do: []

  defp put_candidate_diff_fields(row, nil), do: row

  defp put_candidate_diff_fields(row, %{} = candidate_diff) do
    row
    |> Map.put("invalidated_candidate_id", candidate_diff["invalidated_candidate_id"])
    |> Map.put("invalidated_candidate_ids", candidate_diff["invalidated_candidate_ids"])
    |> Map.put("replacement_candidate_id", candidate_diff["replacement_candidate_id"])
    |> Map.put("invalidated_reason", candidate_diff["invalidated_reason"])
    |> Map.put("semantic_change_reasons", candidate_diff["semantic_change_reasons"])
    |> Map.put("candidate_diff_match_status", candidate_diff["candidate_diff_match_status"])
    |> Map.put("candidate_diff_match_count", candidate_diff["candidate_diff_match_count"])
    |> Map.put("semantic_match_status", candidate_diff["semantic_match_status"])
    |> Map.put("semantic_match_candidate_count", candidate_diff["semantic_match_candidate_count"])
    |> Map.put("semantic_match_candidate_ids", candidate_diff["semantic_match_candidate_ids"])
    |> Map.put("candidate_budget_match_status", candidate_diff["candidate_budget_match_status"])
    |> Map.put("candidate_budget_match_count", candidate_diff["candidate_budget_match_count"])
    |> Map.put("budget_dropped_candidate_ids", candidate_diff["budget_dropped_candidate_ids"])
  end

  defp policy_escalation_reason(%{"required_authority" => authority}) when is_binary(authority),
    do: "policy escalation requires #{authority}"

  defp policy_escalation_reason(%{"escalation_role" => role}) when is_binary(role),
    do: "policy escalation requires #{role}"

  defp policy_escalation_reason(_escalation), do: "policy escalation requires operator review"

  defp matched_policy_escalation(row) do
    preferred_rule_id =
      row
      |> preferred_approval_rule_match()
      |> Map.get("rule_id")

    rule_ids =
      row
      |> Map.get("approval_rule_matches", [])
      |> List.wrap()
      |> Enum.map(&Map.get(&1, "rule_id"))
      |> Enum.reject(&is_nil/1)

    escalations =
      row
      |> get_in(["policy_decision", "escalations"])
      |> List.wrap()
      |> Enum.filter(&is_map/1)

    escalation =
      Enum.find(escalations, &(Map.get(&1, "rule_id") == preferred_rule_id)) ||
        Enum.find(escalations, &(Map.get(&1, "rule_id") in rule_ids)) ||
        List.first(escalations) ||
        row
        |> Map.get("approval_rule_matches", [])
        |> List.wrap()
        |> Enum.find(&policy_escalation_context?/1)

    escalation || %{}
  end

  defp preferred_approval_rule_match(%{} = row) do
    preferred_classification =
      row["approval_status"] || get_in(row, ["policy_decision", "classification"])

    preferred_approval_rule_match(row["approval_rule_matches"], preferred_classification)
  end

  defp preferred_approval_rule_match(rule_matches, preferred_classification)
       when is_list(rule_matches) do
    rule_matches =
      rule_matches
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)

    Enum.find(rule_matches, &(&1["classification"] == preferred_classification)) ||
      List.first(rule_matches) ||
      %{}
  end

  defp preferred_approval_rule_match(_rule_matches, _preferred_classification), do: %{}

  defp policy_escalation_context?(%{} = row) do
    Enum.any?(
      ["escalation_level", "escalation_queue", "escalation_role", "required_authority", "sla_s"],
      &Map.has_key?(row, &1)
    )
  end

  defp policy_escalation_context?(_row), do: false

  defp first_map(values) when is_list(values), do: Enum.find(values, %{}, &is_map/1)
  defp first_map(_values), do: %{}

  defp non_empty_map(%{} = map) when map_size(map) > 0, do: map
  defp non_empty_map(_map), do: nil

  defp review_id(parts) do
    parts
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(nil), do: nil
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp build_package(rows, source_artifact_type, source_artifact_id, provenance) do
    PackageBuilder.build(
      rows,
      source_artifact_type,
      source_artifact_id,
      provenance,
      @schema_contract,
      Capabilities.model_limits()
    )
  end
end
