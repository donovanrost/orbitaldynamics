defmodule OrbitalDynamics.Schema.ProviderCounterofferRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "provider_counteroffer_report.v1" => %{
        "schema_contract" => "provider_counteroffer_report.v1",
        "artifact_family" => "provider_counteroffer_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source",
          "source_artifact_type",
          "source_artifact_id",
          "counteroffer_count",
          "reviewable_count",
          "counteroffer_cost_delta_count",
          "counteroffer_cost_delta_total",
          "counteroffer_lock_deadline_count",
          "counteroffer_status_counts",
          "counteroffer_negotiation_state_counts",
          "required_operator_action_counts",
          "rows",
          "assumptions"
        ],
        "optional_fields" => [
          "earliest_counteroffer_lock_deadline_s",
          "model_limits"
        ],
        "nested_contracts" => ["station_calendar_provider.v1", "station_calendar_report.v1"]
      },
      "provider_counteroffer_review_summary.v1" => %{
        "schema_contract" => "provider_counteroffer_review_summary.v1",
        "artifact_family" => "provider_counteroffer_review_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source_artifact_type",
          "counteroffer_count",
          "reviewable_count",
          "counteroffer_review_status",
          "counteroffer_status_counts",
          "counteroffer_negotiation_state_counts",
          "counteroffer_lock_deadline_count",
          "counteroffer_lock_deadline_status_counts",
          "counteroffer_ids_by_lock_deadline_status",
          "expired_counteroffer_lock_deadline_count",
          "active_counteroffer_lock_deadline_count",
          "missing_counteroffer_lock_deadline_count",
          "review_counteroffer_ids",
          "rows",
          "review_rows",
          "assumptions"
        ],
        "optional_fields" => [
          "source",
          "source_counteroffer_artifact_type",
          "source_artifact_id",
          "earliest_counteroffer_lock_deadline_s",
          "model_limits"
        ],
        "nested_contracts" => ["provider_counteroffer_report.v1"]
      },
      "provider_counteroffer_import_readiness_summary.v1" => %{
        "schema_contract" => "provider_counteroffer_import_readiness_summary.v1",
        "artifact_family" => "provider_counteroffer_import_readiness_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source_artifact_type",
          "counteroffer_count",
          "reviewable_count",
          "import_readiness_status",
          "import_classification",
          "ready_for_import_count",
          "review_required_before_import_count",
          "no_import_required_count",
          "counteroffer_status_counts",
          "counteroffer_negotiation_state_counts",
          "required_import_action_counts",
          "provider_counteroffer_import_status_counts",
          "counteroffer_lock_deadline_status_counts",
          "counteroffer_ids_by_required_import_action",
          "counteroffer_ids_by_import_status",
          "counteroffer_ids_by_lock_deadline_status",
          "review_counteroffer_ids",
          "no_import_required_counteroffer_ids",
          "import_readiness_rows",
          "assumptions"
        ],
        "optional_fields" => [
          "source",
          "source_counteroffer_artifact_type",
          "source_artifact_id",
          "model_limits"
        ],
        "nested_contracts" => ["provider_counteroffer_report.v1"]
      },
      "provider_counteroffer_plan_impact_summary.v1" => %{
        "schema_contract" => "provider_counteroffer_plan_impact_summary.v1",
        "artifact_family" => "provider_counteroffer_plan_impact_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source_artifact_type",
          "counteroffer_count",
          "reviewable_count",
          "plan_impact_status",
          "timing_shift_counteroffer_count",
          "counteroffer_cost_delta_count",
          "counteroffer_cost_delta_total",
          "counteroffer_lock_deadline_status_counts",
          "affected_station_calendar_entry_ids",
          "affected_provider_entry_ids",
          "impact_counteroffer_ids",
          "timing_shift_counteroffer_ids",
          "cost_delta_counteroffer_ids",
          "counteroffer_ids_by_lock_deadline_status",
          "rows",
          "impact_rows",
          "assumptions"
        ],
        "optional_fields" => [
          "source",
          "source_counteroffer_artifact_type",
          "source_artifact_id",
          "model_limits"
        ],
        "nested_contracts" => ["provider_counteroffer_report.v1"]
      }
    }
  end
end
