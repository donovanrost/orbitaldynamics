defmodule OrbitalDynamics.Schema.CampaignPlanActivityCadenceContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2, require_fields: 4]

  alias OrbitalDynamics.Schema.StableIdValidation

  @activity_type_mappings [
    {"observe", "observation"},
    {"downlink", "contact"},
    {"command", "command"},
    {"tracking", "contact"},
    {"health_check", "contact"}
  ]

  def activity_type_mappings, do: @activity_type_mappings

  def validate(issues, path, activity) when is_map(activity) do
    issues
    |> require_fields(path, activity, required_envelope_fields(activity))
    |> validate_envelope(path, activity, Map.fetch(activity, "cadence_import"))
  end

  defp required_envelope_fields(%{"type" => "downlink"}), do: []
  defp required_envelope_fields(_activity), do: ["cadence_import"]

  defp validate_envelope(issues, _path, _activity, :error), do: issues

  defp validate_envelope(issues, path, activity, {:ok, %{} = cadence_import}) do
    issues
    |> validate_nested_requirements(path, activity, cadence_import)
    |> validate_activity_type(path, cadence_import)
    |> validate_activity_type_mapping(path, activity, cadence_import)
    |> validate_external_identity(path, activity, cadence_import)
  end

  defp validate_envelope(issues, _path, %{"type" => "downlink"}, {:ok, _value}),
    do: issues

  defp validate_envelope(issues, path, _activity, {:ok, _value}) do
    [error(path <> ".cadence_import", "must be a map") | issues]
  end

  defp validate_nested_requirements(issues, _path, %{"type" => "downlink"}, _cadence_import),
    do: issues

  defp validate_nested_requirements(issues, path, _activity, cadence_import) do
    issues
    |> require_fields(path <> ".cadence_import", cadence_import, [
      "external_id",
      "activity_type"
    ])
    |> StableIdValidation.validate_stable_ids(path <> ".cadence_import", cadence_import, [
      "external_id"
    ])
  end

  defp validate_activity_type(issues, path, cadence_import) do
    case Map.fetch(cadence_import, "activity_type") do
      :error ->
        issues

      {:ok, activity_type} when is_binary(activity_type) ->
        if String.trim(activity_type) == "",
          do: [
            error(path <> ".cadence_import.activity_type", "must be a non-empty string") | issues
          ],
          else: issues

      {:ok, _activity_type} ->
        [error(path <> ".cadence_import.activity_type", "must be a string") | issues]
    end
  end

  defp validate_activity_type_mapping(issues, path, activity, cadence_import) do
    expected_type =
      @activity_type_mappings
      |> List.keyfind(Map.get(activity, "type"), 0)
      |> case do
        {_activity_type, cadence_type} -> cadence_type
        nil -> nil
      end

    actual_type = Map.get(cadence_import, "activity_type")

    if is_binary(expected_type) and is_binary(actual_type) and String.trim(actual_type) != "" and
         actual_type != expected_type do
      [
        error(
          path <> ".cadence_import.activity_type",
          "must equal #{inspect(expected_type)} for #{Map.get(activity, "type")} activity"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp validate_external_identity(issues, path, activity, cadence_import) do
    activity_id = Map.get(activity, "id")
    external_id = Map.get(cadence_import, "external_id")

    if StableIdValidation.valid?(activity_id) and StableIdValidation.valid?(external_id) and
         external_id != activity_id do
      [error(path <> ".cadence_import.external_id", "must match activity id") | issues]
    else
      issues
    end
  end
end
