defmodule OrbitalDynamics.CampaignPlanner.ValidationSafetyCaseSourceReports.PressureRows do
  @moduledoc false

  def pressure_rows(reports) do
    reports
    |> Enum.flat_map(fn {report, source_path} ->
      trust_boundary =
        Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

      report
      |> report_pressure_rows()
      |> Enum.with_index(1)
      |> Enum.map(fn {row, index} ->
        row_source =
          row
          |> Map.get("source", "validation_safety_case_summary")
          |> String.replace_prefix("validation_safety_case_summary", source_path)

        row =
          row
          |> Map.put("_source_report_trust_boundary", trust_boundary)

        {row, row_source, index}
      end)
    end)
  end

  defp report_pressure_rows(report) do
    report = stringify_keys(report || %{})

    evidence_rows =
      report
      |> Map.get("evidence", [])
      |> List.wrap()
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(fn evidence ->
        %{
          "source" => "validation_safety_case_summary.evidence",
          "report_id" => report["report_id"],
          "validation_safety_case_status" => report["status"],
          "evidence_status" => evidence["status"],
          "input_contract" => evidence["input_contract"] || evidence["contract"],
          "input_contracts" => report["input_contracts"],
          "evidence_ref" => evidence["ref"] || evidence["evidence_ref"] || evidence["id"],
          "evidence_count" => report["evidence_count"] || length(List.wrap(report["evidence"])),
          "accepted_evidence_count" => report["accepted_evidence_count"],
          "review_required_evidence_count" => report["review_required_evidence_count"],
          "blocked_evidence_count" => report["blocked_evidence_count"],
          "schema_error_count" => report["schema_error_count"],
          "schema_warning_count" => report["schema_warning_count"],
          "model_blocked_count" => report["model_blocked_count"],
          "quality_gate_review_count" => report["quality_gate_review_count"],
          "quality_gate_blocked_count" => report["quality_gate_blocked_count"],
          "evidence_status_counts" => report["evidence_status_counts"],
          "evidence_refs_by_status" => report["evidence_refs_by_status"],
          "evidence_refs_by_contract" => report["evidence_refs_by_contract"],
          "source_validation_safety_case_evidence" => evidence,
          "source_validation_safety_case_summary" => report
        }
        |> compact_map()
      end)

    if evidence_rows == [] do
      [
        %{
          "source" => "validation_safety_case_summary",
          "report_id" => report["report_id"],
          "validation_safety_case_status" => report["status"],
          "input_contracts" => report["input_contracts"],
          "evidence_count" => report["evidence_count"],
          "accepted_evidence_count" => report["accepted_evidence_count"],
          "review_required_evidence_count" => report["review_required_evidence_count"],
          "blocked_evidence_count" => report["blocked_evidence_count"],
          "schema_error_count" => report["schema_error_count"],
          "schema_warning_count" => report["schema_warning_count"],
          "model_blocked_count" => report["model_blocked_count"],
          "quality_gate_review_count" => report["quality_gate_review_count"],
          "quality_gate_blocked_count" => report["quality_gate_blocked_count"],
          "evidence_status_counts" => report["evidence_status_counts"],
          "evidence_refs_by_status" => report["evidence_refs_by_status"],
          "evidence_refs_by_contract" => report["evidence_refs_by_contract"],
          "source_validation_safety_case_summary" => report
        }
        |> compact_map()
      ]
    else
      evidence_rows
    end
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> value in [nil, [], %{}] end)
    |> Map.new()
  end

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
