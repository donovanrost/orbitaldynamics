defmodule OrbitalDynamics.CampaignPlanner.SchemaValidationSourceReports.PressureRows do
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
          |> Map.get("source", "schema_validation_report")
          |> String.replace_prefix("schema_validation_report", source_path)

        row =
          row
          |> Map.put("_source_report_trust_boundary", trust_boundary)

        {row, row_source, index}
      end)
    end)
  end

  defp report_pressure_rows(report) do
    report = stringify_keys(report || %{})

    remediation_by_path =
      report
      |> Map.get("remediation", [])
      |> List.wrap()
      |> Enum.map(&stringify_keys/1)
      |> Map.new(&{&1["path"], &1})

    [
      {"errors", "error"},
      {"warnings", "warning"}
    ]
    |> Enum.flat_map(fn {field, severity} ->
      report
      |> Map.get(field, [])
      |> List.wrap()
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(fn issue ->
        remediation = Map.get(remediation_by_path, issue["path"])

        %{
          "source" => "schema_validation_report.#{field}",
          "validation_status" => report["status"],
          "validation_mode" => report["validation_mode"],
          "validated_contract" => report["validated_contract"],
          "validated_artifact_family" => report["validated_artifact_family"],
          "artifact_path" => report["artifact_path"],
          "issue_severity" => issue["severity"] || severity,
          "issue_path" => issue["path"],
          "issue_message" => issue["message"],
          "error_count" => report["error_count"],
          "warning_count" => report["warning_count"],
          "remediation_count" => report["remediation_count"],
          "remediation_category" => remediation && remediation["category"],
          "remediation_action" => remediation && remediation["action"],
          "required_operator_action" => "review_schema_validation",
          "source_validation_issue" => Map.delete(issue, "source"),
          "source_validation_remediation" => remediation,
          "source_schema_validation_report" => report
        }
        |> compact_map()
      end)
    end)
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
