defmodule OrbitalDynamics.Schema.ProviderCounterofferReviewSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "counteroffer_count",
    "reviewable_count",
    "counteroffer_lock_deadline_count",
    "expired_counteroffer_lock_deadline_count",
    "active_counteroffer_lock_deadline_count",
    "missing_counteroffer_lock_deadline_count"
  ]

  @count_map_fields [
    "counteroffer_status_counts",
    "counteroffer_negotiation_state_counts",
    "counteroffer_lock_deadline_status_counts"
  ]

  def property(field, opts) when field in ["rows", "review_rows"] do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_provider_counteroffer_review_summary"}
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

  def property("earliest_counteroffer_lock_deadline_s", _opts) do
    %{"type" => "number"}
  end

  def property("counteroffer_review_status", _opts) do
    %{"type" => "string", "enum" => ["clear", "review_required"]}
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property("counteroffer_ids_by_lock_deadline_status", opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def property("review_counteroffer_ids", opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end
end
