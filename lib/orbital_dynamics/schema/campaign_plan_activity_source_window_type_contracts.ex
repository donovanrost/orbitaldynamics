defmodule OrbitalDynamics.Schema.CampaignPlanActivitySourceWindowTypeContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @activity_type_mappings [
    {"observe", "target_visibility"},
    {"downlink", "ground_station_access"},
    {"command", "ground_station_access"},
    {"tracking", "ground_station_access"},
    {"health_check", "ground_station_access"}
  ]

  def activity_type_mappings, do: @activity_type_mappings

  def validate(issues, path, %{"type" => activity_type, "source_window" => %{} = source_window}) do
    case List.keyfind(@activity_type_mappings, activity_type, 0) do
      {_activity_type, expected_type} ->
        validate_type(issues, path, source_window, activity_type, expected_type)

      nil ->
        issues
    end
  end

  def validate(issues, _path, _activity), do: issues

  defp validate_type(issues, path, source_window, activity_type, expected_type) do
    case Map.fetch(source_window, "type") do
      :error ->
        [error(path <> ".source_window.type", "is required") | issues]

      {:ok, ^expected_type} ->
        issues

      {:ok, type} when is_binary(type) ->
        if String.trim(type) == "" do
          [error(path <> ".source_window.type", "must be a non-empty string") | issues]
        else
          [
            error(
              path <> ".source_window.type",
              "must equal #{inspect(expected_type)} for #{activity_type} activity"
            )
            | issues
          ]
        end

      {:ok, _type} ->
        [error(path <> ".source_window.type", "must be a string") | issues]
    end
  end
end
