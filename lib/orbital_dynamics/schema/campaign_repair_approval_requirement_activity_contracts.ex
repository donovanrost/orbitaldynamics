defmodule OrbitalDynamics.Schema.CampaignRepairApprovalRequirementActivityContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ActivityIdentity, RepairActivityIdentity}

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

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

  defp validate_requirement(issues, path, requirement, [activity]) do
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

  defp validate_requirement(issues, _path, _requirement, _missing_or_ambiguous_activity),
    do: issues
end
