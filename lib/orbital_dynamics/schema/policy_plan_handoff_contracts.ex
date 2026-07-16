defmodule OrbitalDynamics.Schema.PolicyPlanHandoffContracts do
  @moduledoc false

  @approval_requirement_source_field_pairs [
    {"subject_id", "activity_id"},
    {"activity_id", "activity_id"},
    {"activity_type", "activity_type"},
    {"action", "action"},
    {"required_operator_action", "action"},
    {"approval_status", "policy_classification"},
    {"requirement_type", "requirement_type"},
    {"required_authority", "required_authority"},
    {"policy_bundle_id", "policy_bundle_id"},
    {"rule_id", "rule_id"},
    {"reason", "reason"},
    {"approval_rule_matches", "approval_rule_matches"},
    {"activity_context", "activity_context"},
    {"candidate_diff", "candidate_diff"}
  ]
  @approval_requirement_source_review_fields Enum.map(
                                               [
                                                 "subject_id",
                                                 "activity_id",
                                                 "activity_type",
                                                 "action",
                                                 "required_operator_action",
                                                 "approval_status",
                                                 "requirement_type",
                                                 "required_authority",
                                                 "policy_bundle_id",
                                                 "rule_id",
                                                 "reason",
                                                 "approval_rule_matches",
                                                 "activity_context",
                                                 "candidate_diff",
                                                 "source_requirement"
                                               ],
                                               &{&1, &1}
                                             )
  @plan_delta_source_field_pairs [
    {"subject_id", "activity_id"},
    {"activity_id", "activity_id"},
    {"activity_type", "activity_type"},
    {"repair_action", "repair_action"},
    {"reason", "reason"},
    {"source_timeline_id", "source_timeline_id"},
    {"replacement_activity_id", "replacement_activity_id"},
    {"replacement_timeline_id", "replacement_timeline_id"},
    {"timeline_link", "timeline_link"}
  ]
  @plan_delta_source_review_fields Enum.map(
                                     [
                                       "subject_id",
                                       "activity_id",
                                       "activity_type",
                                       "action",
                                       "required_operator_action",
                                       "approval_status",
                                       "repair_action",
                                       "reason",
                                       "source_timeline_id",
                                       "replacement_activity_id",
                                       "replacement_timeline_id",
                                       "timeline_link",
                                       "source_delta"
                                     ],
                                     &{&1, &1}
                                   )

  def validate_approval_requirement_matches_source(
        issues,
        path,
        %{"source_requirement" => %{} = source_row} = row
      ) do
    if approval_requirement_handoff_row?(row) do
      validate_source_pairs(
        issues,
        path,
        row,
        source_row,
        @approval_requirement_source_field_pairs,
        "source_requirement"
      )
    else
      issues
    end
  end

  def validate_approval_requirement_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_approval_requirement_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if approval_requirement_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @approval_requirement_source_review_fields
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_approval_requirement_matches(issues, _path, _row),
    do: issues

  def validate_plan_delta_matches_source(
        issues,
        path,
        %{"source_delta" => %{} = source_row} = row
      ) do
    if plan_delta_handoff_row?(row) do
      validate_source_pairs(
        issues,
        path,
        row,
        source_row,
        @plan_delta_source_field_pairs,
        "source_delta"
      )
    else
      issues
    end
  end

  def validate_plan_delta_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_plan_delta_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if plan_delta_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @plan_delta_source_review_fields
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_plan_delta_matches(issues, _path, _row), do: issues

  def approval_requirement_handoff_row?(row) do
    Map.get(row, "review_type") == "approval_requirement" or
      Map.get(row, "source_review_type") == "approval_requirement" or
      Map.get(row, "import_action") == "review_approval_requirement"
  end

  def plan_delta_handoff_row?(row) do
    Map.get(row, "review_type") == "plan_delta_review" or
      Map.get(row, "source_review_type") == "plan_delta_review"
  end

  defp validate_source_pairs(issues, path, row, source_row, field_pairs, source_key) do
    Enum.reduce(field_pairs, issues, fn {row_field, source_field}, acc ->
      row_value = Map.get(row, row_field)
      source_value = Map.get(source_row, source_field)

      if not is_nil(row_value) and not is_nil(source_value) and row_value != source_value do
        [error("#{path}.#{row_field}", "must match #{source_key}.#{source_field}") | acc]
      else
        acc
      end
    end)
  end

  defp validate_cadence_source_review_pairs(
         issues,
         path,
         row,
         source_review_row,
         field_pairs
       ) do
    Enum.reduce(field_pairs, issues, fn {source_field, row_field}, acc ->
      source_value = Map.get(source_review_row, source_field)
      row_value = Map.get(row, row_field)

      if not is_nil(source_value) and not is_nil(row_value) and source_value != row_value do
        [
          error(
            "#{path}.source_review_row.#{source_field}",
            "must match #{row_field} on Cadence import row"
          )
          | acc
        ]
      else
        acc
      end
    end)
  end

  defp error(path, message) do
    %{"severity" => "error", "path" => path, "message" => message}
  end
end
