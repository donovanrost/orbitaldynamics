defmodule OrbitalDynamics.Schema.Report do
  @moduledoc false

  def validation_report_for_artifact(%{} = artifact, opts, validate_fun, report_opts)
      when is_list(opts) and is_function(validate_fun, 2) and is_list(report_opts) do
    validation_mode = opts |> Keyword.get(:validation_mode, "artifact_map") |> to_string()
    artifact_path = Keyword.get(opts, :artifact_path)

    {_status, report} =
      case validate_fun.(artifact, opts) do
        {:ok, report} -> {:ok, report}
        {:error, report} -> {:error, report}
      end

    validation_report(report, validation_mode, artifact_path, report_opts)
  end

  def validation_report(report, validation_mode, artifact_path, opts) do
    schema_contract = Keyword.fetch!(opts, :schema_contract)
    model_limits = Keyword.fetch!(opts, :model_limits)
    errors = Map.get(report, "errors", [])
    warnings = Map.get(report, "warnings", [])
    remediation = validation_remediation(report, errors)

    %{
      "schema_contract" => schema_contract,
      "model" => "executable_artifact_contract_validation",
      "validation_mode" => validation_mode,
      "validated_contract" => Map.get(report, "schema_contract") || "unknown",
      "validated_artifact_family" => Map.get(report, "artifact_family"),
      "validated_schema_version" => Map.get(report, "schema_version"),
      "status" => Map.get(report, "status"),
      "model_limits" => model_limits,
      "error_count" => length(errors),
      "warning_count" => length(warnings),
      "errors" => errors,
      "warnings" => warnings,
      "remediation_count" => length(remediation),
      "remediation" => remediation,
      "assumptions" => %{
        "validator" => "OrbitalDynamics.Schema.validate_artifact",
        "validation_scope" => "executable_contract_required_fields_and_semantic_checks",
        "json_schema_export_scope" => "top_level_compatibility"
      }
    }
    |> maybe_put("artifact_path", artifact_path)
  end

  defp validation_remediation(report, errors) do
    contract_name = Map.get(report, "schema_contract") || "artifact"

    errors
    |> Enum.map(&remediation_for_issue(&1, contract_name))
    |> Enum.reject(&is_nil/1)
  end

  defp remediation_for_issue(%{"path" => path, "message" => "is required"} = issue, contract_name) do
    %{
      "path" => path,
      "category" => "missing_required_field",
      "action" => "Populate this required field for #{contract_name}",
      "source_message" => issue["message"]
    }
  end

  defp remediation_for_issue(
         %{"path" => path, "message" => "could not infer schema contract from artifact"} = issue,
         _contract_name
       ) do
    %{
      "path" => path,
      "category" => "contract_inference_failure",
      "action" => "Declare schema_contract or pass an explicit contract before validation",
      "source_message" => issue["message"]
    }
  end

  defp remediation_for_issue(
         %{"path" => path, "message" => "unknown schema contract: " <> _} = issue,
         _contract_name
       ) do
    %{
      "path" => path,
      "category" => "unsupported_schema_contract",
      "action" => "Use a supported schema contract or publish a compatible artifact contract",
      "source_message" => issue["message"]
    }
  end

  defp remediation_for_issue(
         %{"path" => path, "message" => "must be a " <> type} = issue,
         contract_name
       ) do
    %{
      "path" => path,
      "category" => "type_mismatch",
      "action" => "Set this field to a #{type} value for #{contract_name}",
      "source_message" => issue["message"]
    }
  end

  defp remediation_for_issue(
         %{"path" => path, "message" => "must equal " <> expected} = issue,
         contract_name
       ) do
    %{
      "path" => path,
      "category" => "constant_mismatch",
      "action" => "Set this field to #{expected} for #{contract_name}",
      "source_message" => issue["message"]
    }
  end

  defp remediation_for_issue(
         %{"path" => path, "message" => "must be one of " <> allowed} = issue,
         contract_name
       ) do
    %{
      "path" => path,
      "category" => "unsupported_value",
      "action" => "Set this field to one of #{allowed} for #{contract_name}",
      "source_message" => issue["message"]
    }
  end

  defp remediation_for_issue(%{"path" => path, "message" => message} = issue, contract_name)
       when is_binary(path) and is_binary(message) do
    %{
      "path" => path,
      "category" => "semantic_validation_failure",
      "action" => "Review this executable validation failure for #{contract_name}",
      "source_message" => issue["message"]
    }
  end

  defp remediation_for_issue(_issue, _contract_name), do: nil

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
