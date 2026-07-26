defmodule OrbitalDynamics.Schema.CampaignRepairProvenanceHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @repair_provenance_fields ~w(
    source_plan_id
    source_plan_generated_at
    source_study_id
    source_provenance
    candidate_source
  )

  def validate(issues, %{} = artifact) do
    issues
    |> validate_source_study(artifact)
    |> validate_operator_review_handoff(artifact)
    |> validate_cadence_handoff(artifact)
  end

  def validate(issues, _artifact), do: issues

  defp validate_source_study(
         issues,
         %{"study_id" => study_id, "provenance" => %{} = provenance}
       ) do
    validate_optional_copy(
      issues,
      "$.provenance.source_study_id",
      provenance,
      "source_study_id",
      study_id,
      "must match enclosing Repair study_id"
    )
  end

  defp validate_source_study(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = review_package} = artifact
       ) do
    issues
    |> validate_equal(
      "$.operator_review_package.source_artifact_type",
      Map.get(review_package, "source_artifact_type"),
      "campaign_repair.v2",
      "must identify campaign_repair.v2"
    )
    |> validate_operator_review_provenance(
      Map.get(artifact, "provenance"),
      Map.get(review_package, "provenance")
    )
  end

  defp validate_operator_review_handoff(issues, _artifact), do: issues

  defp validate_operator_review_provenance(
         issues,
         %{} = repair_provenance,
         %{} = review_provenance
       ) do
    Enum.reduce(@repair_provenance_fields, issues, fn field, acc ->
      if Map.has_key?(repair_provenance, field) and Map.has_key?(review_provenance, field) do
        validate_equal(
          acc,
          "$.operator_review_package.provenance.#{field}",
          Map.get(review_provenance, field),
          Map.get(repair_provenance, field),
          "must match enclosing Repair provenance"
        )
      else
        acc
      end
    end)
  end

  defp validate_operator_review_provenance(issues, _repair_provenance, _review_provenance),
    do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{"provenance" => %{} = provenance}} = artifact
       ) do
    issues
    |> validate_optional_copy(
      "$.cadence_import_manifest.provenance.source_artifact_type",
      provenance,
      "source_artifact_type",
      "campaign_repair.v2",
      "must identify campaign_repair.v2"
    )
    |> validate_optional_copy(
      "$.cadence_import_manifest.provenance.source_plan_id",
      provenance,
      "source_plan_id",
      Map.get(artifact, "source_plan_id"),
      "must match enclosing Repair source_plan_id"
    )
  end

  defp validate_cadence_handoff(issues, _artifact), do: issues

  defp validate_optional_copy(issues, path, container, field, expected, message) do
    if Map.has_key?(container, field) do
      validate_equal(issues, path, Map.get(container, field), expected, message)
    else
      issues
    end
  end

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [error(path, message) | issues]
end
