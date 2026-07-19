defmodule OrbitalDynamics.ResourceFilter.Summary do
  @moduledoc false

  def build(report, opts) do
    report = stringify_keys(report)
    schema_contract = Keyword.fetch!(opts, :schema_contract)
    source_artifact_type = Keyword.fetch!(opts, :source_artifact_type)
    model_limits = Keyword.fetch!(opts, :model_limits)

    suppressed =
      report
      |> Map.get("suppressed_candidates", [])
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)

    invalid_summary_inputs =
      report
      |> Map.get("invalid_resource_summary_inputs", [])
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)

    %{
      "schema_contract" => schema_contract,
      "model" => "artifact_only_resource_filter_summary",
      "source_artifact_type" => Map.get(report, "schema_contract", source_artifact_type),
      "model_limits" => model_limits,
      "input_candidate_count" => Map.get(report, "input_candidate_count", 0),
      "kept_candidate_count" => Map.get(report, "kept_candidate_count", 0),
      "suppressed_candidate_count" => length(suppressed),
      "suppression_review_status" =>
        if(suppressed == [] and invalid_summary_inputs == [],
          do: "clear",
          else: "review_required"
        ),
      "suppressed_candidate_ids" => row_ids(suppressed, "id"),
      "suppressed_reason_counts" => count_by_field(suppressed, "suppressed_reason"),
      "suppressed_candidate_ids_by_reason" => ids_by_field(suppressed, "suppressed_reason", "id"),
      "resource_blocking_dimension_counts" =>
        count_by_field(suppressed, "resource_blocking_dimension"),
      "suppressed_candidate_ids_by_resource_blocking_dimension" =>
        ids_by_field(suppressed, "resource_blocking_dimension", "id"),
      "suppressed_candidate_ids_by_spacecraft_id" =>
        ids_by_field(suppressed, "spacecraft_id", "id"),
      "suppressed_candidate_ids_by_scenario_id" => ids_by_field(suppressed, "scenario_id", "id"),
      "suppressed_resource_source_quality_counts" =>
        count_by_field(suppressed, "resource_source_quality"),
      "suppressed_candidate_ids_by_resource_source_quality" =>
        ids_by_field(suppressed, "resource_source_quality", "id"),
      "suppressed_resource_trust_boundary_status_counts" =>
        count_by_field(suppressed, "resource_trust_boundary_status"),
      "suppressed_candidate_ids_by_resource_trust_boundary_status" =>
        ids_by_field(suppressed, "resource_trust_boundary_status", "id"),
      "invalid_candidate_input_count" => invalid_candidate_input_count(suppressed),
      "invalid_candidate_input_ids" => invalid_candidate_input_ids(suppressed),
      "invalid_resource_summary_input_count" => length(invalid_summary_inputs),
      "invalid_resource_summary_input_ids" =>
        row_ids(invalid_summary_inputs, "resource_summary_id"),
      "duplicate_suppressed_candidate_id_count" =>
        duplicate_suppressed_candidate_id_count(suppressed),
      "duplicate_suppressed_candidate_row_count" =>
        duplicate_suppressed_candidate_row_count(suppressed),
      "review_rows" => suppressed,
      "invalid_resource_summary_inputs" => invalid_summary_inputs,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "source" => "resource_filter_report.v1",
        "operator_authority" => "not_granted_by_resource_filter_summary",
        "resource_state_propagation" => "not_performed"
      }
    }
    |> compact_map()
  end

  defp count_by_field(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> Enum.sort_by(fn {key, _count} -> key end)
    |> Map.new()
  end

  defp ids_by_field(rows, field, id_field) do
    rows
    |> Enum.map(&{Map.get(&1, field), Map.get(&1, id_field)})
    |> stable_ids_by_key()
  end

  defp row_ids(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> sorted_stable_ids()
  end

  defp invalid_candidate_input_count(suppressed) do
    Enum.count(suppressed, &(&1["invalid_candidate_input"] == true))
  end

  defp invalid_candidate_input_ids(suppressed) do
    suppressed
    |> Enum.filter(&(&1["invalid_candidate_input"] == true))
    |> Enum.map(& &1["id"])
    |> Enum.reject(&is_nil/1)
    |> Enum.sort()
  end

  defp duplicate_suppressed_candidate_id_count(rows) do
    rows
    |> duplicate_suppressed_candidate_id_groups()
    |> length()
  end

  defp duplicate_suppressed_candidate_row_count(rows) do
    rows
    |> duplicate_suppressed_candidate_id_groups()
    |> Enum.map(fn {_candidate_id, duplicate_rows} -> length(duplicate_rows) end)
    |> Enum.sum()
  end

  defp duplicate_suppressed_candidate_id_groups(rows) do
    rows
    |> Enum.group_by(&Map.get(&1, "base_candidate_id", Map.get(&1, "id")))
    |> Enum.filter(fn {_candidate_id, duplicate_rows} -> length(duplicate_rows) > 1 end)
    |> Enum.sort_by(fn {candidate_id, _duplicate_rows} -> candidate_id end)
  end

  defp stable_ids_by_key(pairs) do
    pairs
    |> Enum.reject(fn {key, value} -> key in [nil, ""] or value in [nil, ""] end)
    |> Enum.group_by(fn {key, _value} -> key end, fn {_key, value} -> value end)
    |> Map.new(fn {key, values} -> {key, sorted_stable_ids(values)} end)
  end

  defp sorted_stable_ids(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
