defmodule OrbitalDynamics.Frame do
  @moduledoc """
  Reference frame metadata for state vectors.

  Frames are carried explicitly so force models cannot accidentally combine
  incompatible states. The built-in Earth labels identify J2000 inertial and
  provider-defined Earth-fixed states; transforming between them remains an
  explicit opt-in operation through `OrbitalDynamics.FrameTransform`.
  """

  @enforce_keys [:name, :center, :orientation]
  defstruct [:name, :center, :orientation]

  @type t :: %__MODULE__{
          name: atom(),
          center: atom(),
          orientation: atom()
        }

  @doc """
  Creates reference-frame metadata.
  """
  def new!(name, center, orientation) do
    cond do
      not is_atom(name) ->
        raise ArgumentError, "frame name must be an atom"

      not is_atom(center) ->
        raise ArgumentError, "frame center must be an atom"

      not is_atom(orientation) ->
        raise ArgumentError, "frame orientation must be an atom"

      true ->
        %__MODULE__{name: name, center: center, orientation: orientation}
    end
  end

  @doc """
  Earth-centered inertial frame aligned with the conventional J2000 axes.
  """
  def earth_inertial_j2000 do
    new!(:eci_j2000, :earth, :j2000)
  end

  @doc """
  Earth-centered, provider-defined body-fixed frame.

  The label does not select an Earth-rotation provider or perform a transform.
  """
  def earth_fixed do
    new!(:earth_body_fixed, :earth, :body_fixed)
  end

  @doc """
  Returns true when two frames are the same explicit frame label.
  """
  def compatible?(%__MODULE__{} = left, %__MODULE__{} = right) do
    left.name == right.name and left.center == right.center and
      left.orientation == right.orientation
  end

  def compatible?(_left, _right), do: false

  @doc """
  Returns true when a frame is centered on the supplied central body.
  """
  def compatible_with_central_body?(%__MODULE__{} = frame, %{name: body_name})
      when is_atom(body_name),
      do: frame.center == body_name

  def compatible_with_central_body?(_frame, _central_body), do: false
end
