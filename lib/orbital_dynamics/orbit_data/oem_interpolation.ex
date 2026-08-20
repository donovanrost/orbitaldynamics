defmodule OrbitalDynamics.OrbitData.OemInterpolation do
  @moduledoc false

  alias OrbitalDynamics.Epoch

  @j2000 ~U[2000-01-01 12:00:00Z]
  @method "cubic_hermite_position_velocity"
  @method_version "1"
  @supported_frames ~w(EME2000 J2000 ICRF)
  @supported_time_scales ~w(utc tai tdb)
  @covariance_component_keys ~w(
    CX_X CY_X CY_Y CZ_X CZ_Y CZ_Z
    CX_DOT_X CX_DOT_Y CX_DOT_Z CX_DOT_X_DOT
    CY_DOT_X CY_DOT_Y CY_DOT_Z CY_DOT_X_DOT CY_DOT_Y_DOT
    CZ_DOT_X CZ_DOT_Y CZ_DOT_Z CZ_DOT_X_DOT CZ_DOT_Y_DOT CZ_DOT_Z_DOT
  )
  @assumptions [
    "OEM samples are Cartesian kilometers and kilometers per second",
    "endpoint velocities are position derivatives in the declared frame",
    "the requested strategy epoch uses the OEM time scale without conversion"
  ]
  @known_limits [
    "single object and single OEM metadata segment only",
    "Earth-centered EME2000, J2000, or ICRF inertial states only",
    "no extrapolation beyond the source sample bracket or declared coverage",
    "no frame or time-scale conversion",
    "source covariance is preserved as metadata and is not interpolated or propagated",
    "SHA-256 content identity does not authenticate the source authority"
  ]

  def capabilities do
    %{
      mode: :explicit_opt_in,
      request_option: :interpolate,
      strategy_epoch_option: :strategy_epoch,
      source_revision_option: :source_revision,
      optional_max_bracket_option: :max_bracket_s,
      interpolation_method: @method,
      interpolation_method_version: @method_version,
      exact_epoch_policy: :exact_sample,
      coverage_policy: :declared_oem_coverage_and_source_bracket,
      extrapolation: :rejected,
      covariance: :source_metadata_preserved_not_interpolated,
      assumptions: @assumptions,
      known_limits: @known_limits
    }
  end

  def requested?(opts) when is_list(opts) do
    not is_nil(Keyword.get(opts, :strategy_epoch)) or
      Keyword.get(opts, :interpolate) not in [nil, false] or
      not is_nil(Keyword.get(opts, :interpolation))
  end

  def select(kvn, %{fields: fields, samples: source_samples, covariance_fields: covariance}, opts)
      when is_binary(kvn) and is_list(opts) do
    with :ok <- interpolation_request(opts),
         :ok <- reject_sample_selector(opts),
         {:ok, source_revision} <- source_revision(opts),
         {:ok, strategy_epoch} <- strategy_epoch(opts),
         {:ok, source_metadata} <- source_metadata(fields),
         :ok <- matching_time_scale(strategy_epoch, source_metadata),
         {:ok, coverage} <- coverage(fields),
         {:ok, samples} <- samples(source_samples),
         :ok <- validate_samples_against_coverage(samples, coverage),
         :ok <- validate_requested_coverage(strategy_epoch, coverage),
         {:ok, max_bracket_s} <- max_bracket_s(opts),
         {:ok, selection} <- select_bracket(samples, strategy_epoch, max_bracket_s),
         {:ok, result} <- interpolation_result(selection, strategy_epoch),
         evidence <-
           evidence(
             kvn,
             fields,
             source_revision,
             strategy_epoch,
             source_metadata,
             coverage,
             selection,
             result,
             covariance,
             max_bracket_s
           ) do
      {:ok,
       %{
         sample:
           result
           |> Map.put("epoch", selected_epoch_label(selection, strategy_epoch))
           |> Map.put("seconds_since_j2000", strategy_epoch.seconds_since_j2000),
         sample_index: selection.exact_index,
         evidence: evidence
       }}
    end
  end

  defp interpolation_request(opts) do
    value = Keyword.get(opts, :interpolate, Keyword.get(opts, :interpolation, true))

    if value in [true, :cubic_hermite, "cubic_hermite", @method],
      do: :ok,
      else: {:error, {:invalid_option, :interpolate}}
  end

  defp reject_sample_selector(opts) do
    if not is_nil(Keyword.get(opts, :sample)) or
         not is_nil(Keyword.get(opts, :sample_index)),
       do: {:error, {:conflicting_option, :sample}},
       else: :ok
  end

  defp source_revision(opts) do
    case Keyword.get(opts, :source_revision) do
      value when is_binary(value) ->
        if String.valid?(value) and String.trim(value) != "",
          do: {:ok, value},
          else: {:error, {:invalid_option, :source_revision}}

      nil ->
        {:error, {:missing_option, :source_revision}}

      _value ->
        {:error, {:invalid_option, :source_revision}}
    end
  end

  defp strategy_epoch(opts) do
    case Keyword.get(opts, :strategy_epoch) do
      %Epoch{scale: scale, seconds_since_j2000: seconds} ->
        normalize_strategy_epoch(seconds, scale)

      %{} = epoch ->
        seconds = Map.get(epoch, "seconds_since_j2000", Map.get(epoch, :seconds_since_j2000))
        scale = Map.get(epoch, "time_scale", Map.get(epoch, :time_scale, Map.get(epoch, :scale)))
        normalize_strategy_epoch(seconds, scale)

      nil ->
        {:error, {:missing_option, :strategy_epoch}}

      _epoch ->
        {:error, {:invalid_option, :strategy_epoch}}
    end
  end

  defp normalize_strategy_epoch(seconds, scale)
       when is_number(seconds) and scale in [:utc, :tai, :tdb] do
    normalize_strategy_epoch(seconds, Atom.to_string(scale))
  end

  defp normalize_strategy_epoch(seconds, scale) when is_number(seconds) and is_binary(scale) do
    normalize_strategy_epoch(seconds, String.downcase(scale), :normalized)
  end

  defp normalize_strategy_epoch(_seconds, _scale),
    do: {:error, {:invalid_option, :strategy_epoch}}

  defp normalize_strategy_epoch(seconds, scale, :normalized)
       when scale in @supported_time_scales do
    if finite_number?(seconds) do
      {:ok, %{seconds_since_j2000: seconds * 1.0, time_scale: scale}}
    else
      {:error, {:invalid_option, :strategy_epoch}}
    end
  end

  defp normalize_strategy_epoch(_seconds, _scale, :normalized),
    do: {:error, {:invalid_option, :strategy_epoch}}

  defp source_metadata(fields) do
    object_name = value(fields, "OBJECT_NAME")
    object_id = value(fields, "OBJECT_ID")
    center_name = fields |> value("CENTER_NAME", "EARTH") |> String.upcase()
    ref_frame = fields |> value("REF_FRAME", "EME2000") |> String.upcase()
    time_scale = fields |> value("TIME_SYSTEM", "UTC") |> String.downcase()

    cond do
      blank?(object_name) and blank?(object_id) ->
        {:error, {:missing_field, "OBJECT_NAME"}}

      center_name != "EARTH" ->
        {:error, {:unsupported_field, "CENTER_NAME"}}

      ref_frame not in @supported_frames ->
        {:error, {:invalid_field, "REF_FRAME"}}

      time_scale not in @supported_time_scales ->
        {:error, {:invalid_field, "TIME_SYSTEM"}}

      true ->
        {:ok,
         %{
           "object_name" => object_name,
           "object_id" => object_id,
           "center_name" => center_name,
           "ref_frame" => ref_frame,
           "time_system" => String.upcase(time_scale)
         }
         |> compact_map()}
    end
  end

  defp matching_time_scale(strategy_epoch, source_metadata) do
    source_scale = source_metadata["time_system"] |> String.downcase()

    if strategy_epoch.time_scale == source_scale,
      do: :ok,
      else: {:error, {:time_scale_mismatch, strategy_epoch.time_scale, source_scale}}
  end

  defp coverage(fields) do
    with {:ok, declared_start} <- required_epoch(fields, "START_TIME"),
         {:ok, declared_stop} <- required_epoch(fields, "STOP_TIME"),
         {:ok, usable_start} <- optional_epoch(fields, "USEABLE_START_TIME"),
         {:ok, usable_stop} <- optional_epoch(fields, "USEABLE_STOP_TIME"),
         :ok <- paired_usable_coverage(usable_start, usable_stop),
         :ok <- ordered_coverage(declared_start, declared_stop, "START_TIME"),
         effective_start = usable_start || declared_start,
         effective_stop = usable_stop || declared_stop,
         :ok <- ordered_coverage(effective_start, effective_stop, "USEABLE_START_TIME"),
         :ok <-
           usable_within_declared(effective_start, effective_stop, declared_start, declared_stop) do
      {:ok,
       %{
         "declared_start_epoch" => declared_start.label,
         "declared_stop_epoch" => declared_stop.label,
         "declared_starts_at_s" => declared_start.seconds_since_j2000,
         "declared_ends_at_s" => declared_stop.seconds_since_j2000,
         "effective_start_epoch" => effective_start.label,
         "effective_stop_epoch" => effective_stop.label,
         "effective_starts_at_s" => effective_start.seconds_since_j2000,
         "effective_ends_at_s" => effective_stop.seconds_since_j2000,
         "policy" =>
           if(usable_start,
             do: "OEM_USEABLE_START_TIME_USEABLE_STOP_TIME",
             else: "OEM_START_TIME_STOP_TIME"
           )
       }}
    end
  end

  defp paired_usable_coverage(nil, nil), do: :ok
  defp paired_usable_coverage(%{}, %{}), do: :ok
  defp paired_usable_coverage(nil, %{}), do: {:error, {:missing_field, "USEABLE_START_TIME"}}
  defp paired_usable_coverage(%{}, nil), do: {:error, {:missing_field, "USEABLE_STOP_TIME"}}

  defp ordered_coverage(start_epoch, stop_epoch, field) do
    if start_epoch.seconds_since_j2000 <= stop_epoch.seconds_since_j2000,
      do: :ok,
      else: {:error, {:invalid_field, field}}
  end

  defp usable_within_declared(usable_start, usable_stop, declared_start, declared_stop) do
    if usable_start.seconds_since_j2000 >= declared_start.seconds_since_j2000 and
         usable_stop.seconds_since_j2000 <= declared_stop.seconds_since_j2000 do
      :ok
    else
      {:error, {:invalid_field, "OEM_COVERAGE"}}
    end
  end

  defp required_epoch(fields, key) do
    case value(fields, key) do
      nil -> {:error, {:missing_field, key}}
      label -> parse_epoch(label, key)
    end
  end

  defp optional_epoch(fields, key) do
    case value(fields, key) do
      nil -> {:ok, nil}
      label -> parse_epoch(label, key)
    end
  end

  defp samples(source_samples) when is_list(source_samples) and length(source_samples) >= 2 do
    source_samples
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {sample, index}, {:ok, acc} ->
      case normalize_sample(sample, index) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, normalized} ->
        normalized = Enum.reverse(normalized)

        if strictly_increasing?(normalized),
          do: {:ok, normalized},
          else: {:error, {:invalid_field, "ephemeris_data.epochs_not_strictly_increasing"}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp samples(_source_samples), do: {:error, {:missing_field, "ephemeris_data.bracket"}}

  defp normalize_sample(%{} = sample, index) do
    with {:ok, epoch} <- parse_epoch(Map.get(sample, "epoch"), "ephemeris_data.epoch"),
         :ok <- finite_vector(Map.get(sample, "position_km"), "position_km"),
         :ok <- finite_vector(Map.get(sample, "velocity_km_s"), "velocity_km_s") do
      {:ok,
       %{
         index: index,
         epoch: epoch.label,
         seconds_since_j2000: epoch.seconds_since_j2000,
         position_km: Map.fetch!(sample, "position_km"),
         velocity_km_s: Map.fetch!(sample, "velocity_km_s")
       }}
    end
  end

  defp normalize_sample(_sample, _index),
    do: {:error, {:invalid_field, "ephemeris_data"}}

  defp finite_vector([x, y, z], _field) do
    if Enum.all?([x, y, z], &finite_number?/1),
      do: :ok,
      else: {:error, {:invalid_field, "ephemeris_data.nonfinite_value"}}
  end

  defp finite_vector(_vector, field), do: {:error, {:invalid_field, field}}

  defp strictly_increasing?(samples) do
    samples
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.all?(fn [left, right] ->
      left.seconds_since_j2000 < right.seconds_since_j2000
    end)
  end

  defp validate_samples_against_coverage(samples, coverage) do
    if Enum.all?(samples, fn sample ->
         sample.seconds_since_j2000 >= coverage["declared_starts_at_s"] and
           sample.seconds_since_j2000 <= coverage["declared_ends_at_s"]
       end) do
      :ok
    else
      {:error, {:invalid_field, "ephemeris_data.outside_declared_coverage"}}
    end
  end

  defp validate_requested_coverage(strategy_epoch, coverage) do
    requested = strategy_epoch.seconds_since_j2000

    if requested >= coverage["effective_starts_at_s"] and
         requested <= coverage["effective_ends_at_s"] do
      :ok
    else
      {:error, {:out_of_coverage, :strategy_epoch}}
    end
  end

  defp max_bracket_s(opts) do
    case Keyword.get(opts, :max_bracket_s) do
      nil ->
        {:ok, nil}

      value when is_number(value) ->
        if finite_number?(value) and value > 0,
          do: {:ok, value * 1.0},
          else: {:error, {:invalid_option, :max_bracket_s}}

      _value ->
        {:error, {:invalid_option, :max_bracket_s}}
    end
  end

  defp select_bracket(samples, strategy_epoch, max_bracket_s) do
    requested = strategy_epoch.seconds_since_j2000

    case Enum.find(samples, &(&1.seconds_since_j2000 == requested)) do
      nil -> select_bounding_bracket(samples, requested, max_bracket_s)
      exact -> {:ok, %{before: exact, after: exact, exact_index: exact.index, fraction: 0.0}}
    end
  end

  defp select_bounding_bracket(samples, requested, max_bracket_s) do
    case Enum.find(Enum.chunk_every(samples, 2, 1, :discard), fn [before, after_sample] ->
           before.seconds_since_j2000 < requested and
             requested < after_sample.seconds_since_j2000
         end) do
      [before, after_sample] ->
        span_s = after_sample.seconds_since_j2000 - before.seconds_since_j2000

        if is_number(max_bracket_s) and span_s > max_bracket_s do
          {:error, {:max_bracket_exceeded, span_s, max_bracket_s}}
        else
          {:ok,
           %{
             before: before,
             after: after_sample,
             exact_index: nil,
             fraction: (requested - before.seconds_since_j2000) / span_s
           }}
        end

      nil ->
        {:error, {:out_of_coverage, :ephemeris_sample_bracket}}
    end
  end

  defp interpolate(%{exact_index: index, before: sample}, _strategy_epoch)
       when is_integer(index) do
    %{"position_km" => sample.position_km, "velocity_km_s" => sample.velocity_km_s}
  end

  defp interpolate(selection, strategy_epoch) do
    before = selection.before
    after_sample = selection.after
    span_s = after_sample.seconds_since_j2000 - before.seconds_since_j2000
    fraction = selection.fraction

    %{
      "position_km" =>
        hermite_position(
          before.position_km,
          before.velocity_km_s,
          after_sample.position_km,
          after_sample.velocity_km_s,
          span_s,
          fraction
        ),
      "velocity_km_s" =>
        hermite_velocity(
          before.position_km,
          before.velocity_km_s,
          after_sample.position_km,
          after_sample.velocity_km_s,
          span_s,
          fraction
        ),
      "seconds_since_j2000" => strategy_epoch.seconds_since_j2000
    }
  end

  defp interpolation_result(selection, strategy_epoch) do
    result = interpolate(selection, strategy_epoch)

    with :ok <- finite_vector(result["position_km"], "position_km"),
         :ok <- finite_vector(result["velocity_km_s"], "velocity_km_s") do
      {:ok, result}
    else
      {:error, _reason} -> {:error, {:invalid_field, "ephemeris_data.nonfinite_result"}}
    end
  rescue
    ArithmeticError -> {:error, {:invalid_field, "ephemeris_data.nonfinite_result"}}
  end

  defp hermite_position(p0, v0, p1, v1, span_s, t) do
    h00 = 2 * t * t * t - 3 * t * t + 1
    h10 = t * t * t - 2 * t * t + t
    h01 = -2 * t * t * t + 3 * t * t
    h11 = t * t * t - t * t

    zip4(p0, v0, p1, v1, fn p0_axis, v0_axis, p1_axis, v1_axis ->
      h00 * p0_axis + h10 * span_s * v0_axis + h01 * p1_axis +
        h11 * span_s * v1_axis
    end)
  end

  defp hermite_velocity(p0, v0, p1, v1, span_s, t) do
    dh00 = (6 * t * t - 6 * t) / span_s
    dh10 = 3 * t * t - 4 * t + 1
    dh01 = (-6 * t * t + 6 * t) / span_s
    dh11 = 3 * t * t - 2 * t

    zip4(p0, v0, p1, v1, fn p0_axis, v0_axis, p1_axis, v1_axis ->
      dh00 * p0_axis + dh10 * v0_axis + dh01 * p1_axis + dh11 * v1_axis
    end)
  end

  defp zip4(left_a, left_b, right_a, right_b, fun) do
    left_a
    |> Enum.zip(left_b)
    |> Enum.zip(Enum.zip(right_a, right_b))
    |> Enum.map(fn {{a, b}, {c, d}} -> fun.(a, b, c, d) end)
  end

  defp evidence(
         kvn,
         fields,
         source_revision,
         strategy_epoch,
         source_metadata,
         coverage,
         selection,
         result,
         covariance,
         max_bracket_s
       ) do
    source_sha256 = digest(kvn)
    object_identity = source_metadata["object_id"] || source_metadata["object_name"]
    source_id = "ccsds_oem:#{object_identity}:sha256:#{source_sha256}"

    interpolation =
      %{
        "method" => if(selection.exact_index, do: "exact_sample", else: @method),
        "version" => @method_version,
        "selection" => if(selection.exact_index, do: "exact_sample", else: "interpolated"),
        "fraction" => selection.fraction,
        "source_declared_method" => value(fields, "INTERPOLATION"),
        "source_declared_degree" => value(fields, "INTERPOLATION_DEGREE")
      }
      |> compact_map()

    core = %{
      "evidence_type" => "ccsds_oem_strategy_epoch_interpolation",
      "schema_version" => 1,
      "requested_epoch" => epoch_evidence(strategy_epoch),
      "interpolation" => interpolation,
      "source_bracket" =>
        %{
          "before" => sample_evidence(selection.before),
          "after" => sample_evidence(selection.after),
          "span_s" => selection.after.seconds_since_j2000 - selection.before.seconds_since_j2000,
          "max_bracket_s" => max_bracket_s,
          "bounded" => true
        }
        |> compact_map(),
      "coverage" => coverage,
      "object" => Map.take(source_metadata, ["object_name", "object_id", "center_name"]),
      "frame" => %{
        "source_ref_frame" => source_metadata["ref_frame"],
        "accepted_state_frame" => "earth_inertial_j2000",
        "conversion_applied" => false
      },
      "time" => %{
        "source_time_system" => source_metadata["time_system"],
        "requested_time_scale" => strategy_epoch.time_scale,
        "conversion_applied" => false
      },
      "source" => %{
        "source_id" => source_id,
        "source_revision" => source_revision,
        "originator" => value(fields, "ORIGINATOR", "unknown"),
        "content_identity" => %{
          "algorithm" => "sha256",
          "sha256" => source_sha256,
          "scope" => "exact_ccsds_oem_kvn_bytes"
        }
      },
      "covariance" => covariance_evidence(covariance),
      "result" => %{
        "position_km" => result["position_km"],
        "velocity_km_s" => result["velocity_km_s"]
      },
      "assumptions" => @assumptions,
      "known_limits" => @known_limits
    }

    Map.put(core, "id", "oem_interpolation:sha256:#{digest(core)}")
  end

  defp covariance_evidence(covariance) when map_size(covariance) == 0 do
    %{"present" => false, "matrix_present" => false, "status" => "not_present"}
  end

  defp covariance_evidence(covariance) do
    matrix_present = Enum.any?(@covariance_component_keys, &Map.has_key?(covariance, &1))

    %{
      "present" => true,
      "matrix_present" => matrix_present,
      "epoch" => value(covariance, "EPOCH"),
      "reference_frame" => value(covariance, "COV_REF_FRAME"),
      "status" =>
        if(matrix_present,
          do: "source_matrix_preserved_not_interpolated",
          else: "source_covariance_metadata_preserved_not_interpolated"
        )
    }
    |> compact_map()
  end

  defp sample_evidence(sample) do
    %{
      "sample_index" => sample.index,
      "epoch" => sample.epoch,
      "seconds_since_j2000" => sample.seconds_since_j2000,
      "position_km" => sample.position_km,
      "velocity_km_s" => sample.velocity_km_s
    }
  end

  defp epoch_evidence(epoch) do
    %{
      "seconds_since_j2000" => epoch.seconds_since_j2000,
      "time_scale" => epoch.time_scale
    }
  end

  defp strategy_epoch_label(epoch) do
    "#{epoch.seconds_since_j2000} seconds_since_j2000 #{String.upcase(epoch.time_scale)}"
  end

  defp selected_epoch_label(%{exact_index: index, before: sample}, _epoch)
       when is_integer(index),
       do: sample.epoch

  defp selected_epoch_label(_selection, epoch), do: strategy_epoch_label(epoch)

  defp parse_epoch(value, field) when is_binary(value) do
    label = first_token(value)

    case parse_datetime(label) do
      {:ok, datetime} ->
        {:ok,
         %{
           label: label,
           seconds_since_j2000: DateTime.diff(datetime, @j2000, :microsecond) / 1_000_000.0
         }}

      :error ->
        {:error, {:invalid_field, field}}
    end
  end

  defp parse_epoch(_value, field), do: {:error, {:invalid_field, field}}

  defp parse_datetime(value) do
    if String.ends_with?(value, "Z") do
      case DateTime.from_iso8601(value) do
        {:ok, datetime, _offset} -> {:ok, datetime}
        {:error, _reason} -> :error
      end
    else
      case NaiveDateTime.from_iso8601(value) do
        {:ok, naive} ->
          case DateTime.from_naive(naive, "Etc/UTC") do
            {:ok, datetime} -> {:ok, datetime}
            {:error, _reason} -> :error
          end

        {:error, _reason} ->
          :error
      end
    end
  end

  defp value(fields, key, default \\ nil) do
    case Map.get(fields, key) do
      value when is_binary(value) and value != "" -> first_token(value)
      _value -> default
    end
  end

  defp first_token(value) do
    value
    |> String.trim()
    |> String.split(~r/\s+/, parts: 2)
    |> hd()
  end

  defp blank?(value), do: not (is_binary(value) and value != "")

  defp finite_number?(value) when is_number(value) do
    value == value and abs(value) <= 1.7976931348623157e308
  end

  defp finite_number?(_value), do: false

  defp digest(value) when is_binary(value) do
    value
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp digest(value) do
    value
    |> :erlang.term_to_binary([:deterministic])
    |> digest()
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> value in [nil, ""] end)
    |> Map.new()
  end
end
