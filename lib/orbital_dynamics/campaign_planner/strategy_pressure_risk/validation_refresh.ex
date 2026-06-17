defmodule OrbitalDynamics.CampaignPlanner.StrategyPressureRisk.ValidationRefresh do
  @moduledoc false

  def model_acceptance_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &model_acceptance_pressure_risk?/1)
  end

  def model_acceptance_pressure_risk?(%{"feedback_scope" => "model_acceptance"}),
    do: true

  def model_acceptance_pressure_risk?(%{"type" => "model_acceptance_pressure"}),
    do: true

  def model_acceptance_pressure_risk?(_risk), do: false

  def schema_validation_pressure_risk?(%{"feedback_scope" => "schema_validation"}),
    do: true

  def schema_validation_pressure_risk?(%{"type" => "schema_validation_pressure"}),
    do: true

  def schema_validation_pressure_risk?(_risk), do: false

  def schema_validation_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &schema_validation_pressure_risk?/1)
  end

  def refresh_freshness_pressure_risk?(%{"feedback_scope" => "refresh_freshness"}),
    do: true

  def refresh_freshness_pressure_risk?(%{"type" => "refresh_freshness_pressure"}),
    do: true

  def refresh_freshness_pressure_risk?(_risk), do: false

  def refresh_freshness_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &refresh_freshness_pressure_risk?/1)
  end

  def refresh_budget_pressure_risk?(%{"feedback_scope" => "refresh_budget"}),
    do: true

  def refresh_budget_pressure_risk?(%{"type" => "refresh_budget_pressure"}),
    do: true

  def refresh_budget_pressure_risk?(_risk), do: false

  def refresh_budget_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &refresh_budget_pressure_risk?/1)
  end

  def validation_safety_case_pressure_risk?(%{"feedback_scope" => "validation_safety_case"}),
    do: true

  def validation_safety_case_pressure_risk?(%{"type" => "validation_safety_case_pressure"}),
    do: true

  def validation_safety_case_pressure_risk?(_risk), do: false

  def validation_safety_case_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &validation_safety_case_pressure_risk?/1)
  end

  def validation_refresh_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &validation_refresh_pressure_risk?/1)
  end

  defp validation_refresh_pressure_risk?(%{"type" => "quality_gate_pressure"} = risk) do
    schema_validation_quality_gate_pressure_risk?(risk)
  end

  defp validation_refresh_pressure_risk?(%{"type" => "operational_readiness_pressure"} = risk) do
    operational_readiness_schema_validation_pressure_risk?(risk)
  end

  defp validation_refresh_pressure_risk?(_risk), do: false

  def schema_validation_quality_gate_pressure_risk?(%{"type" => "quality_gate_pressure"} = risk) do
    risk["schema_validation_import_blocked"] == true or
      is_map(risk["schema_validation_status_counts"]) or
      get_in(risk, ["source_quality_gate_report", "schema_contract"]) ==
        "operational_quality_gate_schema_validation_summary.v1"
  end

  def schema_validation_quality_gate_pressure_risk?(_risk), do: false

  def operational_readiness_schema_validation_pressure_risk?(
        %{"type" => "operational_readiness_pressure"} = risk
      ) do
    risk["schema_validation_import_blocked"] == true or
      numeric_or_nil(risk["schema_validation_row_count"]) not in [nil, 0.0] or
      numeric_or_nil(risk["schema_validation_fail_count"]) not in [nil, 0.0] or
      numeric_or_nil(risk["schema_validation_error_count"]) not in [nil, 0.0] or
      numeric_or_nil(risk["schema_validation_warning_count"]) not in [nil, 0.0] or
      numeric_or_nil(risk["schema_validation_remediation_count"]) not in [nil, 0.0] or
      is_map(risk["schema_validation_status_counts"]) or
      risk["failed_schema_validation_quality_gate_row_ids"] not in [nil, []]
  end

  def operational_readiness_schema_validation_pressure_risk?(_risk), do: false

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil
end
