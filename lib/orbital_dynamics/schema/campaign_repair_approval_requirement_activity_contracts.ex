defmodule OrbitalDynamics.Schema.CampaignRepairApprovalRequirementActivityContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ActivityIdentity, RepairActivityIdentity}

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @context_identity_fields ["activity_id", "activity_type"]

  def validate(
        issues,
        %{"activities" => activities, "approval_requirements" => requirements}
      )
      when is_list(activities) and is_list(requirements) do
    activities_by_id =
      activities
      |> Enum.filter(&is_map/1)
      |> Enum.reduce(%{}, fn activity, acc ->
        if Map.has_key?(activity, "id") do
          Map.update(
            acc,
            ActivityIdentity.activity_id(activity),
            [activity],
            &[activity | &1]
          )
        else
          acc
        end
      end)

    requirements
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {%{} = requirement, index}, acc ->
        validate_requirement(
          acc,
          "$.approval_requirements[#{index}]",
          requirement,
          Map.get(activities_by_id, Map.get(requirement, "activity_id"), [])
        )

      {_requirement, _index}, acc ->
        acc
    end)
  end

  def validate(issues, _artifact), do: issues

  defp validate_requirement(issues, path, requirement, matching_activities) do
    issues
    |> validate_context_identity(path, requirement)
    |> validate_selected_activity_context(path, requirement, matching_activities)
  end

  defp validate_context_identity(issues, path, requirement) do
    case get_in(requirement, ["activity_context", "timeline_identity"]) do
      %{} = identity ->
        Enum.reduce(@context_identity_fields, issues, fn field, acc ->
          validate_context_identity_field(acc, path, requirement, identity, field)
        end)

      _missing_or_invalid_identity ->
        issues
    end
  end

  defp validate_context_identity_field(issues, path, requirement, identity, field) do
    case {Map.get(requirement, field), Map.get(identity, field)} do
      {actual, expected}
      when is_binary(actual) and is_binary(expected) and actual != expected ->
        [
          error(
            path <> ".#{field}",
            "must match activity_context.timeline_identity.#{field}"
          )
          | issues
        ]

      _matching_or_unreplayable ->
        issues
    end
  end

  defp validate_selected_activity_context(issues, path, requirement, [activity]) do
    case {Map.get(requirement, "activity_context"), RepairActivityIdentity.context(activity)} do
      {%{} = actual, %{} = expected} when actual != expected ->
        [
          error(
            path <> ".activity_context",
            "must match the uniquely identified selected Repair activity context projection"
          )
          | issues
        ]

      _matching_or_unreplayable ->
        issues
    end
  end

  defp validate_selected_activity_context(
         issues,
         _path,
         _requirement,
         _missing_or_ambiguous_activity
       ),
       do: issues
end
