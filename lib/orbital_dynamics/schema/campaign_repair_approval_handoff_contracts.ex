defmodule OrbitalDynamics.Schema.CampaignRepairApprovalHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [indexed_rows: 2, validate_equal: 5, validate_source_copies: 6]

  def validate(issues, %{"approval_requirements" => requirements} = artifact)
      when is_list(requirements) do
    issues
    |> validate_operator_review_handoff(artifact, requirements)
    |> validate_cadence_handoff(artifact, requirements)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         requirements
       ) do
    approval_rows = indexed_rows(Map.get(package, "rows"), &operator_approval_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.approval_requirement_count",
      Map.get(package, "approval_requirement_count"),
      length(requirements),
      "must match enclosing Repair approval requirement count"
    )
    |> validate_equal(
      "$.operator_review_package.rows",
      length(approval_rows),
      length(requirements),
      "must contain one approval-review row per enclosing Repair requirement"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      approval_rows,
      requirements,
      [["source_requirement"]],
      "must match the corresponding enclosing Repair approval requirement"
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _requirements), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         requirements
       ) do
    approval_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_approval_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(approval_rows),
      length(requirements),
      "must contain one approval-import row per enclosing Repair requirement"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      approval_rows,
      requirements,
      [["source_requirement"], ["source_review_row", "source_requirement"]],
      "must match the corresponding enclosing Repair approval requirement"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _requirements), do: issues

  defp operator_approval_row?(row), do: Map.get(row, "review_type") == "approval_requirement"

  defp cadence_approval_row?(row) do
    Map.get(row, "source_review_type") == "approval_requirement" or
      Map.get(row, "import_action") == "review_approval_requirement"
  end
end
