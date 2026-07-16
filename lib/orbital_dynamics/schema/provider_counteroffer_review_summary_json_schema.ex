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

  @stable_id_array_map_fields [
    "counteroffer_ids_by_lock_deadline_status"
  ]

  @stable_id_array_fields [
    "review_counteroffer_ids"
  ]

  def property_opts(field, deps) when field in ["rows", "review_rows"] do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts(field, deps)
      when field in @stable_id_array_map_fields or field in @stable_id_array_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(_field, _deps), do: []

  def property_field?(field)
      when field in @count_fields or field in @count_map_fields or
             field in @stable_id_array_map_fields or field in @stable_id_array_fields or
             field in [
               "rows",
               "review_rows",
               "model",
               "source_artifact_type",
               "source_counteroffer_artifact_type",
               "earliest_counteroffer_lock_deadline_s",
               "counteroffer_review_status"
             ],
      do: true

  def property_field?(_field), do: false

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property_from_context(field, deps)
    end
  end

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

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
