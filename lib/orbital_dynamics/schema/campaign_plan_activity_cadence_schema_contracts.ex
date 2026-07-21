defmodule OrbitalDynamics.Schema.CampaignPlanActivityCadenceSchemaContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @activity_type_mappings [
    {"downlink", "proposed_contact.v1"},
    {"command", "proposed_contact.v1"},
    {"tracking", "proposed_contact.v1"},
    {"health_check", "proposed_contact.v1"}
  ]

  def activity_type_mappings, do: @activity_type_mappings

  def validate(issues, path, %{"type" => activity_type, "cadence_import" => %{} = cadence_import}) do
    case List.keyfind(@activity_type_mappings, activity_type, 0) do
      {_activity_type, expected_contract} ->
        validate_value(issues, path, cadence_import, activity_type, expected_contract)

      nil ->
        issues
    end
  end

  def validate(issues, _path, _activity), do: issues

  defp validate_value(issues, path, cadence_import, activity_type, expected_contract) do
    case Map.fetch(cadence_import, "schema_contract") do
      :error ->
        [error(path <> ".cadence_import.schema_contract", "is required") | issues]

      {:ok, ^expected_contract} ->
        issues

      {:ok, contract} when is_binary(contract) ->
        if String.trim(contract) == "" do
          [
            error(path <> ".cadence_import.schema_contract", "must be a non-empty string")
            | issues
          ]
        else
          [
            error(
              path <> ".cadence_import.schema_contract",
              "must equal #{inspect(expected_contract)} for #{activity_type} activity"
            )
            | issues
          ]
        end

      {:ok, _contract} ->
        [error(path <> ".cadence_import.schema_contract", "must be a string") | issues]
    end
  end
end
