defmodule OrbitalDynamics.CadenceImport.ApprovalContextPolicy do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.JsonNormalization

  def first_requirement(%{"approval_requirements" => requirements})
      when is_list(requirements) do
    requirements
    |> Enum.find(%{}, &is_map/1)
    |> JsonNormalization.stringify_keys()
  end

  def first_requirement(_row), do: %{}

  def first_rule_match(%{"approval_rule_matches" => rule_matches} = row)
      when is_list(rule_matches) do
    preferred_rule_match(rule_matches, row_approval_classification(row))
  end

  def first_rule_match(_row), do: %{}

  def preferred_escalation(escalations, row, source_requirement)
      when is_list(escalations) do
    escalations =
      escalations
      |> Enum.filter(&is_map/1)
      |> Enum.map(&JsonNormalization.stringify_keys/1)

    rule_ids =
      [first_rule_match(row), first_rule_match(source_requirement)]
      |> Enum.map(& &1["rule_id"])
      |> Enum.reject(&is_nil/1)

    Enum.find(escalations, &(Map.get(&1, "rule_id") in rule_ids)) ||
      Enum.find(escalations, %{}, &policy_escalation_context?/1)
  end

  def preferred_escalation(_escalations, _row, _source_requirement), do: %{}

  defp row_approval_classification(%{} = row) do
    row["approval_status"] || get_in(row, ["policy_decision", "classification"])
  end

  defp preferred_rule_match(rule_matches, preferred_classification)
       when is_list(rule_matches) do
    rule_matches =
      rule_matches
      |> Enum.filter(&is_map/1)
      |> Enum.map(&JsonNormalization.stringify_keys/1)

    Enum.find(rule_matches, &(&1["classification"] == preferred_classification)) ||
      List.first(rule_matches) ||
      %{}
  end

  defp policy_escalation_context?(%{} = escalation) do
    Enum.any?(
      ["escalation_level", "escalation_queue", "escalation_role", "required_authority", "sla_s"],
      &Map.has_key?(escalation, &1)
    )
  end

  defp policy_escalation_context?(_escalation), do: false
end
