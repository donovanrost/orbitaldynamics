defmodule OrbitalDynamics.OrbitData.Covariance do
  @moduledoc false

  @j2000 ~U[2000-01-01 12:00:00Z]
  @finite_max_abs_component 1.0e30
  @numerical_support_relative_tolerance 1.0e-12
  @numerical_support_check_name "normalized_principal_minors_nonnegative_relative_symmetric_6x6_bounded_float"
  @source_identity_limit "SHA-256 content identity records exact bytes only; " <>
                           "it does not authenticate source authority"
  @supported_ref_frames ~w(EME2000 J2000 ICRF)
  @canonical_units ~w(km**2 km**2/s km**2/s**2)

  @components [
    {0, 0, "CX_X"},
    {1, 0, "CY_X"},
    {1, 1, "CY_Y"},
    {2, 0, "CZ_X"},
    {2, 1, "CZ_Y"},
    {2, 2, "CZ_Z"},
    {3, 0, "CX_DOT_X"},
    {3, 1, "CX_DOT_Y"},
    {3, 2, "CX_DOT_Z"},
    {3, 3, "CX_DOT_X_DOT"},
    {4, 0, "CY_DOT_X"},
    {4, 1, "CY_DOT_Y"},
    {4, 2, "CY_DOT_Z"},
    {4, 3, "CY_DOT_X_DOT"},
    {4, 4, "CY_DOT_Y_DOT"},
    {5, 0, "CZ_DOT_X"},
    {5, 1, "CZ_DOT_Y"},
    {5, 2, "CZ_DOT_Z"},
    {5, 3, "CZ_DOT_X_DOT"},
    {5, 4, "CZ_DOT_Y_DOT"},
    {5, 5, "CZ_DOT_Z_DOT"}
  ]
  @component_keys Enum.map(@components, &elem(&1, 2))
  @component_order ~w(
    x_km
    y_km
    z_km
    x_dot_km_s
    y_dot_km_s
    z_dot_km_s
  )
  @allowed_oem_keys ["EPOCH", "COV_REF_FRAME" | @component_keys]
  @covariance_partial_fields ~w(
    covariance_reference_frame
    covariance_epoch
    covariance_component_order
    covariance_matrix_6x6
    covariance_unit_contract
    covariance_frame_binding
    covariance_epoch_binding
    covariance_numerical_check
    covariance_propagation_status
    covariance
  )

  def components, do: @components
  def component_keys, do: @component_keys
  def component_order, do: @component_order
  def numerical_support_check_name, do: @numerical_support_check_name
  def source_identity_limit, do: @source_identity_limit

  def capabilities do
    %{
      component_order: @component_order,
      matrix_shape: "exact_symmetric_6x6_from_ccsds_lower_triangular_components",
      required_component_count: length(@component_keys),
      finite_max_abs_component: @finite_max_abs_component,
      unit_contract: %{
        declaration_policy:
          "all_implicit_ccsds_units_or_all_explicit_exact_canonical_ccsds_units",
        position_position: "km**2",
        position_velocity: "km**2/s",
        velocity_velocity: "km**2/s**2"
      },
      frame_binding:
        "covariance_reference_frame_must_match_accepted_state_source_frame_without_conversion",
      epoch_binding:
        "covariance_epoch_must_equal_accepted_state_epoch_under_declared_time_system",
      numerical_support_check: @numerical_support_check_name,
      metadata_only: true,
      propagation: :not_supported,
      interpolation: :not_supported,
      authentication: :not_provided_by_byte_identity
    }
  end

  def from_export_state(format, %{} = state, %{} = context) when format in [:opm, :oem] do
    quality = map_value(Map.get(state, "quality", %{}))
    metadata = map_value(Map.get(state, "metadata", %{}))
    opts = Map.get(context, "opts", [])

    case Map.get(quality, "covariance_matrix_6x6") do
      nil ->
        export_absent_evidence(quality, metadata, opts)

      matrix ->
        export_matrix_evidence(format, matrix, quality, metadata, opts, context)
    end
  end

  def source_identity(format, fields, bytes) when is_binary(format) and is_binary(bytes) do
    sha256 = :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
    object_identity = value(fields, "OBJECT_ID") || value(fields, "OBJECT_NAME") || "unknown"

    %{
      "source_id" => "#{format}:#{object_identity}:sha256:#{sha256}",
      "content_identity" => %{
        "algorithm" => "sha256",
        "sha256" => sha256,
        "scope" => "exact_#{format}_kvn_bytes",
        "authority" => "not_authenticated",
        "known_limits" => [@source_identity_limit]
      }
    }
  end

  def present?(fields) when is_map(fields),
    do: Enum.any?(@component_keys, &Map.has_key?(fields, &1))

  def from_opm_fields(fields, context) when is_map(fields) and is_map(context) do
    with :ok <- reject_unsupported_opm_covariance_keys(fields),
         {:ok, matrix_evidence} <- matrix_evidence(fields) do
      build_evidence(:opm, fields, context, matrix_evidence)
    end
  end

  def from_oem_fields(fields, context) when is_map(fields) and is_map(context) do
    with :ok <- reject_unsupported_oem_covariance_keys(fields),
         {:ok, matrix_evidence} <- matrix_evidence(fields) do
      build_evidence(:oem, fields, context, matrix_evidence)
    end
  end

  def quality_fields(evidence, status_override \\ nil)

  def quality_fields(nil, status_override) when is_binary(status_override),
    do: %{"covariance_status" => status_override}

  def quality_fields(nil, _status_override), do: %{}

  def quality_fields(%{} = evidence, status_override) do
    evidence_fields(evidence, status_override)
  end

  def metadata_fields(evidence, status_override \\ nil)

  def metadata_fields(nil, status_override) when is_binary(status_override),
    do: %{"covariance_status" => status_override}

  def metadata_fields(nil, _status_override), do: %{}

  def metadata_fields(%{} = evidence, status_override) do
    evidence_fields(evidence, status_override)
    |> Map.delete("covariance_matrix_6x6")
  end

  def provenance_fields(evidence, status_override \\ nil),
    do: metadata_fields(evidence, status_override)

  defp build_evidence(:opm, fields, _context, nil) do
    if Map.has_key?(fields, "COV_REF_FRAME"),
      do: {:error, {:missing_field, "covariance_matrix.CX_X"}},
      else: {:ok, nil}
  end

  defp build_evidence(:oem, fields, _context, nil) do
    if map_size(fields) == 0,
      do: {:ok, nil},
      else: {:error, {:missing_field, "covariance_matrix.CX_X"}}
  end

  defp build_evidence(format, fields, context, %{} = matrix_evidence) do
    with {:ok, frame_binding} <- frame_binding(fields, context),
         {:ok, epoch_binding} <- epoch_binding(format, fields, context) do
      {:ok,
       %{
         reference_frame: field_value(fields, "COV_REF_FRAME"),
         epoch: epoch_binding["covariance_epoch"],
         time_scale: Map.get(context, "time_scale"),
         matrix: Map.fetch!(matrix_evidence, :matrix),
         matrix_present: true,
         component_order: @component_order,
         unit_contract: Map.fetch!(matrix_evidence, :unit_contract),
         frame_binding: frame_binding,
         epoch_binding: epoch_binding,
         numerical_check: Map.fetch!(matrix_evidence, :numerical_check),
         propagation_status: "metadata_only_not_propagated",
         status: "matrix_imported_metadata_only_no_propagation"
       }}
    end
  end

  defp matrix_evidence(fields) do
    if present?(fields) do
      with :ok <- require_complete_components(fields),
           {:ok, parsed_components} <- parsed_components(fields),
           {:ok, unit_contract} <- unit_contract(parsed_components),
           {:ok, matrix} <- matrix_from_components(parsed_components),
           :ok <- exact_symmetric_6x6(matrix),
           {:ok, numerical_check} <- numerical_support_check(matrix) do
        {:ok,
         %{
           matrix: matrix,
           unit_contract: unit_contract,
           numerical_check: numerical_check
         }}
      end
    else
      {:ok, nil}
    end
  end

  defp require_complete_components(fields) do
    case Enum.reject(@component_keys, &Map.has_key?(fields, &1)) do
      [] -> :ok
      [missing | _rest] -> {:error, {:missing_field, "covariance_matrix.#{missing}"}}
    end
  end

  defp parsed_components(fields) do
    Enum.reduce_while(@components, {:ok, []}, fn {row, column, key}, {:ok, acc} ->
      case parse_component(Map.fetch!(fields, key), row, column, key) do
        {:ok, parsed} -> {:cont, {:ok, [parsed | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, parsed} -> {:ok, Enum.reverse(parsed)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_component(raw, row, column, key) when is_binary(raw) do
    case Regex.run(
           ~r/^\s*([+-]?(?:(?:\d+(?:\.\d*)?)|(?:\.\d+))(?:[eE][+-]?\d+)?)\s*(?:\[([^\]]+)\])?\s*$/,
           raw,
           capture: :all_but_first
         ) do
      [number_text] ->
        parsed_component(number_text, nil, row, column, key)

      [number_text, unit_text] ->
        parsed_component(number_text, unit_text, row, column, key)

      _captures ->
        {:error, {:invalid_field, "covariance_matrix.#{key}"}}
    end
  end

  defp parse_component(_raw, _row, _column, key),
    do: {:error, {:invalid_field, "covariance_matrix.#{key}"}}

  defp parsed_component(number_text, unit_text, row, column, key) do
    with {:ok, number} <- finite_float(number_text, key),
         {:ok, unit} <- normalize_unit(unit_text, key) do
      {:ok,
       %{
         row: row,
         column: column,
         key: key,
         value: number,
         unit: unit,
         expected_unit: expected_unit(row, column)
       }}
    end
  end

  defp finite_float(number_text, key) do
    case Float.parse(number_text) do
      {number, ""} when number == number and abs(number) <= @finite_max_abs_component ->
        {:ok, number}

      _result ->
        {:error, {:invalid_field, "covariance_matrix.#{key}"}}
    end
  end

  defp normalize_unit(nil, _key), do: {:ok, nil}
  defp normalize_unit("", _key), do: {:ok, nil}

  defp normalize_unit(unit_text, key) do
    if unit_text in @canonical_units do
      {:ok, unit_text}
    else
      {:error, {:invalid_field, "covariance_units.#{key}"}}
    end
  end

  defp unit_contract(components) when is_list(components) do
    cond do
      Enum.all?(components, &is_nil(&1.unit)) ->
        {:ok, unit_contract("implicit_ccsds_units")}

      Enum.any?(components, &is_nil(&1.unit)) ->
        {:error, {:invalid_field, "covariance_units"}}

      true ->
        case Enum.find(components, &(&1.unit != &1.expected_unit)) do
          nil -> {:ok, unit_contract("explicit_ccsds_units")}
          component -> {:error, {:invalid_field, "covariance_units.#{component.key}"}}
        end
    end
  end

  defp unit_contract(declaration) do
    %{
      "declaration" => declaration,
      "component_order" => @component_order,
      "position_position" => "km**2",
      "position_velocity" => "km**2/s",
      "velocity_velocity" => "km**2/s**2",
      "mixed_unit_declarations" => false
    }
  end

  defp expected_unit(row, column) do
    cond do
      row < 3 and column < 3 -> "km**2"
      row >= 3 and column >= 3 -> "km**2/s**2"
      true -> "km**2/s"
    end
  end

  defp matrix_from_components(components) do
    matrix = List.duplicate(List.duplicate(0.0, 6), 6)

    matrix =
      Enum.reduce(components, matrix, fn %{row: row, column: column, value: value}, acc ->
        acc
        |> put_matrix_value(row, column, value)
        |> put_matrix_value(column, row, value)
      end)

    {:ok, matrix}
  end

  defp put_matrix_value(matrix, row, column, value) do
    List.update_at(matrix, row, fn row_values ->
      List.replace_at(row_values, column, value)
    end)
  end

  defp exact_symmetric_6x6(matrix) do
    cond do
      length(matrix) != 6 ->
        {:error, {:invalid_field, "covariance_matrix.symmetric_6x6"}}

      not Enum.all?(matrix, &(is_list(&1) and length(&1) == 6)) ->
        {:error, {:invalid_field, "covariance_matrix.symmetric_6x6"}}

      not Enum.all?(matrix, fn row -> Enum.all?(row, &is_number/1) end) ->
        {:error, {:invalid_field, "covariance_matrix.symmetric_6x6"}}

      not symmetric?(matrix) ->
        {:error, {:invalid_field, "covariance_matrix.symmetric_6x6"}}

      true ->
        :ok
    end
  end

  defp symmetric?(matrix) do
    Enum.all?(0..5, fn row ->
      Enum.all?(0..5, fn column ->
        matrix_value(matrix, row, column) == matrix_value(matrix, column, row)
      end)
    end)
  end

  defp numerical_support_check(matrix) do
    if Enum.all?(principal_index_sets(), &supported_principal_minor?(matrix, &1)) do
      {:ok,
       %{
         "name" => @numerical_support_check_name,
         "status" => "passed",
         "matrix_shape" => "symmetric_6x6",
         "finite_max_abs_component" => @finite_max_abs_component,
         "relative_tolerance" => @numerical_support_relative_tolerance,
         "claim" =>
           "deterministic_normalized_principal_minor_support_check_not_external_validation"
       }}
    else
      {:error, {:invalid_field, "covariance_matrix.numerical_support"}}
    end
  end

  defp supported_principal_minor?(matrix, indices) do
    minor = minor_matrix(matrix, indices)

    case scale_invariant_minor(minor) do
      :zero -> true
      normalized -> determinant(normalized) >= -@numerical_support_relative_tolerance
    end
  end

  defp principal_index_sets do
    indexes(1, 6)
    |> Enum.flat_map(fn size -> combinations([0, 1, 2, 3, 4, 5], size) end)
  end

  defp combinations(_items, 0), do: [[]]
  defp combinations([], _count), do: []

  defp combinations([head | tail], count) do
    Enum.map(combinations(tail, count - 1), &[head | &1]) ++ combinations(tail, count)
  end

  defp minor_matrix(matrix, indices) do
    Enum.map(indices, fn row ->
      Enum.map(indices, fn column -> matrix_value(matrix, row, column) end)
    end)
  end

  defp scale_invariant_minor(minor) do
    max_abs = minor |> List.flatten() |> Enum.map(&abs/1) |> Enum.max()

    if max_abs == 0.0 do
      :zero
    else
      Enum.map(minor, fn row ->
        Enum.map(row, fn value -> value / max_abs end)
      end)
    end
  end

  defp determinant(matrix) do
    size = length(matrix)

    indexes(0, size - 1)
    |> Enum.reduce_while({1.0, matrix}, fn index, {determinant, working} ->
      pivot_row =
        index
        |> indexes(size - 1)
        |> Enum.max_by(fn row -> abs(matrix_value(working, row, index)) end)

      pivot_value = matrix_value(working, pivot_row, index)

      if pivot_value == 0.0 do
        {:halt, 0.0}
      else
        {working, swap_sign} = maybe_swap_rows(working, index, pivot_row)
        pivot_value = matrix_value(working, index, index)
        working = eliminate_below(working, index, pivot_value, size)
        {:cont, {determinant * swap_sign * pivot_value, working}}
      end
    end)
    |> case do
      {determinant, _working} -> determinant
      determinant when is_number(determinant) -> determinant
    end
  end

  defp maybe_swap_rows(matrix, row, row), do: {matrix, 1.0}

  defp maybe_swap_rows(matrix, left, right) do
    left_row = Enum.at(matrix, left)
    right_row = Enum.at(matrix, right)

    matrix =
      matrix
      |> List.replace_at(left, right_row)
      |> List.replace_at(right, left_row)

    {matrix, -1.0}
  end

  defp eliminate_below(matrix, index, pivot_value, size) do
    indexes(index + 1, size - 1)
    |> Enum.reduce(matrix, fn row, working ->
      row_values = Enum.at(working, row)
      pivot_row = Enum.at(working, index)
      factor = Enum.at(row_values, index) / pivot_value

      updated_row =
        row_values
        |> Enum.with_index()
        |> Enum.map(fn {value, column} ->
          if column < index do
            0.0
          else
            value - factor * Enum.at(pivot_row, column)
          end
        end)

      List.replace_at(working, row, updated_row)
    end)
  end

  defp frame_binding(fields, context) do
    with {:ok, covariance_frame} <- required_value(fields, "COV_REF_FRAME") do
      source_frame = context |> Map.fetch!("source_ref_frame") |> exact_text()
      accepted_state_frame = Map.fetch!(context, "accepted_state_frame")

      cond do
        accepted_state_frame != "earth_inertial_j2000" ->
          {:error, {:invalid_field, "covariance_frame_binding"}}

        covariance_frame not in @supported_ref_frames ->
          {:error, {:invalid_field, "covariance_frame_binding"}}

        source_frame not in @supported_ref_frames ->
          {:error, {:invalid_field, "covariance_frame_binding"}}

        covariance_frame != source_frame ->
          {:error, {:invalid_field, "covariance_frame_binding"}}

        true ->
          {:ok,
           %{
             "source_ref_frame" => source_frame,
             "covariance_ref_frame" => covariance_frame,
             "accepted_state_frame" => accepted_state_frame,
             "conversion_applied" => false
           }}
      end
    end
  end

  defp epoch_binding(:opm, _fields, context) do
    state_epoch = Map.fetch!(context, "state_epoch")

    with {:ok, state_epoch_s} <- epoch_seconds(state_epoch) do
      if state_epoch_s == Map.fetch!(context, "state_epoch_s") do
        {:ok,
         %{
           "state_epoch" => state_epoch,
           "covariance_epoch" => state_epoch,
           "time_scale" => Map.fetch!(context, "time_scale"),
           "matched" => true
         }}
      else
        {:error, {:invalid_field, "covariance_epoch_binding"}}
      end
    end
  end

  defp epoch_binding(:oem, fields, context) do
    with {:ok, covariance_epoch} <- required_value(fields, "EPOCH"),
         {:ok, covariance_epoch_s} <- epoch_seconds(covariance_epoch) do
      state_epoch_s = Map.fetch!(context, "state_epoch_s")
      state_epoch = Map.fetch!(context, "state_epoch")

      if covariance_epoch == state_epoch and covariance_epoch_s == state_epoch_s do
        {:ok,
         %{
           "state_epoch" => state_epoch,
           "covariance_epoch" => covariance_epoch,
           "seconds_since_j2000" => covariance_epoch_s,
           "time_scale" => Map.fetch!(context, "time_scale"),
           "matched" => true
         }}
      else
        {:error, {:invalid_field, "covariance_epoch_binding"}}
      end
    end
  end

  defp epoch_seconds(epoch) do
    with {:ok, datetime} <- parse_datetime(epoch) do
      {:ok, DateTime.diff(datetime, @j2000, :microsecond) / 1_000_000.0}
    end
  end

  defp parse_datetime(epoch) do
    epoch = exact_text(epoch)

    cond do
      String.ends_with?(epoch, "Z") ->
        case DateTime.from_iso8601(epoch) do
          {:ok, datetime, _offset} -> {:ok, datetime}
          {:error, _reason} -> {:error, {:invalid_field, "covariance_epoch_binding"}}
        end

      true ->
        case NaiveDateTime.from_iso8601(epoch) do
          {:ok, naive} -> DateTime.from_naive(naive, "Etc/UTC")
          {:error, _reason} -> {:error, {:invalid_field, "covariance_epoch_binding"}}
        end
    end
  end

  defp reject_unsupported_oem_covariance_keys(fields) do
    case Enum.find(Map.keys(fields), &(&1 not in @allowed_oem_keys)) do
      nil -> :ok
      key -> {:error, {:unsupported_field, "covariance_matrix.#{key}"}}
    end
  end

  defp reject_unsupported_opm_covariance_keys(fields) do
    case Enum.find(Map.keys(fields), &unsupported_opm_covariance_key?/1) do
      nil -> :ok
      key -> {:error, {:unsupported_field, "covariance_matrix.#{key}"}}
    end
  end

  defp unsupported_opm_covariance_key?(key) do
    String.match?(key, ~r/^C(?:X|Y|Z)(?:_DOT)?_(?:X|Y|Z)(?:_DOT)?$/) and
      key not in @component_keys
  end

  defp required_value(fields, key) do
    case field_value(fields, key) do
      nil -> {:error, {:missing_field, "covariance_matrix.#{key}"}}
      value -> {:ok, value}
    end
  end

  defp evidence_fields(evidence, status_override) do
    %{
      "covariance_reference_frame" => Map.get(evidence, :reference_frame),
      "covariance_epoch" => Map.get(evidence, :epoch),
      "covariance_status" => status_override || Map.fetch!(evidence, :status),
      "covariance_component_order" => Map.get(evidence, :component_order),
      "covariance_matrix_6x6" => Map.get(evidence, :matrix),
      "covariance_unit_contract" => Map.get(evidence, :unit_contract),
      "covariance_frame_binding" => Map.get(evidence, :frame_binding),
      "covariance_epoch_binding" => Map.get(evidence, :epoch_binding),
      "covariance_numerical_check" => Map.get(evidence, :numerical_check),
      "covariance_propagation_status" => Map.get(evidence, :propagation_status)
    }
    |> compact_map()
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> value in [nil, ""] end)
    |> Map.new()
  end

  defp value(fields, key, default \\ nil)

  defp value(%{} = fields, key, default) do
    case Map.get(fields, key) do
      value when is_binary(value) and value != "" -> value(value)
      _value -> default
    end
  end

  defp value(value, _key, _default) when is_binary(value), do: value(value)

  defp value(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.split(~r/\s+/, parts: 2)
    |> hd()
  end

  defp field_value(fields, key, default \\ nil)

  defp field_value(%{} = fields, key, default) do
    case Map.get(fields, key) do
      value when is_binary(value) -> exact_text(value, default)
      _value -> default
    end
  end

  defp exact_text(value, default \\ nil)

  defp exact_text(value, default) when is_binary(value) do
    case String.trim(value) do
      "" -> default
      trimmed -> trimmed
    end
  end

  defp exact_text(_value, default), do: default

  defp matrix_value(matrix, row, column),
    do: matrix |> Enum.at(row) |> Enum.at(column)

  defp indexes(first, last) when first > last, do: []
  defp indexes(first, last), do: first..last

  defp export_absent_evidence(quality, metadata, opts) do
    if covariance_absent?(quality) and covariance_absent?(metadata) and
         not Keyword.has_key?(opts, :covariance_reference_frame) and
         not Keyword.has_key?(opts, :covariance_epoch) do
      {:ok, nil}
    else
      {:error, {:missing_field, "covariance_matrix_6x6"}}
    end
  end

  defp covariance_absent?(source) do
    partial? =
      @covariance_partial_fields
      |> Enum.reject(&(&1 == "covariance_status"))
      |> Enum.any?(&Map.has_key?(source, &1))

    status = Map.get(source, "covariance_status")
    not partial? and status in [nil, "not_present"]
  end

  defp export_matrix_evidence(format, matrix, quality, metadata, opts, context) do
    with :ok <- export_component_order(quality, metadata),
         {:ok, matrix} <- export_matrix(matrix),
         :ok <- exact_symmetric_6x6(matrix),
         {:ok, numerical_check} <- numerical_support_check(matrix),
         {:ok, unit_contract} <- export_unit_contract(quality, metadata),
         {:ok, frame_binding} <- export_frame_binding(quality, metadata, opts, context),
         {:ok, epoch_binding} <- export_epoch_binding(format, quality, metadata, opts, context) do
      {:ok,
       %{
         reference_frame: frame_binding["covariance_ref_frame"],
         epoch: epoch_binding["covariance_epoch"],
         time_scale: Map.get(context, "time_scale"),
         matrix: matrix,
         matrix_present: true,
         component_order: @component_order,
         unit_contract: unit_contract,
         frame_binding: frame_binding,
         epoch_binding: epoch_binding,
         numerical_check: numerical_check,
         propagation_status: "metadata_only_not_propagated",
         status: "matrix_exported_metadata_only_no_propagation"
       }}
    end
  end

  defp export_component_order(quality, metadata) do
    [
      Map.get(quality, "covariance_component_order"),
      Map.get(metadata, "covariance_component_order")
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.find(&(&1 != @component_order))
    |> case do
      nil -> :ok
      _order -> {:error, {:invalid_field, "covariance_component_order"}}
    end
  end

  defp export_matrix(matrix) when is_list(matrix) and length(matrix) == 6 do
    matrix
    |> Enum.reduce_while({:ok, []}, fn row, {:ok, rows} ->
      case export_matrix_row(row) do
        {:ok, parsed_row} -> {:cont, {:ok, [parsed_row | rows]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, rows} -> {:ok, Enum.reverse(rows)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp export_matrix(_matrix), do: {:error, {:invalid_field, "covariance_matrix_6x6"}}

  defp export_matrix_row(row) when is_list(row) and length(row) == 6 do
    row
    |> Enum.reduce_while({:ok, []}, fn value, {:ok, values} ->
      cond do
        not is_number(value) ->
          {:halt, {:error, {:invalid_field, "covariance_matrix_6x6"}}}

        value != value or abs(value) > @finite_max_abs_component ->
          {:halt, {:error, {:invalid_field, "covariance_matrix_6x6"}}}

        true ->
          {:cont, {:ok, [value * 1.0 | values]}}
      end
    end)
    |> case do
      {:ok, values} -> {:ok, Enum.reverse(values)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp export_matrix_row(_row), do: {:error, {:invalid_field, "covariance_matrix_6x6"}}

  defp export_unit_contract(quality, metadata) do
    [Map.get(quality, "covariance_unit_contract"), Map.get(metadata, "covariance_unit_contract")]
    |> Enum.reject(&is_nil/1)
    |> Enum.reduce_while({:ok, []}, fn contract, {:ok, contracts} ->
      case normalize_export_unit_contract(contract) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | contracts]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, []} -> {:ok, unit_contract("implicit_ccsds_units")}
      {:ok, [contract]} -> {:ok, contract}
      {:ok, [contract | rest]} -> same_export_unit_contracts(contract, rest)
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_export_unit_contract(%{} = contract) do
    declaration = Map.get(contract, "declaration")

    cond do
      declaration not in ["implicit_ccsds_units", "explicit_ccsds_units"] ->
        {:error, {:invalid_field, "covariance_units"}}

      Map.get(contract, "position_position") != "km**2" ->
        {:error, {:invalid_field, "covariance_units"}}

      Map.get(contract, "position_velocity") != "km**2/s" ->
        {:error, {:invalid_field, "covariance_units"}}

      Map.get(contract, "velocity_velocity") != "km**2/s**2" ->
        {:error, {:invalid_field, "covariance_units"}}

      Map.get(contract, "mixed_unit_declarations", false) != false ->
        {:error, {:invalid_field, "covariance_units"}}

      Map.get(contract, "component_order", @component_order) != @component_order ->
        {:error, {:invalid_field, "covariance_units"}}

      true ->
        {:ok, unit_contract(declaration)}
    end
  end

  defp normalize_export_unit_contract(_contract),
    do: {:error, {:invalid_field, "covariance_units"}}

  defp same_export_unit_contracts(contract, rest) do
    if Enum.all?(rest, &(&1 == contract)) do
      {:ok, contract}
    else
      {:error, {:invalid_field, "covariance_units"}}
    end
  end

  defp export_frame_binding(quality, metadata, opts, context) do
    export_ref_frame = Map.fetch!(context, "source_ref_frame")
    accepted_state_frame = Map.fetch!(context, "accepted_state_frame")

    frame_candidates =
      (Keyword.get_values(opts, :covariance_reference_frame) ++
         [
           Map.get(quality, "covariance_reference_frame"),
           Map.get(metadata, "covariance_reference_frame")
         ])
      |> Enum.reject(&is_nil/1)

    with :ok <- exact_supported_frame(export_ref_frame),
         :ok <- accepted_state_frame(accepted_state_frame),
         {:ok, covariance_frame} <-
           exact_candidate("covariance_reference_frame", frame_candidates, export_ref_frame),
         :ok <- exact_supported_frame(covariance_frame),
         :ok <- same_value(covariance_frame, export_ref_frame, "covariance_frame_binding"),
         :ok <-
           export_frame_binding_map(
             Map.get(quality, "covariance_frame_binding"),
             export_ref_frame,
             covariance_frame,
             accepted_state_frame
           ),
         :ok <-
           export_frame_binding_map(
             Map.get(metadata, "covariance_frame_binding"),
             export_ref_frame,
             covariance_frame,
             accepted_state_frame
           ) do
      {:ok,
       %{
         "source_ref_frame" => export_ref_frame,
         "covariance_ref_frame" => covariance_frame,
         "accepted_state_frame" => accepted_state_frame,
         "conversion_applied" => false
       }}
    end
  end

  defp exact_supported_frame(frame) when frame in @supported_ref_frames, do: :ok
  defp exact_supported_frame(_frame), do: {:error, {:invalid_field, "covariance_frame_binding"}}

  defp accepted_state_frame("earth_inertial_j2000"), do: :ok
  defp accepted_state_frame(_frame), do: {:error, {:invalid_field, "covariance_frame_binding"}}

  defp exact_candidate(_field, [], default), do: {:ok, default}

  defp exact_candidate(field, [candidate | rest], _default)
       when is_binary(candidate) and candidate != "" do
    if Enum.all?(rest, &(&1 == candidate)) do
      {:ok, candidate}
    else
      {:error, {:invalid_field, field}}
    end
  end

  defp exact_candidate(field, _candidates, _default), do: {:error, {:invalid_field, field}}

  defp same_value(value, value, _field), do: :ok
  defp same_value(_left, _right, field), do: {:error, {:invalid_field, field}}

  defp export_frame_binding_map(nil, _source_frame, _covariance_frame, _accepted_frame), do: :ok

  defp export_frame_binding_map(
         %{} = binding,
         source_frame,
         covariance_frame,
         accepted_frame
       ) do
    if Map.get(binding, "source_ref_frame") == source_frame and
         Map.get(binding, "covariance_ref_frame") == covariance_frame and
         Map.get(binding, "accepted_state_frame") == accepted_frame and
         Map.get(binding, "conversion_applied") == false do
      :ok
    else
      {:error, {:invalid_field, "covariance_frame_binding"}}
    end
  end

  defp export_frame_binding_map(_binding, _source_frame, _covariance_frame, _accepted_frame),
    do: {:error, {:invalid_field, "covariance_frame_binding"}}

  defp export_epoch_binding(format, quality, metadata, opts, context) do
    state_epoch = Map.fetch!(context, "state_epoch")
    state_epoch_s = Map.fetch!(context, "state_epoch_s")
    time_scale = Map.fetch!(context, "time_scale")

    with :ok <- supported_time_scale(time_scale) do
      export_epoch_binding(
        format,
        quality,
        metadata,
        opts,
        state_epoch,
        state_epoch_s,
        time_scale
      )
    end
  end

  defp export_epoch_binding(:opm, quality, metadata, opts, state_epoch, state_epoch_s, time_scale) do
    with :ok <- export_epoch_candidates(quality, metadata, opts, state_epoch),
         :ok <- export_epoch_candidate_matches_state(state_epoch, state_epoch_s),
         :ok <-
           export_epoch_binding_map(
             :opm,
             Map.get(quality, "covariance_epoch_binding"),
             state_epoch,
             state_epoch_s,
             time_scale
           ),
         :ok <-
           export_epoch_binding_map(
             :opm,
             Map.get(metadata, "covariance_epoch_binding"),
             state_epoch,
             state_epoch_s,
             time_scale
           ) do
      {:ok,
       %{
         "state_epoch" => state_epoch,
         "covariance_epoch" => state_epoch,
         "time_scale" => time_scale,
         "matched" => true
       }}
    end
  end

  defp export_epoch_binding(:oem, quality, metadata, opts, state_epoch, state_epoch_s, time_scale) do
    with :ok <- export_epoch_candidates(quality, metadata, opts, state_epoch),
         :ok <- export_epoch_candidate_matches_state(state_epoch, state_epoch_s),
         :ok <-
           export_epoch_binding_map(
             :oem,
             Map.get(quality, "covariance_epoch_binding"),
             state_epoch,
             state_epoch_s,
             time_scale
           ),
         :ok <-
           export_epoch_binding_map(
             :oem,
             Map.get(metadata, "covariance_epoch_binding"),
             state_epoch,
             state_epoch_s,
             time_scale
           ) do
      {:ok,
       %{
         "state_epoch" => state_epoch,
         "covariance_epoch" => state_epoch,
         "seconds_since_j2000" => state_epoch_s,
         "time_scale" => time_scale,
         "matched" => true
       }}
    end
  end

  defp supported_time_scale(scale) when scale in ["utc", "tai", "tdb"], do: :ok
  defp supported_time_scale(_scale), do: {:error, {:invalid_field, "covariance_epoch_binding"}}

  defp export_epoch_candidates(quality, metadata, opts, state_epoch) do
    (Keyword.get_values(opts, :covariance_epoch) ++
       [
         Map.get(quality, "covariance_epoch"),
         Map.get(metadata, "covariance_epoch")
       ])
    |> Enum.reject(&is_nil/1)
    |> Enum.reduce_while(:ok, fn candidate, :ok ->
      case exact_epoch_candidate(candidate, state_epoch) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp exact_epoch_candidate(candidate, state_epoch)
       when is_binary(candidate) and candidate == state_epoch,
       do: :ok

  defp exact_epoch_candidate(_candidate, _state_epoch),
    do: {:error, {:invalid_field, "covariance_epoch_binding"}}

  defp export_epoch_candidate_matches_state(candidate, state_epoch_s) when is_binary(candidate) do
    with {:ok, candidate_s} <- epoch_seconds(candidate) do
      if candidate_s == state_epoch_s do
        :ok
      else
        {:error, {:invalid_field, "covariance_epoch_binding"}}
      end
    end
  end

  defp export_epoch_candidate_matches_state(_candidate, _state_epoch_s),
    do: {:error, {:invalid_field, "covariance_epoch_binding"}}

  defp export_epoch_binding_map(_format, nil, _epoch, _state_epoch_s, _time_scale), do: :ok

  defp export_epoch_binding_map(:opm, %{} = binding, epoch, state_epoch_s, time_scale) do
    with :ok <- same_value(Map.get(binding, "time_scale"), time_scale, "covariance_epoch_binding"),
         :ok <- same_value(Map.get(binding, "matched"), true, "covariance_epoch_binding"),
         :ok <- exact_epoch_candidate(Map.get(binding, "state_epoch"), epoch),
         :ok <- exact_epoch_candidate(Map.get(binding, "covariance_epoch"), epoch),
         :ok <- export_epoch_candidate_matches_state(epoch, state_epoch_s) do
      :ok
    end
  end

  defp export_epoch_binding_map(:oem, %{} = binding, epoch, state_epoch_s, time_scale) do
    with :ok <- same_value(Map.get(binding, "time_scale"), time_scale, "covariance_epoch_binding"),
         :ok <- same_value(Map.get(binding, "matched"), true, "covariance_epoch_binding"),
         :ok <- exact_epoch_candidate(Map.get(binding, "state_epoch"), epoch),
         :ok <- exact_epoch_candidate(Map.get(binding, "covariance_epoch"), epoch),
         :ok <- export_epoch_candidate_matches_state(epoch, state_epoch_s) do
      :ok
    end
  end

  defp export_epoch_binding_map(_format, _binding, _epoch, _state_epoch_s, _time_scale),
    do: {:error, {:invalid_field, "covariance_epoch_binding"}}

  defp map_value(%{} = map), do: map
  defp map_value(_value), do: %{}
end
