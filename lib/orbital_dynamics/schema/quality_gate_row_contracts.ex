defmodule OrbitalDynamics.Schema.QualityGateRowContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_non_negative_integer: 4,
      expect_one_of: 5,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  alias OrbitalDynamics.Schema.OperationalReadinessContextContracts

  def validate(
        issues,
        path,
        row,
        source_gate_handoff_validator,
        source_report_handoff_validator,
        timeline_publication_validator
      ) do
    capability = OrbitalDynamics.OperationalReadiness.capabilities()

    issues
    |> require_fields(
      path,
      row,
      ["id", "rank", "gate_id", "status", "classification", "reason"]
    )
    |> validate_stable_ids(path, row, ["id"])
    |> expect_non_negative_integer(path, row, "rank")
    |> expect_one_of(path, row, "gate_id", capability.gates)
    |> expect_one_of(path, row, "status", capability.gate_statuses)
    |> expect_one_of(path, row, "classification", capability.import_classifications)
    |> expect_type(path, row, "reason", :binary)
    |> expect_optional_one_of(path, row, "analysis_mode", capability.analysis_modes)
    |> expect_optional_type(path, row, "analysis_mode_source", :binary)
    |> expect_optional_type(path, row, "source_operational_readiness_gate", :map)
    |> source_gate_handoff_validator.(path, row)
    |> source_report_handoff_validator.(path, row)
    |> OperationalReadinessContextContracts.validate_resource_context(path, row)
    |> OperationalReadinessContextContracts.validate_operator_training_context(path, row)
    |> OperationalReadinessContextContracts.validate_adapter_boundary_context(path, row)
    |> OperationalReadinessContextContracts.validate_cadence_import_context(path, row)
    |> timeline_publication_validator.(path, row)
  end

  def status_count(rows, status) when is_list(rows) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.count(&(Map.get(&1, "status") == status))
  end

  def status_count(_rows, _status), do: nil

  def ids_by(rows, field) when is_list(rows) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.group_by(&Map.get(&1, field), &Map.get(&1, "gate_id"))
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {to_string(key), stable_sorted_ids(ids)} end)
  end

  def ids_by(_rows, _field), do: nil

  def row_ids_by(rows, field) when is_list(rows) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.group_by(&Map.get(&1, field), &Map.get(&1, "id"))
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {to_string(key), stable_sorted_ids(ids)} end)
  end

  def row_ids_by(_rows, _field), do: nil

  def ids(rows, status) when is_list(rows) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.filter(&(Map.get(&1, "status") == status))
    |> Enum.map(&Map.get(&1, "gate_id"))
    |> stable_sorted_ids()
  end

  def ids(_rows, _status), do: nil

  defp stable_sorted_ids(ids) do
    ids
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end
end
