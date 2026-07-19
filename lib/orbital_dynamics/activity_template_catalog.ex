defmodule OrbitalDynamics.ActivityTemplateCatalog do
  @moduledoc false

  alias OrbitalDynamics.{Schema, Timeline}

  @activity_template_schema_contract "activity_template.v1"
  @activity_template_validation_level "artifact_contract"
  @activity_template_version 1
  @activity_template_known_limits [
    "template_only_no_schedule_mutation",
    "no_resource_reservation"
  ]
  @activity_template_assumptions %{
    "boundary" => "template_only_no_schedule_mutation"
  }
  @activity_template_activity_context_fields ~w(
    metadata
    dependency_activity_ids
    dependency_timeline_ids
    exclusive_with_activity_ids
    exclusive_with_timeline_ids
  )
  @activity_template_operational_hint_fields ~w(
    setup_duration_s
    cooldown_duration_s
    telemetry_confirmation_required
    telemetry_confirmation_status
  )
  @activity_template_subsystem_state_hint_fields ~w(
    required_states
    produced_states
  )
  @activity_template_lifecycle_defaults %{
    "status" => "planned",
    "approval_status" => "not_evaluated",
    "locked" => false,
    "allow_overlap" => false
  }
  @activity_template_specs [
    %{
      id: "template:observe:basic",
      activity_type: "observe",
      display_name: "Basic observe activity",
      description: "Reusable evidence contract for a target observation activity template.",
      required_fields: ["id", "type", "target_id", "starts_at_s", "ends_at_s"],
      optional_fields:
        ["payload_id", "instrument_id", "allow_overlap"] ++
          @activity_template_operational_hint_fields,
      default_fields: %{"type" => "observe", "allow_overlap" => false},
      operational_hints: %{
        "setup_duration_s" => 120.0,
        "cooldown_duration_s" => 60.0,
        "telemetry_confirmation_required" => true,
        "telemetry_confirmation_status" => "required"
      },
      subsystem_state_hints: %{
        "required_states" => [
          %{
            "subsystem" => "spacecraft",
            "state" => "standby",
            "reason" => "spacecraft must be outside safe mode",
            "blocking" => true
          },
          %{
            "subsystem" => "payload",
            "state" => "ready",
            "reason" => "payload must be ready before observation",
            "blocking" => true
          }
        ],
        "produced_states" => [
          %{
            "subsystem" => "payload",
            "state" => "observation_collected",
            "reason" => "observation activity produces collection evidence"
          }
        ]
      },
      resource_hints: %{
        "requires_payload" => true,
        "uses_storage" => true,
        "suppressed_activity_types" => ["downlink"],
        "estimated_data_volume_mb" => 48.0
      },
      precondition_hints: [
        %{
          "precondition_type" => "payload_unavailable",
          "status" => "review_required",
          "reason" => "payload availability must be checked",
          "blocking" => true
        }
      ]
    },
    %{
      id: "template:downlink:basic",
      activity_type: "downlink",
      display_name: "Basic downlink",
      description: "Template for a single ground-station downlink activity.",
      required_fields: ["id", "type", "ground_station_id", "starts_at_s", "ends_at_s"],
      optional_fields:
        ["spacecraft_id", "data_volume_mb", "allow_overlap"] ++
          @activity_template_operational_hint_fields,
      default_fields: %{"type" => "downlink", "allow_overlap" => false},
      operational_hints: %{
        "setup_duration_s" => 60.0,
        "cooldown_duration_s" => 30.0,
        "telemetry_confirmation_required" => true,
        "telemetry_confirmation_status" => "required"
      },
      subsystem_state_hints: %{
        "required_states" => [
          %{
            "subsystem" => "antenna",
            "state" => "available",
            "reason" => "antenna must be available for downlink",
            "blocking" => true
          },
          %{
            "subsystem" => "recorder",
            "state" => "data_available",
            "reason" => "recorder must contain downlinkable data",
            "blocking" => true
          }
        ],
        "produced_states" => [
          %{
            "subsystem" => "recorder",
            "state" => "data_transmitted",
            "reason" => "downlink activity produces recorder-transfer evidence"
          }
        ]
      },
      resource_hints: %{
        "requires_antenna" => true,
        "requires_contact" => true,
        "uses_power" => true,
        "estimated_downlink_mb" => 48.0
      },
      precondition_hints: [
        %{
          "precondition_type" => "antenna_unavailable",
          "status" => "review_required",
          "reason" => "station_capacity_blocks_downlink",
          "blocking" => true
        }
      ]
    },
    %{
      id: "template:command:basic",
      activity_type: "command",
      display_name: "Basic command",
      description: "Template for a single command uplink activity.",
      required_fields: ["id", "type", "ground_station_id", "starts_at_s", "ends_at_s"],
      optional_fields:
        ["spacecraft_id", "command_count", "allow_overlap"] ++
          @activity_template_operational_hint_fields,
      default_fields: %{"type" => "command", "allow_overlap" => false},
      operational_hints: %{
        "setup_duration_s" => 90.0,
        "cooldown_duration_s" => 30.0,
        "telemetry_confirmation_required" => true,
        "telemetry_confirmation_status" => "required"
      },
      subsystem_state_hints: %{
        "required_states" => [
          %{
            "subsystem" => "spacecraft",
            "state" => "commandable",
            "reason" => "spacecraft must accept uplinked commands",
            "blocking" => true
          },
          %{
            "subsystem" => "command_receiver",
            "state" => "available",
            "reason" => "command receiver must be available",
            "blocking" => true
          }
        ],
        "produced_states" => [
          %{
            "subsystem" => "command_receiver",
            "state" => "awaiting_confirmation",
            "reason" => "command activity requires telemetry confirmation"
          }
        ]
      },
      resource_hints: %{
        "requires_antenna" => true,
        "requires_contact" => true,
        "uses_power" => true
      },
      precondition_hints: [
        %{
          "precondition_type" => "spacecraft_unavailable",
          "status" => "review_required",
          "reason" => "spacecraft_state_blocks_command",
          "blocking" => true
        }
      ]
    },
    %{
      id: "template:health_check:basic",
      activity_type: "health_check",
      display_name: "Basic health check",
      description: "Template for a spacecraft health-check activity.",
      required_fields: ["id", "type", "starts_at_s", "ends_at_s"],
      optional_fields:
        ["spacecraft_id", "allow_overlap"] ++ @activity_template_operational_hint_fields,
      default_fields: %{"type" => "health_check", "allow_overlap" => true},
      lifecycle_defaults: %{"allow_overlap" => true},
      operational_hints: %{
        "setup_duration_s" => 30.0,
        "cooldown_duration_s" => 15.0,
        "telemetry_confirmation_required" => true,
        "telemetry_confirmation_status" => "required"
      },
      subsystem_state_hints: %{
        "required_states" => [
          %{
            "subsystem" => "spacecraft",
            "state" => "telemetry_available",
            "reason" => "health check needs current telemetry",
            "blocking" => true
          }
        ],
        "produced_states" => [
          %{
            "subsystem" => "spacecraft",
            "state" => "health_reported",
            "reason" => "health-check activity produces health evidence"
          }
        ]
      },
      resource_hints: %{
        "uses_power" => true
      },
      precondition_hints: [
        %{
          "precondition_type" => "spacecraft_unavailable",
          "status" => "review_required",
          "reason" => "spacecraft_state_blocks_health_check",
          "blocking" => true
        }
      ]
    },
    %{
      id: "template:slew:basic",
      activity_type: "slew",
      display_name: "Basic slew",
      description: "Template for an attitude slew activity.",
      required_fields: ["id", "type", "attitude_target_id", "starts_at_s", "ends_at_s"],
      optional_fields:
        ["spacecraft_id", "allow_overlap"] ++ @activity_template_operational_hint_fields,
      default_fields: %{"type" => "slew", "allow_overlap" => false},
      operational_hints: %{
        "setup_duration_s" => 45.0,
        "cooldown_duration_s" => 15.0,
        "telemetry_confirmation_required" => false,
        "telemetry_confirmation_status" => "not_required"
      },
      subsystem_state_hints: %{
        "required_states" => [
          %{
            "subsystem" => "attitude_control",
            "state" => "available",
            "reason" => "attitude control must be available before slew",
            "blocking" => true
          }
        ],
        "produced_states" => [
          %{
            "subsystem" => "attitude_control",
            "state" => "on_target",
            "reason" => "slew produces target-pointing state evidence"
          }
        ]
      },
      resource_hints: %{
        "uses_power" => true
      },
      precondition_hints: [
        %{
          "precondition_type" => "spacecraft_unavailable",
          "status" => "review_required",
          "reason" => "spacecraft_state_blocks_slew",
          "blocking" => true
        }
      ]
    },
    %{
      id: "template:impulsive_burn:basic",
      activity_type: "impulsive_burn",
      display_name: "Basic maneuver",
      description: "Template for a single impulsive maneuver activity.",
      required_fields: ["id", "type", "delta_v_m_s", "starts_at_s", "ends_at_s"],
      optional_fields:
        ["spacecraft_id", "allow_overlap"] ++ @activity_template_operational_hint_fields,
      default_fields: %{"type" => "impulsive_burn", "allow_overlap" => false},
      operational_hints: %{
        "setup_duration_s" => 300.0,
        "cooldown_duration_s" => 300.0,
        "telemetry_confirmation_required" => true,
        "telemetry_confirmation_status" => "required"
      },
      subsystem_state_hints: %{
        "required_states" => [
          %{
            "subsystem" => "propulsion",
            "state" => "ready",
            "reason" => "propulsion subsystem must be ready for maneuver",
            "blocking" => true
          },
          %{
            "subsystem" => "attitude_control",
            "state" => "burn_attitude",
            "reason" => "spacecraft must hold burn attitude",
            "blocking" => true
          }
        ],
        "produced_states" => [
          %{
            "subsystem" => "propulsion",
            "state" => "post_burn_review",
            "reason" => "maneuver requires post-burn review evidence"
          }
        ]
      },
      resource_hints: %{
        "uses_fuel" => true,
        "uses_power" => true
      },
      precondition_hints: [
        %{
          "precondition_type" => "fuel_margin_depleted",
          "status" => "review_required",
          "reason" => "maneuver_margin_blocks_burn",
          "blocking" => true
        }
      ]
    }
  ]

  def templates do
    Enum.map(@activity_template_specs, &activity_template_artifact/1)
  end

  def template(id_or_activity_type) when is_binary(id_or_activity_type) do
    templates()
    |> Enum.find(&activity_template_match?(&1, id_or_activity_type))
    |> case do
      nil -> :error
      template -> {:ok, template}
    end
  end

  def template(_id_or_activity_type), do: :error

  def activity(template_or_id, fields) when is_map(fields) do
    with {:ok, template} <- resolve_activity_template(template_or_id),
         overrides <- stringify_activity_template_keys(fields),
         :ok <- validate_activity_template_overrides(template, overrides),
         {:ok, activity} <- build_activity_from_template(template, overrides) do
      {:ok, activity}
    end
  end

  def activity(_template_or_id, _fields),
    do: {:error, %{reason: "invalid_activity_template_fields"}}

  defp activity_template_artifact(spec) do
    required_fields = Map.fetch!(spec, :required_fields)
    optional_fields = Map.fetch!(spec, :optional_fields)

    %{
      "schema_contract" => @activity_template_schema_contract,
      "id" => Map.fetch!(spec, :id),
      "activity_type" => Map.fetch!(spec, :activity_type),
      "template_version" => @activity_template_version,
      "validation_level" => @activity_template_validation_level,
      "known_limits" => @activity_template_known_limits,
      "display_name" => Map.fetch!(spec, :display_name),
      "description" => Map.fetch!(spec, :description),
      "required_fields" => required_fields,
      "optional_fields" => optional_fields,
      "default_fields" => Map.fetch!(spec, :default_fields),
      "field_count" => length(required_fields) + length(optional_fields),
      "required_field_count" => length(required_fields),
      "optional_field_count" => length(optional_fields),
      "lifecycle_defaults" => activity_template_lifecycle_defaults(spec),
      "operational_hints" => Map.fetch!(spec, :operational_hints),
      "subsystem_state_hints" => Map.fetch!(spec, :subsystem_state_hints),
      "resource_hints" => Map.fetch!(spec, :resource_hints),
      "precondition_hints" => Map.fetch!(spec, :precondition_hints),
      "assumptions" => @activity_template_assumptions
    }
  end

  defp activity_template_lifecycle_defaults(spec) do
    @activity_template_lifecycle_defaults
    |> Map.merge(Map.get(spec, :lifecycle_defaults, %{}))
  end

  defp activity_template_match?(template, id_or_activity_type) do
    id_or_activity_type in [template["id"], template["activity_type"]]
  end

  def capabilities do
    templates = templates()

    %{
      model: :activity_template_catalog,
      artifact_contract: @activity_template_schema_contract,
      validation_level: :artifact_contract,
      supported_activity_types:
        templates
        |> Enum.map(& &1["activity_type"])
        |> Enum.sort(),
      template_ids:
        templates
        |> Enum.map(& &1["id"])
        |> Enum.sort(),
      template_count: length(templates),
      public_facades: [:activity_templates, :activity_template, :activity_from_template],
      output_shape: :normalized_timeline_activity,
      transition_path: :timeline_transition_application,
      operational_hint_fields: @activity_template_operational_hint_fields,
      subsystem_state_hint_fields: @activity_template_subsystem_state_hint_fields,
      known_limits: @activity_template_known_limits,
      assumptions: @activity_template_assumptions
    }
  end

  defp resolve_activity_template(id_or_activity_type) when is_binary(id_or_activity_type) do
    case template(id_or_activity_type) do
      {:ok, template} -> {:ok, template}
      :error -> {:error, %{reason: "unknown_activity_template"}}
    end
  end

  defp resolve_activity_template(%{} = template) do
    template = stringify_activity_template_keys(template)

    with "activity_template.v1" <- Map.get(template, "schema_contract"),
         {:ok, _report} <- Schema.validate_artifact(template) do
      {:ok, template}
    else
      nil ->
        {:error, %{reason: "invalid_activity_template", error: "missing_schema_contract"}}

      contract when is_binary(contract) ->
        {:error,
         %{
           reason: "invalid_activity_template",
           error: "unsupported_schema_contract",
           schema_contract: contract
         }}

      {:error, validation_report} ->
        {:error,
         %{
           reason: "invalid_activity_template",
           validation_report: validation_report
         }}

      contract ->
        {:error,
         %{
           reason: "invalid_activity_template",
           error: "unsupported_schema_contract",
           schema_contract: inspect(contract)
         }}
    end
  end

  defp resolve_activity_template(_template_or_id),
    do: {:error, %{reason: "unknown_activity_template"}}

  defp validate_activity_template_overrides(template, overrides) do
    allowed_fields = activity_template_allowed_fields(template)

    undeclared_fields =
      overrides
      |> Map.keys()
      |> Enum.reject(&MapSet.member?(allowed_fields, &1))
      |> Enum.sort()

    if undeclared_fields == [] do
      :ok
    else
      {:error,
       %{
         reason: "undeclared_activity_template_fields",
         fields: undeclared_fields
       }}
    end
  end

  defp activity_template_allowed_fields(template) do
    template
    |> activity_template_declared_fields()
    |> Enum.concat(["id", "type"])
    |> Enum.concat(Map.keys(Map.get(template, "lifecycle_defaults", %{})))
    |> Enum.concat(@activity_template_activity_context_fields)
    |> MapSet.new()
  end

  defp activity_template_declared_fields(template) do
    (Map.get(template, "required_fields", []) ++ Map.get(template, "optional_fields", []))
    |> Enum.filter(&is_binary/1)
  end

  defp build_activity_from_template(template, overrides) do
    metadata = activity_template_metadata(template, Map.get(overrides, "metadata", %{}))
    fields = Map.drop(overrides, ["metadata"])

    activity =
      template
      |> Map.get("lifecycle_defaults", %{})
      |> Map.merge(Map.get(template, "operational_hints", %{}))
      |> Map.merge(Map.get(template, "default_fields", %{}))
      |> Map.merge(fields)
      |> Map.put("metadata", metadata)

    with :ok <- validate_activity_template_required_fields(template, activity),
         :ok <- validate_activity_template_activity_type(template, activity) do
      activity
      |> Timeline.normalize_activity()
      |> activity_template_normalized_result(template)
    end
  end

  defp activity_template_metadata(_template, metadata) when not is_map(metadata), do: metadata

  defp activity_template_metadata(template, metadata) do
    metadata
    |> stringify_activity_template_keys()
    |> Map.put("activity_template", activity_template_provenance(template))
  end

  defp activity_template_provenance(template) do
    %{
      "schema_contract" => Map.get(template, "schema_contract"),
      "id" => Map.get(template, "id"),
      "activity_type" => Map.get(template, "activity_type"),
      "template_version" => Map.get(template, "template_version"),
      "validation_level" => Map.get(template, "validation_level"),
      "known_limits" => Map.get(template, "known_limits", []),
      "operational_hints" => Map.get(template, "operational_hints", %{}),
      "subsystem_state_hints" => Map.get(template, "subsystem_state_hints", %{}),
      "assumptions" => Map.get(template, "assumptions", %{})
    }
  end

  defp validate_activity_template_required_fields(template, activity) do
    missing_fields =
      template
      |> Map.get("required_fields", [])
      |> Enum.concat(["id", "type"])
      |> Enum.uniq()
      |> Enum.reject(&activity_template_present_field?(activity, &1))
      |> Enum.sort()

    if missing_fields == [] do
      :ok
    else
      {:error,
       %{
         reason: "missing_required_activity_template_fields",
         fields: missing_fields
       }}
    end
  end

  defp activity_template_present_field?(activity, field) do
    case Map.get(activity, field) do
      nil -> false
      "" -> false
      _value -> true
    end
  end

  defp validate_activity_template_activity_type(template, activity) do
    activity_type = activity["type"]
    template_type = template["activity_type"]

    cond do
      is_nil(activity_type) ->
        {:error,
         %{
           reason: "missing_required_activity_template_fields",
           fields: ["type"]
         }}

      to_string(activity_type) == template_type ->
        :ok

      true ->
        {:error,
         %{
           reason: "activity_template_type_mismatch",
           activity_type: activity_type,
           template_activity_type: template_type
         }}
    end
  end

  defp activity_template_normalized_result(
         %{"invalid_activity_input" => true} = activity,
         _template
       ) do
    {:error,
     %{
       reason: "invalid_activity_from_template",
       invalid_activity_input_reason: activity["invalid_activity_input_reason"],
       activity: activity
     }}
  end

  defp activity_template_normalized_result(activity, template) do
    provenance = activity_template_provenance(template)

    activity =
      activity
      |> Map.put("activity_template", provenance)
      |> Map.update("activity_context", %{"activity_template" => provenance}, fn context ->
        Map.put(context, "activity_template", provenance)
      end)

    {:ok, activity}
  end

  defp stringify_activity_template_keys(%{} = map) do
    Map.new(map, fn {key, value} ->
      {stringify_activity_template_key(key), stringify_activity_template_keys(value)}
    end)
  end

  defp stringify_activity_template_keys(values) when is_list(values),
    do: Enum.map(values, &stringify_activity_template_keys/1)

  defp stringify_activity_template_keys(value), do: value

  defp stringify_activity_template_key(key) when is_atom(key), do: Atom.to_string(key)
  defp stringify_activity_template_key(key) when is_binary(key), do: key
  defp stringify_activity_template_key(key), do: to_string(key)
end
