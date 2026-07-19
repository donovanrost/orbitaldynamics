defmodule OrbitalDynamics.TimelineFeedback.ReconciliationRealizedIngressEvidence do
  @moduledoc false

  def context(realized) do
    %{
      "realized_timeline_id" => value(realized, "timeline_id"),
      "realized_activity_id" => value(realized, "realized_activity_id"),
      "realized_source" => value(realized, "source"),
      "realized_provider" => value(realized, "provider"),
      "realized_source_quality" => value(realized, "source_quality"),
      "realized_adapter" => value(realized, "adapter"),
      "realized_adapter_version" => value(realized, "adapter_version"),
      "realized_external_id" => value(realized, "external_id"),
      "realized_schema_contract" => value(realized, "schema_contract"),
      "realized_trust_boundary" => value(realized, "trust_boundary"),
      "realized_received_at" => value(realized, "received_at"),
      "realized_ingested_at" => value(realized, "ingested_at"),
      "realized_provenance" => value(realized, "provenance"),
      "invalid_realized_feedback_input" => value(realized, "invalid_realized_feedback_input"),
      "invalid_realized_feedback_input_reason" =>
        value(realized, "invalid_realized_feedback_input_reason"),
      "invalid_realized_feedback_sections" =>
        value(realized, "invalid_realized_feedback_sections"),
      "unsupported_realized_status" => value(realized, "unsupported_realized_status"),
      "invalid_cadence_import" => value(realized, "invalid_cadence_import"),
      "invalid_cadence_import_reason" => value(realized, "invalid_cadence_import_reason"),
      "source_cadence_import" => value(realized, "source_cadence_import")
    }
  end

  defp value(nil, _key), do: nil
  defp value(map, key), do: Map.get(map, key)
end
