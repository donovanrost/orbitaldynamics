defmodule OrbitalDynamics.Schema.RegistryCapability do
  @moduledoc false

  def build(contracts, opts) when is_map(contracts) do
    json_schema_draft = Keyword.fetch!(opts, :json_schema_draft)
    compatibility_policy = Keyword.fetch!(opts, :compatibility_policy)
    identity_policy = Keyword.fetch!(opts, :identity_policy)
    validation_report_contracts = Keyword.fetch!(opts, :validation_report_contracts)

    %{
      model: :executable_artifact_contract_registry,
      artifact_contracts: contracts |> Map.keys() |> Enum.sort(),
      artifact_contract_count: map_size(contracts),
      json_schema_draft: json_schema_draft,
      compatibility_policy_version: compatibility_policy["policy_version"],
      identity_policy_version: identity_policy["policy_version"],
      validation_report_contracts: validation_report_contracts,
      validation_report_semantics: validation_report_semantics(),
      compatibility_export_semantics: compatibility_export_semantics(),
      known_limits: model_limits()
    }
  end

  def model_limits do
    [
      "top_level_json_schema_compatibility_export",
      "executable_elixir_validator_is_source_of_truth",
      "semantic_checks_are_not_fully_represented_in_json_schema"
    ]
  end

  defp validation_report_semantics do
    [
      :schema_validation_validated_contract_metadata,
      :schema_validation_status_and_issue_counts,
      :schema_validation_remediation_rows,
      :schema_validation_model_limit_enforcement,
      :schema_validation_batch_file_artifact_and_skip_counts,
      :schema_validation_batch_nested_report_entries,
      :schema_validation_batch_skipped_artifact_rows,
      :schema_migration_deprecation_warning_rollups,
      :schema_migration_status_and_action_counts
    ]
  end

  defp compatibility_export_semantics do
    [
      :compatibility_policy_version_breadcrumbs,
      :identity_policy_version_breadcrumbs,
      :top_level_json_schema_compatibility_export,
      :direct_declared_nested_contract_defs,
      :executable_validator_source_of_truth
    ]
  end
end
