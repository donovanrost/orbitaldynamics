defmodule OrbitalDynamics.OperationalReadiness.OperatorTrainingEvidence do
  @moduledoc false

  alias OrbitalDynamics.OperationalReadiness.EvidenceNormalization

  def context(artifact, review_rows, import_rows) do
    maps = evidence_maps(artifact, review_rows, import_rows)

    roles =
      maps
      |> Enum.flat_map(&role_values/1)
      |> stable_sorted_values()

    training_ids =
      maps
      |> Enum.flat_map(&training_values/1)
      |> stable_sorted_values()

    certification_ids =
      maps
      |> Enum.flat_map(&certification_values/1)
      |> stable_sorted_values()

    qualification_ids =
      maps
      |> Enum.flat_map(&qualification_values/1)
      |> stable_sorted_values()

    requirement_counts =
      %{
        "operator_role" => length(roles),
        "training" => length(training_ids),
        "certification" => length(certification_ids),
        "qualification" => length(qualification_ids)
      }
      |> Enum.filter(fn {_kind, count} -> count > 0 end)
      |> Map.new()

    %{
      "operator_training_requirement_count" =>
        EvidenceNormalization.map_value_count(requirement_counts),
      "operator_training_requirement_counts" => requirement_counts,
      "required_operator_roles" => roles,
      "required_training_ids" => training_ids,
      "required_certification_ids" => certification_ids,
      "required_qualification_ids" => qualification_ids
    }
  end

  defp evidence_maps(artifact, review_rows, import_rows) do
    [artifact | review_rows ++ import_rows]
    |> Enum.flat_map(&nested_maps/1)
    |> Enum.filter(&is_map/1)
  end

  defp nested_maps(%{} = row) do
    [
      row,
      row["operator_training"],
      row["training_requirements"],
      row["source_review_row"],
      row["source_operational_readiness_gate"],
      get_in(row, ["source_review_row", "operator_training"]),
      get_in(row, ["source_review_row", "training_requirements"]),
      get_in(row, ["source_review_row", "source_operational_readiness_gate"])
    ]
    |> Enum.filter(&is_map/1)
  end

  defp nested_maps(_row), do: []

  defp role_values(row) do
    list_values(row, ~w(
      required_operator_role
      required_operator_roles
      required_role
      required_roles
      operator_role
      operator_roles
    ))
  end

  defp training_values(row) do
    list_values(row, ~w(
      required_training_id
      required_training_ids
      required_operator_training_id
      required_operator_training_ids
      training_requirement_id
      training_requirement_ids
    ))
  end

  defp certification_values(row) do
    list_values(row, ~w(
      required_certification_id
      required_certification_ids
      required_operator_certification_id
      required_operator_certification_ids
      certification_requirement_id
      certification_requirement_ids
    ))
  end

  defp qualification_values(row) do
    list_values(row, ~w(
      required_qualification_id
      required_qualification_ids
      required_operator_qualification_id
      required_operator_qualification_ids
      qualification_requirement_id
      qualification_requirement_ids
    ))
  end

  defp list_values(row, fields) do
    Enum.flat_map(fields, fn field ->
      row
      |> Map.get(field)
      |> EvidenceNormalization.list_value()
    end)
  end

  defp stable_sorted_values(values) do
    values
    |> Enum.map(&EvidenceNormalization.normalized_evidence_string/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end
end
