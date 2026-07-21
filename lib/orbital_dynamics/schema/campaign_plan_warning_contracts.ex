defmodule OrbitalDynamics.Schema.CampaignPlanWarningContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  def validate(issues, artifact) when is_map(artifact) do
    case Map.get(artifact, "warnings") do
      warnings when is_list(warnings) -> validate_warnings(issues, warnings)
      _warnings -> issues
    end
  end

  defp validate_warnings(issues, warnings) do
    issues
    |> validate_warning_items(warnings)
    |> reject_duplicate_warnings(warnings)
  end

  defp validate_warning_items(issues, warnings) do
    warnings
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {warning, index}, acc when is_binary(warning) and byte_size(warning) > 0 ->
        if String.trim(warning) == "" do
          invalid_warning(acc, index)
        else
          acc
        end

      {_warning, index}, acc ->
        invalid_warning(acc, index)
    end)
  end

  defp invalid_warning(issues, index) do
    [error("$.warnings[#{index}]", "must be a non-empty string") | issues]
  end

  defp reject_duplicate_warnings(issues, warnings) do
    duplicates =
      warnings
      |> Enum.filter(&is_binary/1)
      |> Enum.frequencies()
      |> Enum.filter(fn {_warning, count} -> count > 1 end)
      |> Enum.map(fn {warning, _count} -> warning end)
      |> Enum.sort()

    if duplicates == [] do
      issues
    else
      [
        error("$.warnings", "must not contain duplicate warnings: #{inspect(duplicates)}")
        | issues
      ]
    end
  end
end
