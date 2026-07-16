defmodule OrbitalDynamics.Schema.StationReservationReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "affected_contact_reservation_count",
    "provider_calendar_contention_group_count",
    "reservation_review_count"
  ]

  @stable_id_array_map_fields [
    "reservation_ids_by_status",
    "reservation_ids_by_match_status"
  ]

  @stable_id_fields ["reservation_ids" | @stable_id_array_map_fields]

  @count_map_fields [
    "station_reservation_match_status_counts",
    "reservation_status_counts"
  ]

  def property_field?(field)
      when field in [
             "schema_contract",
             "model",
             "source",
             "affected_contacts",
             "provider_calendar_contention_groups",
             "reservation_review_status"
           ],
      do: true

  def property_field?(field)
      when field in @count_fields or field in @stable_id_fields or field in @count_map_fields,
      do: true

  def property_field?(_field), do: false

  def property_opts("model", deps) do
    [models: fetch_dep!(deps, :models)]
  end

  def property_opts("affected_contacts", deps) do
    [contact_schema: fetch_dep!(deps, :contact_schema)]
  end

  def property_opts("provider_calendar_contention_groups", deps) do
    [provider_contention_group_schema: fetch_dep!(deps, :provider_contention_group_schema)]
  end

  def property_opts(field, deps) when field in @stable_id_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(_field, _deps), do: []

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property("schema_contract", _opts) do
    %{"type" => "string", "const" => "station_reservation_report.v1"}
  end

  def property("model", opts) do
    %{"type" => "string", "enum" => Keyword.fetch!(opts, :models)}
  end

  def property("source", _opts) do
    %{"type" => "string"}
  end

  def property("affected_contacts", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :contact_schema)}
  end

  def property("provider_calendar_contention_groups", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :provider_contention_group_schema)
    }
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("reservation_review_status", _opts) do
    %{"type" => "string", "enum" => ["clear", "review_required"]}
  end

  def property("reservation_ids", opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def contact(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    approval_requirement_schema = Keyword.fetch!(opts, :approval_requirement_schema)
    policy_decision_rule_match_schema = Keyword.fetch!(opts, :policy_decision_rule_match_schema)
    policy_decision_schema = Keyword.fetch!(opts, :policy_decision_schema)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "id" => stable_id(stable_id_pattern),
        "contact_id" => stable_id(stable_id_pattern),
        "ground_station_id" => stable_id(stable_id_pattern),
        "starts_at_s" => %{"type" => "number"},
        "ends_at_s" => %{"type" => "number"},
        "overlap_starts_at_s" => %{"type" => "number"},
        "overlap_ends_at_s" => %{"type" => "number"},
        "overlap_duration_s" => %{"type" => "number"},
        "station_calendar_entry_id" => stable_id(stable_id_pattern),
        "station_calendar_provider_id" => stable_id(stable_id_pattern),
        "station_calendar_provider_entry_id" => stable_id(stable_id_pattern),
        "station_calendar_entry_ambiguous" => %{"type" => "boolean"},
        "station_calendar_ambiguous_entry_count" => %{"type" => "integer", "minimum" => 0},
        "station_calendar_ambiguous_entry_ids" =>
          CommonJsonSchema.stable_id_array(stable_id_pattern),
        "station_contention_status" => %{"type" => "string"},
        "station_reservation_match_status" => %{"type" => "string"},
        "station_reservation_id" => stable_id(stable_id_pattern),
        "station_reserved_by" => %{"type" => "string"},
        "station_reservation_status" => %{"type" => "string"},
        "station_reservation_expires_at_s" => %{"type" => "number"},
        "station_calendar_reservation_overlap_count" => %{
          "type" => "integer",
          "minimum" => 0
        },
        "station_calendar_reservation_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
        "station_calendar_reserved_by" => CommonJsonSchema.string_array(),
        "station_calendar_reservation_statuses" => CommonJsonSchema.string_array(),
        "station_calendar_reservation_expires_at_s" => CommonJsonSchema.number_array(),
        "required_operator_action" => %{"type" => "string"},
        "operator_action_reason" => %{"type" => "string"},
        "approval_status" => %{
          "type" => "string",
          "enum" => ["auto_approvable", "operator_review_required", "blocked_by_policy"]
        },
        "approval_requirements" => %{
          "type" => "array",
          "items" => approval_requirement_schema
        },
        "approval_rule_matches" => %{
          "type" => "array",
          "items" => policy_decision_rule_match_schema
        },
        "policy_decision" => policy_decision_schema
      }
    }
  end

  def provider_contention_group(opts) do
    opts
    |> Keyword.fetch!(:calendar_group_schema)
    |> Map.delete("required")
  end

  defp stable_id(stable_id_pattern) do
    %{"type" => "string", "pattern" => stable_id_pattern}
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
