defmodule OrbitalDynamics.CadenceImport.CampaignRowBuilder do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.{
    BranchEvidenceFields,
    JsonNormalization,
    ManifestMapNormalization,
    ProviderResultNormalization
  }

  def proposed_contact(contact, rank) do
    OrbitalDynamics.CadenceImport.ProposedContactManifestRow.build(
      contact,
      rank,
      encode_json_value: &encode_json_value/1,
      normalize_provider_result_artifact_fields: &normalize_provider_result_artifact_fields/1,
      compact_map: &compact_map/1
    )
  end

  def strategy(row, recommendation, rank, operational_feedback_context) do
    OrbitalDynamics.CadenceImport.StrategyManifestRow.build(
      row,
      recommendation,
      rank,
      operational_feedback_context,
      branch_timeline_evidence_fields: &branch_timeline_evidence_fields/0,
      branch_readiness_quality_gate_fields: &branch_readiness_quality_gate_fields/0,
      branch_contact_allocation_fields: &branch_contact_allocation_fields/0,
      stringify_keys: &stringify_keys/1,
      compact_map: &compact_map/1
    )
  end

  def operational_feedback_context(provenance) do
    OrbitalDynamics.CadenceImport.OperationalFeedbackManifestContext.build(
      provenance,
      stringify_keys: &stringify_keys/1,
      encode_json_value: &encode_json_value/1,
      compact_map: &compact_map/1
    )
  end

  defp branch_contact_allocation_fields,
    do: BranchEvidenceFields.contact_allocation()

  defp branch_readiness_quality_gate_fields,
    do: BranchEvidenceFields.readiness_quality_gate()

  defp branch_timeline_evidence_fields,
    do: BranchEvidenceFields.timeline()

  defp stringify_keys(value), do: JsonNormalization.stringify_keys(value)

  defp encode_json_value(value), do: JsonNormalization.encode_json_value(value)

  defp normalize_provider_result_artifact_fields(value),
    do: ProviderResultNormalization.normalize_artifact_fields(value)

  defp compact_map(map), do: ManifestMapNormalization.compact(map)
end
