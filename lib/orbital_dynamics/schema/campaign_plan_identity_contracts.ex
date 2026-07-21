defmodule OrbitalDynamics.Schema.CampaignPlanIdentityContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  def validate(issues, artifact) when is_map(artifact) do
    issues
    |> validate_generated_at(Map.get(artifact, "generated_at"))
    |> validate_plan_id(artifact)
  end

  defp validate_generated_at(issues, generated_at) when is_binary(generated_at) do
    case DateTime.from_iso8601(generated_at) do
      {:ok, _date_time, _utc_offset} -> issues
      {:error, _reason} -> invalid_generated_at(issues)
    end
  end

  defp validate_generated_at(issues, nil), do: issues
  defp validate_generated_at(issues, _generated_at), do: invalid_generated_at(issues)

  defp invalid_generated_at(issues) do
    [error("$.generated_at", "must be an ISO 8601 date-time string") | issues]
  end

  defp validate_plan_id(
         issues,
         %{
           "plan_id" => plan_id,
           "study_id" => study_id,
           "generated_at" => generated_at
         }
       )
       when is_binary(plan_id) and is_binary(study_id) and is_binary(generated_at) do
    expected = "campaign_plan:#{study_id}:#{generated_at}"

    if plan_id == expected do
      issues
    else
      [
        error(
          "$.plan_id",
          "must equal campaign_plan:<study_id>:<generated_at>"
        )
        | issues
      ]
    end
  end

  defp validate_plan_id(issues, _artifact), do: issues
end
