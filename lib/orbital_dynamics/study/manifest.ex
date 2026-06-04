defmodule OrbitalDynamics.Study.Manifest do
  @moduledoc """
  JSON manifest loader for reproducible study execution.

  The first manifest schema is intentionally narrow. It supports explicit
  Cartesian scenarios, mission-plan timelines, and the deterministic
  `circular_leo` scenario generator used by benchmark/demo studies.
  """

  alias OrbitalDynamics.Benchmark.ScenarioFixture
  alias OrbitalDynamics.Maneuver.ImpulsiveBurn
  alias OrbitalDynamics.MissionPlan
  alias OrbitalDynamics.MissionPlan.Activity
  alias OrbitalDynamics.ResultSet.Report

  alias OrbitalDynamics.Environment.{
    ConstantEarthRotationProvider,
    TabularEarthOrientationProvider
  }

  alias OrbitalDynamics.{
    CentralBody,
    Epoch,
    Frame,
    GroundStation,
    OrbitData,
    Scenario,
    ResourceSummary,
    Schema,
    Spacecraft,
    StateVector,
    Study,
    StudyRunner,
    Target,
    Search.Grid,
    Search.MonteCarlo
  }

  alias OrbitalDynamics.Propagators.{
    J2,
    J2ExlaCpu,
    TwoBody,
    TwoBodyExlaCpu,
    TwoBodyNx,
    TwoBodyNxCompiled
  }

  @schema_version 1
  @propagators %{
    "two_body" => TwoBody,
    "two_body_nx" => TwoBodyNx,
    "two_body_nx_compiled" => TwoBodyNxCompiled,
    "two_body_exla_cpu" => TwoBodyExlaCpu,
    "j2" => J2,
    "j2_exla_cpu" => J2ExlaCpu
  }
  @propagator_opts %{
    "max_step_s" => :max_step_s,
    "integration" => :integration,
    "min_step_s" => :min_step_s,
    "adaptive_position_tolerance_km" => :adaptive_position_tolerance_km,
    "adaptive_velocity_tolerance_km_s" => :adaptive_velocity_tolerance_km_s
  }
  @outputs %{
    "trajectories" => :trajectories,
    "access_windows" => :access_windows,
    "eclipses" => :eclipses,
    "target_visibility" => :target_visibility,
    "ground_track_crossings" => :ground_track_crossings
  }
  @json_schema_draft "https://json-schema.org/draft/2020-12/schema"
  @json_schema_contract "study_manifest.v1"
  @lint_schema_contract "study_manifest_lint.v1"
  @semantic_validator "OrbitalDynamics.Study.Manifest.from_map/1 + OrbitalDynamics.StudyRunner.validate_run_inputs/2"
  @lint_error_codes [
    "file_error",
    "invalid_field",
    "invalid_json",
    "invalid_json_object",
    "invalid_manifest",
    "invalid_output",
    "invalid_run_option",
    "manifest_error",
    "missing_field",
    "missing_run_option",
    "unsupported_central_body",
    "unsupported_option",
    "unsupported_output",
    "unsupported_propagator",
    "unsupported_schema_version"
  ]
  @run_option_keys %{
    "max_concurrency" => :max_concurrency,
    "timeout" => :timeout,
    "task_chunk_size" => :task_chunk_size
  }
  @search_objectives Report.supported_objectives()

  @enforce_keys [:study, :run_opts, :central_body, :ground_stations, :targets, :source]
  defstruct [:study, :run_opts, :central_body, :ground_stations, :targets, :source]

  @type t :: %__MODULE__{
          study: Study.t(),
          run_opts: keyword(),
          central_body: CentralBody.t(),
          ground_stations: [GroundStation.t()],
          targets: [Target.t()],
          source: map()
        }

  @doc """
  Loads a study manifest from JSON on disk.
  """
  def from_file(path) when is_binary(path) do
    with {:ok, content} <- File.read(path),
         {:ok, source} <- decode_json(content),
         {:ok, manifest} <- from_map(source) do
      manifest_metadata = %{
        path: path,
        sha256: sha256(content)
      }

      {:ok,
       %{
         manifest
         | run_opts: manifest.run_opts ++ [manifest: manifest_metadata],
           source: Map.put(manifest.source, "manifest_path", path)
       }}
    else
      {:error, %File.Error{} = error} -> {:error, {:file_error, error.reason, path}}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Decodes a JSON study manifest string.
  """
  def from_json(json) when is_binary(json) do
    with {:ok, source} <- decode_json(json), do: from_map(source)
  end

  @doc """
  Builds a runnable study manifest from a decoded JSON map.
  """
  def from_map(%{} = source) do
    with :ok <- validate_schema_version(source),
         {:ok, central_body} <- central_body(source),
         {:ok, scenarios} <- scenarios(source, central_body),
         {:ok, mission_plan_metadata} <- mission_plan_metadata(scenarios),
         {:ok, propagator} <- propagator(source),
         {:ok, propagator_opts} <- propagator_opts(source),
         {:ok, outputs} <- outputs(source),
         {:ok, ground_stations} <- ground_stations(source),
         {:ok, targets} <- targets(source),
         {:ok, ground_track_crossings} <- ground_track_crossings(source),
         {:ok, sun_direction} <- sun_direction(source),
         {:ok, run_options} <- run_options(source),
         {:ok, metadata} <- metadata(source),
         {:ok, campaign_metadata} <- campaign_metadata(source),
         {:ok, candidate_refresh_metadata} <- candidate_refresh_metadata(source),
         {:ok, search_metadata} <- search_metadata(source),
         {:ok, monte_carlo_metadata} <- monte_carlo_metadata(source),
         {:ok, constraints} <- constraints(source),
         {:ok, seed_manifest} <- seed_manifest(source),
         {:ok, study_id} <- required(source, "study_id") do
      metadata =
        metadata
        |> Map.put("manifest_schema_version", @schema_version)
        |> maybe_put("campaign", campaign_metadata)
        |> maybe_put("candidate_refresh", candidate_refresh_metadata)
        |> maybe_put("search", search_metadata)
        |> maybe_put("monte_carlo", monte_carlo_metadata)
        |> maybe_put("mission_plans", mission_plan_metadata)
        |> maybe_put("constraints", constraints)

      study =
        Study.new!(study_id, scenarios,
          propagator: propagator,
          propagator_opts: propagator_opts,
          outputs: outputs,
          seed_manifest: seed_manifest,
          metadata: metadata
        )

      run_opts =
        [
          central_body: central_body,
          ground_stations: ground_stations,
          targets: targets,
          ground_track_crossings: ground_track_crossings,
          sun_direction: sun_direction
        ] ++ run_options

      {:ok,
       %__MODULE__{
         study: study,
         run_opts: run_opts,
         central_body: central_body,
         ground_stations: ground_stations,
         targets: targets,
         source: source
       }}
    end
  rescue
    error in ArgumentError -> {:error, {:invalid_manifest, Exception.message(error)}}
  end

  def from_map(_source), do: {:error, {:invalid_manifest, :expected_object}}

  @doc """
  Validates a study manifest file and returns a JSON-serializable lint report.

  The report is intended for CLI and integration tooling that needs stable error
  codes and paths instead of raw Elixir tuples.
  """
  def validation_report(path) when is_binary(path) do
    base_report = validation_report_base()

    case from_file(path) do
      {:ok, manifest} ->
        case StudyRunner.validate_run_inputs(manifest.study, manifest.run_opts) do
          :ok ->
            Map.merge(base_report, %{
              "manifest" => manifest_report_metadata(manifest, path),
              "status" => "pass",
              "study_id" => to_string(manifest.study.id),
              "scenario_count" => length(manifest.study.scenarios),
              "outputs" => Enum.map(manifest.study.outputs, &Atom.to_string/1),
              "error_count" => 0,
              "warning_count" => 0,
              "errors" => [],
              "warnings" => []
            })

          {:error, reason} ->
            Map.merge(base_report, %{
              "manifest" => manifest_report_metadata(manifest, path),
              "status" => "fail",
              "study_id" => to_string(manifest.study.id),
              "scenario_count" => length(manifest.study.scenarios),
              "outputs" => Enum.map(manifest.study.outputs, &Atom.to_string/1),
              "error_count" => 1,
              "warning_count" => 0,
              "errors" => [manifest_error(reason)],
              "warnings" => []
            })
        end

      {:error, reason} ->
        Map.merge(base_report, %{
          "manifest" => %{"path" => path},
          "status" => "fail",
          "study_id" => nil,
          "scenario_count" => nil,
          "outputs" => [],
          "error_count" => 1,
          "warning_count" => 0,
          "errors" => [manifest_error(reason)],
          "warnings" => []
        })
    end
  end

  @doc """
  Exports the accepted study manifest shape as a JSON Schema document.

  This schema is intentionally structural. `from_map/1` and the manifest lint
  task remain the executable semantic validators for scenario generation,
  domain constraints, accepted planning state contracts, and artifact imports.
  """
  def json_schema do
    %{
      "$schema" => @json_schema_draft,
      "$id" => "https://orbital-dynamics.local/schemas/#{@json_schema_contract}.schema.json",
      "title" => "OrbitalDynamics #{@json_schema_contract}",
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["schema_version", "study_id", "outputs"],
      "anyOf" =>
        Enum.map(
          [
            "scenarios",
            "mission_plans",
            "campaign",
            "candidate_refresh",
            "search",
            "monte_carlo"
          ],
          &%{"required" => [&1]}
        ),
      "properties" => manifest_schema_properties(),
      "x-orbital-dynamics" => %{
        "schema_contract" => @json_schema_contract,
        "manifest_family" => "study_manifest",
        "schema_version" => @schema_version,
        "validation_mode" => "top_level_manifest_compatibility_export",
        "compatibility_policy_version" => Schema.compatibility_policy()["policy_version"],
        "compatibility_policy" => Schema.compatibility_policy(),
        "identity_policy_version" => Schema.identity_policy()["policy_version"],
        "identity_policy" => Schema.identity_policy(),
        "executable_validator" => @semantic_validator,
        "lint_error_codes" => @lint_error_codes,
        "lint_task" => "mix orbital_dynamics.manifest.lint --manifest PATH",
        "schema_export_task" =>
          "mix orbital_dynamics.manifest.schema.export --output schemas/study_manifest.v1.schema.json",
        "nested_contracts" => [
          "accepted_planning_state.v1",
          "resource_summary.v1",
          "station_calendar_provider.v1"
        ],
        "executable_contract" => false
      }
    }
  end

  @doc """
  Writes the exported study manifest JSON Schema document to disk.
  """
  def write_json_schema!(path) when is_binary(path) do
    path
    |> Path.dirname()
    |> File.mkdir_p!()

    json =
      json_schema()
      |> :json.encode()
      |> IO.iodata_to_binary()

    File.write!(path, json <> "\n")
    path
  end

  @doc """
  Returns a compact JSON-serializable manifest field reference.

  The reference is derived from the exported JSON Schema so CLI docs and
  integration tooling do not need to maintain a separate field list.
  """
  def field_reference do
    schema = json_schema()
    fields = schema_field_rows(schema)

    %{
      "schema_contract" => @json_schema_contract,
      "schema_version" => @schema_version,
      "reference_mode" => "study_manifest_schema_field_reference",
      "compatibility_policy_version" => Schema.compatibility_policy()["policy_version"],
      "identity_policy_version" => Schema.identity_policy()["policy_version"],
      "identity_policy" => manifest_identity_policy_reference(),
      "schema_export_command" =>
        "mix orbital_dynamics.manifest.schema.export --output schemas/study_manifest.v1.schema.json",
      "lint_command" => "mix orbital_dynamics.manifest.lint --manifest PATH",
      "field_count" => length(fields),
      "top_level_required" => Map.get(schema, "required", []),
      "activation_sections" =>
        schema
        |> Map.get("anyOf", [])
        |> Enum.flat_map(&Map.get(&1, "required", [])),
      "supported" => validation_report_base()["supported"],
      "fields" => fields
    }
  end

  defp manifest_identity_policy_reference do
    Schema.identity_policy()
    |> Map.take([
      "policy_version",
      "stable_id_pattern",
      "semantic_invariants",
      "generated_id_scopes"
    ])
  end

  defp decode_json(json) do
    case :json.decode(json) do
      decoded when is_map(decoded) -> {:ok, decoded}
      _decoded -> {:error, {:invalid_json, :expected_object}}
    end
  rescue
    _error -> {:error, :invalid_json}
  end

  defp validate_schema_version(source) do
    case Map.get(source, "schema_version") do
      @schema_version -> :ok
      nil -> {:error, {:missing_field, "schema_version"}}
      other -> {:error, {:unsupported_schema_version, other}}
    end
  end

  defp sha256(content) do
    :crypto.hash(:sha256, content)
    |> Base.encode16(case: :lower)
  end

  defp manifest_report_metadata(manifest, path) do
    metadata =
      manifest.run_opts
      |> Keyword.get(:manifest, %{})

    %{"path" => path}
    |> maybe_put("sha256", metadata[:sha256])
  end

  defp manifest_error({:missing_field, field}) when is_binary(field) do
    error("missing_field", manifest_path(field), "required field is missing: #{field}", %{
      "field" => field
    })
  end

  defp manifest_error({:invalid_field, field}) when is_binary(field) do
    error("invalid_field", manifest_path(field), "field has an invalid value: #{field}", %{
      "field" => field
    })
  end

  defp manifest_error({:unsupported_schema_version, version}) do
    error(
      "unsupported_schema_version",
      "$.schema_version",
      "unsupported study manifest schema_version: #{inspect(version)}",
      %{"expected" => @schema_version, "actual" => json_safe(version)}
    )
  end

  defp manifest_error({:unsupported_central_body, value}) do
    error("unsupported_central_body", "$.central_body", "unsupported central_body", %{
      "actual" => json_safe(value)
    })
  end

  defp manifest_error({:unsupported_propagator, value}) do
    error("unsupported_propagator", "$.propagator", "unsupported propagator", %{
      "actual" => json_safe(value)
    })
  end

  defp manifest_error({:unsupported_output, value}) do
    error("unsupported_output", "$.outputs", "unsupported output", %{
      "actual" => json_safe(value)
    })
  end

  defp manifest_error({:invalid_output, value}) do
    error("invalid_output", "$.outputs", "output entries must be supported strings", %{
      "actual" => json_safe(value)
    })
  end

  defp manifest_error({:missing_option, option}) when is_atom(option) do
    option = Atom.to_string(option)

    error(
      "missing_run_option",
      manifest_option_path(option),
      "required run option is missing: #{option}",
      %{"option" => option}
    )
  end

  defp manifest_error({:invalid_option, option}) when is_atom(option) do
    option = Atom.to_string(option)

    error(
      "invalid_run_option",
      manifest_option_path(option),
      "run option has an invalid value: #{option}",
      %{"option" => option}
    )
  end

  defp manifest_error({:unsupported_option, field, option})
       when is_binary(field) and is_binary(option) do
    error("unsupported_option", manifest_path("#{field}.#{option}"), "unsupported option", %{
      "field" => field,
      "option" => option
    })
  end

  defp manifest_error({:file_error, reason, path}) do
    error("file_error", "$", "could not read manifest file", %{
      "file_reason" => to_string(reason),
      "path" => path
    })
  end

  defp manifest_error({:invalid_json, :expected_object}) do
    error("invalid_json_object", "$", "manifest JSON must decode to an object", %{})
  end

  defp manifest_error(:invalid_json) do
    error("invalid_json", "$", "manifest file is not valid JSON", %{})
  end

  defp manifest_error({:invalid_manifest, message}) do
    error("invalid_manifest", "$", to_string(message), %{})
  end

  defp manifest_error(reason) do
    error("manifest_error", "$", "manifest validation failed", %{
      "reason" => inspect(reason)
    })
  end

  defp manifest_option_path("ground_stations"), do: "$.ground_stations"
  defp manifest_option_path("targets"), do: "$.targets"
  defp manifest_option_path("ground_track_crossings"), do: "$.ground_track_crossings"
  defp manifest_option_path(option), do: manifest_path(option)

  defp error(code, path, message, details) do
    %{
      "code" => code,
      "path" => path,
      "message" => message,
      "details" => details
    }
  end

  defp manifest_path(field) do
    "$." <> field
  end

  defp json_safe(value) do
    value
    |> :json.encode()
    |> :json.decode()
  rescue
    _error -> inspect(value)
  end

  defp manifest_schema_properties do
    %{
      "schema_version" => %{
        "type" => "integer",
        "const" => @schema_version,
        "description" => "Study manifest schema version."
      },
      "study_id" => string_property("Stable identifier for the study run."),
      "central_body" => %{
        "oneOf" => [
          %{"type" => "string", "const" => "earth"},
          object_property(%{
            "name" => string_property(),
            "mu_km3_s2" => number_property(),
            "equatorial_radius_km" => number_property(),
            "j2" => number_property()
          })
        ]
      },
      "propagator" => enum_property(Map.keys(@propagators)),
      "propagator_opts" =>
        object_property(%{
          "max_step_s" => number_property(),
          "integration" => enum_property(["fixed_step", "adaptive_step"]),
          "min_step_s" => number_property(),
          "adaptive_position_tolerance_km" => number_property(),
          "adaptive_velocity_tolerance_km_s" => number_property()
        }),
      "outputs" => %{
        "type" => "array",
        "items" => enum_property(Map.keys(@outputs)),
        "minItems" => 1
      },
      "run_options" =>
        object_property(%{
          "max_concurrency" => integer_property(),
          "timeout" => integer_property(),
          "task_chunk_size" => integer_property(),
          "task_supervisor_node" => string_property(),
          "task_supervisor_nodes" => array_property(string_property())
        }),
      "ground_stations" => array_property(ground_station_schema()),
      "ground_track_crossings" => array_property(ground_track_crossing_schema()),
      "sun_direction" => vector3_schema(),
      "scenarios" => array_property(scenario_schema()),
      "mission_plans" => array_property(mission_plan_schema()),
      "campaign" => campaign_schema(),
      "candidate_refresh" => candidate_refresh_schema(),
      "search" => search_schema(),
      "monte_carlo" => monte_carlo_schema(),
      "constraints" => array_property(constraint_schema()),
      "seed_manifest" => object_property(),
      "metadata" => object_property()
    }
  end

  defp validation_report_base do
    %{
      "schema_contract" => @lint_schema_contract,
      "schema_version" => @schema_version,
      "schema_id" =>
        "https://orbital-dynamics.local/schemas/#{@lint_schema_contract}.schema.json",
      "manifest_schema_contract" => @json_schema_contract,
      "manifest_schema_id" =>
        "https://orbital-dynamics.local/schemas/#{@json_schema_contract}.schema.json",
      "validation_mode" => "study_manifest_lint",
      "semantic_validator" => @semantic_validator,
      "lint_task" => "mix orbital_dynamics.manifest.lint --manifest PATH",
      "schema_export_command" =>
        "mix orbital_dynamics.manifest.schema.export --output schemas/study_manifest.v1.schema.json",
      "supported" => %{
        "lint_error_codes" => @lint_error_codes,
        "outputs" => Enum.sort(Map.keys(@outputs)),
        "propagators" => Enum.sort(Map.keys(@propagators)),
        "search_objectives" => Enum.sort(@search_objectives)
      }
    }
  end

  defp schema_field_rows(schema) do
    schema
    |> Map.get("properties", %{})
    |> Enum.sort_by(fn {field, _property} -> field end)
    |> Enum.flat_map(fn {field, property} ->
      field_rows(["$", field], property, MapSet.new(Map.get(schema, "required", [])))
    end)
  end

  defp field_rows(path, property, required_fields) do
    field = List.last(path)
    child_required_fields = MapSet.new(Map.get(property, "required", []))
    row = field_row(path, property, MapSet.member?(required_fields, field))

    child_rows =
      property
      |> Map.get("properties", %{})
      |> Enum.sort_by(fn {child_field, _child_property} -> child_field end)
      |> Enum.flat_map(fn {child_field, child_property} ->
        field_rows(path ++ [child_field], child_property, child_required_fields)
      end)

    item_rows =
      case Map.get(property, "items") do
        %{} = item_schema -> field_rows(path ++ ["[]"], item_schema, MapSet.new())
        _items -> []
      end

    [row | child_rows ++ item_rows]
  end

  defp field_row(path, property, required?) do
    %{
      "path" => Enum.join(path, "."),
      "parent_path" => parent_path(path),
      "section" => manifest_section(path),
      "type" => schema_type(property),
      "required" => required?,
      "array_item" => List.last(path) == "[]"
    }
    |> maybe_put("enum", Map.get(property, "enum"))
    |> maybe_put("const", Map.get(property, "const"))
    |> maybe_put("description", Map.get(property, "description"))
    |> maybe_put("min_items", Map.get(property, "minItems"))
    |> maybe_put("max_items", Map.get(property, "maxItems"))
    |> maybe_put("minimum", Map.get(property, "minimum"))
    |> maybe_put("maximum", Map.get(property, "maximum"))
    |> maybe_put("schema_contract_ref", schema_contract_ref(property))
    |> maybe_put("additional_properties_type", additional_properties_type(property))
    |> maybe_put("stable_id_pattern", stable_id_pattern(path, property))
    |> maybe_put_non_empty("trust_boundary_sources", trust_boundary_sources(property))
    |> maybe_put_non_empty("nested_contracts", nested_contracts(property))
    |> maybe_put_non_empty("required_children", Map.get(property, "required", []))
    |> maybe_put_non_empty("required_alternatives", required_alternatives(property))
  end

  defp parent_path(["$", _field]), do: "$"

  defp parent_path(path) do
    path
    |> Enum.drop(-1)
    |> Enum.join(".")
  end

  defp manifest_section(["$", section | _rest]), do: section
  defp manifest_section(_path), do: "$"

  defp schema_type(%{"type" => type}), do: type
  defp schema_type(%{"oneOf" => _one_of}), do: "oneOf"
  defp schema_type(%{"anyOf" => _any_of}), do: "anyOf"
  defp schema_type(%{"allOf" => _all_of}), do: "allOf"
  defp schema_type(_property), do: "unspecified"

  defp required_alternatives(%{"anyOf" => alternatives, "allOf" => all_of})
       when is_list(alternatives) and is_list(all_of) do
    required_alternatives_from_any_of(alternatives) ++ required_alternatives_from_all_of(all_of)
  end

  defp required_alternatives(%{"anyOf" => alternatives}) when is_list(alternatives) do
    required_alternatives_from_any_of(alternatives)
  end

  defp required_alternatives(%{"allOf" => all_of}) when is_list(all_of) do
    required_alternatives_from_all_of(all_of)
  end

  defp required_alternatives(_property), do: []

  defp required_alternatives_from_all_of(all_of) do
    Enum.flat_map(all_of, fn
      %{"anyOf" => alternatives} when is_list(alternatives) ->
        required_alternatives_from_any_of(alternatives)

      _schema ->
        []
    end)
  end

  defp required_alternatives_from_any_of(alternatives) do
    alternatives
    |> Enum.flat_map(fn
      %{"required" => required} when is_list(required) -> [required]
      _alternative -> []
    end)
  end

  defp schema_contract_ref(%{"x-orbital-dynamics" => %{"schema_contract" => contract}})
       when is_binary(contract),
       do: contract

  defp schema_contract_ref(%{"properties" => %{"schema_contract" => %{"const" => contract}}})
       when is_binary(contract),
       do: contract

  defp schema_contract_ref(_property), do: nil

  defp nested_contracts(%{"x-orbital-dynamics" => %{"nested_contracts" => contracts}})
       when is_list(contracts),
       do: Enum.filter(contracts, &is_binary/1)

  defp nested_contracts(_property), do: []

  defp additional_properties_type(%{"additionalProperties" => %{} = property}) do
    schema_type(property)
  end

  defp additional_properties_type(_property), do: nil

  defp stable_id_pattern(path, property) do
    if stable_id_field_path?(path, property) do
      Schema.identity_policy()["stable_id_pattern"]
    end
  end

  defp stable_id_field_path?(path, %{"type" => "string"}) do
    if List.last(path) == "[]" do
      path
      |> Enum.at(-2)
      |> stable_id_array_field_name?()
    else
      path
      |> List.last()
      |> stable_id_field_name?()
    end
  end

  defp stable_id_field_path?(path, %{"type" => "array", "items" => %{"type" => "string"}}) do
    path
    |> List.last()
    |> stable_id_array_field_name?()
  end

  defp stable_id_field_path?(_path, _property), do: false

  defp stable_id_field_name?("id"), do: true
  defp stable_id_field_name?("study_id"), do: true
  defp stable_id_field_name?("snapshot_id"), do: true
  defp stable_id_field_name?("activity_id"), do: true
  defp stable_id_field_name?("spacecraft_id"), do: true
  defp stable_id_field_name?("scenario_id"), do: true
  defp stable_id_field_name?("station_id"), do: true
  defp stable_id_field_name?("ground_station_id"), do: true
  defp stable_id_field_name?("target_id"), do: true
  defp stable_id_field_name?("source_window_id"), do: true
  defp stable_id_field_name?("reservation_id"), do: true
  defp stable_id_field_name?(field) when is_binary(field), do: String.ends_with?(field, "_id")
  defp stable_id_field_name?(_field), do: false

  defp stable_id_array_field_name?("dependencies"), do: true

  defp stable_id_array_field_name?(field) when is_binary(field),
    do: String.ends_with?(field, "_ids")

  defp stable_id_array_field_name?(_field), do: false

  defp trust_boundary_sources(property) do
    alternatives = required_alternatives(property)
    required = Map.get(property, "required", [])

    cond do
      ["trust_boundary"] in alternatives and ["provenance"] in alternatives ->
        ["trust_boundary", "provenance.trust_boundary"]

      "trust_boundary" in required ->
        ["trust_boundary"]

      true ->
        []
    end
  end

  defp scenario_schema do
    %{
      "oneOf" => [
        object_property(%{
          "generator" => %{"type" => "string", "const" => "circular_leo"},
          "count" => integer_property(),
          "duration_s" => number_property(),
          "output_step_s" => number_property(),
          "radius_km" => number_property(),
          "dry_mass_kg" => number_property(),
          "id_prefix" => string_property(),
          "epoch" => epoch_schema(),
          "frame" => frame_schema()
        }),
        explicit_scenario_schema()
      ]
    }
  end

  defp explicit_scenario_schema do
    object_property(
      %{
        "id" => string_property(),
        "spacecraft" => spacecraft_schema(),
        "initial_state" => state_vector_schema(),
        "duration_s" => number_property(),
        "output_step_s" => number_property(),
        "maneuvers" => array_property(maneuver_schema())
      },
      ["id", "spacecraft", "initial_state", "duration_s", "output_step_s"]
    )
  end

  defp mission_plan_schema do
    object_property(
      %{
        "id" => string_property(),
        "spacecraft" => spacecraft_schema(),
        "initial_state" => state_vector_schema(),
        "horizon_s" => number_property(),
        "output_step_s" => number_property(),
        "activities" => array_property(activity_schema()),
        "metadata" => object_property()
      },
      ["id", "spacecraft", "initial_state", "horizon_s", "output_step_s"]
    )
  end

  defp activity_schema do
    object_property(
      %{
        "id" => string_property(),
        "type" => enum_property(activity_type_values()),
        "activity_type" => enum_property(activity_type_values()),
        "timeline_id" => string_property(),
        "scenario_id" => string_property(),
        "spacecraft_id" => string_property(),
        "satellite_id" => string_property(),
        "spacecraft" => spacecraft_identity_schema(),
        "satellite" => spacecraft_identity_schema(),
        "resource_id" => string_property(),
        "resource_source_quality" => string_property(),
        "resource_trust_boundary" => string_property(),
        "resource_trust_boundary_status" => string_property(),
        "resource_provenance" => object_property(),
        "resource_blocking_dimension" => string_property(),
        "fuel_margin" => number_property(),
        "power_margin" => number_property(),
        "storage_margin" => number_property(),
        "downlink_margin" => number_property(),
        "battery_capacity_wh" => number_property(),
        "battery_energy_used_wh" => number_property(),
        "battery_state_of_charge" => number_property(),
        "spacecraft_available" => boolean_property(),
        "payload_available" => boolean_property(),
        "antenna_available" => boolean_property(),
        "degraded" => boolean_property(),
        "mode" => string_property(),
        "incompatible_activity_types" => array_property(string_property()),
        "suppressed_activity_types" => array_property(string_property()),
        "collection_id" => string_property(),
        "product_id" => string_property(),
        "product_ids" => array_property(string_property()),
        "payload_id" => string_property(),
        "instrument_id" => string_property(),
        "target_priority" => number_property(),
        "target_priority_source" => string_property(),
        "target_priority_objective_ids" => array_property(string_property()),
        "target_priority_objective_type" => string_property(),
        "contact_success" => boolean_property(),
        "contact_result" => string_property(),
        "contact_success_factor" => number_property(),
        "contact_success_factor_source" => string_property(),
        "command_success" => boolean_property(),
        "command_result" => string_property(),
        "command_success_factor" => number_property(),
        "command_success_factor_source" => string_property(),
        "observation_success" => boolean_property(),
        "observation_result" => string_property(),
        "observation_success_factor" => number_property(),
        "observation_success_factor_source" => string_property(),
        "image_quality_score" => number_property(),
        "image_quality_status" => string_property(),
        "image_quality_source" => string_property(),
        "cloud_cover_fraction" => number_property(),
        "blur_score" => number_property(),
        "maneuver_success" => boolean_property(),
        "maneuver_result" => string_property(),
        "maneuver_success_factor" => number_property(),
        "maneuver_success_factor_source" => string_property(),
        "feedback_weight" => number_property(),
        "feedback_weight_source" => string_property(),
        "data_volume_mb" => number_property(),
        "planned_data_volume_mb" => number_property(),
        "actual_data_volume_mb" => number_property(),
        "estimated_data_volume_mb" => number_property(),
        "estimated_storage_mb" => number_property(),
        "estimated_downlink_mb" => number_property(),
        "required_downlink_mb" => number_property(),
        "collection_ends_at_s" => number_property(),
        "planned_delivery_at_s" => number_property(),
        "actual_delivery_at_s" => number_property(),
        "max_latency_s" => number_property(),
        "planned_latency_s" => number_property(),
        "actual_latency_s" => number_property(),
        "planned_estimated_throughput_mb" => number_property(),
        "actual_throughput_mb" => number_property(),
        "link_protocol" => string_property(),
        "frequency_band" => string_property(),
        "modulation" => string_property(),
        "coding_scheme" => string_property(),
        "polarization" => string_property(),
        "data_rate_mbps" => number_property(),
        "downlink_rate_mbps" => number_property(),
        "data_rate_mb_s" => number_property(),
        "downlink_rate_mb_s" => number_property(),
        "actual_data_rate_mbps" => number_property(),
        "actual_downlink_rate_mbps" => number_property(),
        "actual_data_rate_mb_s" => number_property(),
        "actual_downlink_rate_mb_s" => number_property(),
        "delivered_rate_mbps" => number_property(),
        "received_rate_mbps" => number_property(),
        "delivered_rate_mb_s" => number_property(),
        "received_rate_mb_s" => number_property(),
        "actual_duration_s" => number_property(),
        "actual_contact_duration_s" => number_property(),
        "contact_duration_s" => number_property(),
        "link_margin_db" => number_property(),
        "snr_db" => number_property(),
        "eb_no_db" => number_property(),
        "bit_error_rate" => number_property(),
        "packet_loss_rate" => number_property(),
        "frame_loss_rate" => number_property(),
        "carrier_lock" => boolean_property(),
        "symbol_lock" => boolean_property(),
        "link_quality_status" => string_property(),
        "pointing_mode" => string_property(),
        "pointing_target_id" => string_property(),
        "boresight_axis" => string_property(),
        "off_nadir_angle_deg" => number_property(),
        "slew_angle_deg" => number_property(),
        "slew_rate_deg_s" => number_property(),
        "pointing_error_deg" => number_property(),
        "pointing_status" => string_property(),
        "pointing_model" => string_property(),
        "pointing_source" => string_property(),
        "pointing_confidence" => number_property(),
        "attitude_mode" => string_property(),
        "attitude_target_id" => string_property(),
        "roll_deg" => number_property(),
        "pitch_deg" => number_property(),
        "yaw_deg" => number_property(),
        "attitude_error_deg" => number_property(),
        "attitude_status" => string_property(),
        "attitude_model" => string_property(),
        "attitude_source" => string_property(),
        "attitude_confidence" => number_property(),
        "thermal_zone_id" => string_property(),
        "temperature_c" => number_property(),
        "planned_temperature_c" => number_property(),
        "actual_temperature_c" => number_property(),
        "min_operating_temperature_c" => number_property(),
        "max_operating_temperature_c" => number_property(),
        "thermal_margin_c" => number_property(),
        "thermal_status" => string_property(),
        "thermal_model" => string_property(),
        "thermal_source" => string_property(),
        "thermal_confidence" => number_property(),
        "eclipse_overlap_fraction" => number_property(),
        "eclipse_overlap_s" => number_property(),
        "lighting_condition" => string_property(),
        "lighting_condition_detail" => string_property(),
        "lighting_condition_model" => string_property(),
        "lighting_detail_model" => string_property(),
        "lighting_confidence" => %{"type" => ["number", "string"]},
        "command_window_id" => string_property(),
        "command_window_type" => string_property(),
        "window_type" => string_property(),
        "command_window" => object_property(),
        "start_s" => number_property(),
        "end_s" => number_property(),
        "target_id" => string_property(),
        "target" => target_identity_schema(),
        "ground_station_id" => string_property(),
        "station_id" => string_property(),
        "station" => ground_station_identity_schema(),
        "ground_station" => ground_station_identity_schema(),
        "direction" => contact_direction_property(),
        "epoch_s" => number_property(),
        "delta_v_km_s" => vector3_schema(),
        "frame" => frame_schema(),
        "allow_overlap" => boolean_property(),
        "allow_overlap?" => boolean_property(),
        "status" => enum_property(activity_status_values()),
        "approval_status" => enum_property(activity_approval_status_values()),
        "locked" => boolean_property(),
        "dependencies" => array_property(string_property()),
        "dependency_activity_ids" => array_property(string_property()),
        "dependency_timeline_ids" => array_property(string_property()),
        "exclusive_with_activity_ids" => array_property(string_property()),
        "exclusive_with_timeline_ids" => array_property(string_property()),
        "exclusivity_group" => string_property(),
        "source_window_id" => string_property(),
        "source_window_type" => string_property(),
        "source_window" => object_property(),
        "cadence_import" => object_property(),
        "provenance" => object_property(),
        "metadata" => object_property()
      },
      ["id"]
    )
    |> Map.put("anyOf", [%{"required" => ["type"]}, %{"required" => ["activity_type"]}])
  end

  defp maneuver_schema do
    object_property(
      %{
        "id" => string_property(),
        "epoch" => epoch_schema(),
        "delta_v_km_s" => vector3_schema(),
        "frame" => frame_schema()
      },
      ["id", "epoch", "delta_v_km_s"]
    )
  end

  defp campaign_schema do
    object_property(
      %{
        "planning_horizon" =>
          object_property(
            %{
              "duration_s" => number_property(),
              "output_step_s" => number_property()
            },
            ["duration_s", "output_step_s"]
          ),
        "spacecraft" => array_property(campaign_spacecraft_schema()),
        "targets" => array_property(target_schema()),
        "constraints" =>
          object_property(%{
            "min_activity_duration_s" => number_property(),
            "max_timeline_activities" => integer_property(),
            "avoid_eclipse" => boolean_property()
          }),
        "scoring_policy" =>
          object_property(%{
            "target_value_weight" => number_property(),
            "contact_value_weight" => number_property(),
            "eclipse_penalty_weight" => number_property(),
            "activity_count_penalty" => number_property(),
            "rank_limit" => integer_property()
          }),
        "ground_network" => array_property(ground_network_entry_schema()),
        "resource_summaries" => array_property(object_property())
      },
      ["planning_horizon", "spacecraft", "targets"]
    )
  end

  defp campaign_spacecraft_schema do
    object_property(
      Map.merge(%{"initial_state" => state_vector_schema()}, spacecraft_fields()),
      ["id", "dry_mass_kg", "initial_state"]
    )
  end

  defp candidate_refresh_schema do
    object_property(
      %{
        "accepted_planning_state" => artifact_json_schema("accepted_planning_state.v1"),
        "orbit_data" => orbit_data_schema(),
        "current_epoch_s" => number_property(),
        "current_epoch" => epoch_schema(),
        "remaining_horizon" =>
          object_property(
            %{
              "starts_at_s" => number_property(),
              "ends_at_s" => number_property(),
              "duration_s" => number_property(),
              "output_step_s" => number_property()
            },
            ["output_step_s"]
          ),
        "targets" => array_property(target_schema()),
        "constraints" =>
          object_property(%{
            "min_activity_duration_s" => number_property(),
            "avoid_eclipse" => boolean_property()
          }),
        "scoring_policy" =>
          object_property(%{
            "target_value_weight" => number_property(),
            "contact_value_weight" => number_property(),
            "eclipse_penalty_weight" => number_property(),
            "downlink_rate_mb_s" => number_property(),
            "downlink_completion_weight" => number_property(),
            "observation_objective_weight" => number_property(),
            "collection_latency_observation_weight" => number_property()
          }),
        "objectives" => array_property(object_property()),
        "freshness_policy" => freshness_policy_schema(),
        "resource_filter_policy" => resource_filter_policy_schema(),
        "candidate_limit_policy" => candidate_limit_policy_schema(),
        "approval_policy" => object_property(),
        "operational_feedback" => operational_feedback_schema(),
        "mission_state" => object_property(),
        "source_timeline_feedback_report" => artifact_json_schema("timeline_feedback_report.v1"),
        "timeline_feedback_report" => artifact_json_schema("timeline_feedback_report.v1"),
        "source_operational_timeline_report" => operational_timeline_report_input_schema(),
        "operational_timeline_report" => operational_timeline_report_input_schema(),
        "model_assumptions" => object_property(),
        "resource_summaries" => array_property(resource_summary_input_schema()),
        "ground_network" => array_property(ground_network_entry_schema()),
        "prior_candidate_activities" => array_property(prior_candidate_activity_schema())
      },
      ["remaining_horizon"]
    )
    |> Map.put("anyOf", [
      %{"required" => ["accepted_planning_state"]},
      %{"required" => ["orbit_data"]},
      %{"required" => ["mission_state"]}
    ])
  end

  defp operational_timeline_report_input_schema do
    %{
      "oneOf" => [
        artifact_json_schema("operational_timeline_report.v1"),
        array_property(artifact_json_schema("operational_timeline_report.v1"))
      ]
    }
  end

  defp search_schema do
    object_property(
      %{
        "generator" => %{"type" => "string", "const" => "impulsive_burn_grid"},
        "base_scenario" => explicit_scenario_schema(),
        "burn_epoch_s" => array_property(number_property()),
        "delta_v_km_s" => array_property(vector3_schema()),
        "id_prefix" => string_property(),
        "objective" => enum_property(Enum.sort(@search_objectives)),
        "objective_direction" => enum_property(["maximize", "minimize"]),
        "rank_limit" => integer_property()
      },
      ["base_scenario", "burn_epoch_s", "delta_v_km_s"]
    )
  end

  defp monte_carlo_schema do
    object_property(
      %{
        "generator" => %{"type" => "string", "const" => "state_vector_dispersion"},
        "base_scenario" => explicit_scenario_schema(),
        "count" => integer_property(),
        "seed" => integer_property(),
        "position_sigma_km" => vector3_schema(),
        "velocity_sigma_km_s" => vector3_schema(),
        "id_prefix" => string_property(),
        "objective" => enum_property(Enum.sort(@search_objectives)),
        "objective_direction" => enum_property(["maximize", "minimize"]),
        "rank_limit" => integer_property()
      },
      ["base_scenario", "count", "seed", "position_sigma_km", "velocity_sigma_km_s"]
    )
  end

  defp constraint_schema do
    object_property(
      %{
        "id" => string_property(),
        "metric" => string_property(),
        "operator" => enum_property(["<", "<=", "==", ">=", ">"]),
        "value" => number_property()
      },
      ["id", "metric", "operator", "value"]
    )
  end

  defp spacecraft_schema do
    object_property(spacecraft_fields(), ["id", "dry_mass_kg"])
  end

  defp spacecraft_fields do
    %{
      "id" => string_property(),
      "dry_mass_kg" => number_property(),
      "propellant_mass_kg" => number_property(),
      "area_m2" => number_property(),
      "drag_coefficient" => number_property()
    }
  end

  defp state_vector_schema do
    object_property(
      %{
        "position_km" => vector3_schema(),
        "velocity_km_s" => vector3_schema(),
        "epoch" => epoch_schema(),
        "frame" => frame_schema()
      },
      ["position_km", "velocity_km_s", "epoch"]
    )
  end

  defp epoch_schema do
    object_property(
      %{
        "seconds_since_j2000" => number_property(),
        "scale" => enum_property(["tdb", "tai", "utc"]),
        "time_scale" => enum_property(["tdb", "tai", "utc"])
      },
      ["seconds_since_j2000"]
    )
  end

  defp frame_schema, do: %{"type" => "string", "const" => "earth_inertial_j2000"}

  defp ground_station_schema do
    object_property(
      %{
        "id" => string_property(),
        "latitude_deg" => number_property(),
        "longitude_deg" => number_property(),
        "altitude_km" => number_property(),
        "minimum_elevation_deg" => number_property()
      },
      ["id", "latitude_deg", "longitude_deg"]
    )
  end

  defp target_schema do
    object_property(
      %{
        "id" => string_property(),
        "latitude_deg" => number_property(),
        "longitude_deg" => number_property(),
        "altitude_km" => number_property(),
        "minimum_elevation_deg" => number_property(),
        "priority" => number_property()
      },
      ["id", "latitude_deg", "longitude_deg"]
    )
  end

  defp target_identity_schema do
    object_property(%{
      "id" => string_property(),
      "target_id" => string_property()
    })
  end

  defp ground_station_identity_schema do
    object_property(%{
      "id" => string_property(),
      "station_id" => string_property(),
      "ground_station_id" => string_property()
    })
  end

  defp spacecraft_identity_schema do
    object_property(%{
      "id" => string_property(),
      "spacecraft_id" => string_property(),
      "satellite_id" => string_property()
    })
  end

  defp ground_track_crossing_schema do
    object_property(%{
      "id" => string_property(),
      "crossing" => enum_property(["latitude", "longitude"]),
      "latitude_deg" => number_property(),
      "longitude_deg" => number_property(),
      "frame" => enum_property(["inertial", "body_fixed"]),
      "rotation_rate_rad_s" => number_property(),
      "rotation_epoch_s" => number_property(),
      "rotation_angle_offset_rad" => number_property(),
      "earth_rotation_provider" => earth_rotation_provider_schema()
    })
  end

  defp earth_rotation_provider_schema do
    %{
      "oneOf" => [
        enum_property(["constant_earth_rotation", "tabular_earth_orientation"]),
        object_property(%{
          "provider" => enum_property(["constant_earth_rotation", "tabular_earth_orientation"]),
          "provider_id" => string_property(),
          "source" => string_property(),
          "samples" => array_property(earth_rotation_sample_schema())
        })
      ]
    }
  end

  defp earth_rotation_sample_schema do
    object_property(%{
      "seconds_since_j2000" => number_property(),
      "epoch_s" => number_property(),
      "earth_rotation_angle_rad" => number_property(),
      "rotation_angle_rad" => number_property(),
      "earth_rotation_rate_rad_s" => number_property(),
      "rotation_rate_rad_s" => number_property()
    })
  end

  defp ground_network_entry_schema do
    object_property(%{
      "id" => string_property(),
      "ground_station_id" => string_property(),
      "station_id" => string_property(),
      "status" => string_property(),
      "availability" => station_availability_property(),
      "starts_at_s" => number_property(),
      "ends_at_s" => number_property(),
      "capacity_fraction" => number_property(),
      "available" => boolean_property(),
      "station_calendar_entry_id" => string_property(),
      "station_calendar_provider_id" => string_property(),
      "station_calendar_provider_entry_id" => string_property(),
      "station_calendar_directions" => array_property(string_property()),
      "station_calendar_status" => string_property(),
      "station_calendar_trust_boundary_status" => string_property(),
      "station_contention_status" => string_property(),
      "reservation_id" => string_property(),
      "reserved_by" => string_property(),
      "reservation_status" => string_property(),
      "station_reservation_match_status" => string_property(),
      "provenance" => object_property()
    })
    |> Map.put("anyOf", [
      %{"required" => ["ground_station_id"]},
      %{"required" => ["station_id"]}
    ])
  end

  defp orbit_data_schema do
    object_property(
      %{
        "snapshot_id" => string_property(),
        "accepted_at" => string_property(),
        "state_estimates" => array_property(planning_state_row_schema()),
        "maneuver_execution_deltas" => array_property(object_property()),
        "source" => object_property(),
        "quality" => object_property(),
        "provenance" => object_property()
      },
      ["snapshot_id", "accepted_at", "state_estimates", "source", "quality", "provenance"]
    )
  end

  defp planning_state_row_schema do
    object_property(
      %{
        "spacecraft_id" => string_property(),
        "scenario_id" => string_property(),
        "dry_mass_kg" => number_property(),
        "epoch" => epoch_schema(),
        "seconds_since_j2000" => number_property(),
        "time_scale" => enum_property(["tdb", "tai", "utc"]),
        "scale" => enum_property(["tdb", "tai", "utc"]),
        "frame" => frame_schema(),
        "state_vector" =>
          object_property(
            %{
              "position_km" => vector3_schema(),
              "velocity_km_s" => vector3_schema()
            },
            ["position_km", "velocity_km_s"]
          ),
        "position_km" => vector3_schema(),
        "velocity_km_s" => vector3_schema(),
        "source" => object_property(),
        "quality" => object_property(),
        "metadata" => object_property()
      },
      ["spacecraft_id", "source"]
    )
    |> Map.put("anyOf", [%{"required" => ["epoch"]}, %{"required" => ["seconds_since_j2000"]}])
    |> Map.put("allOf", [
      %{
        "anyOf" => [
          %{"required" => ["state_vector"]},
          %{"required" => ["position_km", "velocity_km_s"]}
        ]
      }
    ])
  end

  defp resource_summary_input_schema do
    object_property(
      %{
        "schema_contract" => %{"type" => "string", "const" => "resource_summary.v1"},
        "spacecraft_id" => string_property(),
        "mode" => string_property(),
        "fuel_margin" => number_property(),
        "power_margin" => number_property(),
        "storage_capacity_mb" => number_property(),
        "storage_used_mb" => number_property(),
        "storage_margin" => number_property(),
        "downlink_capacity_mb" => number_property(),
        "downlink_margin" => number_property(),
        "source_quality" => string_property(),
        "payload_available" => boolean_property(),
        "antenna_available" => boolean_property(),
        "assumptions" => object_property(),
        "provenance" => object_property()
      },
      ["spacecraft_id"]
    )
  end

  defp freshness_policy_schema do
    object_property(%{
      "max_state_age_s" => number_property(),
      "max_candidate_age_s" => number_property(),
      "stale_candidate_action" => string_property()
    })
  end

  defp resource_filter_policy_schema do
    object_property(%{
      "min_activity_fuel_margin" => number_property(),
      "min_observe_power_margin" => number_property(),
      "min_observe_storage_margin" => number_property(),
      "min_downlink_power_margin" => number_property(),
      "min_downlink_margin" => number_property()
    })
  end

  defp candidate_limit_policy_schema do
    object_property(%{
      "max_candidate_activities" => integer_property()
    })
  end

  defp operational_feedback_schema do
    object_property(%{
      "trust_boundary" => string_property(),
      "provenance" => object_property(),
      "source" => object_property(),
      "metadata" => object_property(),
      "contact_success_rate" => numeric_feedback_map_schema(),
      "observation_success_rate" => numeric_feedback_map_schema(),
      "station_throughput_factor" => numeric_feedback_map_schema(),
      "downlink_demand_mb" => numeric_feedback_map_schema(),
      "target_priority_overrides" => numeric_feedback_map_schema(),
      "resource_margin_overrides" => object_property(),
      "resource_availability_overrides" => object_property(),
      "availability_overrides" => object_property(),
      "realized_activities" => array_property(realized_activity_input_schema()),
      "realized_state" => object_property(),
      "station_calendar" => array_property(ground_network_entry_schema())
    })
  end

  defp numeric_feedback_map_schema do
    %{
      "type" => "object",
      "additionalProperties" => number_property(),
      "properties" => %{}
    }
  end

  defp realized_activity_input_schema do
    object_property(
      %{
        "schema_contract" => %{"type" => "string", "const" => "realized_activity.v1"},
        "id" => string_property(),
        "activity_id" => string_property(),
        "type" => string_property(),
        "status" => string_property(),
        "planned_starts_at_s" => number_property(),
        "planned_ends_at_s" => number_property(),
        "actual_starts_at_s" => number_property(),
        "actual_ends_at_s" => number_property(),
        "ground_station_id" => string_property(),
        "station_id" => string_property(),
        "spacecraft_id" => string_property(),
        "satellite_id" => string_property(),
        "target_id" => string_property(),
        "target" => target_identity_schema(),
        "station" => ground_station_identity_schema(),
        "ground_station" => ground_station_identity_schema(),
        "spacecraft" => spacecraft_identity_schema(),
        "satellite" => spacecraft_identity_schema(),
        "source_window_id" => string_property(),
        "resource_id" => string_property(),
        "resource_source_quality" => string_property(),
        "resource_trust_boundary" => string_property(),
        "resource_trust_boundary_status" => string_property(),
        "resource_provenance" => object_property(),
        "resource_blocking_dimension" => string_property(),
        "fuel_margin" => number_property(),
        "power_margin" => number_property(),
        "storage_margin" => number_property(),
        "downlink_margin" => number_property(),
        "battery_capacity_wh" => number_property(),
        "battery_energy_used_wh" => number_property(),
        "battery_state_of_charge" => number_property(),
        "spacecraft_available" => boolean_property(),
        "payload_available" => boolean_property(),
        "antenna_available" => boolean_property(),
        "degraded" => boolean_property(),
        "mode" => string_property(),
        "incompatible_activity_types" => array_property(string_property()),
        "suppressed_activity_types" => array_property(string_property()),
        "collection_id" => string_property(),
        "product_id" => string_property(),
        "product_ids" => array_property(string_property()),
        "payload_id" => string_property(),
        "instrument_id" => string_property(),
        "data_volume_mb" => number_property(),
        "planned_data_volume_mb" => number_property(),
        "actual_data_volume_mb" => number_property(),
        "estimated_data_volume_mb" => number_property(),
        "estimated_storage_mb" => number_property(),
        "estimated_downlink_mb" => number_property(),
        "required_downlink_mb" => number_property(),
        "collection_ends_at_s" => number_property(),
        "planned_delivery_at_s" => number_property(),
        "actual_delivery_at_s" => number_property(),
        "max_latency_s" => number_property(),
        "planned_latency_s" => number_property(),
        "actual_latency_s" => number_property(),
        "planned_estimated_throughput_mb" => number_property(),
        "target_priority" => number_property(),
        "contact_result" => string_property(),
        "contact_success_factor" => number_property(),
        "contact_success_factor_source" => string_property(),
        "command_result" => string_property(),
        "command_success_factor" => number_property(),
        "command_success_factor_source" => string_property(),
        "observation_success" => boolean_property(),
        "observation_result" => string_property(),
        "observation_success_factor" => number_property(),
        "observation_success_factor_source" => string_property(),
        "image_quality_score" => number_property(),
        "image_quality_status" => string_property(),
        "image_quality_source" => string_property(),
        "cloud_cover_fraction" => number_property(),
        "blur_score" => number_property(),
        "maneuver_success" => boolean_property(),
        "maneuver_result" => string_property(),
        "maneuver_success_factor" => number_property(),
        "maneuver_success_factor_source" => string_property(),
        "feedback_weight" => number_property(),
        "feedback_weight_source" => string_property(),
        "delta_v_km_s" => vector3_schema(),
        "actual_delta_v_km_s" => vector3_schema(),
        "executed_delta_v_km_s" => vector3_schema(),
        "delta_v_magnitude_km_s" => number_property(),
        "execution_uncertainty" => object_property(),
        "maneuver_execution_uncertainty" => object_property(),
        "execution_uncertainty_status" => string_property(),
        "timing_3sigma_s" => number_property(),
        "delta_v_3sigma_km_s" => vector3_schema(),
        "delta_v_3sigma_magnitude_km_s" => number_property(),
        "execution_uncertainty_source" => string_property(),
        "pointing_mode" => string_property(),
        "pointing_target_id" => string_property(),
        "boresight_axis" => string_property(),
        "off_nadir_angle_deg" => number_property(),
        "slew_angle_deg" => number_property(),
        "slew_rate_deg_s" => number_property(),
        "pointing_error_deg" => number_property(),
        "pointing_status" => string_property(),
        "pointing_model" => string_property(),
        "pointing_source" => string_property(),
        "pointing_confidence" => number_property(),
        "attitude_mode" => string_property(),
        "attitude_target_id" => string_property(),
        "roll_deg" => number_property(),
        "pitch_deg" => number_property(),
        "yaw_deg" => number_property(),
        "attitude_error_deg" => number_property(),
        "attitude_status" => string_property(),
        "attitude_model" => string_property(),
        "attitude_source" => string_property(),
        "attitude_confidence" => number_property(),
        "thermal_zone_id" => string_property(),
        "temperature_c" => number_property(),
        "planned_temperature_c" => number_property(),
        "actual_temperature_c" => number_property(),
        "min_operating_temperature_c" => number_property(),
        "max_operating_temperature_c" => number_property(),
        "thermal_margin_c" => number_property(),
        "thermal_status" => string_property(),
        "thermal_model" => string_property(),
        "thermal_source" => string_property(),
        "thermal_confidence" => number_property(),
        "eclipse_overlap_fraction" => number_property(),
        "eclipse_overlap_s" => number_property(),
        "lighting_condition" => string_property(),
        "lighting_condition_detail" => string_property(),
        "lighting_condition_model" => string_property(),
        "lighting_detail_model" => string_property(),
        "lighting_confidence" => number_property(),
        "link_protocol" => string_property(),
        "frequency_band" => string_property(),
        "modulation" => string_property(),
        "coding_scheme" => string_property(),
        "polarization" => string_property(),
        "data_rate_mbps" => number_property(),
        "downlink_rate_mbps" => number_property(),
        "data_rate_mb_s" => number_property(),
        "downlink_rate_mb_s" => number_property(),
        "actual_data_rate_mbps" => number_property(),
        "actual_downlink_rate_mbps" => number_property(),
        "actual_data_rate_mb_s" => number_property(),
        "actual_downlink_rate_mb_s" => number_property(),
        "delivered_rate_mbps" => number_property(),
        "received_rate_mbps" => number_property(),
        "delivered_rate_mb_s" => number_property(),
        "received_rate_mb_s" => number_property(),
        "actual_duration_s" => number_property(),
        "actual_contact_duration_s" => number_property(),
        "contact_duration_s" => number_property(),
        "link_margin_db" => number_property(),
        "snr_db" => number_property(),
        "eb_no_db" => number_property(),
        "bit_error_rate" => number_property(),
        "packet_loss_rate" => number_property(),
        "frame_loss_rate" => number_property(),
        "carrier_lock" => boolean_property(),
        "symbol_lock" => boolean_property(),
        "link_quality_status" => string_property(),
        "contact_success" => boolean_property(),
        "command_success" => boolean_property(),
        "actual_throughput_mb" => number_property(),
        "source" => object_property(),
        "provenance" => object_property(),
        "metadata" => object_property()
      },
      ["id", "status"]
    )
  end

  defp prior_candidate_activity_schema do
    object_property(%{
      "id" => string_property(),
      "type" => string_property(),
      "activity_type" => string_property(),
      "scenario_id" => string_property(),
      "target_id" => string_property(),
      "ground_station_id" => string_property(),
      "station_id" => string_property(),
      "station" => ground_station_identity_schema(),
      "ground_station" => ground_station_identity_schema(),
      "direction" => contact_direction_property(),
      "start_s" => number_property(),
      "end_s" => number_property(),
      "starts_at_s" => number_property(),
      "ends_at_s" => number_property(),
      "source_window_id" => string_property(),
      "source_window" => object_property(),
      "metadata" => object_property()
    })
  end

  defp artifact_json_schema(contract_name) do
    {:ok, schema} = Schema.json_schema(contract_name)

    schema
    |> Map.drop(["$schema", "$id", "title"])
    |> Map.put(
      "description",
      "Embedded #{contract_name} artifact accepted by the manifest loader."
    )
  end

  defp vector3_schema do
    %{
      "type" => "array",
      "items" => number_property(),
      "minItems" => 3,
      "maxItems" => 3
    }
  end

  defp object_property(properties \\ %{}, required \\ []) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => properties
    }
    |> maybe_put_required(required)
  end

  defp array_property(items), do: %{"type" => "array", "items" => items}

  defp string_property(description \\ nil),
    do: maybe_put(%{"type" => "string"}, "description", description)

  defp number_property, do: %{"type" => "number"}
  defp integer_property, do: %{"type" => "integer"}
  defp boolean_property, do: %{"type" => "boolean"}
  defp enum_property(values), do: %{"type" => "string", "enum" => Enum.sort(values)}

  defp station_availability_property do
    %{
      "oneOf" => [
        enum_property([
          "available",
          "unavailable",
          "reduced_capacity",
          "maintenance",
          "reserved"
        ]),
        %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0}
      ]
    }
  end

  defp maybe_put_required(property, []), do: property
  defp maybe_put_required(property, required), do: Map.put(property, "required", required)

  defp central_body(source) do
    case Map.get(source, "central_body", "earth") do
      "earth" -> {:ok, CentralBody.earth()}
      %{} = body -> custom_central_body(body)
      other -> {:error, {:unsupported_central_body, other}}
    end
  end

  defp custom_central_body(body) do
    with {:ok, name} <- required_atom(body, "name"),
         {:ok, mu_km3_s2} <- required_number(body, "mu_km3_s2"),
         {:ok, opts} <- central_body_opts(body) do
      {:ok, CentralBody.new!(name, mu_km3_s2, opts)}
    end
  end

  defp central_body_opts(body) do
    with {:ok, radius} <- optional_number(body, "equatorial_radius_km"),
         {:ok, j2} <- optional_number(body, "j2") do
      {:ok, compact_keyword(equatorial_radius_km: radius, j2: j2)}
    end
  end

  defp scenarios(source, central_body) do
    with {:ok, scenario_specs} <- optional_list(source, "scenarios"),
         {:ok, explicit_scenarios} <- scenario_specs(scenario_specs, central_body),
         {:ok, mission_plan_scenarios} <- mission_plan_scenarios(source, central_body),
         {:ok, campaign_scenarios} <- campaign_scenarios(source, central_body),
         {:ok, candidate_refresh_scenarios} <- candidate_refresh_scenarios(source, central_body),
         {:ok, search_scenarios} <- search_scenarios(source, central_body),
         {:ok, monte_carlo_scenarios} <- monte_carlo_scenarios(source, central_body),
         scenarios =
           explicit_scenarios ++
             mission_plan_scenarios ++
             campaign_scenarios ++
             candidate_refresh_scenarios ++ search_scenarios ++ monte_carlo_scenarios,
         :ok <- validate_non_empty_scenarios(scenarios) do
      {:ok, scenarios}
    end
  end

  defp scenario_specs(scenario_specs, central_body) do
    scenario_specs
    |> Enum.reduce_while({:ok, []}, fn scenario_spec, {:ok, scenarios} ->
      case scenario(scenario_spec, central_body) do
        {:ok, built} -> {:cont, {:ok, scenarios ++ built}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp validate_non_empty_scenarios([]), do: {:error, {:missing_field, "scenarios"}}
  defp validate_non_empty_scenarios(_scenarios), do: :ok

  defp mission_plan_metadata(scenarios) do
    scenarios
    |> Enum.map(&get_in(&1.metadata, [:mission_plan]))
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> {:ok, nil}
      plans -> {:ok, plans}
    end
  end

  defp scenario(%{"generator" => "circular_leo"} = spec, central_body) do
    with :ok <- reject_generated_maneuvers(spec),
         {:ok, opts} <- circular_leo_opts(spec, central_body) do
      {:ok, ScenarioFixture.circular_leo(opts)}
    end
  end

  defp scenario(%{} = spec, central_body) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, spacecraft} <- spacecraft(spec),
         {:ok, initial_state} <- initial_state(spec),
         {:ok, duration_s} <- required_number(spec, "duration_s"),
         {:ok, output_step_s} <- required_number(spec, "output_step_s"),
         {:ok, maneuvers} <- maneuvers(spec) do
      {:ok,
       [
         Scenario.new!(id, spacecraft, initial_state,
           duration_s: duration_s,
           output_step_s: output_step_s,
           central_body: central_body,
           maneuvers: maneuvers
         )
       ]}
    end
  end

  defp scenario(_spec, _central_body), do: {:error, {:invalid_field, "scenarios"}}

  defp mission_plan_scenarios(%{"mission_plans" => plans}, central_body) when is_list(plans) do
    plans
    |> Enum.reduce_while({:ok, []}, fn plan_spec, {:ok, scenarios} ->
      case mission_plan_scenario(plan_spec, central_body) do
        {:ok, scenario} -> {:cont, {:ok, scenarios ++ [scenario]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp mission_plan_scenarios(%{"mission_plans" => _plans}, _central_body),
    do: {:error, {:invalid_field, "mission_plans"}}

  defp mission_plan_scenarios(_source, _central_body), do: {:ok, []}

  defp mission_plan_scenario(%{} = spec, central_body) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, spacecraft} <- spacecraft(spec),
         {:ok, initial_state} <- initial_state(spec),
         {:ok, horizon_s} <- required_number(spec, "horizon_s"),
         {:ok, output_step_s} <- required_number(spec, "output_step_s"),
         {:ok, activities} <- activities(spec),
         {:ok, activities} <- scoped_activities(activities, id, spacecraft.id),
         {:ok, metadata} <- metadata(spec) do
      plan =
        MissionPlan.new!(id, spacecraft, initial_state,
          horizon_s: horizon_s,
          output_step_s: output_step_s,
          central_body: central_body,
          activities: activities,
          metadata: metadata
        )

      MissionPlan.to_scenario(plan)
    end
  end

  defp mission_plan_scenario(_spec, _central_body),
    do: {:error, {:invalid_field, "mission_plans"}}

  defp campaign_scenarios(%{"campaign" => %{} = campaign}, central_body) do
    with {:ok, horizon} <- required_map(campaign, "planning_horizon"),
         {:ok, duration_s} <- required_number(horizon, "duration_s"),
         {:ok, output_step_s} <- required_number(horizon, "output_step_s"),
         {:ok, spacecraft_specs} <- required_list(campaign, "spacecraft") do
      spacecraft_specs
      |> Enum.reduce_while({:ok, []}, fn spacecraft_spec, {:ok, scenarios} ->
        case campaign_spacecraft_scenario(
               spacecraft_spec,
               duration_s,
               output_step_s,
               central_body
             ) do
          {:ok, scenario} -> {:cont, {:ok, scenarios ++ [scenario]}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
    end
  end

  defp campaign_scenarios(%{"campaign" => _campaign}, _central_body),
    do: {:error, {:invalid_field, "campaign"}}

  defp campaign_scenarios(_source, _central_body), do: {:ok, []}

  defp candidate_refresh_scenarios(%{"candidate_refresh" => %{} = refresh}, central_body) do
    with {:ok, accepted_state} <- accepted_planning_state(refresh),
         {:ok, horizon} <- candidate_refresh_horizon(refresh),
         {:ok, output_step_s} <- required_number(horizon, "output_step_s"),
         {:ok, end_s} <- candidate_refresh_horizon_end(refresh, horizon),
         spacecraft_states = Map.get(accepted_state, "spacecraft_states", []),
         :ok <- validate_spacecraft_states(spacecraft_states) do
      spacecraft_states
      |> Enum.reduce_while({:ok, []}, fn state, {:ok, scenarios} ->
        case candidate_refresh_scenario(state, accepted_state, end_s, output_step_s, central_body) do
          {:ok, scenario} -> {:cont, {:ok, scenarios ++ [scenario]}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
    end
  end

  defp candidate_refresh_scenarios(%{"candidate_refresh" => _refresh}, _central_body),
    do: {:error, {:invalid_field, "candidate_refresh"}}

  defp candidate_refresh_scenarios(_source, _central_body), do: {:ok, []}

  defp candidate_refresh_scenario(
         %{} = state,
         accepted_state,
         end_s,
         output_step_s,
         central_body
       ) do
    with {:ok, scenario_id} <- required(state, "scenario_id"),
         {:ok, spacecraft_id} <- required(state, "spacecraft_id"),
         {:ok, initial_state} <- planning_state_vector(state),
         {:ok, dry_mass_kg} <- spacecraft_dry_mass(state),
         duration_s = end_s - initial_state.epoch.seconds_since_j2000,
         :ok <- validate_positive_duration(duration_s, "candidate_refresh.remaining_horizon") do
      spacecraft = Spacecraft.new!(spacecraft_id, dry_mass_kg)

      {:ok,
       Scenario.new!(scenario_id, spacecraft, initial_state,
         duration_s: duration_s,
         output_step_s: output_step_s,
         central_body: central_body,
         metadata: %{
           candidate_refresh: %{
             accepted_snapshot_id: Map.get(accepted_state, "snapshot_id"),
             spacecraft_id: spacecraft_id,
             state_source: Map.get(state, "source", %{}),
             state_quality: Map.get(state, "quality", %{})
           }
         }
       )}
    end
  end

  defp candidate_refresh_scenario(_state, _accepted_state, _end_s, _output_step_s, _central_body),
    do: {:error, {:invalid_field, "candidate_refresh.accepted_planning_state.spacecraft_states"}}

  defp campaign_spacecraft_scenario(%{} = spec, duration_s, output_step_s, central_body) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, spacecraft} <- campaign_spacecraft(spec),
         {:ok, initial_state} <- initial_state(spec) do
      {:ok,
       Scenario.new!(id, spacecraft, initial_state,
         duration_s: duration_s,
         output_step_s: output_step_s,
         central_body: central_body,
         metadata: %{campaign_spacecraft_id: id}
       )}
    end
  end

  defp campaign_spacecraft_scenario(_spec, _duration_s, _output_step_s, _central_body),
    do: {:error, {:invalid_field, "campaign.spacecraft"}}

  defp search_scenarios(%{"search" => %{} = search}, central_body) do
    case Map.get(search, "generator", "impulsive_burn_grid") do
      "impulsive_burn_grid" -> impulsive_burn_grid(search, central_body)
      other -> {:error, {:unsupported_search_generator, other}}
    end
  end

  defp search_scenarios(%{"search" => _search}, _central_body),
    do: {:error, {:invalid_field, "search"}}

  defp search_scenarios(_source, _central_body), do: {:ok, []}

  defp monte_carlo_scenarios(%{"monte_carlo" => %{} = monte_carlo}, central_body) do
    case Map.get(monte_carlo, "generator", "state_vector_dispersion") do
      "state_vector_dispersion" -> state_vector_dispersion(monte_carlo, central_body)
      other -> {:error, {:unsupported_monte_carlo_generator, other}}
    end
  end

  defp monte_carlo_scenarios(%{"monte_carlo" => _monte_carlo}, _central_body),
    do: {:error, {:invalid_field, "monte_carlo"}}

  defp monte_carlo_scenarios(_source, _central_body), do: {:ok, []}

  defp impulsive_burn_grid(search, central_body) do
    with {:ok, base_scenario_spec} <- required_map(search, "base_scenario"),
         {:ok, [base_scenario]} <- scenario(base_scenario_spec, central_body),
         {:ok, burn_epoch_s_values} <- required_number_list(search, "burn_epoch_s"),
         {:ok, delta_v_values} <- required_vector_list(search, "delta_v_km_s"),
         {:ok, id_prefix} <- optional_string(search, "id_prefix", "#{base_scenario.id}_grid") do
      {:ok,
       Grid.impulsive_burn_grid(base_scenario,
         burn_epoch_s: burn_epoch_s_values,
         delta_v_km_s: delta_v_values,
         id_prefix: id_prefix
       )}
    else
      {:ok, _other} -> {:error, {:invalid_field, "search.base_scenario"}}
      {:error, reason} -> {:error, reason}
    end
  rescue
    error in ArgumentError -> {:error, {:invalid_search, Exception.message(error)}}
  end

  defp state_vector_dispersion(monte_carlo, central_body) do
    with {:ok, base_scenario_spec} <- required_map(monte_carlo, "base_scenario"),
         {:ok, [base_scenario]} <- scenario(base_scenario_spec, central_body),
         {:ok, count} <- required_positive_integer(monte_carlo, "count"),
         {:ok, seed} <- required_non_negative_integer(monte_carlo, "seed"),
         {:ok, position_sigma_km} <- required_vector(monte_carlo, "position_sigma_km"),
         {:ok, velocity_sigma_km_s} <- required_vector(monte_carlo, "velocity_sigma_km_s"),
         :ok <- validate_non_negative_vector(position_sigma_km, "position_sigma_km"),
         :ok <- validate_non_negative_vector(velocity_sigma_km_s, "velocity_sigma_km_s"),
         {:ok, id_prefix} <- optional_string(monte_carlo, "id_prefix", "#{base_scenario.id}_mc") do
      {:ok,
       MonteCarlo.state_vector_dispersion(base_scenario,
         count: count,
         seed: seed,
         position_sigma_km: position_sigma_km,
         velocity_sigma_km_s: velocity_sigma_km_s,
         id_prefix: id_prefix
       )}
    else
      {:ok, _other} -> {:error, {:invalid_field, "monte_carlo.base_scenario"}}
      {:error, reason} -> {:error, reason}
    end
  rescue
    error in ArgumentError -> {:error, {:invalid_monte_carlo, Exception.message(error)}}
  end

  defp search_metadata(%{"search" => %{} = search}) do
    with {:ok, generator} <- search_generator(search),
         {:ok, burn_epoch_s_values} <- required_number_list(search, "burn_epoch_s"),
         {:ok, delta_v_values} <- required_vector_list(search, "delta_v_km_s"),
         {:ok, id_prefix} <- optional_string(search, "id_prefix"),
         {:ok, objective} <- optional_search_objective(search),
         {:ok, objective_direction} <- optional_search_objective_direction(search, objective),
         {:ok, rank_limit} <- optional_search_rank_limit(search, objective) do
      {:ok,
       %{
         "generator" => generator,
         "burn_epoch_s" => burn_epoch_s_values,
         "delta_v_km_s" => delta_v_values
       }
       |> maybe_put("id_prefix", id_prefix)
       |> maybe_put("objective", objective)
       |> maybe_put("objective_direction", objective_direction)
       |> maybe_put("rank_limit", rank_limit)}
    end
  end

  defp search_metadata(%{"search" => _search}), do: {:error, {:invalid_field, "search"}}
  defp search_metadata(_source), do: {:ok, nil}

  defp monte_carlo_metadata(%{"monte_carlo" => %{} = monte_carlo}) do
    with {:ok, generator} <- monte_carlo_generator(monte_carlo),
         {:ok, count} <- required_positive_integer(monte_carlo, "count"),
         {:ok, seed} <- required_non_negative_integer(monte_carlo, "seed"),
         {:ok, position_sigma_km} <- required_vector(monte_carlo, "position_sigma_km"),
         {:ok, velocity_sigma_km_s} <- required_vector(monte_carlo, "velocity_sigma_km_s"),
         :ok <- validate_non_negative_vector(position_sigma_km, "position_sigma_km"),
         :ok <- validate_non_negative_vector(velocity_sigma_km_s, "velocity_sigma_km_s"),
         {:ok, id_prefix} <- optional_string(monte_carlo, "id_prefix"),
         {:ok, objective} <- optional_objective(monte_carlo, "monte_carlo.objective"),
         {:ok, objective_direction} <-
           optional_objective_direction(
             monte_carlo,
             objective,
             "monte_carlo.objective_direction"
           ),
         {:ok, rank_limit} <-
           optional_rank_limit(monte_carlo, objective, "monte_carlo.rank_limit") do
      {:ok,
       %{
         "generator" => generator,
         "count" => count,
         "seed" => seed,
         "position_sigma_km" => Tuple.to_list(position_sigma_km),
         "velocity_sigma_km_s" => Tuple.to_list(velocity_sigma_km_s)
       }
       |> maybe_put("id_prefix", id_prefix)
       |> maybe_put("objective", objective)
       |> maybe_put("objective_direction", objective_direction)
       |> maybe_put("rank_limit", rank_limit)}
    end
  end

  defp monte_carlo_metadata(%{"monte_carlo" => _monte_carlo}),
    do: {:error, {:invalid_field, "monte_carlo"}}

  defp monte_carlo_metadata(_source), do: {:ok, nil}

  defp campaign_metadata(%{"campaign" => %{} = campaign}) do
    with {:ok, horizon} <- required_map(campaign, "planning_horizon"),
         {:ok, duration_s} <- required_number(horizon, "duration_s"),
         {:ok, output_step_s} <- required_number(horizon, "output_step_s"),
         {:ok, spacecraft_specs} <- required_list(campaign, "spacecraft"),
         {:ok, target_specs} <- required_list(campaign, "targets"),
         {:ok, constraints} <- campaign_constraints(campaign),
         {:ok, scoring_policy} <- campaign_scoring_policy(campaign),
         {:ok, ground_network} <- campaign_ground_network(campaign),
         {:ok, resource_summaries} <- campaign_resource_summaries(campaign) do
      {:ok,
       %{
         "planning_horizon" => %{
           "duration_s" => duration_s * 1.0,
           "output_step_s" => output_step_s * 1.0
         },
         "spacecraft" => Enum.map(spacecraft_specs, &campaign_spacecraft_metadata/1),
         "targets" => Enum.map(target_specs, &target_metadata/1),
         "constraints" => constraints,
         "scoring_policy" => scoring_policy,
         "ground_network" => ground_network,
         "resource_summaries" => resource_summaries
       }}
    end
  rescue
    error in ArgumentError -> {:error, {:invalid_campaign, Exception.message(error)}}
  end

  defp campaign_metadata(%{"campaign" => _campaign}), do: {:error, {:invalid_field, "campaign"}}
  defp campaign_metadata(_source), do: {:ok, nil}

  defp campaign_ground_network(campaign) do
    with {:ok, entries} <- optional_list(campaign, "ground_network") do
      normalize_ground_network_entries(entries, "campaign.ground_network")
    end
  end

  defp normalize_ground_network_entries(entries, field) do
    entries
    |> Enum.reduce_while({:ok, []}, fn entry, {:ok, acc} ->
      case ground_network_entry(entry, field) do
        {:ok, normalized} -> {:cont, {:ok, acc ++ [normalized]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp ground_network_entry(%{} = entry, field) do
    with {:ok, ground_station_id} <- required_ground_station_id(entry),
         {:ok, id} <- optional_string(entry, "id"),
         {:ok, status} <- optional_string(entry, "status"),
         {:ok, availability} <- optional_station_availability(entry, "availability"),
         {:ok, starts_at_s} <- optional_number(entry, "starts_at_s"),
         {:ok, ends_at_s} <- optional_number(entry, "ends_at_s"),
         {:ok, capacity_fraction} <- optional_number(entry, "capacity_fraction"),
         {:ok, available?} <- optional_boolean_or_nil(entry, "available"),
         {:ok, station_calendar_entry_id} <- optional_string(entry, "station_calendar_entry_id"),
         {:ok, station_calendar_provider_id} <-
           optional_string(entry, "station_calendar_provider_id"),
         {:ok, station_calendar_provider_entry_id} <-
           optional_string(entry, "station_calendar_provider_entry_id"),
         {:ok, station_calendar_directions} <-
           optional_identifier_list(entry, "station_calendar_directions"),
         {:ok, station_calendar_status} <- optional_string(entry, "station_calendar_status"),
         {:ok, station_calendar_trust_boundary_status} <-
           optional_string(entry, "station_calendar_trust_boundary_status"),
         {:ok, station_contention_status} <- optional_string(entry, "station_contention_status"),
         {:ok, reservation_id} <- optional_string(entry, "reservation_id"),
         {:ok, reserved_by} <- optional_string(entry, "reserved_by"),
         {:ok, reservation_status} <- optional_string(entry, "reservation_status"),
         {:ok, station_reservation_match_status} <-
           optional_string(entry, "station_reservation_match_status"),
         {:ok, provenance} <- optional_map(entry, "provenance"),
         :ok <- validate_optional_interval(field, starts_at_s, ends_at_s) do
      capacity_fraction = capacity_fraction || numeric_availability_fraction(availability)
      status = ground_network_status(status, availability)
      availability = normalized_ground_network_availability(availability)

      {:ok,
       %{}
       |> Map.put("ground_station_id", ground_station_id)
       |> maybe_put("id", id)
       |> Map.put("status", status)
       |> maybe_put("availability", availability)
       |> maybe_put("starts_at_s", starts_at_s)
       |> maybe_put("ends_at_s", ends_at_s)
       |> maybe_put("capacity_fraction", capacity_fraction)
       |> maybe_put("available", available?)
       |> maybe_put("station_calendar_entry_id", station_calendar_entry_id)
       |> maybe_put("station_calendar_provider_id", station_calendar_provider_id)
       |> maybe_put("station_calendar_provider_entry_id", station_calendar_provider_entry_id)
       |> maybe_put_non_empty("station_calendar_directions", station_calendar_directions)
       |> maybe_put("station_calendar_status", station_calendar_status)
       |> maybe_put(
         "station_calendar_trust_boundary_status",
         station_calendar_trust_boundary_status
       )
       |> maybe_put("station_contention_status", station_contention_status)
       |> maybe_put("reservation_id", reservation_id)
       |> maybe_put("reserved_by", reserved_by)
       |> maybe_put("reservation_status", reservation_status)
       |> maybe_put("station_reservation_match_status", station_reservation_match_status)
       |> maybe_put("provenance", provenance)}
    end
  end

  defp ground_network_entry(_entry, field), do: {:error, {:invalid_field, field}}

  defp ground_network_status(status, _availability) when is_binary(status), do: status

  defp ground_network_status(nil, availability) when is_number(availability) do
    if availability < 1.0, do: "reduced_capacity", else: "available"
  end

  defp ground_network_status(nil, availability) when is_binary(availability), do: availability
  defp ground_network_status(nil, _availability), do: "available"

  defp normalized_ground_network_availability(value) when is_number(value) do
    if value < 1.0, do: "reduced_capacity", else: "available"
  end

  defp normalized_ground_network_availability(value) when is_binary(value), do: value
  defp normalized_ground_network_availability(_value), do: nil

  defp numeric_availability_fraction(value) when is_number(value), do: value
  defp numeric_availability_fraction(_value), do: nil

  defp required_ground_station_id(entry) do
    case Map.get(entry, "ground_station_id") || Map.get(entry, "station_id") do
      value when value not in [nil, ""] -> {:ok, value}
      _missing -> {:error, {:missing_field, "ground_station_id"}}
    end
  end

  defp campaign_resource_summaries(campaign) do
    with {:ok, summaries} <- optional_list(campaign, "resource_summaries") do
      {:ok, ResourceSummary.to_maps(summaries)}
    end
  rescue
    error in ArgumentError ->
      {:error, {:invalid_campaign, Exception.message(error)}}
  end

  defp candidate_refresh_metadata(%{"candidate_refresh" => %{} = refresh} = source) do
    with {:ok, accepted_state} <- accepted_planning_state(refresh),
         {:ok, horizon} <- candidate_refresh_horizon(refresh),
         {:ok, current_epoch_s} <- candidate_refresh_current_epoch(refresh, accepted_state),
         {:ok, targets} <- candidate_refresh_target_metadata(refresh),
         {:ok, constraints} <- candidate_refresh_constraints(refresh),
         {:ok, scoring_policy} <- candidate_refresh_scoring_policy(refresh),
         {:ok, objectives} <- candidate_refresh_objectives(refresh),
         {:ok, freshness_policy} <- candidate_refresh_freshness_policy(refresh),
         {:ok, resource_filter_policy} <- candidate_refresh_resource_filter_policy(refresh),
         {:ok, candidate_limit_policy} <- candidate_refresh_candidate_limit_policy(refresh),
         {:ok, approval_policy} <- candidate_refresh_approval_policy(refresh),
         {:ok, operational_feedback} <- candidate_refresh_operational_feedback(refresh),
         {:ok, mission_state} <- candidate_refresh_mission_state(refresh),
         {:ok, source_timeline_feedback_report} <-
           candidate_refresh_timeline_feedback_report(refresh, "source_timeline_feedback_report"),
         {:ok, timeline_feedback_report} <-
           candidate_refresh_timeline_feedback_report(refresh, "timeline_feedback_report"),
         {:ok, source_operational_timeline_report} <-
           candidate_refresh_operational_timeline_report(
             refresh,
             "source_operational_timeline_report"
           ),
         {:ok, operational_timeline_report} <-
           candidate_refresh_operational_timeline_report(refresh, "operational_timeline_report"),
         {:ok, model_assumptions} <- candidate_refresh_model_assumptions(refresh),
         {:ok, resource_summaries} <- candidate_refresh_resource_summaries(refresh),
         {:ok, ground_network} <- candidate_refresh_ground_network(refresh),
         {:ok, prior_candidate_activities} <- candidate_refresh_prior_candidates(refresh) do
      refresh_metadata =
        %{
          "accepted_planning_state" => accepted_state,
          "current_epoch_s" => current_epoch_s,
          "remaining_horizon" => horizon,
          "targets" => targets,
          "constraints" => constraints,
          "scoring_policy" => scoring_policy,
          "objectives" => objectives,
          "freshness_policy" => freshness_policy,
          "resource_filter_policy" => resource_filter_policy,
          "candidate_limit_policy" => candidate_limit_policy,
          "approval_policy" => approval_policy,
          "operational_feedback" => operational_feedback,
          "mission_state" => mission_state,
          "model_assumptions" => model_assumptions,
          "resource_summaries" => resource_summaries,
          "ground_network" => ground_network,
          "prior_candidate_activities" => prior_candidate_activities,
          "run_input_sources" => candidate_refresh_run_input_sources(source)
        }
        |> maybe_put("source_timeline_feedback_report", source_timeline_feedback_report)
        |> maybe_put("timeline_feedback_report", timeline_feedback_report)
        |> maybe_put("source_operational_timeline_report", source_operational_timeline_report)
        |> maybe_put("operational_timeline_report", operational_timeline_report)

      {:ok, refresh_metadata}
    end
  end

  defp candidate_refresh_metadata(%{"candidate_refresh" => _refresh}),
    do: {:error, {:invalid_field, "candidate_refresh"}}

  defp candidate_refresh_metadata(_source), do: {:ok, nil}

  defp campaign_spacecraft_metadata(%{} = spec) do
    %{
      "id" => Map.get(spec, "id"),
      "dry_mass_kg" => Map.get(spec, "dry_mass_kg"),
      "propellant_mass_kg" => Map.get(spec, "propellant_mass_kg"),
      "area_m2" => Map.get(spec, "area_m2"),
      "drag_coefficient" => Map.get(spec, "drag_coefficient")
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp campaign_constraints(campaign) do
    case Map.get(campaign, "constraints", %{}) do
      %{} = constraints ->
        with {:ok, min_activity_duration_s} <-
               optional_number(constraints, "min_activity_duration_s"),
             {:ok, max_timeline_activities} <-
               optional_positive_integer(constraints, "max_timeline_activities", nil),
             {:ok, avoid_eclipse?} <- optional_boolean(constraints, "avoid_eclipse", true) do
          {:ok,
           %{}
           |> maybe_put("min_activity_duration_s", min_activity_duration_s || 0.0)
           |> maybe_put("max_timeline_activities", max_timeline_activities)
           |> Map.put("avoid_eclipse", avoid_eclipse?)}
        end

      _constraints ->
        {:error, {:invalid_field, "campaign.constraints"}}
    end
  end

  defp campaign_scoring_policy(campaign) do
    case Map.get(campaign, "scoring_policy", %{}) do
      %{} = policy ->
        with {:ok, target_value_weight} <- optional_number(policy, "target_value_weight"),
             {:ok, contact_value_weight} <- optional_number(policy, "contact_value_weight"),
             {:ok, eclipse_penalty_weight} <- optional_number(policy, "eclipse_penalty_weight"),
             {:ok, activity_count_penalty} <- optional_number(policy, "activity_count_penalty"),
             {:ok, rank_limit} <- optional_positive_integer(policy, "rank_limit", 10) do
          {:ok,
           %{
             "target_value_weight" => target_value_weight || 1.0,
             "contact_value_weight" => contact_value_weight || 0.1,
             "eclipse_penalty_weight" => eclipse_penalty_weight || 1.0,
             "activity_count_penalty" => activity_count_penalty || 0.0,
             "rank_limit" => rank_limit
           }}
        end

      _policy ->
        {:error, {:invalid_field, "campaign.scoring_policy"}}
    end
  end

  defp monte_carlo_generator(monte_carlo) do
    case Map.get(monte_carlo, "generator", "state_vector_dispersion") do
      "state_vector_dispersion" -> {:ok, "state_vector_dispersion"}
      other -> {:error, {:unsupported_monte_carlo_generator, other}}
    end
  end

  defp search_generator(search) do
    case Map.get(search, "generator", "impulsive_burn_grid") do
      "impulsive_burn_grid" -> {:ok, "impulsive_burn_grid"}
      other -> {:error, {:unsupported_search_generator, other}}
    end
  end

  defp optional_search_objective(search) do
    optional_objective(search, "search.objective")
  end

  defp optional_search_objective_direction(search, nil) do
    optional_objective_direction(search, nil, "search.objective_direction")
  end

  defp optional_search_objective_direction(search, objective) do
    optional_objective_direction(search, objective, "search.objective_direction")
  end

  defp optional_search_rank_limit(search, nil) do
    optional_rank_limit(search, nil, "search.rank_limit")
  end

  defp optional_search_rank_limit(search, objective) do
    optional_rank_limit(search, objective, "search.rank_limit")
  end

  defp optional_objective(map, field) do
    case Map.fetch(map, "objective") do
      {:ok, objective} when objective in @search_objectives -> {:ok, objective}
      {:ok, _objective} -> {:error, {:invalid_field, field}}
      :error -> {:ok, nil}
    end
  end

  defp optional_objective_direction(map, nil, field) do
    case Map.fetch(map, "objective_direction") do
      {:ok, _direction} -> {:error, {:invalid_field, field}}
      :error -> {:ok, nil}
    end
  end

  defp optional_objective_direction(map, objective, field) do
    inferred_direction = Report.objective_direction_label(objective)

    case Map.fetch(map, "objective_direction") do
      {:ok, ^inferred_direction} ->
        {:ok, inferred_direction}

      {:ok, direction} when direction in ["maximize", "minimize"] ->
        {:error, {:invalid_objective_direction, objective, direction, inferred_direction}}

      {:ok, _direction} ->
        {:error, {:invalid_field, field}}

      :error ->
        {:ok, inferred_direction}
    end
  end

  defp optional_rank_limit(map, nil, field) do
    case Map.fetch(map, "rank_limit") do
      {:ok, _limit} -> {:error, {:invalid_field, field}}
      :error -> {:ok, nil}
    end
  end

  defp optional_rank_limit(map, _objective, _field) do
    optional_positive_integer(map, "rank_limit", 10)
  end

  defp constraints(source) do
    with {:ok, specs} <- optional_list(source, "constraints") do
      specs
      |> Enum.reduce_while({:ok, []}, fn spec, {:ok, constraints} ->
        case constraint(spec) do
          {:ok, constraint} -> {:cont, {:ok, constraints ++ [constraint]}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
      |> case do
        {:ok, []} -> {:ok, nil}
        result -> result
      end
    end
  end

  defp constraint(%{} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, metric} <- required_constraint_metric(spec),
         {:ok, operator} <- required_constraint_operator(spec),
         {:ok, value} <- required_number(spec, "value") do
      {:ok,
       %{
         "id" => id,
         "metric" => metric,
         "operator" => operator,
         "value" => value * 1.0
       }}
    end
  end

  defp constraint(_spec), do: {:error, {:invalid_field, "constraints"}}

  defp required_constraint_metric(spec) do
    case Map.fetch(spec, "metric") do
      {:ok, metric} when metric in @search_objectives -> {:ok, metric}
      {:ok, _metric} -> {:error, {:invalid_field, "constraints.metric"}}
      :error -> {:error, {:missing_field, "constraints.metric"}}
    end
  end

  defp required_constraint_operator(spec) do
    case Map.fetch(spec, "operator") do
      {:ok, operator} when operator in ["<", "<=", "==", ">=", ">"] -> {:ok, operator}
      {:ok, _operator} -> {:error, {:invalid_field, "constraints.operator"}}
      :error -> {:error, {:missing_field, "constraints.operator"}}
    end
  end

  defp reject_generated_maneuvers(%{"maneuvers" => _maneuvers}),
    do: {:error, {:unsupported_field, "scenarios.maneuvers_for_generator"}}

  defp reject_generated_maneuvers(_spec), do: :ok

  defp circular_leo_opts(spec, central_body) do
    with {:ok, count} <- required_positive_integer(spec, "count"),
         {:ok, duration_s} <- required_number(spec, "duration_s"),
         {:ok, output_step_s} <- required_number(spec, "output_step_s"),
         {:ok, radius_km} <- optional_number(spec, "radius_km"),
         {:ok, dry_mass_kg} <- optional_number(spec, "dry_mass_kg"),
         {:ok, id_prefix} <- optional_string(spec, "id_prefix", "manifest_leo"),
         {:ok, epoch} <- optional_epoch(spec),
         {:ok, frame} <- optional_frame(spec) do
      {:ok,
       compact_keyword(
         count: count,
         duration_s: duration_s,
         output_step_s: output_step_s,
         radius_km: radius_km,
         dry_mass_kg: dry_mass_kg,
         id_prefix: id_prefix,
         epoch: epoch,
         frame: frame,
         central_body: central_body
       )}
    end
  end

  defp spacecraft(spec) do
    with {:ok, spacecraft} <- required_map(spec, "spacecraft"),
         {:ok, id} <- required(spacecraft, "id"),
         {:ok, dry_mass_kg} <- required_number(spacecraft, "dry_mass_kg"),
         {:ok, propellant_mass_kg} <- optional_number(spacecraft, "propellant_mass_kg"),
         {:ok, area_m2} <- optional_number(spacecraft, "area_m2"),
         {:ok, drag_coefficient} <- optional_number(spacecraft, "drag_coefficient") do
      {:ok,
       Spacecraft.new!(
         id,
         dry_mass_kg,
         compact_keyword(
           propellant_mass_kg: propellant_mass_kg,
           area_m2: area_m2,
           drag_coefficient: drag_coefficient
         )
       )}
    end
  end

  defp campaign_spacecraft(spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, dry_mass_kg} <- required_number(spec, "dry_mass_kg"),
         {:ok, propellant_mass_kg} <- optional_number(spec, "propellant_mass_kg"),
         {:ok, area_m2} <- optional_number(spec, "area_m2"),
         {:ok, drag_coefficient} <- optional_number(spec, "drag_coefficient") do
      {:ok,
       Spacecraft.new!(
         id,
         dry_mass_kg,
         compact_keyword(
           propellant_mass_kg: propellant_mass_kg,
           area_m2: area_m2,
           drag_coefficient: drag_coefficient
         )
       )}
    end
  end

  defp initial_state(spec) do
    with {:ok, initial_state} <- required_map(spec, "initial_state"),
         {:ok, position_km} <- required_vector(initial_state, "position_km"),
         {:ok, velocity_km_s} <- required_vector(initial_state, "velocity_km_s"),
         {:ok, epoch} <- epoch(initial_state),
         {:ok, frame} <- frame(initial_state) do
      {:ok, StateVector.new!(position_km, velocity_km_s, epoch, frame)}
    end
  end

  defp maneuvers(spec) do
    spec
    |> Map.get("maneuvers", [])
    |> case do
      maneuvers when is_list(maneuvers) ->
        maneuvers
        |> Enum.reduce_while({:ok, []}, fn maneuver_spec, {:ok, maneuvers} ->
          case maneuver(maneuver_spec) do
            {:ok, maneuver} -> {:cont, {:ok, maneuvers ++ [maneuver]}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      _other ->
        {:error, {:invalid_field, "maneuvers"}}
    end
  end

  defp maneuver(%{} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, epoch} <- epoch(spec),
         {:ok, delta_v_km_s} <- required_vector(spec, "delta_v_km_s"),
         {:ok, frame} <- frame(spec) do
      {:ok, ImpulsiveBurn.new!(id, epoch, delta_v_km_s, frame)}
    end
  end

  defp maneuver(_spec), do: {:error, {:invalid_field, "maneuvers"}}

  defp activities(spec) do
    spec
    |> Map.get("activities", [])
    |> case do
      activities when is_list(activities) ->
        activities
        |> Enum.reduce_while({:ok, []}, fn activity_spec, {:ok, activities} ->
          case activity(activity_spec) do
            {:ok, activity} -> {:cont, {:ok, activities ++ [activity]}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      _other ->
        {:error, {:invalid_field, "activities"}}
    end
  end

  defp scoped_activities(activities, scenario_id, spacecraft_id) do
    activities
    |> Enum.reduce_while({:ok, []}, fn %Activity{} = activity, {:ok, scoped} ->
      cond do
        not scope_matches?(activity.scenario_id, scenario_id) ->
          {:halt, {:error, {:invalid_field, "activities.scenario_id"}}}

        not scope_matches?(activity.spacecraft_id, spacecraft_id) ->
          {:halt, {:error, {:invalid_field, "activities.spacecraft_id"}}}

        true ->
          {:cont,
           {:ok,
            scoped ++
              [
                %Activity{
                  activity
                  | scenario_id: activity.scenario_id || scenario_id,
                    spacecraft_id: activity.spacecraft_id || spacecraft_id
                }
              ]}}
      end
    end)
  end

  defp scope_matches?(nil, _expected), do: true
  defp scope_matches?(value, expected), do: to_string(value) == to_string(expected)

  defp activity(%{"type" => type} = spec) when type in [nil, ""] do
    spec
    |> Map.delete("type")
    |> activity()
  end

  defp activity(%{"type" => "coast"} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, start_s} <- required_number(spec, "start_s"),
         {:ok, end_s} <- required_number(spec, "end_s"),
         {:ok, opts} <- activity_opts(spec) do
      {:ok, Activity.coast!(id, start_s, end_s, opts)}
    end
  end

  defp activity(%{"type" => "observe"} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, start_s} <- required_number(spec, "start_s"),
         {:ok, end_s} <- required_number(spec, "end_s"),
         {:ok, target_id} <- required_target_id(spec),
         {:ok, opts} <- activity_opts(spec) do
      {:ok, Activity.observe!(id, start_s, end_s, target_id, opts)}
    end
  end

  defp activity(%{"type" => "downlink"} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, start_s} <- required_number(spec, "start_s"),
         {:ok, end_s} <- required_number(spec, "end_s"),
         {:ok, ground_station_id} <- required_activity_ground_station_id(spec),
         {:ok, opts} <- activity_opts(spec) do
      {:ok, Activity.downlink!(id, start_s, end_s, ground_station_id, opts)}
    end
  end

  defp activity(%{"type" => "attitude"} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, start_s} <- required_number(spec, "start_s"),
         {:ok, end_s} <- required_number(spec, "end_s"),
         {:ok, opts} <- activity_opts(spec) do
      {:ok, Activity.attitude!(id, start_s, end_s, opts)}
    end
  end

  defp activity(%{"type" => "command"} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, start_s} <- required_number(spec, "start_s"),
         {:ok, end_s} <- required_number(spec, "end_s"),
         {:ok, opts} <- activity_opts(spec) do
      {:ok, Activity.command!(id, start_s, end_s, opts)}
    end
  end

  defp activity(%{"type" => "tracking"} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, start_s} <- required_number(spec, "start_s"),
         {:ok, end_s} <- required_number(spec, "end_s"),
         {:ok, ground_station_id} <- required_activity_ground_station_id(spec),
         {:ok, opts} <- activity_opts(spec) do
      {:ok, Activity.tracking!(id, start_s, end_s, ground_station_id, opts)}
    end
  end

  defp activity(%{"type" => "health_check"} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, start_s} <- required_number(spec, "start_s"),
         {:ok, end_s} <- required_number(spec, "end_s"),
         {:ok, opts} <- activity_opts(spec),
         :ok <- ensure_health_check_direction(opts) do
      {:ok, Activity.health_check!(id, start_s, end_s, opts)}
    end
  end

  defp activity(%{"type" => "planned_contact"} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, start_s} <- required_number(spec, "start_s"),
         {:ok, end_s} <- required_number(spec, "end_s"),
         {:ok, ground_station_id} <- required_activity_ground_station_id(spec),
         {:ok, direction} <- required_contact_direction(spec),
         {:ok, opts} <- activity_opts(spec) do
      activity =
        if direction == :health_check do
          opts =
            opts
            |> Keyword.put(:ground_station_id, ground_station_id)
            |> Keyword.put(:direction, :health_check)

          Activity.health_check!(id, start_s, end_s, opts)
        else
          Activity.planned_contact!(id, start_s, end_s, ground_station_id, direction, opts)
        end

      {:ok, activity}
    end
  end

  defp activity(%{"type" => "slew"} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, start_s} <- required_number(spec, "start_s"),
         {:ok, end_s} <- required_number(spec, "end_s"),
         {:ok, opts} <- activity_opts(spec) do
      {:ok, Activity.slew!(id, start_s, end_s, opts)}
    end
  end

  defp activity(%{"type" => "impulsive_burn"} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, epoch_s} <- required_number(spec, "epoch_s"),
         {:ok, delta_v_km_s} <- required_vector(spec, "delta_v_km_s"),
         {:ok, frame} <- optional_frame(spec),
         {:ok, opts} <- activity_opts(spec) do
      opts = if is_nil(frame), do: opts, else: Keyword.put(opts, :frame, frame)
      {:ok, Activity.impulsive_burn!(id, epoch_s, delta_v_km_s, opts)}
    end
  end

  defp activity(%{"type" => type}), do: {:error, {:unsupported_activity_type, type}}

  defp activity(%{"activity_type" => type} = spec) when type not in [nil, ""] do
    activity(Map.put(spec, "type", type))
  end

  defp activity(_spec), do: {:error, {:invalid_field, "activities"}}

  defp activity_opts(spec) do
    with {:ok, metadata} <- metadata(spec),
         {:ok, allow_overlap?} <- optional_activity_overlap(spec),
         {:ok, status} <- optional_activity_status(spec),
         {:ok, approval_status} <- optional_approval_status(spec),
         {:ok, locked?} <- optional_boolean(spec, "locked", false),
         {:ok, timeline_id} <- optional_identifier(spec, "timeline_id"),
         {:ok, scenario_id} <- optional_identifier(spec, "scenario_id"),
         {:ok, spacecraft_id} <- optional_spacecraft_id(spec),
         {:ok, resource_id} <- optional_identifier(spec, "resource_id"),
         {:ok, resource_source_quality} <- optional_identifier(spec, "resource_source_quality"),
         {:ok, resource_trust_boundary} <- optional_identifier(spec, "resource_trust_boundary"),
         {:ok, resource_trust_boundary_status} <-
           optional_identifier(spec, "resource_trust_boundary_status"),
         {:ok, resource_provenance} <- optional_map_or_nil(spec, "resource_provenance"),
         {:ok, resource_blocking_dimension} <-
           optional_identifier(spec, "resource_blocking_dimension"),
         {:ok, fuel_margin} <- optional_number(spec, "fuel_margin"),
         {:ok, power_margin} <- optional_number(spec, "power_margin"),
         {:ok, storage_margin} <- optional_number(spec, "storage_margin"),
         {:ok, downlink_margin} <- optional_number(spec, "downlink_margin"),
         {:ok, battery_capacity_wh} <- optional_number(spec, "battery_capacity_wh"),
         {:ok, battery_energy_used_wh} <- optional_number(spec, "battery_energy_used_wh"),
         {:ok, battery_state_of_charge} <- optional_number(spec, "battery_state_of_charge"),
         {:ok, spacecraft_available} <- optional_boolean_or_nil(spec, "spacecraft_available"),
         {:ok, payload_available} <- optional_boolean_or_nil(spec, "payload_available"),
         {:ok, antenna_available} <- optional_boolean_or_nil(spec, "antenna_available"),
         {:ok, degraded} <- optional_boolean_or_nil(spec, "degraded"),
         {:ok, mode} <- optional_identifier(spec, "mode"),
         {:ok, incompatible_activity_types} <-
           optional_identifier_list(spec, "incompatible_activity_types"),
         {:ok, suppressed_activity_types} <-
           optional_identifier_list(spec, "suppressed_activity_types"),
         {:ok, collection_id} <- optional_identifier(spec, "collection_id"),
         {:ok, product_id} <- optional_identifier(spec, "product_id"),
         {:ok, product_ids} <- optional_identifier_list(spec, "product_ids"),
         {:ok, payload_id} <- optional_identifier(spec, "payload_id"),
         {:ok, instrument_id} <- optional_identifier(spec, "instrument_id"),
         {:ok, target_priority} <- optional_number(spec, "target_priority"),
         {:ok, target_priority_source} <- optional_identifier(spec, "target_priority_source"),
         {:ok, target_priority_objective_ids} <-
           optional_identifier_list(spec, "target_priority_objective_ids"),
         {:ok, target_priority_objective_type} <-
           optional_identifier(spec, "target_priority_objective_type"),
         {:ok, contact_success} <- optional_boolean_or_nil(spec, "contact_success"),
         {:ok, contact_result} <- optional_identifier(spec, "contact_result"),
         {:ok, contact_success_factor} <- optional_number(spec, "contact_success_factor"),
         {:ok, contact_success_factor_source} <-
           optional_identifier(spec, "contact_success_factor_source"),
         {:ok, command_success} <- optional_boolean_or_nil(spec, "command_success"),
         {:ok, command_result} <- optional_identifier(spec, "command_result"),
         {:ok, command_success_factor} <- optional_number(spec, "command_success_factor"),
         {:ok, command_success_factor_source} <-
           optional_identifier(spec, "command_success_factor_source"),
         {:ok, observation_success} <- optional_boolean_or_nil(spec, "observation_success"),
         {:ok, observation_result} <- optional_identifier(spec, "observation_result"),
         {:ok, observation_success_factor} <- optional_number(spec, "observation_success_factor"),
         {:ok, observation_success_factor_source} <-
           optional_identifier(spec, "observation_success_factor_source"),
         {:ok, image_quality_score} <- optional_number(spec, "image_quality_score"),
         {:ok, image_quality_status} <- optional_identifier(spec, "image_quality_status"),
         {:ok, image_quality_source} <- optional_string(spec, "image_quality_source"),
         {:ok, cloud_cover_fraction} <- optional_number(spec, "cloud_cover_fraction"),
         {:ok, blur_score} <- optional_number(spec, "blur_score"),
         {:ok, maneuver_success} <- optional_boolean_or_nil(spec, "maneuver_success"),
         {:ok, maneuver_result} <- optional_identifier(spec, "maneuver_result"),
         {:ok, maneuver_success_factor} <- optional_number(spec, "maneuver_success_factor"),
         {:ok, maneuver_success_factor_source} <-
           optional_identifier(spec, "maneuver_success_factor_source"),
         {:ok, feedback_weight} <- optional_number(spec, "feedback_weight"),
         {:ok, feedback_weight_source} <- optional_identifier(spec, "feedback_weight_source"),
         {:ok, data_volume_mb} <- optional_number(spec, "data_volume_mb"),
         {:ok, planned_data_volume_mb} <- optional_number(spec, "planned_data_volume_mb"),
         {:ok, actual_data_volume_mb} <- optional_number(spec, "actual_data_volume_mb"),
         {:ok, estimated_data_volume_mb} <- optional_number(spec, "estimated_data_volume_mb"),
         {:ok, estimated_storage_mb} <- optional_number(spec, "estimated_storage_mb"),
         {:ok, estimated_downlink_mb} <- optional_number(spec, "estimated_downlink_mb"),
         {:ok, required_downlink_mb} <- optional_number(spec, "required_downlink_mb"),
         {:ok, collection_ends_at_s} <- optional_number(spec, "collection_ends_at_s"),
         {:ok, planned_delivery_at_s} <- optional_number(spec, "planned_delivery_at_s"),
         {:ok, actual_delivery_at_s} <- optional_number(spec, "actual_delivery_at_s"),
         {:ok, max_latency_s} <- optional_number(spec, "max_latency_s"),
         {:ok, planned_latency_s} <- optional_number(spec, "planned_latency_s"),
         {:ok, actual_latency_s} <- optional_number(spec, "actual_latency_s"),
         {:ok, planned_estimated_throughput_mb} <-
           optional_number(spec, "planned_estimated_throughput_mb"),
         {:ok, actual_throughput_mb} <- optional_number(spec, "actual_throughput_mb"),
         {:ok, link_protocol} <- optional_identifier(spec, "link_protocol"),
         {:ok, frequency_band} <- optional_identifier(spec, "frequency_band"),
         {:ok, modulation} <- optional_identifier(spec, "modulation"),
         {:ok, coding_scheme} <- optional_identifier(spec, "coding_scheme"),
         {:ok, polarization} <- optional_identifier(spec, "polarization"),
         {:ok, data_rate_mbps} <- optional_number(spec, "data_rate_mbps"),
         {:ok, downlink_rate_mbps} <- optional_number(spec, "downlink_rate_mbps"),
         {:ok, data_rate_mb_s} <- optional_number(spec, "data_rate_mb_s"),
         {:ok, downlink_rate_mb_s} <- optional_number(spec, "downlink_rate_mb_s"),
         {:ok, actual_data_rate_mbps} <- optional_number(spec, "actual_data_rate_mbps"),
         {:ok, actual_downlink_rate_mbps} <-
           optional_number(spec, "actual_downlink_rate_mbps"),
         {:ok, actual_data_rate_mb_s} <- optional_number(spec, "actual_data_rate_mb_s"),
         {:ok, actual_downlink_rate_mb_s} <-
           optional_number(spec, "actual_downlink_rate_mb_s"),
         {:ok, delivered_rate_mbps} <- optional_number(spec, "delivered_rate_mbps"),
         {:ok, received_rate_mbps} <- optional_number(spec, "received_rate_mbps"),
         {:ok, delivered_rate_mb_s} <- optional_number(spec, "delivered_rate_mb_s"),
         {:ok, received_rate_mb_s} <- optional_number(spec, "received_rate_mb_s"),
         {:ok, actual_duration_s} <- optional_number(spec, "actual_duration_s"),
         {:ok, actual_contact_duration_s} <- optional_number(spec, "actual_contact_duration_s"),
         {:ok, contact_duration_s} <- optional_number(spec, "contact_duration_s"),
         {:ok, link_margin_db} <- optional_number(spec, "link_margin_db"),
         {:ok, snr_db} <- optional_number(spec, "snr_db"),
         {:ok, eb_no_db} <- optional_number(spec, "eb_no_db"),
         {:ok, bit_error_rate} <- optional_number(spec, "bit_error_rate"),
         {:ok, packet_loss_rate} <- optional_number(spec, "packet_loss_rate"),
         {:ok, frame_loss_rate} <- optional_number(spec, "frame_loss_rate"),
         {:ok, carrier_lock} <- optional_boolean_or_nil(spec, "carrier_lock"),
         {:ok, symbol_lock} <- optional_boolean_or_nil(spec, "symbol_lock"),
         {:ok, link_quality_status} <- optional_identifier(spec, "link_quality_status"),
         {:ok, pointing_mode} <- optional_identifier(spec, "pointing_mode"),
         {:ok, pointing_target_id} <- optional_identifier(spec, "pointing_target_id"),
         {:ok, boresight_axis} <- optional_string(spec, "boresight_axis"),
         {:ok, off_nadir_angle_deg} <- optional_number(spec, "off_nadir_angle_deg"),
         {:ok, slew_angle_deg} <- optional_number(spec, "slew_angle_deg"),
         {:ok, slew_rate_deg_s} <- optional_number(spec, "slew_rate_deg_s"),
         {:ok, pointing_error_deg} <- optional_number(spec, "pointing_error_deg"),
         {:ok, pointing_status} <- optional_identifier(spec, "pointing_status"),
         {:ok, pointing_model} <- optional_identifier(spec, "pointing_model"),
         {:ok, pointing_source} <- optional_string(spec, "pointing_source"),
         {:ok, pointing_confidence} <- optional_number(spec, "pointing_confidence"),
         {:ok, attitude_mode} <- optional_identifier(spec, "attitude_mode"),
         {:ok, attitude_target_id} <- optional_identifier(spec, "attitude_target_id"),
         {:ok, roll_deg} <- optional_number(spec, "roll_deg"),
         {:ok, pitch_deg} <- optional_number(spec, "pitch_deg"),
         {:ok, yaw_deg} <- optional_number(spec, "yaw_deg"),
         {:ok, attitude_error_deg} <- optional_number(spec, "attitude_error_deg"),
         {:ok, attitude_status} <- optional_identifier(spec, "attitude_status"),
         {:ok, attitude_model} <- optional_identifier(spec, "attitude_model"),
         {:ok, attitude_source} <- optional_string(spec, "attitude_source"),
         {:ok, attitude_confidence} <- optional_number(spec, "attitude_confidence"),
         {:ok, thermal_zone_id} <- optional_identifier(spec, "thermal_zone_id"),
         {:ok, temperature_c} <- optional_number(spec, "temperature_c"),
         {:ok, planned_temperature_c} <- optional_number(spec, "planned_temperature_c"),
         {:ok, actual_temperature_c} <- optional_number(spec, "actual_temperature_c"),
         {:ok, min_operating_temperature_c} <-
           optional_number(spec, "min_operating_temperature_c"),
         {:ok, max_operating_temperature_c} <-
           optional_number(spec, "max_operating_temperature_c"),
         {:ok, thermal_margin_c} <- optional_number(spec, "thermal_margin_c"),
         {:ok, thermal_status} <- optional_identifier(spec, "thermal_status"),
         {:ok, thermal_model} <- optional_identifier(spec, "thermal_model"),
         {:ok, thermal_source} <- optional_string(spec, "thermal_source"),
         {:ok, thermal_confidence} <- optional_number(spec, "thermal_confidence"),
         {:ok, eclipse_overlap_fraction} <- optional_number(spec, "eclipse_overlap_fraction"),
         {:ok, eclipse_overlap_s} <- optional_number(spec, "eclipse_overlap_s"),
         {:ok, lighting_condition} <- optional_identifier(spec, "lighting_condition"),
         {:ok, lighting_condition_detail} <-
           optional_identifier(spec, "lighting_condition_detail"),
         {:ok, lighting_condition_model} <- optional_identifier(spec, "lighting_condition_model"),
         {:ok, lighting_detail_model} <- optional_identifier(spec, "lighting_detail_model"),
         {:ok, lighting_confidence} <- optional_number_or_identifier(spec, "lighting_confidence"),
         {:ok, command_window_id} <- optional_command_window_id(spec),
         {:ok, command_window_type} <- optional_command_window_type(spec),
         {:ok, command_window} <- optional_map_or_nil(spec, "command_window"),
         {:ok, dependencies} <- optional_identifier_list(spec, "dependencies"),
         {:ok, dependency_activity_ids} <-
           optional_identifier_list_or_nil(spec, "dependency_activity_ids"),
         {:ok, dependency_timeline_ids} <-
           optional_identifier_list_or_nil(spec, "dependency_timeline_ids"),
         {:ok, exclusive_with_activity_ids} <-
           optional_identifier_list_or_nil(spec, "exclusive_with_activity_ids"),
         {:ok, exclusive_with_timeline_ids} <-
           optional_identifier_list_or_nil(spec, "exclusive_with_timeline_ids"),
         {:ok, exclusivity_group} <- optional_identifier(spec, "exclusivity_group"),
         {:ok, source_window_id} <- optional_identifier(spec, "source_window_id"),
         {:ok, source_window_type} <- optional_identifier(spec, "source_window_type"),
         {:ok, source_window} <- optional_map_or_nil(spec, "source_window"),
         {:ok, cadence_import} <- optional_map_or_nil(spec, "cadence_import"),
         {:ok, provenance} <- optional_map(spec, "provenance"),
         {:ok, direction} <- optional_contact_direction(spec),
         {:ok, ground_station_id} <- optional_ground_station_id(spec) do
      {:ok,
       compact_keyword(
         metadata: metadata,
         allow_overlap?: allow_overlap?,
         status: status,
         approval_status: approval_status,
         locked?: locked?,
         timeline_id: timeline_id,
         scenario_id: scenario_id,
         spacecraft_id: spacecraft_id,
         resource_id: resource_id,
         resource_source_quality: resource_source_quality,
         resource_trust_boundary: resource_trust_boundary,
         resource_trust_boundary_status: resource_trust_boundary_status,
         resource_provenance: resource_provenance,
         resource_blocking_dimension: resource_blocking_dimension,
         fuel_margin: fuel_margin,
         power_margin: power_margin,
         storage_margin: storage_margin,
         downlink_margin: downlink_margin,
         battery_capacity_wh: battery_capacity_wh,
         battery_energy_used_wh: battery_energy_used_wh,
         battery_state_of_charge: battery_state_of_charge,
         spacecraft_available: spacecraft_available,
         payload_available: payload_available,
         antenna_available: antenna_available,
         degraded: degraded,
         mode: mode,
         incompatible_activity_types: incompatible_activity_types,
         suppressed_activity_types: suppressed_activity_types,
         collection_id: collection_id,
         product_id: product_id,
         product_ids: product_ids,
         payload_id: payload_id,
         instrument_id: instrument_id,
         target_priority: target_priority,
         target_priority_source: target_priority_source,
         target_priority_objective_ids: target_priority_objective_ids,
         target_priority_objective_type: target_priority_objective_type,
         contact_success: contact_success,
         contact_result: contact_result,
         contact_success_factor: contact_success_factor,
         contact_success_factor_source: contact_success_factor_source,
         command_success: command_success,
         command_result: command_result,
         command_success_factor: command_success_factor,
         command_success_factor_source: command_success_factor_source,
         observation_success: observation_success,
         observation_result: observation_result,
         observation_success_factor: observation_success_factor,
         observation_success_factor_source: observation_success_factor_source,
         image_quality_score: image_quality_score,
         image_quality_status: image_quality_status,
         image_quality_source: image_quality_source,
         cloud_cover_fraction: cloud_cover_fraction,
         blur_score: blur_score,
         maneuver_success: maneuver_success,
         maneuver_result: maneuver_result,
         maneuver_success_factor: maneuver_success_factor,
         maneuver_success_factor_source: maneuver_success_factor_source,
         feedback_weight: feedback_weight,
         feedback_weight_source: feedback_weight_source,
         data_volume_mb: data_volume_mb,
         planned_data_volume_mb: planned_data_volume_mb,
         actual_data_volume_mb: actual_data_volume_mb,
         estimated_data_volume_mb: estimated_data_volume_mb,
         estimated_storage_mb: estimated_storage_mb,
         estimated_downlink_mb: estimated_downlink_mb,
         required_downlink_mb: required_downlink_mb,
         collection_ends_at_s: collection_ends_at_s,
         planned_delivery_at_s: planned_delivery_at_s,
         actual_delivery_at_s: actual_delivery_at_s,
         max_latency_s: max_latency_s,
         planned_latency_s: planned_latency_s,
         actual_latency_s: actual_latency_s,
         planned_estimated_throughput_mb: planned_estimated_throughput_mb,
         actual_throughput_mb: actual_throughput_mb,
         link_protocol: link_protocol,
         frequency_band: frequency_band,
         modulation: modulation,
         coding_scheme: coding_scheme,
         polarization: polarization,
         data_rate_mbps: data_rate_mbps,
         downlink_rate_mbps: downlink_rate_mbps,
         data_rate_mb_s: data_rate_mb_s,
         downlink_rate_mb_s: downlink_rate_mb_s,
         actual_data_rate_mbps: actual_data_rate_mbps,
         actual_downlink_rate_mbps: actual_downlink_rate_mbps,
         actual_data_rate_mb_s: actual_data_rate_mb_s,
         actual_downlink_rate_mb_s: actual_downlink_rate_mb_s,
         delivered_rate_mbps: delivered_rate_mbps,
         received_rate_mbps: received_rate_mbps,
         delivered_rate_mb_s: delivered_rate_mb_s,
         received_rate_mb_s: received_rate_mb_s,
         actual_duration_s: actual_duration_s,
         actual_contact_duration_s: actual_contact_duration_s,
         contact_duration_s: contact_duration_s,
         link_margin_db: link_margin_db,
         snr_db: snr_db,
         eb_no_db: eb_no_db,
         bit_error_rate: bit_error_rate,
         packet_loss_rate: packet_loss_rate,
         frame_loss_rate: frame_loss_rate,
         carrier_lock: carrier_lock,
         symbol_lock: symbol_lock,
         link_quality_status: link_quality_status,
         pointing_mode: pointing_mode,
         pointing_target_id: pointing_target_id,
         boresight_axis: boresight_axis,
         off_nadir_angle_deg: off_nadir_angle_deg,
         slew_angle_deg: slew_angle_deg,
         slew_rate_deg_s: slew_rate_deg_s,
         pointing_error_deg: pointing_error_deg,
         pointing_status: pointing_status,
         pointing_model: pointing_model,
         pointing_source: pointing_source,
         pointing_confidence: pointing_confidence,
         attitude_mode: attitude_mode,
         attitude_target_id: attitude_target_id,
         roll_deg: roll_deg,
         pitch_deg: pitch_deg,
         yaw_deg: yaw_deg,
         attitude_error_deg: attitude_error_deg,
         attitude_status: attitude_status,
         attitude_model: attitude_model,
         attitude_source: attitude_source,
         attitude_confidence: attitude_confidence,
         thermal_zone_id: thermal_zone_id,
         temperature_c: temperature_c,
         planned_temperature_c: planned_temperature_c,
         actual_temperature_c: actual_temperature_c,
         min_operating_temperature_c: min_operating_temperature_c,
         max_operating_temperature_c: max_operating_temperature_c,
         thermal_margin_c: thermal_margin_c,
         thermal_status: thermal_status,
         thermal_model: thermal_model,
         thermal_source: thermal_source,
         thermal_confidence: thermal_confidence,
         eclipse_overlap_fraction: eclipse_overlap_fraction,
         eclipse_overlap_s: eclipse_overlap_s,
         lighting_condition: lighting_condition,
         lighting_condition_detail: lighting_condition_detail,
         lighting_condition_model: lighting_condition_model,
         lighting_detail_model: lighting_detail_model,
         lighting_confidence: lighting_confidence,
         command_window_id: command_window_id,
         command_window_type: command_window_type,
         command_window: command_window,
         dependencies: dependencies,
         dependency_activity_ids: dependency_activity_ids,
         dependency_timeline_ids: dependency_timeline_ids,
         exclusive_with_activity_ids: exclusive_with_activity_ids,
         exclusive_with_timeline_ids: exclusive_with_timeline_ids,
         exclusivity_group: exclusivity_group,
         source_window_id: source_window_id,
         source_window_type: source_window_type,
         source_window: source_window,
         cadence_import: cadence_import,
         provenance: provenance,
         direction: direction,
         ground_station_id: ground_station_id
       )}
    end
  end

  defp optional_ground_station_id(spec) do
    case optional_identifier(spec, "ground_station_id") do
      {:ok, nil} ->
        case optional_identifier(spec, "station_id") do
          {:ok, nil} ->
            optional_nested_identifier(spec, ["ground_station", "station"], [
              "ground_station_id",
              "station_id",
              "id"
            ])

          other ->
            other
        end

      other ->
        other
    end
  end

  defp optional_spacecraft_id(spec) do
    case optional_identifier(spec, "spacecraft_id") do
      {:ok, nil} ->
        case optional_identifier(spec, "satellite_id") do
          {:ok, nil} ->
            optional_nested_identifier(spec, ["spacecraft", "satellite"], [
              "spacecraft_id",
              "satellite_id",
              "id"
            ])

          other ->
            other
        end

      other ->
        other
    end
  end

  defp required_target_id(spec) do
    case optional_identifier(spec, "target_id") do
      {:ok, nil} ->
        case optional_nested_identifier(spec, ["target"], ["target_id", "id"]) do
          {:ok, nil} -> {:error, {:missing_field, "target_id"}}
          other -> other
        end

      other ->
        other
    end
  end

  defp optional_command_window_id(spec) do
    case optional_identifier(spec, "command_window_id") do
      {:ok, nil} ->
        case optional_identifier(spec, "command_window_ref") do
          {:ok, nil} ->
            optional_nested_identifier(spec, ["command_window"], [
              "id",
              "window_id",
              "command_window_id"
            ])

          other ->
            other
        end

      other ->
        other
    end
  end

  defp optional_command_window_type(spec) do
    case optional_identifier(spec, "command_window_type") do
      {:ok, nil} ->
        case optional_identifier(spec, "window_type") do
          {:ok, nil} ->
            case optional_identifier(spec, "command_window_kind") do
              {:ok, nil} ->
                optional_nested_identifier(spec, ["command_window"], [
                  "type",
                  "window_type",
                  "command_window_type"
                ])

              other ->
                other
            end

          other ->
            other
        end

      other ->
        other
    end
  end

  defp required_activity_ground_station_id(spec) do
    case optional_ground_station_id(spec) do
      {:ok, nil} -> {:error, {:missing_field, "ground_station_id"}}
      other -> other
    end
  end

  defp optional_nested_identifier(spec, object_keys, identity_keys) do
    Enum.reduce_while(object_keys, {:ok, nil}, fn object_key, {:ok, nil} ->
      case Map.fetch(spec, object_key) do
        {:ok, %{} = object} ->
          case first_nested_identifier(object, identity_keys) do
            {:ok, nil} -> {:cont, {:ok, nil}}
            other -> {:halt, other}
          end

        {:ok, nil} ->
          {:cont, {:ok, nil}}

        {:ok, _value} ->
          {:halt, {:error, {:invalid_field, object_key}}}

        :error ->
          {:cont, {:ok, nil}}
      end
    end)
  end

  defp first_nested_identifier(object, identity_keys) do
    Enum.reduce_while(identity_keys, {:ok, nil}, fn identity_key, {:ok, nil} ->
      case optional_identifier(object, identity_key) do
        {:ok, nil} -> {:cont, {:ok, nil}}
        other -> {:halt, other}
      end
    end)
  end

  defp optional_activity_overlap(%{"allow_overlap" => _value, "allow_overlap?" => _legacy_value}),
    do: {:error, {:invalid_field, "activities.allow_overlap"}}

  defp optional_activity_overlap(%{"allow_overlap?" => _value} = spec),
    do: optional_boolean(spec, "allow_overlap?", false)

  defp optional_activity_overlap(spec), do: optional_boolean(spec, "allow_overlap", false)

  defp optional_activity_status(spec) do
    optional_atom(spec, "status", :planned, activity_status_values())
  end

  defp optional_approval_status(spec) do
    optional_atom(spec, "approval_status", :not_required, activity_approval_status_values())
  end

  defp activity_type_values do
    Activity.capabilities().activity_types
    |> Enum.map(&Atom.to_string/1)
  end

  defp activity_status_values do
    Activity.capabilities().activity_statuses
    |> Enum.map(&Atom.to_string/1)
  end

  defp activity_approval_status_values do
    Activity.capabilities().approval_statuses
    |> Enum.map(&Atom.to_string/1)
  end

  defp required_contact_direction(spec) do
    case optional_contact_direction(spec) do
      {:ok, nil} -> {:error, {:missing_field, "activities.direction"}}
      result -> result
    end
  end

  defp optional_contact_direction(spec) do
    case Map.fetch(spec, "direction") do
      :error -> {:ok, nil}
      {:ok, nil} -> {:ok, nil}
      {:ok, value} -> contact_direction_value(value)
    end
  end

  defp contact_direction_value(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> contact_direction_value()
  end

  defp contact_direction_value(value) when is_binary(value) do
    normalized =
      value
      |> String.trim()
      |> String.downcase()
      |> String.replace(~r/[\s-]+/, "_")

    alias_map =
      Activity.capabilities().contact_direction_aliases
      |> Map.new(fn {alias, direction} -> {alias, direction} end)

    direction =
      Map.get_lazy(alias_map, normalized, fn ->
        Enum.find(Activity.capabilities().contact_directions, &(Atom.to_string(&1) == normalized))
      end)

    if is_nil(direction) do
      {:error, {:invalid_field, "activities.direction"}}
    else
      {:ok, direction}
    end
  end

  defp contact_direction_value(_value), do: {:error, {:invalid_field, "activities.direction"}}

  defp ensure_health_check_direction(opts) do
    case Keyword.get(opts, :direction) do
      nil -> :ok
      :health_check -> :ok
      _direction -> {:error, {:invalid_field, "activities.direction"}}
    end
  end

  defp activity_contact_direction_values do
    Activity.capabilities().contact_directions
    |> Enum.map(&Atom.to_string/1)
  end

  defp contact_direction_property do
    enum_property(activity_contact_direction_schema_values())
    |> Map.put(
      "description",
      "Canonical contact directions plus provider aliases accepted by the manifest loader."
    )
    |> Map.put("x-orbital-dynamics", %{
      "canonical_values" => activity_contact_direction_values(),
      "provider_aliases" =>
        Activity.capabilities().contact_direction_aliases
        |> Map.new(fn {alias, direction} -> {alias, Atom.to_string(direction)} end)
    })
  end

  defp activity_contact_direction_schema_values do
    (activity_contact_direction_values() ++
       (Activity.capabilities().contact_direction_aliases |> Map.keys()) ++
       [
         "Down Link",
         "Health Check",
         "Health Check Window",
         "Track-ing",
         "Up Link",
         "up-link"
       ])
    |> Enum.uniq()
  end

  defp epoch(source) do
    with {:ok, epoch} <- required_map(source, "epoch"),
         {:ok, seconds_since_j2000} <- required_number(epoch, "seconds_since_j2000"),
         {:ok, scale} <- optional_atom(epoch, "scale", :tdb, ["tdb", "tai", "utc"]) do
      {:ok, Epoch.new!(seconds_since_j2000, scale)}
    end
  end

  defp optional_epoch(source) do
    case Map.fetch(source, "epoch") do
      {:ok, _epoch} -> epoch(source)
      :error -> {:ok, nil}
    end
  end

  defp frame(source) do
    case Map.get(source, "frame", "earth_inertial_j2000") do
      "earth_inertial_j2000" -> {:ok, Frame.earth_inertial_j2000()}
      other -> {:error, {:unsupported_frame, other}}
    end
  end

  defp optional_frame(source) do
    case Map.fetch(source, "frame") do
      {:ok, _frame} -> frame(source)
      :error -> {:ok, nil}
    end
  end

  defp propagator(source) do
    case Map.get(source, "propagator", "two_body") do
      key when is_binary(key) ->
        case Map.fetch(@propagators, key) do
          {:ok, module} -> {:ok, module}
          :error -> {:error, {:unsupported_propagator, key}}
        end

      other ->
        {:error, {:unsupported_propagator, other}}
    end
  end

  defp propagator_opts(source) do
    source
    |> Map.get("propagator_opts", %{})
    |> known_keyword_map("propagator_opts", @propagator_opts)
  end

  defp outputs(source) do
    with {:ok, outputs} <- required_list(source, "outputs") do
      outputs
      |> Enum.reduce_while({:ok, []}, fn
        output, {:ok, acc} when is_binary(output) ->
          case Map.fetch(@outputs, output) do
            {:ok, output_atom} -> {:cont, {:ok, acc ++ [output_atom]}}
            :error -> {:halt, {:error, {:unsupported_output, output}}}
          end

        output, {:ok, _acc} ->
          {:halt, {:error, {:invalid_output, output}}}
      end)
    end
  end

  defp ground_stations(%{"ground_stations" => [], "candidate_refresh" => %{} = refresh}) do
    case candidate_refresh_mission_state(refresh) do
      {:ok, mission_state} when map_size(mission_state) > 0 ->
        mission_state
        |> mission_state_ground_station_specs()
        |> parse_ground_stations("candidate_refresh.mission_state.ground_stations")

      _mission_state ->
        {:ok, []}
    end
  end

  defp ground_stations(%{"ground_stations" => station_specs}) when is_list(station_specs) do
    parse_ground_stations(station_specs, "ground_stations")
  end

  defp ground_stations(%{"ground_stations" => _stations}),
    do: {:error, {:invalid_field, "ground_stations"}}

  defp ground_stations(%{"candidate_refresh" => %{"mission_state" => %{} = mission_state}}) do
    mission_state
    |> mission_state_ground_station_specs()
    |> parse_ground_stations("candidate_refresh.mission_state.ground_stations")
  end

  defp ground_stations(_source), do: {:ok, []}

  defp parse_ground_stations(station_specs, field) when is_list(station_specs) do
    station_specs
    |> Enum.reduce_while({:ok, []}, fn station_spec, {:ok, stations} ->
      case ground_station(station_spec, field) do
        {:ok, station} -> {:cont, {:ok, stations ++ [station]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp parse_ground_stations(:invalid, field), do: {:error, {:invalid_field, field}}

  defp ground_station(%{} = spec, _field) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, latitude_deg} <- required_number(spec, "latitude_deg"),
         {:ok, longitude_deg} <- required_number(spec, "longitude_deg"),
         {:ok, altitude_km} <- optional_number(spec, "altitude_km"),
         {:ok, minimum_elevation_deg} <- optional_number(spec, "minimum_elevation_deg") do
      {:ok,
       GroundStation.new!(
         id,
         latitude_deg,
         longitude_deg,
         compact_keyword(
           altitude_km: altitude_km,
           minimum_elevation_deg: minimum_elevation_deg
         )
       )}
    end
  end

  defp ground_station(_spec, field), do: {:error, {:invalid_field, field}}

  defp mission_state_ground_station_specs(%{} = mission_state) do
    case mission_state_ground_station_catalog_specs(mission_state) do
      :invalid ->
        :invalid

      catalog_specs ->
        case mission_state_ground_network_station_specs(mission_state) do
          :invalid when catalog_specs == [] -> :invalid
          :invalid -> catalog_specs
          network_specs -> unique_specs_by_id(catalog_specs ++ network_specs)
        end
    end
  end

  defp mission_state_ground_station_catalog_specs(%{"ground_stations" => station_specs})
       when is_list(station_specs),
       do: Enum.map(station_specs, &normalize_ground_station_spec/1)

  defp mission_state_ground_station_catalog_specs(%{"ground_stations" => _station_specs}),
    do: :invalid

  defp mission_state_ground_station_catalog_specs(_mission_state), do: []

  defp mission_state_ground_network_station_specs(%{"ground_network" => ground_network})
       when is_list(ground_network) do
    ground_network
    |> Enum.map(&normalize_ground_station_spec/1)
    |> Enum.filter(fn
      %{"latitude_deg" => latitude_deg, "longitude_deg" => longitude_deg}
      when is_number(latitude_deg) and is_number(longitude_deg) ->
        true

      _station ->
        false
    end)
    |> unique_specs_by_id()
  end

  defp mission_state_ground_network_station_specs(%{"ground_network" => _ground_network}),
    do: :invalid

  defp mission_state_ground_network_station_specs(_mission_state), do: []

  defp normalize_ground_station_spec(%{} = station) do
    station
    |> Map.put_new("id", Map.get(station, "ground_station_id") || Map.get(station, "station_id"))
    |> Map.put_new("minimum_elevation_deg", 5.0)
  end

  defp normalize_ground_station_spec(station), do: station

  defp candidate_refresh_run_input_sources(%{"candidate_refresh" => %{} = refresh} = source) do
    %{
      "accepted_planning_state" => candidate_refresh_accepted_planning_state_sources(refresh),
      "targets" => candidate_refresh_target_sources(refresh),
      "ground_stations" => candidate_refresh_ground_station_sources(source)
    }
  end

  defp candidate_refresh_accepted_planning_state_sources(refresh) do
    cond do
      Map.has_key?(refresh, "accepted_planning_state") ->
        ["candidate_refresh.accepted_planning_state"]

      Map.has_key?(refresh, "orbit_data") ->
        ["candidate_refresh.orbit_data"]

      is_map(get_in(refresh, ["mission_state", "accepted_planning_state"])) ->
        ["candidate_refresh.mission_state.accepted_planning_state"]

      Map.has_key?(Map.get(refresh, "mission_state", %{}), "spacecraft_states") ->
        ["candidate_refresh.mission_state.spacecraft_states"]

      true ->
        []
    end
  end

  defp candidate_refresh_target_sources(%{"targets" => target_specs} = refresh)
       when is_list(target_specs) do
    cond do
      target_specs != [] ->
        ["candidate_refresh.targets"]

      is_map(Map.get(refresh, "mission_state")) ->
        mission_state_target_sources(Map.get(refresh, "mission_state"))

      true ->
        ["candidate_refresh.targets"]
    end
  end

  defp candidate_refresh_target_sources(%{"mission_state" => %{} = mission_state}),
    do: mission_state_target_sources(mission_state)

  defp candidate_refresh_target_sources(_refresh), do: []

  defp mission_state_target_sources(%{} = mission_state) do
    []
    |> maybe_append_source(
      "candidate_refresh.mission_state.targets",
      non_empty_list?(Map.get(mission_state, "targets"))
    )
    |> maybe_append_source(
      "candidate_refresh.mission_state.objectives",
      mission_state_objective_targets_present?(mission_state)
    )
  end

  defp candidate_refresh_ground_station_sources(%{
         "ground_stations" => station_specs,
         "candidate_refresh" => %{} = refresh
       })
       when is_list(station_specs) do
    cond do
      station_specs != [] ->
        ["ground_stations"]

      is_map(Map.get(refresh, "mission_state")) ->
        mission_state_ground_station_sources(Map.get(refresh, "mission_state"))

      true ->
        ["ground_stations"]
    end
  end

  defp candidate_refresh_ground_station_sources(%{
         "candidate_refresh" => %{"mission_state" => %{} = mission_state}
       }),
       do: mission_state_ground_station_sources(mission_state)

  defp candidate_refresh_ground_station_sources(_source), do: []

  defp mission_state_ground_station_sources(%{} = mission_state) do
    []
    |> maybe_append_source(
      "candidate_refresh.mission_state.ground_stations",
      non_empty_list?(Map.get(mission_state, "ground_stations"))
    )
    |> maybe_append_source(
      "candidate_refresh.mission_state.ground_network",
      mission_state_ground_network_geometry_present?(mission_state)
    )
  end

  defp mission_state_objective_targets_present?(%{"objectives" => objectives})
       when is_list(objectives) do
    Enum.any?(objectives, fn objective ->
      objective
      |> objective_target_specs()
      |> Enum.any?(&target_geometry?/1)
    end)
  end

  defp mission_state_objective_targets_present?(_mission_state), do: false

  defp mission_state_ground_network_geometry_present?(%{"ground_network" => ground_network})
       when is_list(ground_network),
       do: Enum.any?(ground_network, &ground_station_geometry?/1)

  defp mission_state_ground_network_geometry_present?(_mission_state), do: false

  defp target_geometry?(%{"latitude_deg" => latitude_deg, "longitude_deg" => longitude_deg})
       when is_number(latitude_deg) and is_number(longitude_deg),
       do: true

  defp target_geometry?(_target), do: false

  defp ground_station_geometry?(%{
         "latitude_deg" => latitude_deg,
         "longitude_deg" => longitude_deg
       })
       when is_number(latitude_deg) and is_number(longitude_deg),
       do: true

  defp ground_station_geometry?(_station), do: false

  defp non_empty_list?(value), do: is_list(value) and value != []

  defp maybe_append_source(sources, source, true), do: sources ++ [source]
  defp maybe_append_source(sources, _source, false), do: sources

  defp targets(%{"campaign" => %{"targets" => target_specs}}) when is_list(target_specs) do
    parse_targets(target_specs, "campaign.targets")
  end

  defp targets(%{"campaign" => %{"targets" => _targets}}),
    do: {:error, {:invalid_field, "campaign.targets"}}

  defp targets(%{"candidate_refresh" => %{"targets" => []} = refresh}) do
    case candidate_refresh_mission_state(refresh) do
      {:ok, mission_state} when map_size(mission_state) > 0 ->
        mission_state
        |> mission_state_target_specs()
        |> parse_targets("candidate_refresh.mission_state.targets")

      _mission_state ->
        {:ok, []}
    end
  end

  defp targets(%{"candidate_refresh" => %{"targets" => target_specs}})
       when is_list(target_specs) do
    parse_targets(target_specs, "candidate_refresh.targets")
  end

  defp targets(%{"candidate_refresh" => %{"targets" => _targets}}),
    do: {:error, {:invalid_field, "candidate_refresh.targets"}}

  defp targets(%{"candidate_refresh" => %{"mission_state" => %{} = mission_state}}) do
    mission_state
    |> mission_state_target_specs()
    |> parse_targets("candidate_refresh.mission_state.targets")
  end

  defp targets(_source), do: {:ok, []}

  defp parse_targets(target_specs, field) when is_list(target_specs) do
    target_specs
    |> Enum.reduce_while({:ok, []}, fn target_spec, {:ok, targets} ->
      case target(target_spec, field) do
        {:ok, target} -> {:cont, {:ok, targets ++ [target]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp parse_targets(:invalid, field), do: {:error, {:invalid_field, field}}

  defp target(%{} = spec, _field) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, latitude_deg} <- required_number(spec, "latitude_deg"),
         {:ok, longitude_deg} <- required_number(spec, "longitude_deg"),
         {:ok, altitude_km} <- optional_number(spec, "altitude_km"),
         {:ok, minimum_elevation_deg} <- optional_number(spec, "minimum_elevation_deg"),
         {:ok, priority} <- optional_number(spec, "priority") do
      {:ok,
       Target.new!(
         id,
         latitude_deg,
         longitude_deg,
         compact_keyword(
           altitude_km: altitude_km,
           minimum_elevation_deg: minimum_elevation_deg,
           priority: priority
         )
       )}
    end
  end

  defp target(_spec, field), do: {:error, {:invalid_field, field}}

  defp mission_state_target_specs(%{} = mission_state) do
    case mission_state_target_catalog_specs(mission_state) do
      :invalid ->
        :invalid

      catalog_specs ->
        case mission_state_objective_target_specs(mission_state) do
          :invalid when catalog_specs == [] -> :invalid
          :invalid -> catalog_specs
          objective_specs -> unique_specs_by_id(catalog_specs ++ objective_specs)
        end
    end
  end

  defp mission_state_target_catalog_specs(%{"targets" => target_specs})
       when is_list(target_specs) do
    target_specs
    |> Enum.map(&normalize_target_spec/1)
    |> unique_specs_by_id()
  end

  defp mission_state_target_catalog_specs(%{"targets" => _target_specs}), do: :invalid

  defp mission_state_target_catalog_specs(_mission_state), do: []

  defp mission_state_objective_target_specs(%{"objectives" => objectives})
       when is_list(objectives) do
    objectives
    |> Enum.flat_map(&objective_target_specs/1)
    |> Enum.filter(fn
      %{"latitude_deg" => latitude_deg, "longitude_deg" => longitude_deg}
      when is_number(latitude_deg) and is_number(longitude_deg) ->
        true

      _target ->
        false
    end)
    |> unique_specs_by_id()
  end

  defp mission_state_objective_target_specs(%{"objectives" => _objectives}), do: :invalid

  defp mission_state_objective_target_specs(_mission_state), do: []

  defp normalize_target_spec(%{} = target) do
    target
    |> Map.put_new("id", Map.get(target, "target_id"))
    |> Map.put_new("minimum_elevation_deg", 10.0)
  end

  defp normalize_target_spec(target), do: target

  defp objective_target_specs(%{} = objective) do
    objective_specs =
      objective
      |> normalize_target_spec()
      |> List.wrap()

    nested_specs =
      objective_target_selector_aliases()
      |> Enum.flat_map(&target_spec_values(Map.get(objective, &1)))
      |> Enum.map(&normalize_target_spec/1)

    objective_specs ++ nested_specs
  end

  defp objective_target_specs(_objective), do: [:invalid]

  defp objective_target_selector_aliases do
    [
      "target",
      "target_ids",
      "targets",
      "target_specs",
      "required_target_ids",
      "required_targets",
      "committed_targets",
      "priority_targets",
      "uncovered_target_ids",
      "uncovered_targets",
      "unsatisfied_target_ids",
      "unsatisfied_targets",
      "missing_target_ids",
      "missing_targets",
      "missed_target",
      "missed_targets",
      "target_gap_ids",
      "target_gap_targets"
    ]
  end

  defp target_spec_values(values) when is_list(values),
    do: Enum.flat_map(values, &target_spec_values/1)

  defp target_spec_values(%{} = value), do: [value]
  defp target_spec_values(_value), do: []

  defp unique_specs_by_id(specs) do
    specs
    |> Enum.reduce({[], MapSet.new()}, fn
      %{"id" => id} = spec, {acc, ids} when id not in [nil, ""] ->
        if MapSet.member?(ids, id) do
          {acc, ids}
        else
          {acc ++ [spec], MapSet.put(ids, id)}
        end

      spec, {acc, ids} ->
        {acc ++ [spec], ids}
    end)
    |> elem(0)
  end

  defp ground_track_crossings(source) do
    source
    |> Map.get("ground_track_crossings", [])
    |> case do
      requests when is_list(requests) ->
        requests
        |> Enum.reduce_while({:ok, []}, fn request, {:ok, requests} ->
          case ground_track_crossing(request) do
            {:ok, request} -> {:cont, {:ok, requests ++ [request]}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      _requests ->
        {:error, {:invalid_field, "ground_track_crossings"}}
    end
  end

  defp ground_track_crossing(%{"crossing" => "latitude"} = spec) do
    with {:ok, latitude_deg} <- required_number(spec, "latitude_deg"),
         {:ok, frame} <- optional_atom(spec, "frame", :inertial, ["inertial", "body_fixed"]),
         {:ok, rotation_opts} <- ground_track_rotation_opts(spec),
         {:ok, id} <- optional_identifier(spec, "id") do
      request =
        %{
          crossing: :latitude,
          latitude_deg: latitude_deg * 1.0,
          frame: frame,
          id: id
        }
        |> Map.merge(rotation_opts)

      {:ok, request |> Enum.reject(fn {_key, value} -> is_nil(value) end) |> Map.new()}
    end
  end

  defp ground_track_crossing(%{"crossing" => "longitude"} = spec) do
    with {:ok, longitude_deg} <- required_number(spec, "longitude_deg"),
         {:ok, frame} <- optional_atom(spec, "frame", :inertial, ["inertial", "body_fixed"]),
         {:ok, rotation_opts} <- ground_track_rotation_opts(spec),
         {:ok, id} <- optional_identifier(spec, "id") do
      request =
        %{
          crossing: :longitude,
          longitude_deg: longitude_deg * 1.0,
          frame: frame,
          id: id
        }
        |> Map.merge(rotation_opts)

      {:ok, request |> Enum.reject(fn {_key, value} -> is_nil(value) end) |> Map.new()}
    end
  end

  defp ground_track_crossing(%{"crossing" => _crossing}),
    do: {:error, {:invalid_field, "ground_track_crossings.crossing"}}

  defp ground_track_crossing(_spec), do: {:error, {:invalid_field, "ground_track_crossings"}}

  defp ground_track_rotation_opts(spec) do
    with {:ok, rotation_rate_rad_s} <- optional_number(spec, "rotation_rate_rad_s"),
         {:ok, rotation_epoch_s} <- optional_number(spec, "rotation_epoch_s"),
         {:ok, rotation_angle_offset_rad} <- optional_number(spec, "rotation_angle_offset_rad"),
         {:ok, earth_rotation_provider} <- earth_rotation_provider(spec) do
      {:ok,
       %{}
       |> maybe_put(:rotation_rate_rad_s, rotation_rate_rad_s)
       |> maybe_put(:rotation_epoch_s, rotation_epoch_s)
       |> maybe_put(:rotation_angle_offset_rad, rotation_angle_offset_rad)
       |> maybe_put(:earth_rotation_provider, earth_rotation_provider)}
    end
  end

  defp earth_rotation_provider(spec) do
    case Map.fetch(spec, "earth_rotation_provider") do
      {:ok, "constant_earth_rotation"} ->
        {:ok, ConstantEarthRotationProvider}

      {:ok, "tabular_earth_orientation"} ->
        {:error, {:missing_field, "ground_track_crossings.earth_rotation_provider.samples"}}

      {:ok, %{"provider" => "constant_earth_rotation"}} ->
        {:ok, ConstantEarthRotationProvider}

      {:ok, %{"provider" => "tabular_earth_orientation"} = provider_spec} ->
        tabular_earth_rotation_provider(provider_spec)

      {:ok, _provider} ->
        {:error, {:invalid_field, "ground_track_crossings.earth_rotation_provider"}}

      :error ->
        {:ok, nil}
    end
  end

  defp tabular_earth_rotation_provider(provider_spec) do
    with {:ok, samples} <- earth_rotation_samples(provider_spec),
         {:ok, source} <- optional_string(provider_spec, "source"),
         {:ok, provider_id} <- optional_string(provider_spec, "provider_id") do
      opts =
        [samples: samples]
        |> maybe_keyword_put(:source, source)
        |> maybe_keyword_put(:provider_id, provider_id)

      {:ok, {TabularEarthOrientationProvider, opts}}
    end
  end

  defp earth_rotation_samples(provider_spec) do
    case Map.fetch(provider_spec, "samples") do
      {:ok, samples} when is_list(samples) and samples != [] ->
        samples
        |> Enum.reduce_while({:ok, []}, fn sample, {:ok, acc} ->
          case earth_rotation_sample(sample) do
            {:ok, sample} -> {:cont, {:ok, acc ++ [sample]}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      {:ok, _samples} ->
        {:error, {:invalid_field, "ground_track_crossings.earth_rotation_provider.samples"}}

      :error ->
        {:error, {:missing_field, "ground_track_crossings.earth_rotation_provider.samples"}}
    end
  end

  defp earth_rotation_sample(%{} = sample) do
    with {:ok, seconds_since_j2000} <-
           earth_rotation_sample_number(
             sample,
             [
               "seconds_since_j2000",
               "epoch_s"
             ],
             "seconds_since_j2000"
           ),
         {:ok, angle_rad} <-
           earth_rotation_sample_number(
             sample,
             [
               "earth_rotation_angle_rad",
               "rotation_angle_rad"
             ],
             "earth_rotation_angle_rad"
           ),
         {:ok, rate_rad_s} <-
           optional_earth_rotation_sample_number(sample, [
             "earth_rotation_rate_rad_s",
             "rotation_rate_rad_s"
           ]) do
      {:ok,
       %{
         seconds_since_j2000: seconds_since_j2000 * 1.0,
         earth_rotation_angle_rad: angle_rad * 1.0
       }
       |> maybe_put(:earth_rotation_rate_rad_s, rate_rad_s)}
    end
  end

  defp earth_rotation_sample(_sample),
    do: {:error, {:invalid_field, "ground_track_crossings.earth_rotation_provider.samples"}}

  defp earth_rotation_sample_number(sample, keys, field) do
    keys
    |> Enum.find_value(fn key ->
      case Map.get(sample, key) do
        value when is_number(value) -> {:ok, value}
        _value -> nil
      end
    end)
    |> case do
      {:ok, value} ->
        {:ok, value}

      nil ->
        {:error,
         {:missing_field, "ground_track_crossings.earth_rotation_provider.samples.#{field}"}}
    end
  end

  defp optional_earth_rotation_sample_number(sample, keys) do
    keys
    |> Enum.find_value(fn key ->
      case Map.get(sample, key) do
        value when is_number(value) -> {:ok, value * 1.0}
        _value -> nil
      end
    end)
    |> case do
      {:ok, value} -> {:ok, value}
      nil -> {:ok, nil}
    end
  end

  defp target_metadata(%{} = spec) do
    %{
      "id" => Map.get(spec, "id"),
      "latitude_deg" => Map.get(spec, "latitude_deg"),
      "longitude_deg" => Map.get(spec, "longitude_deg"),
      "altitude_km" => Map.get(spec, "altitude_km", 0.0),
      "minimum_elevation_deg" => Map.get(spec, "minimum_elevation_deg", 0.0),
      "priority" => Map.get(spec, "priority", 1.0)
    }
  end

  defp accepted_planning_state(refresh) do
    case Map.fetch(refresh, "accepted_planning_state") do
      {:ok, %{} = accepted_state} ->
        case Schema.validate_artifact(accepted_state,
               schema_contract: "accepted_planning_state.v1"
             ) do
          {:ok, _report} -> {:ok, accepted_state}
          {:error, report} -> {:error, {:invalid_accepted_planning_state, report}}
        end

      {:ok, _accepted_state} ->
        {:error, {:invalid_field, "candidate_refresh.accepted_planning_state"}}

      :error ->
        accepted_planning_state_from_fallback(refresh)
    end
  end

  defp accepted_planning_state_from_fallback(%{"orbit_data" => _orbit_data} = refresh),
    do: accepted_planning_state_from_orbit_data(refresh)

  defp accepted_planning_state_from_fallback(%{"mission_state" => %{} = mission_state}) do
    accepted_state =
      case Map.get(mission_state, "accepted_planning_state") do
        %{} = accepted_state ->
          accepted_state

        _accepted_state ->
          mission_state_accepted_planning_state(mission_state)
      end

    case accepted_state do
      %{} = accepted_state ->
        case Schema.validate_artifact(accepted_state,
               schema_contract: "accepted_planning_state.v1"
             ) do
          {:ok, _report} -> {:ok, accepted_state}
          {:error, report} -> {:error, {:invalid_accepted_planning_state, report}}
        end

      :invalid ->
        {:error, {:invalid_field, "candidate_refresh.mission_state.spacecraft_states"}}

      nil ->
        {:error, {:missing_field, "candidate_refresh.accepted_planning_state"}}
    end
  end

  defp accepted_planning_state_from_fallback(_refresh),
    do: {:error, {:missing_field, "candidate_refresh.accepted_planning_state"}}

  defp mission_state_accepted_planning_state(
         %{"spacecraft_states" => spacecraft_states} = mission_state
       )
       when is_list(spacecraft_states) do
    spacecraft_states =
      spacecraft_states
      |> Enum.map(&complete_mission_state_spacecraft_state/1)

    if spacecraft_states == [] or Enum.any?(spacecraft_states, &(&1 == :invalid)) do
      :invalid
    else
      %{
        "schema_version" => 1,
        "artifact_type" => "accepted_planning_state",
        "snapshot_id" => Map.get(mission_state, "snapshot_id", "mission-state"),
        "accepted_at" =>
          Map.get(mission_state, "accepted_at") ||
            Map.get(mission_state, "captured_at") ||
            "1970-01-01T00:00:00Z",
        "spacecraft_states" => spacecraft_states,
        "maneuver_execution_deltas" => [],
        "source" =>
          Map.get(mission_state, "source", %{"system" => "candidate_refresh.mission_state"}),
        "quality" => Map.get(mission_state, "quality", %{"level" => "planning_accepted"}),
        "provenance" =>
          Map.get(mission_state, "provenance", %{
            "created_by" => "OrbitalDynamics.Study.Manifest",
            "trust_boundary" => "candidate_refresh.mission_state"
          })
      }
    end
  end

  defp mission_state_accepted_planning_state(%{"spacecraft_states" => _spacecraft_states}),
    do: :invalid

  defp mission_state_accepted_planning_state(_mission_state), do: nil

  defp complete_mission_state_spacecraft_state(%{} = state) do
    state
    |> Map.put_new("spacecraft_id", Map.get(state, "scenario_id"))
    |> Map.put_new("scenario_id", Map.get(state, "spacecraft_id"))
    |> Map.put_new("source", %{"system" => "candidate_refresh.mission_state.spacecraft_states"})
    |> Map.put_new("quality", %{"level" => "planning_accepted"})
    |> Map.put_new("provenance", %{"trust_boundary" => "candidate_refresh.mission_state"})
  end

  defp complete_mission_state_spacecraft_state(_state), do: :invalid

  defp accepted_planning_state_from_orbit_data(%{"orbit_data" => orbit_data}) do
    case OrbitData.import_orbit_data(orbit_data) do
      {:ok, accepted_state} -> {:ok, accepted_state}
      {:error, reason} -> {:error, {:invalid_field, "candidate_refresh.orbit_data", reason}}
    end
  end

  defp accepted_planning_state_from_orbit_data(_refresh),
    do: {:error, {:missing_field, "candidate_refresh.accepted_planning_state"}}

  defp candidate_refresh_horizon(%{"remaining_horizon" => %{} = horizon}) do
    with {:ok, output_step_s} <- required_number(horizon, "output_step_s"),
         {:ok, normalized} <- candidate_refresh_horizon_bounds(horizon) do
      {:ok, Map.put(normalized, "output_step_s", output_step_s * 1.0)}
    end
  end

  defp candidate_refresh_horizon(%{"remaining_horizon" => _horizon}),
    do: {:error, {:invalid_field, "candidate_refresh.remaining_horizon"}}

  defp candidate_refresh_horizon(_refresh),
    do: {:error, {:missing_field, "candidate_refresh.remaining_horizon"}}

  defp candidate_refresh_horizon_bounds(%{"starts_at_s" => _start_s, "ends_at_s" => _end_s} = h) do
    with {:ok, start_s} <- required_number(h, "starts_at_s"),
         {:ok, end_s} <- required_number(h, "ends_at_s"),
         :ok <- validate_positive_duration(end_s - start_s, "candidate_refresh.remaining_horizon") do
      {:ok, %{"starts_at_s" => start_s * 1.0, "ends_at_s" => end_s * 1.0}}
    end
  end

  defp candidate_refresh_horizon_bounds(%{"duration_s" => _duration_s} = h) do
    with {:ok, duration_s} <- required_number(h, "duration_s"),
         :ok <- validate_positive_duration(duration_s, "candidate_refresh.remaining_horizon") do
      {:ok, %{"duration_s" => duration_s * 1.0}}
    end
  end

  defp candidate_refresh_horizon_bounds(_horizon),
    do: {:error, {:missing_field, "candidate_refresh.remaining_horizon.ends_at_s"}}

  defp candidate_refresh_horizon_end(_refresh, %{"ends_at_s" => end_s}), do: {:ok, end_s}

  defp candidate_refresh_horizon_end(refresh, %{"duration_s" => duration_s}) do
    with {:ok, accepted_state} <- accepted_planning_state(refresh),
         {:ok, current_epoch_s} <- candidate_refresh_current_epoch(refresh, accepted_state) do
      {:ok, current_epoch_s + duration_s}
    end
  end

  defp candidate_refresh_current_epoch(%{"current_epoch_s" => value}, _accepted_state)
       when is_integer(value) or is_float(value),
       do: {:ok, value * 1.0}

  defp candidate_refresh_current_epoch(
         %{"current_epoch" => %{"seconds_since_j2000" => value}},
         _accepted_state
       )
       when is_integer(value) or is_float(value),
       do: {:ok, value * 1.0}

  defp candidate_refresh_current_epoch(_refresh, %{"spacecraft_states" => [state | _]}) do
    case get_in(state, ["epoch", "seconds_since_j2000"]) do
      value when is_integer(value) or is_float(value) -> {:ok, value * 1.0}
      _value -> {:error, {:missing_field, "candidate_refresh.current_epoch_s"}}
    end
  end

  defp candidate_refresh_current_epoch(_refresh, _accepted_state),
    do: {:error, {:missing_field, "candidate_refresh.current_epoch_s"}}

  defp candidate_refresh_target_metadata(%{"targets" => target_specs})
       when is_list(target_specs) do
    {:ok, Enum.map(target_specs, &target_metadata/1)}
  end

  defp candidate_refresh_target_metadata(%{"targets" => _targets}),
    do: {:error, {:invalid_field, "candidate_refresh.targets"}}

  defp candidate_refresh_target_metadata(_refresh), do: {:ok, []}

  defp candidate_refresh_constraints(%{"constraints" => %{} = constraints}) do
    with {:ok, min_activity_duration_s} <-
           optional_number(constraints, "min_activity_duration_s"),
         {:ok, avoid_eclipse?} <- optional_boolean(constraints, "avoid_eclipse", true) do
      {:ok,
       %{
         "min_activity_duration_s" => min_activity_duration_s || 0.0,
         "avoid_eclipse" => avoid_eclipse?
       }}
    end
  end

  defp candidate_refresh_constraints(%{"constraints" => _constraints}),
    do: {:error, {:invalid_field, "candidate_refresh.constraints"}}

  defp candidate_refresh_constraints(_refresh),
    do: {:ok, %{"min_activity_duration_s" => 0.0, "avoid_eclipse" => true}}

  defp candidate_refresh_scoring_policy(%{"scoring_policy" => %{} = policy}) do
    with {:ok, target_value_weight} <- optional_number(policy, "target_value_weight"),
         {:ok, contact_value_weight} <- optional_number(policy, "contact_value_weight"),
         {:ok, eclipse_penalty_weight} <- optional_number(policy, "eclipse_penalty_weight"),
         {:ok, downlink_rate_mb_s} <- optional_number(policy, "downlink_rate_mb_s"),
         {:ok, downlink_completion_weight} <-
           optional_number(policy, "downlink_completion_weight"),
         {:ok, observation_objective_weight} <-
           optional_number(policy, "observation_objective_weight"),
         {:ok, collection_latency_observation_weight} <-
           optional_number(policy, "collection_latency_observation_weight") do
      {:ok,
       %{
         "target_value_weight" => target_value_weight || 1.0,
         "contact_value_weight" => contact_value_weight || 0.1,
         "eclipse_penalty_weight" => eclipse_penalty_weight || 1.0,
         "downlink_rate_mb_s" => downlink_rate_mb_s || 1.0,
         "downlink_completion_weight" => downlink_completion_weight,
         "observation_objective_weight" => observation_objective_weight,
         "collection_latency_observation_weight" => collection_latency_observation_weight
       }
       |> Enum.reject(fn {_key, value} -> is_nil(value) end)
       |> Map.new()}
    end
  end

  defp candidate_refresh_scoring_policy(%{"scoring_policy" => _policy}),
    do: {:error, {:invalid_field, "candidate_refresh.scoring_policy"}}

  defp candidate_refresh_scoring_policy(_refresh) do
    {:ok,
     %{
       "target_value_weight" => 1.0,
       "contact_value_weight" => 0.1,
       "eclipse_penalty_weight" => 1.0,
       "downlink_rate_mb_s" => 1.0
     }}
  end

  defp candidate_refresh_objectives(%{"objectives" => objectives}) when is_list(objectives),
    do: {:ok, objectives}

  defp candidate_refresh_objectives(%{"objectives" => _objectives}),
    do: {:error, {:invalid_field, "candidate_refresh.objectives"}}

  defp candidate_refresh_objectives(_refresh), do: {:ok, []}

  defp candidate_refresh_model_assumptions(%{"model_assumptions" => %{} = assumptions}),
    do: {:ok, assumptions}

  defp candidate_refresh_model_assumptions(%{"model_assumptions" => _assumptions}),
    do: {:error, {:invalid_field, "candidate_refresh.model_assumptions"}}

  defp candidate_refresh_model_assumptions(_refresh), do: {:ok, %{}}

  defp candidate_refresh_freshness_policy(refresh),
    do: optional_map(refresh, "freshness_policy")

  defp candidate_refresh_resource_filter_policy(refresh),
    do: optional_map(refresh, "resource_filter_policy")

  defp candidate_refresh_candidate_limit_policy(refresh),
    do: optional_map(refresh, "candidate_limit_policy")

  defp candidate_refresh_approval_policy(refresh),
    do: optional_map(refresh, "approval_policy")

  defp candidate_refresh_operational_feedback(refresh),
    do: optional_map(refresh, "operational_feedback")

  defp candidate_refresh_mission_state(%{"mission_state" => %{} = mission_state}),
    do: {:ok, mission_state}

  defp candidate_refresh_mission_state(%{"mission_state" => _mission_state}),
    do: {:error, {:invalid_field, "candidate_refresh.mission_state"}}

  defp candidate_refresh_mission_state(_refresh), do: {:ok, %{}}

  defp candidate_refresh_timeline_feedback_report(refresh, key),
    do: optional_map_or_nil(refresh, key)

  defp candidate_refresh_operational_timeline_report(refresh, key) do
    case Map.fetch(refresh, key) do
      {:ok, %{} = report} -> {:ok, report}
      {:ok, reports} when is_list(reports) -> {:ok, reports}
      {:ok, nil} -> {:ok, nil}
      {:ok, _value} -> {:error, {:invalid_field, key}}
      :error -> {:ok, nil}
    end
  end

  defp candidate_refresh_resource_summaries(%{"resource_summaries" => summaries})
       when is_list(summaries),
       do: {:ok, summaries}

  defp candidate_refresh_resource_summaries(%{"resource_summaries" => _summaries}),
    do: {:error, {:invalid_field, "candidate_refresh.resource_summaries"}}

  defp candidate_refresh_resource_summaries(_refresh), do: {:ok, []}

  defp candidate_refresh_ground_network(%{"ground_network" => ground_network})
       when is_list(ground_network),
       do: normalize_ground_network_entries(ground_network, "candidate_refresh.ground_network")

  defp candidate_refresh_ground_network(%{"ground_network" => _ground_network}),
    do: {:error, {:invalid_field, "candidate_refresh.ground_network"}}

  defp candidate_refresh_ground_network(_refresh), do: {:ok, []}

  defp candidate_refresh_prior_candidates(%{"prior_candidate_activities" => candidates})
       when is_list(candidates),
       do: {:ok, candidates}

  defp candidate_refresh_prior_candidates(%{"prior_candidate_activities" => _candidates}),
    do: {:error, {:invalid_field, "candidate_refresh.prior_candidate_activities"}}

  defp candidate_refresh_prior_candidates(_refresh), do: {:ok, []}

  defp validate_spacecraft_states([_ | _]), do: :ok

  defp validate_spacecraft_states(_states),
    do: {:error, {:missing_field, "candidate_refresh.accepted_planning_state.spacecraft_states"}}

  defp planning_state_vector(%{} = state) do
    with {:ok, state_vector} <- required_map(state, "state_vector"),
         {:ok, position_km} <- required_vector(state_vector, "position_km"),
         {:ok, velocity_km_s} <- required_vector(state_vector, "velocity_km_s"),
         {:ok, epoch} <- planning_state_epoch(state),
         {:ok, frame} <- frame(state) do
      {:ok, StateVector.new!(position_km, velocity_km_s, epoch, frame)}
    end
  end

  defp planning_state_epoch(%{"epoch" => %{} = epoch}) do
    with {:ok, seconds_since_j2000} <- required_number(epoch, "seconds_since_j2000"),
         {:ok, scale} <- planning_state_time_scale(epoch) do
      {:ok, Epoch.new!(seconds_since_j2000, scale)}
    end
  end

  defp planning_state_epoch(_state),
    do: {:error, {:missing_field, "candidate_refresh.spacecraft_states.epoch"}}

  defp planning_state_time_scale(%{"time_scale" => scale})
       when scale in ["tdb", "tai", "utc"],
       do: {:ok, String.to_atom(scale)}

  defp planning_state_time_scale(%{"scale" => scale}) when scale in ["tdb", "tai", "utc"],
    do: {:ok, String.to_atom(scale)}

  defp planning_state_time_scale(_epoch), do: {:ok, :tdb}

  defp spacecraft_dry_mass(%{"dry_mass_kg" => value}) when is_integer(value) or is_float(value),
    do: {:ok, value * 1.0}

  defp spacecraft_dry_mass(%{"spacecraft" => %{"dry_mass_kg" => value}})
       when is_integer(value) or is_float(value),
       do: {:ok, value * 1.0}

  defp spacecraft_dry_mass(_state), do: {:ok, 0.0}

  defp validate_positive_duration(duration_s, _field) when duration_s > 0.0, do: :ok
  defp validate_positive_duration(_duration_s, field), do: {:error, {:invalid_field, field}}

  defp sun_direction(source) do
    case Map.fetch(source, "sun_direction") do
      {:ok, value} -> vector(value, "sun_direction")
      :error -> {:ok, {1.0, 0.0, 0.0}}
    end
  end

  defp run_options(source) do
    case Map.get(source, "run_options", %{}) do
      %{} = run_options ->
        with {:ok, known_options} <- known_run_options(run_options),
             {:ok, task_supervisor_options} <- task_supervisor_options(run_options) do
          {:ok, known_options ++ task_supervisor_options}
        end

      _run_options ->
        {:error, {:invalid_field, "run_options"}}
    end
  end

  defp known_run_options(run_options) do
    run_options
    |> Map.drop(["task_supervisor_node", "task_supervisor_nodes"])
    |> known_keyword_map("run_options", @run_option_keys)
  end

  defp task_supervisor_options(%{
         "task_supervisor_node" => _node_name,
         "task_supervisor_nodes" => _node_names
       }),
       do: {:error, {:invalid_field, "run_options.task_supervisor"}}

  defp task_supervisor_options(%{"task_supervisor_nodes" => node_names})
       when is_list(node_names) and node_names != [] do
    node_names
    |> Enum.reduce_while({:ok, []}, fn node_name, {:ok, supervisors} ->
      case task_supervisor(node_name) do
        {:ok, supervisor} -> {:cont, {:ok, supervisors ++ [supervisor]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, supervisors} -> {:ok, [task_supervisors: supervisors]}
      {:error, reason} -> {:error, reason}
    end
  end

  defp task_supervisor_options(%{"task_supervisor_nodes" => _node_names}),
    do: {:error, {:invalid_field, "run_options.task_supervisor_nodes"}}

  defp task_supervisor_options(%{"task_supervisor_node" => node_name})
       when is_binary(node_name) and node_name != "" do
    with {:ok, supervisor} <- task_supervisor(node_name) do
      {:ok, [task_supervisor: supervisor]}
    end
  end

  defp task_supervisor_options(%{"task_supervisor_node" => _node_name}),
    do: {:error, {:invalid_field, "run_options.task_supervisor_node"}}

  defp task_supervisor_options(_run_options), do: {:ok, []}

  defp task_supervisor("local"), do: {:ok, OrbitalDynamics.ScenarioSupervisor}

  defp task_supervisor(node_name) when is_binary(node_name) and node_name != "" do
    {:ok, {OrbitalDynamics.ScenarioSupervisor, String.to_atom(node_name)}}
  end

  defp task_supervisor(_node_name),
    do: {:error, {:invalid_field, "run_options.task_supervisor_nodes"}}

  defp metadata(source) do
    case Map.get(source, "metadata", %{}) do
      metadata when is_map(metadata) -> {:ok, metadata}
      _metadata -> {:error, {:invalid_field, "metadata"}}
    end
  end

  defp seed_manifest(source) do
    case Map.get(source, "seed_manifest", %{}) do
      seed_manifest when is_map(seed_manifest) -> {:ok, seed_manifest}
      _seed_manifest -> {:error, {:invalid_field, "seed_manifest"}}
    end
  end

  defp known_keyword_map(map, field, known_keys) when is_map(map) do
    map
    |> Enum.reduce_while({:ok, []}, fn {key, value}, {:ok, acc} ->
      case Map.fetch(known_keys, key) do
        {:ok, atom_key} -> {:cont, {:ok, acc ++ [{atom_key, value}]}}
        :error -> {:halt, {:error, {:unsupported_option, field, key}}}
      end
    end)
  end

  defp known_keyword_map(_map, field, _known_keys), do: {:error, {:invalid_field, field}}

  defp required(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when value not in [nil, ""] -> {:ok, value}
      _missing_or_empty -> {:error, {:missing_field, key}}
    end
  end

  defp required_map(map, key) do
    case Map.fetch(map, key) do
      {:ok, %{} = value} -> {:ok, value}
      {:ok, _value} -> {:error, {:invalid_field, key}}
      :error -> {:error, {:missing_field, key}}
    end
  end

  defp required_list(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_list(value) and value != [] -> {:ok, value}
      {:ok, _value} -> {:error, {:invalid_field, key}}
      :error -> {:error, {:missing_field, key}}
    end
  end

  defp optional_list(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_list(value) -> {:ok, value}
      {:ok, _value} -> {:error, {:invalid_field, key}}
      :error -> {:ok, []}
    end
  end

  defp required_number(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_integer(value) or is_float(value) -> {:ok, value}
      {:ok, _value} -> {:error, {:invalid_field, key}}
      :error -> {:error, {:missing_field, key}}
    end
  end

  defp required_number_list(map, key) do
    case Map.fetch(map, key) do
      {:ok, values} when is_list(values) and values != [] ->
        if Enum.all?(values, &(is_integer(&1) or is_float(&1))) do
          {:ok, values}
        else
          {:error, {:invalid_field, key}}
        end

      {:ok, _value} ->
        {:error, {:invalid_field, key}}

      :error ->
        {:error, {:missing_field, key}}
    end
  end

  defp optional_number(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_integer(value) or is_float(value) -> {:ok, value}
      {:ok, nil} -> {:ok, nil}
      {:ok, _value} -> {:error, {:invalid_field, key}}
      :error -> {:ok, nil}
    end
  end

  defp optional_string(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_binary(value) and value != "" -> {:ok, value}
      {:ok, nil} -> {:ok, nil}
      {:ok, _value} -> {:error, {:invalid_field, key}}
      :error -> {:ok, nil}
    end
  end

  defp optional_number_or_identifier(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_integer(value) or is_float(value) -> {:ok, value}
      {:ok, value} when is_binary(value) and value != "" -> {:ok, value}
      {:ok, nil} -> {:ok, nil}
      {:ok, value} when is_atom(value) -> {:ok, value}
      {:ok, _value} -> {:error, {:invalid_field, key}}
      :error -> {:ok, nil}
    end
  end

  defp optional_boolean(map, key, default) do
    case Map.fetch(map, key) do
      {:ok, value} when is_boolean(value) -> {:ok, value}
      {:ok, _value} -> {:error, {:invalid_field, key}}
      :error -> {:ok, default}
    end
  end

  defp optional_boolean_or_nil(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_boolean(value) -> {:ok, value}
      {:ok, nil} -> {:ok, nil}
      {:ok, _value} -> {:error, {:invalid_field, key}}
      :error -> {:ok, nil}
    end
  end

  defp optional_string(map, key, default) do
    case Map.fetch(map, key) do
      {:ok, value} when is_binary(value) and value != "" -> {:ok, value}
      {:ok, _value} -> {:error, {:invalid_field, key}}
      :error -> {:ok, default}
    end
  end

  defp optional_station_availability(map, key) do
    allowed = ["available", "unavailable", "reduced_capacity", "maintenance", "reserved"]

    case Map.fetch(map, key) do
      {:ok, value} when is_binary(value) ->
        if value in allowed do
          {:ok, value}
        else
          {:error, {:invalid_field, key}}
        end

      {:ok, value} when is_number(value) and value >= 0.0 and value <= 1.0 ->
        {:ok, value}

      {:ok, nil} ->
        {:ok, nil}

      {:ok, _value} ->
        {:error, {:invalid_field, key}}

      :error ->
        {:ok, nil}
    end
  end

  defp validate_optional_interval(_field, nil, nil), do: :ok
  defp validate_optional_interval(_field, nil, end_s) when is_number(end_s), do: :ok
  defp validate_optional_interval(_field, start_s, nil) when is_number(start_s), do: :ok

  defp validate_optional_interval(field, start_s, end_s)
       when is_number(start_s) and is_number(end_s) do
    if end_s > start_s, do: :ok, else: {:error, {:invalid_field, field}}
  end

  defp validate_optional_interval(field, _start_s, _end_s), do: {:error, {:invalid_field, field}}

  defp optional_identifier(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_binary(value) and value != "" -> {:ok, value}
      {:ok, nil} -> {:ok, nil}
      {:ok, value} when is_atom(value) -> {:ok, value}
      {:ok, _value} -> {:error, {:invalid_field, key}}
      :error -> {:ok, nil}
    end
  end

  defp optional_identifier_list(map, key) do
    case Map.fetch(map, key) do
      {:ok, values} when is_list(values) ->
        if Enum.all?(values, &(is_binary(&1) and &1 != "")) do
          {:ok, values}
        else
          {:error, {:invalid_field, key}}
        end

      {:ok, _value} ->
        {:error, {:invalid_field, key}}

      :error ->
        {:ok, []}
    end
  end

  defp optional_identifier_list_or_nil(map, key) do
    case optional_identifier_list(map, key) do
      {:ok, []} ->
        if Map.has_key?(map, key), do: {:ok, []}, else: {:ok, nil}

      other ->
        other
    end
  end

  defp optional_map(map, key) do
    case Map.fetch(map, key) do
      {:ok, %{} = value} -> {:ok, value}
      {:ok, nil} -> {:ok, %{}}
      {:ok, _value} -> {:error, {:invalid_field, key}}
      :error -> {:ok, %{}}
    end
  end

  defp optional_map_or_nil(map, key) do
    case Map.fetch(map, key) do
      {:ok, %{} = value} -> {:ok, value}
      {:ok, nil} -> {:ok, nil}
      {:ok, _value} -> {:error, {:invalid_field, key}}
      :error -> {:ok, nil}
    end
  end

  defp required_positive_integer(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_integer(value) and value > 0 -> {:ok, value}
      {:ok, _value} -> {:error, {:invalid_field, key}}
      :error -> {:error, {:missing_field, key}}
    end
  end

  defp required_non_negative_integer(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_integer(value) and value >= 0 -> {:ok, value}
      {:ok, _value} -> {:error, {:invalid_field, key}}
      :error -> {:error, {:missing_field, key}}
    end
  end

  defp optional_positive_integer(map, key, default) do
    case Map.fetch(map, key) do
      {:ok, value} when is_integer(value) and value > 0 -> {:ok, value}
      {:ok, _value} -> {:error, {:invalid_field, key}}
      :error -> {:ok, default}
    end
  end

  defp required_vector(map, key) do
    with {:ok, value} <- required(map, key), do: vector(value, key)
  end

  defp vector([x, y, z], _key)
       when (is_integer(x) or is_float(x)) and (is_integer(y) or is_float(y)) and
              (is_integer(z) or is_float(z)) do
    {:ok, {x * 1.0, y * 1.0, z * 1.0}}
  end

  defp vector(_value, key), do: {:error, {:invalid_field, key}}

  defp validate_non_negative_vector({x, y, z}, _key) when x >= 0.0 and y >= 0.0 and z >= 0.0,
    do: :ok

  defp validate_non_negative_vector(_vector, key), do: {:error, {:invalid_field, key}}

  defp required_vector_list(map, key) do
    case Map.fetch(map, key) do
      {:ok, values} when is_list(values) and values != [] ->
        values
        |> Enum.reduce_while({:ok, []}, fn value, {:ok, vectors} ->
          case vector(value, key) do
            {:ok, vector} -> {:cont, {:ok, vectors ++ [vector]}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      {:ok, _value} ->
        {:error, {:invalid_field, key}}

      :error ->
        {:error, {:missing_field, key}}
    end
  end

  defp required_atom(map, key) do
    with {:ok, value} <- required(map, key) do
      if is_binary(value), do: {:ok, String.to_atom(value)}, else: {:error, {:invalid_field, key}}
    end
  end

  defp optional_atom(map, key, default, allowed) do
    case Map.fetch(map, key) do
      {:ok, value} when is_binary(value) ->
        if value in allowed do
          {:ok, String.to_atom(value)}
        else
          {:error, {:invalid_field, key}}
        end

      {:ok, _value} ->
        {:error, {:invalid_field, key}}

      :error ->
        {:ok, default}
    end
  end

  defp compact_keyword(keyword) do
    Enum.reject(keyword, fn {_key, value} -> is_nil(value) end)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_keyword_put(keyword, _key, nil), do: keyword
  defp maybe_keyword_put(keyword, key, value), do: Keyword.put(keyword, key, value)

  defp maybe_put_non_empty(map, _key, []), do: map
  defp maybe_put_non_empty(map, key, value), do: maybe_put(map, key, value)
end
