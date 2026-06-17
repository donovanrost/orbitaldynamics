defmodule OrbitalDynamics.Schema.ContactContentionJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @contact_contention_report "contact_contention_report.v1"
  @contact_contention_resolution_report "contact_contention_resolution_report.v1"
  @contact_contention_resolution_summary "contact_contention_resolution_summary.v1"

  @report_count_fields [
    "input_contact_count",
    "conflicted_contact_count",
    "conflict_group_count",
    "duplicate_contact_candidate_count",
    "duplicate_contact_id_count",
    "invalid_contact_input_count"
  ]

  @summary_count_fields [
    "conflict_group_count",
    "recommendation_count",
    "review_recommendation_count"
  ]

  @summary_count_map_fields [
    "resource_scope_counts",
    "selection_reason_counts",
    "action_counts",
    "required_capacity_fraction_source_counts"
  ]

  @summary_number_fields [
    "capacity_pack_required_capacity_fraction",
    "capacity_pack_selected_required_capacity_fraction",
    "capacity_pack_deferred_required_capacity_fraction"
  ]

  @summary_number_map_fields [
    "capacity_pack_required_capacity_fraction_by_status",
    "capacity_pack_required_capacity_fraction_by_ground_station_id",
    "capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
    "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"
  ]

  @summary_stable_id_array_fields [
    "recommendation_group_ids",
    "review_group_ids",
    "selected_contact_ids",
    "deferred_contact_ids",
    "ambiguous_group_ids",
    "ambiguous_duplicate_contact_ids",
    "review_contact_ids"
  ]

  @summary_stable_id_array_map_fields [
    "selected_contact_ids_by_group_id",
    "deferred_contact_ids_by_group_id",
    "ambiguous_duplicate_contact_ids_by_group_id",
    "review_contact_ids_by_group_id",
    "selected_contact_ids_by_resource_scope",
    "deferred_contact_ids_by_resource_scope",
    "review_contact_ids_by_resource_scope",
    "selected_contact_ids_by_selection_reason",
    "review_contact_ids_by_action",
    "required_capacity_fraction_contact_ids_by_source"
  ]

  def property("conflict_groups", @contact_contention_report, opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :conflict_group_schema)}
  end

  def property("invalid_contact_input_ids", @contact_contention_report, opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property("invalid_contact_inputs", @contact_contention_report, _opts) do
    %{
      "type" => "array",
      "items" => %{"type" => "object", "additionalProperties" => true}
    }
  end

  def property("model", @contact_contention_report, _opts) do
    %{"type" => "string", "const" => "single_station_interval_overlap"}
  end

  def property(field, @contact_contention_report, _opts) when field in @report_count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("model_limits", @contact_contention_report, opts) do
    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => Keyword.fetch!(opts, :model_limits)}
    }
  end

  def property("assumptions", @contact_contention_report, opts) do
    Keyword.fetch!(opts, :report_assumptions_schema)
  end

  def property(field, @contact_contention_resolution_report, _opts)
      when field in ["conflict_group_count", "recommendation_count"] do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("model", @contact_contention_resolution_report, _opts) do
    %{"type" => "string", "const" => "deterministic_contact_contention_recommendation"}
  end

  def property("model_limits", @contact_contention_resolution_report, opts) do
    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => Keyword.fetch!(opts, :model_limits)}
    }
  end

  def property("recommendations", @contact_contention_resolution_report, opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :recommendation_schema)}
  end

  def property("policy", @contact_contention_resolution_report, opts) do
    Keyword.fetch!(opts, :resolution_policy_schema)
  end

  def property("schema_contract", @contact_contention_resolution_summary, opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :schema_contract)}
  end

  def property("source_artifact_type", @contact_contention_resolution_summary, opts) do
    %{"type" => "string", "enum" => [Keyword.fetch!(opts, :source_artifact_type)]}
  end

  def property("model", @contact_contention_resolution_summary, _opts) do
    %{"type" => "string", "const" => "artifact_only_contact_contention_resolution_summary"}
  end

  def property("model_limits", @contact_contention_resolution_summary, opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("policy", @contact_contention_resolution_summary, opts) do
    Keyword.fetch!(opts, :resolution_policy_schema)
  end

  def property(field, @contact_contention_resolution_summary, _opts)
      when field in @summary_count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, @contact_contention_resolution_summary, _opts)
      when field in @summary_count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, @contact_contention_resolution_summary, _opts)
      when field in @summary_number_fields do
    %{"type" => "number", "minimum" => 0}
  end

  def property(field, @contact_contention_resolution_summary, _opts)
      when field in @summary_number_map_fields do
    CommonJsonSchema.non_negative_number_map()
  end

  def property(field, @contact_contention_resolution_summary, opts)
      when field in @summary_stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, @contact_contention_resolution_summary, opts)
      when field in @summary_stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end
end
