defmodule OrbitalDynamics.Schema.ModelCapabilityContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation
  alias OrbitalDynamics.Schema.StableIdValidation
  alias OrbitalDynamics.Schema.ValidationPolicyContracts

  def validate_environment_model(issues, path, record) do
    issues
    |> StableIdValidation.validate_stable_ids(path, record, ["id"])
    |> PrimitiveValidation.expect_equal(
      path,
      record,
      "schema_contract",
      "environment_model_capability.v1"
    )
    |> PrimitiveValidation.expect_type(path, record, "category", :binary)
    |> PrimitiveValidation.expect_type(path, record, "model", :binary)
    |> PrimitiveValidation.expect_type(path, record, "source", :binary)
    |> PrimitiveValidation.expect_type(path, record, "validation_level", :binary)
    |> PrimitiveValidation.expect_one_of(
      path,
      record,
      "validation_level",
      ValidationPolicyContracts.level_names()
    )
    |> PrimitiveValidation.expect_type(path, record, "time_span", :binary)
    |> PrimitiveValidation.expect_type(path, record, "supported_bodies", :list)
    |> PrimitiveValidation.expect_type(path, record, "network_access", :boolean)
    |> PrimitiveValidation.expect_type(path, record, "parameters", :map)
    |> PrimitiveValidation.expect_type(path, record, "known_limits", :list)
    |> PrimitiveValidation.validate_string_list_items(path, record, "supported_bodies")
    |> PrimitiveValidation.validate_string_list_items(path, record, "known_limits")
    |> validate_environment_model_contract(path, record)
    |> PrimitiveValidation.expect_optional_type(path, record, "coordinate_frame", :binary)
    |> PrimitiveValidation.expect_optional_type(path, record, "interpolation", :binary)
  end

  def validate_environment_provider(issues, path, record) do
    coverage = Map.get(record, "coverage")
    coverage_map = if is_map(coverage), do: coverage, else: %{}

    issues
    |> StableIdValidation.validate_stable_ids(path, record, ["id"])
    |> PrimitiveValidation.expect_equal(
      path,
      record,
      "schema_contract",
      "environment_provider_capability.v1"
    )
    |> PrimitiveValidation.expect_type(path, record, "category", :binary)
    |> PrimitiveValidation.expect_type(path, record, "source", :binary)
    |> PrimitiveValidation.expect_type(path, record, "validation_level", :binary)
    |> PrimitiveValidation.expect_one_of(
      path,
      record,
      "validation_level",
      ValidationPolicyContracts.level_names()
    )
    |> PrimitiveValidation.expect_type(path, record, "coverage", :map)
    |> PrimitiveValidation.expect_type(path, record, "interpolation", :binary)
    |> PrimitiveValidation.expect_type(path, record, "supported_bodies", :list)
    |> PrimitiveValidation.expect_type(path, record, "network_access", :boolean)
    |> PrimitiveValidation.expect_type(path, record, "known_limits", :list)
    |> PrimitiveValidation.validate_string_list_items(path, record, "supported_bodies")
    |> PrimitiveValidation.validate_string_list_items(path, record, "known_limits")
    |> PrimitiveValidation.expect_optional_type(path, record, "outputs", :list)
    |> PrimitiveValidation.validate_string_list_items(path, record, "outputs")
    |> validate_environment_provider_contract(path, record)
    |> PrimitiveValidation.expect_optional_number(
      path <> ".coverage",
      coverage_map,
      "starts_at_s"
    )
    |> PrimitiveValidation.expect_optional_number(path <> ".coverage", coverage_map, "ends_at_s")
    |> validate_environment_provider_coverage(path <> ".coverage", coverage_map)
  end

  def validate_subsystem_model(issues, path, record) do
    issues
    |> StableIdValidation.validate_stable_ids(path, record, ["id"])
    |> PrimitiveValidation.expect_equal(
      path,
      record,
      "schema_contract",
      "subsystem_model_capability.v1"
    )
    |> PrimitiveValidation.expect_type(path, record, "subsystem", :binary)
    |> PrimitiveValidation.expect_type(path, record, "model", :binary)
    |> PrimitiveValidation.expect_type(path, record, "source", :binary)
    |> PrimitiveValidation.expect_type(path, record, "fidelity_tier", :binary)
    |> PrimitiveValidation.expect_type(path, record, "validation_level", :binary)
    |> PrimitiveValidation.expect_one_of(
      path,
      record,
      "validation_level",
      ValidationPolicyContracts.level_names()
    )
    |> PrimitiveValidation.expect_type(path, record, "applicability", :map)
    |> PrimitiveValidation.expect_type(path, record, "state_variables", :list)
    |> PrimitiveValidation.expect_type(path, record, "activity_effects", :map)
    |> PrimitiveValidation.expect_type(path, record, "parameters", :map)
    |> PrimitiveValidation.expect_type(path, record, "known_limits", :list)
    |> PrimitiveValidation.validate_string_list_items(path, record, "state_variables")
    |> PrimitiveValidation.validate_string_list_items(path, record, "known_limits")
    |> validate_subsystem_model_contract(path, record)
    |> PrimitiveValidation.expect_optional_type(path, record, "provenance", :map)
  end

  defp validate_environment_provider_coverage(issues, path, %{} = coverage) do
    starts_at_s = Map.get(coverage, "starts_at_s")
    ends_at_s = Map.get(coverage, "ends_at_s")

    if is_number(starts_at_s) and is_number(ends_at_s) and ends_at_s < starts_at_s do
      [
        PrimitiveValidation.error(
          path <> ".ends_at_s",
          "must be greater than or equal to starts_at_s"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp validate_environment_model_contract(issues, path, record) do
    case OrbitalDynamics.Environment.validate_capability(record) do
      :ok ->
        issues

      {:error, {:missing_trust_boundary, "network_access"}} ->
        [
          PrimitiveValidation.error(
            path <> ".trust_boundary",
            "is required when environment model network_access is true"
          )
          | issues
        ]

      {:error, {:invalid_field, "known_limits"}} ->
        [
          PrimitiveValidation.error(
            path <> ".known_limits",
            "must match Environment.model_capabilities known limits"
          )
          | issues
        ]

      {:error, {:invalid_field, field}} ->
        [PrimitiveValidation.error(path <> ".#{field}", "is invalid") | issues]

      {:error, reason} ->
        [
          PrimitiveValidation.error(
            path,
            "invalid environment model capability: #{inspect(reason)}"
          )
          | issues
        ]
    end
  end

  defp validate_environment_provider_contract(issues, path, record) do
    case OrbitalDynamics.Environment.validate_provider_capability(record) do
      :ok ->
        issues

      {:error, {:missing_trust_boundary, "network_access"}} ->
        [
          PrimitiveValidation.error(
            path <> ".trust_boundary",
            "is required when environment provider network_access is true"
          )
          | issues
        ]

      {:error, {:invalid_field, "known_limits"}} ->
        [
          PrimitiveValidation.error(
            path <> ".known_limits",
            "must match Environment.provider_capabilities known limits"
          )
          | issues
        ]

      {:error, {:invalid_field, field}} ->
        [PrimitiveValidation.error(path <> ".#{field}", "is invalid") | issues]

      {:error, reason} ->
        [
          PrimitiveValidation.error(
            path,
            "invalid environment provider capability: #{inspect(reason)}"
          )
          | issues
        ]
    end
  end

  defp validate_subsystem_model_contract(issues, path, record) do
    case OrbitalDynamics.SubsystemModel.validate_capability(record) do
      :ok ->
        issues

      {:error, {:invalid_field, "known_limits"}} ->
        [
          PrimitiveValidation.error(
            path <> ".known_limits",
            "must match SubsystemModel.capabilities known limits"
          )
          | issues
        ]

      {:error, {:invalid_field, field}} ->
        [PrimitiveValidation.error(path <> ".#{field}", "is invalid") | issues]

      {:error, reason} ->
        [
          PrimitiveValidation.error(
            path,
            "invalid subsystem model capability: #{inspect(reason)}"
          )
          | issues
        ]
    end
  end
end
