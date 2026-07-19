defmodule OrbitalDynamics.TimelineFeedback.ReconciliationOutcomeEvidence do
  @moduledoc false

  alias OrbitalDynamics.TimelineFeedback.ProviderResult

  def context(realized, feedback_kind, provider_result_keys, failure_statuses) do
    status = value(realized, "status")

    %{
      "contact_success" =>
        contact_success(
          feedback_kind,
          status,
          value(realized, "contact_success"),
          value(realized, "contact_result"),
          provider_result_keys
        ),
      "contact_result" => artifact_value(value(realized, "contact_result"), provider_result_keys),
      "command_success" =>
        command_success(
          feedback_kind,
          status,
          value(realized, "command_success"),
          value(realized, "command_result"),
          provider_result_keys
        ),
      "command_result" => artifact_value(value(realized, "command_result"), provider_result_keys),
      "observation_success" =>
        observation_success(
          feedback_kind,
          status,
          value(realized, "observation_success"),
          value(realized, "observation_result"),
          provider_result_keys,
          failure_statuses
        ),
      "observation_result" =>
        artifact_value(value(realized, "observation_result"), provider_result_keys),
      "maneuver_success" =>
        maneuver_success(
          feedback_kind,
          status,
          value(realized, "maneuver_success"),
          value(realized, "maneuver_result"),
          provider_result_keys,
          failure_statuses
        ),
      "maneuver_result" =>
        artifact_value(value(realized, "maneuver_result"), provider_result_keys),
      "completed_fraction" => value(realized, "completed_fraction"),
      "reason" => value(realized, "reason")
    }
  end

  defp contact_success("contact", _status, explicit, _result, _keys)
       when is_boolean(explicit),
       do: explicit

  defp contact_success("contact", status, explicit, result, keys) when not is_nil(result) do
    case ProviderResult.outcome(result, keys) do
      :failure -> false
      :success -> true
      :unknown -> contact_success("contact", status, explicit, nil, keys)
    end
  end

  defp contact_success("contact", status, _explicit, _result, _keys)
       when status in ["completed", "executed"],
       do: true

  defp contact_success("contact", "partial", _explicit, _result, _keys), do: nil

  defp contact_success("contact", status, _explicit, _result, _keys)
       when is_binary(status),
       do: false

  defp contact_success(_feedback_kind, _status, _explicit, _result, _keys), do: nil

  defp command_success(kind, _status, explicit, _result, _keys)
       when kind in ["command", "health_check"] and is_boolean(explicit),
       do: explicit

  defp command_success(kind, status, explicit, result, keys)
       when kind in ["command", "health_check"] and not is_nil(result) do
    case ProviderResult.outcome(result, keys) do
      :failure -> false
      :success -> true
      :unknown -> command_success(kind, status, explicit, nil, keys)
    end
  end

  defp command_success(kind, status, _explicit, _result, _keys)
       when kind in ["command", "health_check"] and status in ["completed", "executed"],
       do: true

  defp command_success(kind, "partial", _explicit, _result, _keys)
       when kind in ["command", "health_check"],
       do: nil

  defp command_success(kind, status, _explicit, _result, _keys)
       when kind in ["command", "health_check"] and is_binary(status),
       do: false

  defp command_success(_feedback_kind, _status, _explicit, _result, _keys), do: nil

  defp observation_success(
         "observation",
         _status,
         explicit,
         _result,
         _keys,
         _failure_statuses
       )
       when is_boolean(explicit),
       do: explicit

  defp observation_success("observation", status, explicit, result, keys, failure_statuses)
       when not is_nil(result) do
    case ProviderResult.outcome(result, keys) do
      :failure ->
        false

      :success ->
        true

      :unknown ->
        observation_success("observation", status, explicit, nil, keys, failure_statuses)
    end
  end

  defp observation_success(
         "observation",
         status,
         _explicit,
         _result,
         _keys,
         _failure_statuses
       )
       when status in ["completed", "executed"],
       do: true

  defp observation_success(
         "observation",
         "partial",
         _explicit,
         _result,
         _keys,
         _failure_statuses
       ),
       do: nil

  defp observation_success(
         "observation",
         status,
         _explicit,
         _result,
         _keys,
         failure_statuses
       ) do
    if status in failure_statuses, do: false
  end

  defp observation_success(
         _feedback_kind,
         _status,
         _explicit,
         _result,
         _keys,
         _failure_statuses
       ),
       do: nil

  defp maneuver_success("maneuver", _status, explicit, _result, _keys, _failure_statuses)
       when is_boolean(explicit),
       do: explicit

  defp maneuver_success("maneuver", status, explicit, result, keys, failure_statuses)
       when not is_nil(result) do
    case ProviderResult.outcome(result, keys) do
      :failure -> false
      :success -> true
      :unknown -> maneuver_success("maneuver", status, explicit, nil, keys, failure_statuses)
    end
  end

  defp maneuver_success(
         "maneuver",
         status,
         _explicit,
         _result,
         _keys,
         _failure_statuses
       )
       when status in ["completed", "executed"],
       do: true

  defp maneuver_success("maneuver", status, _explicit, _result, _keys, failure_statuses) do
    if status in failure_statuses, do: false
  end

  defp maneuver_success(
         _feedback_kind,
         _status,
         _explicit,
         _result,
         _keys,
         _failure_statuses
       ),
       do: nil

  defp artifact_value(result, keys), do: ProviderResult.artifact_value(result, keys)

  defp value(nil, _key), do: nil
  defp value(map, key), do: Map.get(map, key)
end
