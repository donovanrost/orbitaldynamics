defmodule OrbitalDynamics.Schema.ProviderCounterofferJsonSchema do
  @moduledoc false

  def row_from_context(stable_id_pattern, station_calendar) do
    row(
      stable_id_pattern: stable_id_pattern,
      station_calendar: station_calendar
    )
  end

  def row_from_context(deps) do
    row(
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      station_calendar: fetch_dep!(deps, :station_calendar)
    )
  end

  def row(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    station_calendar = Keyword.fetch!(opts, :station_calendar)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "id",
        "provider_counteroffer_id",
        "provider_counteroffer_status",
        "provider_counteroffer_negotiation_state",
        "reviewable",
        "required_operator_action",
        "source_station_calendar_entry"
      ],
      "properties" => %{
        "id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "provider_counteroffer_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "provider_counteroffer_status" => %{"type" => "string"},
        "provider_counteroffer_negotiation_state" => %{
          "type" => "string",
          "enum" => station_calendar.provider_counteroffer_negotiation_states
        },
        "provider_counteroffer_reason_code" => %{"type" => "string"},
        "provider_counteroffer_cost_delta" => %{"type" => "number"},
        "provider_counteroffer_lock_deadline_s" => %{"type" => "number"},
        "provider_counteroffer_starts_at_s" => %{"type" => "number"},
        "provider_counteroffer_ends_at_s" => %{"type" => "number"},
        "provider_counteroffer_start_delta_s" => %{"type" => "number"},
        "provider_counteroffer_end_delta_s" => %{"type" => "number"},
        "provider_counteroffer_duration_delta_s" => %{"type" => "number"},
        "provider_counteroffer_lock_deadline_status" => %{
          "type" => "string",
          "enum" => station_calendar.provider_counteroffer_lock_deadline_statuses
        },
        "provider_counteroffer_import_status" => %{
          "type" => "string",
          "enum" => station_calendar.provider_counteroffer_import_statuses
        },
        "reviewable" => %{"type" => "boolean"},
        "required_operator_action" => %{
          "type" => "string",
          "enum" => station_calendar.provider_counteroffer_actions
        },
        "ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "starts_at_s" => %{"type" => "number"},
        "ends_at_s" => %{"type" => "number"},
        "station_calendar_entry_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "station_calendar_provider_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "station_calendar_provider_entry_id" => %{
          "type" => "string",
          "pattern" => stable_id_pattern
        },
        "station_availability" => %{"type" => "string"},
        "source_station_calendar_entry" => %{"type" => "object"}
      }
    }
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      value when is_function(value, 0) -> value.()
      value -> value
    end
  end
end
