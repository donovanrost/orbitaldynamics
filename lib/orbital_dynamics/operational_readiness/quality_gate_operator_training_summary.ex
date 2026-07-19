defmodule OrbitalDynamics.OperationalReadiness.QualityGateOperatorTrainingSummary do
  @moduledoc false

  @schema_contract "operational_quality_gate_operator_training_summary.v1"

  def build(%{} = quality_gate_report) do
    training_rows = quality_gate_report |> rows() |> operator_training_rows()
    requirement_counts = operator_training_requirement_counts(training_rows)
    quality_gate_row_ids_by_status = quality_gate_row_ids_by_status(training_rows)

    quality_gate_row_ids_by_classification =
      quality_gate_row_ids_by(training_rows, "classification")

    %{
      "schema_contract" => @schema_contract,
      "model" => "artifact_only_quality_gate_operator_training_summary",
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => quality_gate_report["source_artifact_type"],
      "source_artifact_id" => quality_gate_report["source_artifact_id"],
      "source_quality_gate_report_id" => quality_gate_report["report_id"],
      "source_readiness_report_id" => quality_gate_report["source_readiness_report_id"],
      "operator_training_row_count" => length(training_rows),
      "operator_training_requirement_count" => map_value_count(requirement_counts),
      "operator_training_requirement_counts" => requirement_counts,
      "operator_training_requirement_ids" => sorted_count_keys(requirement_counts),
      "required_operator_roles" =>
        training_rows
        |> Enum.flat_map(&list_value(&1["required_operator_roles"]))
        |> stable_sorted_ids(),
      "required_training_ids" =>
        training_rows
        |> Enum.flat_map(&list_value(&1["required_training_ids"]))
        |> stable_sorted_ids(),
      "required_certification_ids" =>
        training_rows
        |> Enum.flat_map(&list_value(&1["required_certification_ids"]))
        |> stable_sorted_ids(),
      "required_qualification_ids" =>
        training_rows
        |> Enum.flat_map(&list_value(&1["required_qualification_ids"]))
        |> stable_sorted_ids(),
      "quality_gate_row_ids_by_status" => quality_gate_row_ids_by_status,
      "quality_gate_row_ids_by_classification" => quality_gate_row_ids_by_classification,
      "quality_gate_ids_by_status" => quality_gate_ids_by(training_rows, "status"),
      "quality_gate_ids_by_classification" =>
        quality_gate_ids_by(training_rows, "classification"),
      "review_required_quality_gate_row_ids" =>
        quality_gate_row_ids_by_status |> Map.get("review_required", []),
      "blocked_quality_gate_row_ids" => quality_gate_row_ids_by_status |> Map.get("blocked", []),
      "review_only_quality_gate_row_ids" =>
        quality_gate_row_ids_by_classification |> Map.get("review_only", []),
      "operator_training_gate_ids" =>
        training_rows
        |> Enum.map(& &1["gate_id"])
        |> stable_sorted_ids(),
      "operator_training_review_required" =>
        Enum.any?(training_rows, &(&1["status"] == "review_required")),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "quality_gate_report.v1",
        "operator_authority" => "not_granted_by_operator_training_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "model_limits" => [
        "quality_gate_operator_training_summary_routes_only",
        "quality_gate_operator_training_summary_does_not_approve_or_import"
      ]
    }
    |> compact_map()
  end

  defp operator_training_rows(rows) do
    Enum.filter(rows, &(&1["gate_id"] == "operator_training"))
  end

  defp operator_training_requirement_counts(rows) do
    rows
    |> Enum.map(&Map.get(&1, "operator_training_requirement_counts"))
    |> merge_positive_count_maps()
  end

  defp rows(%{"rows" => rows}) when is_list(rows), do: Enum.filter(rows, &is_map/1)
  defp rows(_artifact), do: []

  defp positive_count_map(%{} = counts) do
    counts
    |> Enum.filter(fn {_key, value} -> is_integer(value) and value > 0 end)
    |> Map.new()
  end

  defp merge_positive_count_maps(maps) do
    Enum.reduce(maps, %{}, fn
      %{} = counts, acc ->
        counts
        |> positive_count_map()
        |> Enum.reduce(acc, fn {key, count}, inner_acc ->
          Map.update(inner_acc, key, count, &(&1 + count))
        end)

      _counts, acc ->
        acc
    end)
  end

  defp map_value_count(counts) when is_map(counts) do
    counts
    |> Map.values()
    |> Enum.filter(&is_integer/1)
    |> Enum.sum()
  end

  defp sorted_count_keys(counts) when is_map(counts) do
    counts
    |> Map.keys()
    |> stable_sorted_ids()
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(value) when value in [nil, ""], do: []
  defp list_value(value), do: [value]

  defp quality_gate_ids_by(rows, field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), & &1["gate_id"])
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {key, stable_sorted_ids(ids)} end)
  end

  defp quality_gate_row_ids_by_status(rows) do
    rows
    |> Enum.group_by(&Map.get(&1, "status"), & &1["id"])
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {key, stable_sorted_ids(ids)} end)
  end

  defp quality_gate_row_ids_by(rows, field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), & &1["id"])
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {key, stable_sorted_ids(ids)} end)
  end

  defp stable_sorted_ids(ids) do
    ids
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
