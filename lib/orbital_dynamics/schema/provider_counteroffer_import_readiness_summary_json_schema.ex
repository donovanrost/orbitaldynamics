defmodule OrbitalDynamics.Schema.ProviderCounterofferImportReadinessSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "counteroffer_count",
    "reviewable_count",
    "ready_for_import_count",
    "review_required_before_import_count",
    "no_import_required_count"
  ]

  @count_map_fields [
    "counteroffer_status_counts",
    "counteroffer_negotiation_state_counts",
    "required_import_action_counts",
    "provider_counteroffer_import_status_counts",
    "counteroffer_lock_deadline_status_counts"
  ]

  @stable_id_array_map_fields [
    "counteroffer_ids_by_required_import_action",
    "counteroffer_ids_by_import_status",
    "counteroffer_ids_by_lock_deadline_status"
  ]

  @stable_id_array_fields [
    "review_counteroffer_ids",
    "no_import_required_counteroffer_ids"
  ]

  def property("import_readiness_rows", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property("model", _opts) do
    %{
      "type" => "string",
      "const" => "artifact_only_provider_counteroffer_import_readiness_summary"
    }
  end

  def property("source_artifact_type", _opts) do
    %{"type" => "string", "enum" => ["provider_counteroffer_report.v1"]}
  end

  def property("source_counteroffer_artifact_type", _opts) do
    %{
      "type" => "string",
      "enum" => ["station_calendar_provider.v1", "station_calendar_report.v1"]
    }
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("import_readiness_status", opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :readiness_statuses)}
  end

  def property("import_classification", opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :import_classifications)}
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end
end
