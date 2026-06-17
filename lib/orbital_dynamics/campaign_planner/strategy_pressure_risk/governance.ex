defmodule OrbitalDynamics.CampaignPlanner.StrategyPressureRisk.Governance do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.StrategyPressureRisk.ValidationRefresh

  def operational_readiness_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &operational_readiness_pressure_risk?/1)
  end

  defp operational_readiness_pressure_risk?(%{"type" => "operational_readiness_pressure"} = risk) do
    not operational_readiness_operator_training_pressure_risk?(risk) and
      not operational_readiness_import_readiness_pressure_risk?(risk) and
      not ValidationRefresh.operational_readiness_schema_validation_pressure_risk?(risk) and
      not operational_readiness_resource_availability_pressure_risk?(risk)
  end

  defp operational_readiness_pressure_risk?(_risk), do: false

  def operational_readiness_pressure_event_risk?(%{
        "type" => "operational_readiness_pressure"
      }),
      do: true

  def operational_readiness_pressure_event_risk?(_risk), do: false

  def quality_gate_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &quality_gate_pressure_risk?/1)
  end

  defp quality_gate_pressure_risk?(%{"type" => "quality_gate_pressure"} = risk) do
    not operator_training_pressure_risk?(risk) and
      not ValidationRefresh.schema_validation_quality_gate_pressure_risk?(risk) and
      not import_readiness_pressure_risk?(risk) and
      not resource_availability_quality_gate_pressure_risk?(risk)
  end

  defp quality_gate_pressure_risk?(_risk), do: false

  def quality_gate_pressure_event_risk?(%{"type" => "quality_gate_pressure"}), do: true
  def quality_gate_pressure_event_risk?(_risk), do: false

  def operator_training_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &operator_training_pressure_risk?/1)
  end

  defp operator_training_pressure_risk?(%{"type" => "quality_gate_pressure"} = risk) do
    risk["gate_id"] == "operator_training" or
      risk["operator_training_requirement_count"] not in [nil, 0] or
      get_in(risk, ["source_quality_gate_report", "schema_contract"]) ==
        "operational_quality_gate_operator_training_summary.v1"
  end

  defp operator_training_pressure_risk?(%{"type" => "operational_readiness_pressure"} = risk) do
    operational_readiness_operator_training_pressure_risk?(risk)
  end

  defp operator_training_pressure_risk?(_risk), do: false

  defp operational_readiness_operator_training_pressure_risk?(
         %{"type" => "operational_readiness_pressure"} = risk
       ) do
    risk["readiness_gate_id"] == "operator_training" or
      risk["operator_training_requirement_count"] not in [nil, 0] or
      is_map(risk["operator_training_requirement_counts"]) or
      risk["required_operator_roles"] not in [nil, []] or
      risk["required_training_ids"] not in [nil, []] or
      risk["required_certification_ids"] not in [nil, []] or
      risk["required_qualification_ids"] not in [nil, []]
  end

  defp operational_readiness_operator_training_pressure_risk?(_risk), do: false

  def import_readiness_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &import_readiness_pressure_risk?/1)
  end

  defp import_readiness_pressure_risk?(%{"type" => "quality_gate_pressure"} = risk) do
    risk["import_blocked"] == true or
      risk["freshness_review_required"] == true or
      risk["import_preparation_required"] == true or
      is_map(risk["freshness_status_counts"]) or
      is_map(risk["import_status_counts"]) or
      is_map(risk["cadence_import_status_counts"]) or
      get_in(risk, ["source_quality_gate_report", "schema_contract"]) ==
        "operational_quality_gate_import_readiness_summary.v1"
  end

  defp import_readiness_pressure_risk?(%{"type" => "operational_readiness_pressure"} = risk) do
    operational_readiness_import_readiness_pressure_risk?(risk)
  end

  defp import_readiness_pressure_risk?(_risk), do: false

  defp operational_readiness_import_readiness_pressure_risk?(
         %{"type" => "operational_readiness_pressure"} = risk
       ) do
    risk["readiness_gate_id"] in ["cadence_import", "import_readiness"] or
      risk["import_blocked"] == true or
      risk["freshness_review_required"] == true or
      risk["import_preparation_required"] == true or
      numeric_or_nil(risk["import_readiness_row_count"]) not in [nil, 0.0] or
      numeric_or_nil(risk["manifest_review_required_count"]) not in [nil, 0.0] or
      numeric_or_nil(risk["blocked_import_count"]) not in [nil, 0.0] or
      numeric_or_nil(risk["missing_import_count"]) not in [nil, 0.0] or
      numeric_or_nil(risk["invalid_cadence_import_count"]) not in [nil, 0.0] or
      is_map(risk["freshness_status_counts"]) or
      is_map(risk["import_status_counts"]) or
      is_map(risk["cadence_import_status_counts"])
  end

  defp operational_readiness_import_readiness_pressure_risk?(_risk), do: false

  def approval_boundary_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &approval_boundary_pressure_risk?/1)
  end

  defp approval_boundary_pressure_risk?(%{"type" => "approval_boundary_pressure"}), do: true
  defp approval_boundary_pressure_risk?(_risk), do: false

  def resource_availability_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &resource_availability_pressure_risk?/1)
  end

  defp resource_availability_pressure_risk?(%{"feedback_scope" => "resource_filter"}),
    do: false

  defp resource_availability_pressure_risk?(%{"type" => "resource_unavailable"}), do: true

  defp resource_availability_pressure_risk?(%{"type" => "quality_gate_pressure"} = risk) do
    resource_availability_quality_gate_pressure_risk?(risk)
  end

  defp resource_availability_pressure_risk?(%{"type" => "operational_readiness_pressure"} = risk) do
    operational_readiness_resource_availability_pressure_risk?(risk)
  end

  defp resource_availability_pressure_risk?(%{"type" => type}) do
    type in resource_projection_availability_pressure_types()
  end

  defp resource_availability_pressure_risk?(_risk), do: false

  defp resource_availability_quality_gate_pressure_risk?(
         %{"type" => "quality_gate_pressure"} = risk
       ) do
    risk["gate_id"] == "resource_availability" or
      numeric_or_nil(risk["resource_availability_pressure_count"]) not in [nil, 0.0] or
      is_map(risk["resource_availability_reason_counts"]) or
      is_map(risk["unavailable_resource_reason_counts"]) or
      is_map(risk["blocked_contact_ids_by_blocking_dimension"]) or
      get_in(risk, ["source_quality_gate_report", "schema_contract"]) ==
        "operational_quality_gate_unavailable_resource_summary.v1"
  end

  defp resource_availability_quality_gate_pressure_risk?(_risk), do: false

  defp operational_readiness_resource_availability_pressure_risk?(
         %{"type" => "operational_readiness_pressure"} = risk
       ) do
    risk["readiness_gate_id"] == "resource_availability" or
      numeric_or_nil(risk["resource_availability_pressure_count"]) not in [nil, 0.0] or
      is_map(risk["resource_availability_reason_counts"]) or
      is_map(risk["unavailable_resource_reason_counts"]) or
      is_map(risk["blocked_contact_ids_by_blocking_dimension"])
  end

  defp operational_readiness_resource_availability_pressure_risk?(_risk), do: false

  defp resource_projection_availability_pressure_types do
    ~w(spacecraft_unavailable payload_unavailable spacecraft_degraded_payload_unavailable antenna_unavailable activity_type_suppressed_by_resource_summary activity_type_incompatible_with_resource_summary)
  end

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
