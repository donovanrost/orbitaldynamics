defmodule OrbitalDynamics.Schema.CampaignRepairApprovalRequirementActivityContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    RepairAccumulator,
    RepairActivityIdentity
  }

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @context_identity_fields ["activity_id", "activity_type"]

  def validate(
        issues,
        %{"activities" => activities, "approval_requirements" => requirements} = artifact
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

    deltas_by_related_activity_id =
      case Map.get(artifact, "deltas") do
        deltas when is_list(deltas) -> index_deltas_by_related_activity_id(deltas)
        _missing_or_invalid_deltas -> %{}
      end

    requirements
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {%{} = requirement, index}, acc ->
        validate_requirement(
          acc,
          "$.approval_requirements[#{index}]",
          requirement,
          Map.get(activities_by_id, Map.get(requirement, "activity_id"), []),
          Map.get(
            deltas_by_related_activity_id,
            Map.get(requirement, "activity_id"),
            []
          )
        )

      {_requirement, _index}, acc ->
        acc
    end)
  end

  def validate(issues, _artifact), do: issues

  defp index_deltas_by_related_activity_id(deltas) do
    Enum.reduce(deltas, %{}, fn
      %{} = delta, acc ->
        delta
        |> related_activity_ids()
        |> Enum.reduce(acc, fn activity_id, index ->
          Map.update(index, activity_id, [delta], &[delta | &1])
        end)

      _delta, acc ->
        acc
    end)
  end

  defp related_activity_ids(delta) do
    [Map.get(delta, "activity_id"), Map.get(delta, "replacement_activity_id")]
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
  end

  defp validate_requirement(
         issues,
         path,
         requirement,
         matching_activities,
         matching_deltas
       ) do
    issues
    |> validate_reason(path, requirement, matching_activities, matching_deltas)
    |> validate_requirement_type(path, requirement)
    |> validate_context_identity(path, requirement)
    |> validate_selected_activity_context(path, requirement, matching_activities)
  end

  defp validate_reason(issues, path, requirement, matching_activities, matching_deltas) do
    expected = approval_reason(matching_activities, matching_deltas)

    case {Map.get(requirement, "reason"), expected} do
      {actual, expected} when is_binary(actual) and is_binary(expected) and actual != expected ->
        [
          error(
            path <> ".reason",
            "must match the uniquely identified selected activity or related delta reason"
          )
          | issues
        ]

      _matching_or_unreplayable ->
        issues
    end
  end

  defp approval_reason([activity], _matching_deltas) do
    case get_in(activity, ["repair", "reason"]) do
      reason when is_binary(reason) -> reason
      _missing_or_invalid_reason -> nil
    end
  end

  defp approval_reason(_missing_or_ambiguous_activity, matching_deltas),
    do: unique_delta_reason(matching_deltas)

  defp unique_delta_reason([delta]) do
    case Map.get(delta, "reason") do
      reason when is_binary(reason) -> reason
      _missing_or_invalid_reason -> nil
    end
  end

  defp unique_delta_reason(_missing_or_ambiguous_delta), do: nil

  defp validate_requirement_type(issues, path, requirement) do
    case {Map.get(requirement, "action"), Map.get(requirement, "activity_type"),
          Map.get(requirement, "requirement_type")} do
      {action, activity_type, actual}
      when is_binary(action) and is_binary(activity_type) and is_binary(actual) ->
        expected =
          RepairAccumulator.approval_requirement_type(action, %{"type" => activity_type})

        if actual == expected do
          issues
        else
          [
            error(
              path <> ".requirement_type",
              "must match the requirement type derived from action and activity_type"
            )
            | issues
          ]
        end

      _missing_or_unreplayable ->
        issues
    end
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
