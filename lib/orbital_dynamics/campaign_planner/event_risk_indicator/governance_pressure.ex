defmodule OrbitalDynamics.CampaignPlanner.EventRiskIndicator.GovernancePressure do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.PressureRiskFields

  def indicators(%{"type" => "operational_readiness_pressure"} = event) do
    [
      event
      |> Map.take(PressureRiskFields.operational_readiness())
      |> Map.merge(%{
        "type" => "operational_readiness_pressure",
        "severity" => readiness_pressure_risk_severity(event),
        "reason" =>
          event["readiness_gate_reason"] ||
            "operational readiness pressure requires review before import"
      })
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "quality_gate_pressure"} = event) do
    [
      event
      |> Map.take(PressureRiskFields.quality_gate())
      |> Map.merge(%{
        "type" => "quality_gate_pressure",
        "severity" => readiness_pressure_risk_severity(event),
        "reason" => event["gate_reason"] || "quality gate pressure requires review before import"
      })
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "provider_counteroffer_pressure"} = event) do
    [
      event
      |> Map.take(PressureRiskFields.provider_counteroffer())
      |> Map.merge(%{
        "type" => "provider_counteroffer_pressure",
        "severity" => event["severity"] || "medium",
        "reason" =>
          event["provider_counteroffer_reason"] ||
            event["reason"] ||
            "provider counteroffer requires operator review before schedule import"
      })
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "approval_boundary_pressure"} = event) do
    [
      event
      |> Map.take(PressureRiskFields.approval_boundary())
      |> Map.merge(%{
        "type" => "approval_boundary_pressure",
        "severity" => event["severity"] || "medium",
        "reason" =>
          event["approval_boundary_reason"] ||
            event["reason"] ||
            "approval boundary pressure requires operator review before automation"
      })
      |> compact_map()
    ]
  end

  def indicators(%{"type" => type} = event)
      when type in [
             "schema_validation_pressure",
             "model_acceptance_pressure",
             "validation_safety_case_pressure",
             "refresh_budget_pressure",
             "refresh_freshness_pressure"
           ] do
    [
      event
      |> Map.take(PressureRiskFields.validation_refresh())
      |> Map.merge(%{
        "type" => type,
        "severity" => validation_refresh_pressure_risk_severity(event),
        "reason" => validation_refresh_pressure_risk_reason(event)
      })
      |> compact_map()
    ]
  end

  def indicators(_event), do: []

  defp readiness_pressure_risk_severity(event) do
    blocked_values = ["blocked", "blocked_by_policy", "review_blocked_operational_readiness"]

    if Enum.any?(
         [
           event["readiness_level"],
           event["import_classification"],
           event["operational_readiness_status"],
           event["readiness_gate_status"],
           event["readiness_gate_classification"],
           event["quality_gate_status"],
           event["gate_status"],
           event["gate_classification"],
           event["required_operator_action"]
         ],
         &(&1 in blocked_values)
       ) do
      "high"
    else
      "medium"
    end
  end

  defp validation_refresh_pressure_risk_severity(event) do
    high_values = [
      "blocked",
      "fail",
      "error",
      "invalid",
      "review_blocked_validation_safety_case"
    ]

    if Enum.any?(
         [
           event["validation_status"],
           event["issue_severity"],
           event["model_acceptance_status"],
           event["model_status"],
           event["validation_safety_case_status"],
           event["evidence_status"],
           event["freshness_status"],
           event["state_quality_status"],
           event["refresh_budget_status"],
           event["candidate_limit_status"],
           event["required_operator_action"]
         ],
         &(&1 in high_values)
       ) do
      "high"
    else
      "medium"
    end
  end

  defp validation_refresh_pressure_risk_reason(%{"type" => "schema_validation_pressure"} = event) do
    "schema validation #{event["validated_contract"] || event["validated_artifact_family"] || "artifact"} requires review"
  end

  defp validation_refresh_pressure_risk_reason(%{"type" => "model_acceptance_pressure"} = event) do
    "model acceptance #{event["model_id"] || event["report_id"] || "report"} requires review"
  end

  defp validation_refresh_pressure_risk_reason(
         %{"type" => "validation_safety_case_pressure"} = event
       ) do
    "validation safety case #{event["evidence_ref"] || event["report_id"] || "summary"} requires review"
  end

  defp validation_refresh_pressure_risk_reason(%{"type" => "refresh_budget_pressure"} = event) do
    "refresh budget #{event["feedback_key"] || event["candidate_limit_status"] || "report"} requires review"
  end

  defp validation_refresh_pressure_risk_reason(%{"type" => "refresh_freshness_pressure"} = event) do
    "refresh freshness #{event["freshness_status"] || event["state_quality_status"] || "report"} requires review"
  end

  defp validation_refresh_pressure_risk_reason(_event),
    do: "validation or refresh-governance pressure requires review"

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
