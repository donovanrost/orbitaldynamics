defmodule OrbitalDynamics.Schema.ModelCapabilityContracts do
  @moduledoc false

  def validate_environment_model(issues, path, record, callbacks) when is_list(callbacks) do
    issues
    |> validate_stable_ids(callbacks, path, record, ["id"])
    |> expect_equal(callbacks, path, record, "schema_contract", "environment_model_capability.v1")
    |> expect_type(callbacks, path, record, "category", :binary)
    |> expect_type(callbacks, path, record, "model", :binary)
    |> expect_type(callbacks, path, record, "source", :binary)
    |> expect_type(callbacks, path, record, "validation_level", :binary)
    |> expect_one_of(
      callbacks,
      path,
      record,
      "validation_level",
      validation_level_names(callbacks)
    )
    |> expect_type(callbacks, path, record, "time_span", :binary)
    |> expect_type(callbacks, path, record, "supported_bodies", :list)
    |> expect_type(callbacks, path, record, "network_access", :boolean)
    |> expect_type(callbacks, path, record, "parameters", :map)
    |> expect_type(callbacks, path, record, "known_limits", :list)
    |> validate_string_list_items(callbacks, path, record, "supported_bodies")
    |> validate_string_list_items(callbacks, path, record, "known_limits")
    |> validate_environment_model_contract(callbacks, path, record)
    |> expect_optional_type(callbacks, path, record, "coordinate_frame", :binary)
    |> expect_optional_type(callbacks, path, record, "interpolation", :binary)
  end

  def validate_environment_provider(issues, path, record, callbacks) when is_list(callbacks) do
    coverage = Map.get(record, "coverage")
    coverage_map = if is_map(coverage), do: coverage, else: %{}

    issues
    |> validate_stable_ids(callbacks, path, record, ["id"])
    |> expect_equal(
      callbacks,
      path,
      record,
      "schema_contract",
      "environment_provider_capability.v1"
    )
    |> expect_type(callbacks, path, record, "category", :binary)
    |> expect_type(callbacks, path, record, "source", :binary)
    |> expect_type(callbacks, path, record, "validation_level", :binary)
    |> expect_one_of(
      callbacks,
      path,
      record,
      "validation_level",
      validation_level_names(callbacks)
    )
    |> expect_type(callbacks, path, record, "coverage", :map)
    |> expect_type(callbacks, path, record, "interpolation", :binary)
    |> expect_type(callbacks, path, record, "supported_bodies", :list)
    |> expect_type(callbacks, path, record, "network_access", :boolean)
    |> expect_type(callbacks, path, record, "known_limits", :list)
    |> validate_string_list_items(callbacks, path, record, "supported_bodies")
    |> validate_string_list_items(callbacks, path, record, "known_limits")
    |> expect_optional_type(callbacks, path, record, "outputs", :list)
    |> validate_string_list_items(callbacks, path, record, "outputs")
    |> validate_environment_provider_contract(callbacks, path, record)
    |> expect_optional_number(callbacks, path <> ".coverage", coverage_map, "starts_at_s")
    |> expect_optional_number(callbacks, path <> ".coverage", coverage_map, "ends_at_s")
    |> validate_environment_provider_coverage(callbacks, path <> ".coverage", coverage_map)
  end

  def validate_subsystem_model(issues, path, record, callbacks) when is_list(callbacks) do
    issues
    |> validate_stable_ids(callbacks, path, record, ["id"])
    |> expect_equal(callbacks, path, record, "schema_contract", "subsystem_model_capability.v1")
    |> expect_type(callbacks, path, record, "subsystem", :binary)
    |> expect_type(callbacks, path, record, "model", :binary)
    |> expect_type(callbacks, path, record, "source", :binary)
    |> expect_type(callbacks, path, record, "fidelity_tier", :binary)
    |> expect_type(callbacks, path, record, "validation_level", :binary)
    |> expect_one_of(
      callbacks,
      path,
      record,
      "validation_level",
      validation_level_names(callbacks)
    )
    |> expect_type(callbacks, path, record, "applicability", :map)
    |> expect_type(callbacks, path, record, "state_variables", :list)
    |> expect_type(callbacks, path, record, "activity_effects", :map)
    |> expect_type(callbacks, path, record, "parameters", :map)
    |> expect_type(callbacks, path, record, "known_limits", :list)
    |> validate_string_list_items(callbacks, path, record, "state_variables")
    |> validate_string_list_items(callbacks, path, record, "known_limits")
    |> validate_subsystem_model_contract(callbacks, path, record)
    |> expect_optional_type(callbacks, path, record, "provenance", :map)
  end

  defp validate_environment_provider_coverage(issues, callbacks, path, %{} = coverage) do
    starts_at_s = Map.get(coverage, "starts_at_s")
    ends_at_s = Map.get(coverage, "ends_at_s")

    if is_number(starts_at_s) and is_number(ends_at_s) and ends_at_s < starts_at_s do
      [
        error(callbacks, path <> ".ends_at_s", "must be greater than or equal to starts_at_s")
        | issues
      ]
    else
      issues
    end
  end

  defp validate_environment_model_contract(issues, callbacks, path, record) do
    case OrbitalDynamics.Environment.validate_capability(record) do
      :ok ->
        issues

      {:error, {:missing_trust_boundary, "network_access"}} ->
        [
          error(
            callbacks,
            path <> ".trust_boundary",
            "is required when environment model network_access is true"
          )
          | issues
        ]

      {:error, {:invalid_field, "known_limits"}} ->
        [
          error(
            callbacks,
            path <> ".known_limits",
            "must match Environment.model_capabilities known limits"
          )
          | issues
        ]

      {:error, {:invalid_field, field}} ->
        [error(callbacks, path <> ".#{field}", "is invalid") | issues]

      {:error, reason} ->
        [
          error(callbacks, path, "invalid environment model capability: #{inspect(reason)}")
          | issues
        ]
    end
  end

  defp validate_environment_provider_contract(issues, callbacks, path, record) do
    case OrbitalDynamics.Environment.validate_provider_capability(record) do
      :ok ->
        issues

      {:error, {:missing_trust_boundary, "network_access"}} ->
        [
          error(
            callbacks,
            path <> ".trust_boundary",
            "is required when environment provider network_access is true"
          )
          | issues
        ]

      {:error, {:invalid_field, "known_limits"}} ->
        [
          error(
            callbacks,
            path <> ".known_limits",
            "must match Environment.provider_capabilities known limits"
          )
          | issues
        ]

      {:error, {:invalid_field, field}} ->
        [error(callbacks, path <> ".#{field}", "is invalid") | issues]

      {:error, reason} ->
        [
          error(callbacks, path, "invalid environment provider capability: #{inspect(reason)}")
          | issues
        ]
    end
  end

  defp validate_subsystem_model_contract(issues, callbacks, path, record) do
    case OrbitalDynamics.SubsystemModel.validate_capability(record) do
      :ok ->
        issues

      {:error, {:invalid_field, "known_limits"}} ->
        [
          error(
            callbacks,
            path <> ".known_limits",
            "must match SubsystemModel.capabilities known limits"
          )
          | issues
        ]

      {:error, {:invalid_field, field}} ->
        [error(callbacks, path <> ".#{field}", "is invalid") | issues]

      {:error, reason} ->
        [
          error(callbacks, path, "invalid subsystem model capability: #{inspect(reason)}")
          | issues
        ]
    end
  end

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_number), [issues, path, map, field])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validation_level_names(callbacks),
    do: apply(Keyword.fetch!(callbacks, :validation_tolerance_policy_level_names), [])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
