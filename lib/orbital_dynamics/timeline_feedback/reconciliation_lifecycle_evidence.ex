defmodule OrbitalDynamics.TimelineFeedback.ReconciliationLifecycleEvidence do
  @moduledoc false

  alias OrbitalDynamics.Timeline
  alias OrbitalDynamics.TimelineFeedback.ArtifactValue

  def context(planned, realized) do
    protection_decision = feedback_protection_decision(planned, realized)

    %{
      "status" => row_status(planned, realized),
      "planned_type" => value(planned, "type"),
      "realized_type" => value(realized, "type"),
      "planned_status" => value(planned, "status"),
      "realized_status" => value(realized, "status"),
      "feedback_status" => value(realized, "feedback_status"),
      "status_transition" => feedback_status_transition(planned, realized),
      "planned_protection_decision" => value(protection_decision, "protection_decision"),
      "planned_protection_category" => value(protection_decision, "protection_category"),
      "planned_protection_reason" => value(protection_decision, "reason"),
      "source_protection_decision" => protection_decision,
      "planned_activity" => value(planned, "source_activity"),
      "realized_activity" => value(realized, "source_activity"),
      "source_activity_context" => feedback_source_activity_context(planned),
      "realized_activity_context" => value(realized, "realized_activity_context")
    }
  end

  defp row_status(nil, %{}), do: "realized_only"
  defp row_status(%{}, nil), do: "planned_only"
  defp row_status(%{}, %{}), do: "matched"

  defp feedback_status_transition(nil, nil), do: nil

  defp feedback_status_transition(planned, realized) do
    Timeline.status_transition(
      value(planned, "source_activity"),
      realized_source_activity_for_transition(realized)
    )
  end

  defp realized_source_activity_for_transition(nil), do: nil

  defp realized_source_activity_for_transition(%{} = realized) do
    case value(realized, "source_activity") do
      %{} = source_activity -> Map.put(source_activity, "status", value(realized, "status"))
      source_activity -> source_activity
    end
  end

  defp feedback_protection_decision(nil, _realized), do: nil

  defp feedback_protection_decision(%{"invalid_activity_input" => true}, _realized), do: nil

  defp feedback_protection_decision(planned, realized) do
    opts =
      case value(realized, "status") do
        nil -> []
        status -> [realized_status: status]
      end

    planned
    |> value("source_activity")
    |> Timeline.protection_decision(opts)
  end

  defp feedback_source_activity_context(nil), do: nil

  defp feedback_source_activity_context(planned) do
    (value(planned, "source_activity_context") || %{})
    |> Map.merge(%{
      "command_authority_status" => value(planned, "command_authority_status"),
      "required_authority" => value(planned, "required_authority"),
      "command_safety_status" => value(planned, "command_safety_status"),
      "command_authorized" => value(planned, "command_authorized"),
      "command_safety_checked" => value(planned, "command_safety_checked")
    })
    |> ArtifactValue.compact_map()
  end

  defp value(nil, _key), do: nil
  defp value(map, key), do: Map.get(map, key)
end
