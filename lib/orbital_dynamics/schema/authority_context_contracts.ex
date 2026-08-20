defmodule OrbitalDynamics.Schema.AuthorityContextContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @identity_pattern "^authority_context:[0-9a-f]{64}$"
  @propagation_fields ~w(eligibility_status authority_context authority_context_evaluation)
  @evidence_propagation_fields ~w(authority_context authority_context_evaluation)

  def validate(issues, path, context) do
    case OrbitalDynamics.AuthorityContext.validate(context) do
      {:ok, _context} ->
        issues

      {:error, failure} ->
        validation_errors =
          Map.get(failure, "validation_errors", [
            %{"path" => "$", "reason" => failure["reason"]}
          ])

        Enum.reduce(validation_errors, issues, fn validation_error, acc ->
          relative_path = validation_error["path"] |> to_string() |> String.trim_leading("$")
          [error(path <> relative_path, validation_error["reason"]) | acc]
        end)
    end
  end

  def validate_optional(issues, path, artifact, field \\ "authority_context") do
    evaluation_field = "authority_context_evaluation"
    context_present? = Map.has_key?(artifact, field)
    evaluation_present? = Map.has_key?(artifact, evaluation_field)
    context = Map.get(artifact, field)
    evaluation = Map.get(artifact, evaluation_field)

    cond do
      not context_present? and not evaluation_present? ->
        issues

      context_present? and not evaluation_present? ->
        [
          error(
            "#{path}.#{evaluation_field}",
            "is required whenever authority_context is present"
          )
          | validate_context_value(issues, "#{path}.#{field}", context)
        ]

      true ->
        validate_context_evaluation(issues, path, context, evaluation)
    end
  end

  def validate_policy_boundary(issues, path, artifact) do
    issues
    |> validate_optional(path, artifact)
    |> validate_overall_eligibility(path, artifact, Map.get(artifact, "classification"))
  end

  def validate_recommendation_boundary(issues, path, artifact) do
    issues
    |> validate_optional(path, artifact)
    |> validate_overall_eligibility(path, artifact, Map.get(artifact, "approval_status"))
  end

  def validate_campaign_boundary(issues, path, artifact) do
    classification = get_in(artifact, ["recommendation", "approval_status"])

    issues
    |> validate_optional(path, artifact)
    |> validate_overall_eligibility(path, artifact, classification)
  end

  def validate_strategy_propagation(issues, artifact) when is_map(artifact) do
    if Enum.any?(@propagation_fields, &Map.has_key?(artifact, &1)) do
      targets =
        [
          {"$.recommendation", Map.get(artifact, "recommendation")},
          {"$.operator_review_package", Map.get(artifact, "operator_review_package")},
          {"$.cadence_import_manifest", Map.get(artifact, "cadence_import_manifest")}
        ] ++ review_targets(artifact) ++ manifest_targets(artifact)

      targets
      |> Enum.reduce(issues, fn {target_path, target}, acc ->
        validate_propagation_target(acc, artifact, target_path, target, @propagation_fields)
      end)
      |> then(fn acc ->
        Enum.reduce(branch_decision_targets(artifact), acc, fn {target_path, target},
                                                               nested_acc ->
          validate_propagation_target(
            nested_acc,
            artifact,
            target_path,
            target,
            @evidence_propagation_fields
          )
        end)
      end)
    else
      issues
    end
  end

  def validate_strategy_propagation(issues, _artifact), do: issues

  def json_schema do
    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => OrbitalDynamics.AuthorityContext.required_fields(),
      "properties" => %{
        "schema_contract" => %{"const" => "authority_context.v1", "type" => "string"},
        "authority_context_id" => %{"type" => "string", "pattern" => @identity_pattern},
        "authority_source" => %{"type" => "string", "minLength" => 1},
        "source_revision" => %{"type" => "string", "minLength" => 1},
        "effective_from" => %{"type" => "string", "format" => "date-time"},
        "valid_until" => %{"type" => "string", "format" => "date-time"},
        "evaluation_time" => %{"type" => "string", "format" => "date-time"}
      }
    }
  end

  def evaluation_json_schema do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "mode",
        "eligibility_status",
        "outcome",
        "reason_code",
        "reason",
        "provenance"
      ],
      "properties" => %{
        "mode" => %{
          "type" => "string",
          "enum" => ["explicit", "missing", "invalid"]
        },
        "eligibility_status" => %{
          "type" => "string",
          "enum" => ["eligible", "non_eligible"]
        },
        "outcome" => %{
          "type" => "string",
          "enum" => ["policy_evaluation_allowed", "blocked_by_policy"]
        },
        "reason_code" => %{
          "type" => "string",
          "enum" => [
            "authority_context_valid",
            "missing_authority_context_mode",
            "invalid_authority_context_mode",
            "missing_authority_context",
            "malformed_authority_context",
            "authority_context_not_yet_effective",
            "stale_authority_context"
          ]
        },
        "reason" => %{"type" => "string", "minLength" => 1},
        "authority_context_id" => %{"type" => "string", "pattern" => @identity_pattern},
        "authority_source" => %{"type" => "string", "minLength" => 1},
        "source_revision" => %{"type" => "string", "minLength" => 1},
        "evaluation_time" => %{"type" => "string", "format" => "date-time"},
        "provenance" => %{
          "type" => "object",
          "additionalProperties" => true,
          "required" => [
            "input_source",
            "validation",
            "authority_context_mode_supplied",
            "authority_context_supplied"
          ],
          "properties" => %{
            "input_source" => %{"const" => "caller_supplied", "type" => "string"},
            "validation" => %{
              "const" => "deterministic_no_wall_clock",
              "type" => "string"
            },
            "authority_context_mode_supplied" => %{"type" => "boolean"},
            "authority_context_supplied" => %{"type" => "boolean"},
            "provided_authority_context_mode" => %{"type" => "object"},
            "provided_authority_context" => %{"type" => "object"}
          }
        },
        "validation_errors" => %{"type" => "array", "items" => %{"type" => "object"}}
      }
    }
  end

  def property(field), do: json_schema() |> Map.fetch!("properties") |> Map.fetch!(field)

  defp validate_context_evaluation(issues, path, context, evaluation) do
    case OrbitalDynamics.AuthorityContext.validate_evaluation(context, evaluation) do
      {:ok, _result} ->
        issues

      {:error, validation_errors} ->
        Enum.reduce(validation_errors, issues, fn validation_error, acc ->
          relative_path =
            validation_error["path"]
            |> to_string()
            |> String.trim_leading("$")

          [error(path <> relative_path, validation_error["reason"]) | acc]
        end)
    end
  end

  defp validate_context_value(issues, path, %{} = context), do: validate(issues, path, context)

  defp validate_context_value(issues, path, _context),
    do: [error(path, "must be an object") | issues]

  defp validate_overall_eligibility(issues, path, artifact, classification) do
    evaluation = Map.get(artifact, "authority_context_evaluation")
    actual = Map.get(artifact, "eligibility_status")

    cond do
      not is_map(evaluation) ->
        issues

      evaluation["outcome"] == "blocked_by_policy" and actual != "non_eligible" ->
        [
          error(
            path <> ".eligibility_status",
            "must be non_eligible for failed authority evidence"
          )
          | issues
        ]

      classification == "blocked_by_policy" and actual != "non_eligible" ->
        [
          error(
            path <> ".eligibility_status",
            "must preserve substantive blocked_by_policy eligibility"
          )
          | issues
        ]

      classification in ["auto_approvable", "operator_review_required"] and
        evaluation["outcome"] == "policy_evaluation_allowed" and actual != "eligible" ->
        [
          error(
            path <> ".eligibility_status",
            "must be eligible when policy and authority evidence are eligible"
          )
          | issues
        ]

      true ->
        issues
    end
  end

  defp branch_decision_targets(%{"branches" => branches}) when is_list(branches) do
    branches
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {%{"policy_decision" => decision}, index} ->
        [{"$.branches[#{index}].policy_decision", decision}]

      {_branch, _index} ->
        []
    end)
  end

  defp branch_decision_targets(_artifact), do: []

  defp review_targets(artifact) do
    artifact
    |> nested_rows("operator_review_package")
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {%{"review_type" => "strategy_recommendation"} = row, index} ->
        [{"$.operator_review_package.rows[#{index}]", row}]

      {_row, _index} ->
        []
    end)
  end

  defp manifest_targets(artifact) do
    artifact
    |> nested_rows("cadence_import_manifest")
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {%{"source_review_type" => "strategy_branch_comparison"} = row, index} ->
        [{"$.cadence_import_manifest.rows[#{index}]", row}]

      {_row, _index} ->
        []
    end)
  end

  defp nested_rows(artifact, field) do
    case Map.get(artifact, field) do
      %{"rows" => rows} when is_list(rows) -> rows
      _value -> []
    end
  end

  defp validate_propagation_target(issues, _source, _path, target, _fields)
       when not is_map(target),
       do: issues

  defp validate_propagation_target(issues, source, path, target, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      if Map.get(target, field) == Map.get(source, field) do
        acc
      else
        [error("#{path}.#{field}", "must match the enclosing CampaignStrategy #{field}") | acc]
      end
    end)
  end
end
