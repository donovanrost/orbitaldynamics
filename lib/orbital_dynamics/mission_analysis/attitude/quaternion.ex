defmodule OrbitalDynamics.MissionAnalysis.Attitude.Quaternion do
  @moduledoc "Hamilton unit quaternions [w,x,y,z], active body-to-inertial rotations. Angles use degrees."
  alias OrbitalDynamics.{Vector3}
  alias OrbitalDynamics.MissionAnalysis.Input

  def new!([w, x, y, z]), do: new!({w, x, y, z})

  def new!({w, x, y, z}) do
    values = Enum.map([w, x, y, z], &Input.number!(&1, "quaternion component", -1.0e15, 1.0e15))
    norm = :math.sqrt(Enum.sum(Enum.map(values, &(&1 * &1))))
    if norm < 1.0e-12, do: raise(ArgumentError, "nonzero quaternion required")
    [w, x, y, z] = Enum.map(values, &(&1 / norm))
    {w, x, y, z}
  end

  def new!(_), do: raise(ArgumentError, "quaternion requires four components in w,x,y,z order")
  def inverse({w, x, y, z}), do: {w, -x, -y, -z}

  def multiply({a, b, c, d}, {w, x, y, z}),
    do:
      new!(
        {a * w - b * x - c * y - d * z, a * x + b * w + c * z - d * y,
         a * y - b * z + c * w + d * x, a * z + b * y - c * x + d * w}
      )

  def increment(vector_deg) do
    angle = Vector3.norm(vector_deg)

    if angle == 0 do
      {1.0, 0.0, 0.0, 0.0}
    else
      {x, y, z} = Vector3.scale(vector_deg, 1 / angle)
      half = angle * :math.pi() / 360
      sine = :math.sin(half)
      {:math.cos(half), x * sine, y * sine, z * sine}
    end
  end

  def rotation_vector(q) do
    {w, x, y, z} = new!(q)
    {w, x, y, z} = if w < 0, do: {-w, -x, -y, -z}, else: {w, x, y, z}
    sine = :math.sqrt(x * x + y * y + z * z)

    if sine == 0,
      do: {0.0, 0.0, 0.0},
      else: Vector3.scale({x, y, z}, 2 * :math.atan2(sine, w) * 180 / :math.pi() / sine)
  end

  def delta(from, to) do
    a = new!(from)
    b = new!(to)
    {w, x, y, z} = a
    # Exact identical/antipodal representations have zero separation. Avoid
    # inverse-product roundoff without snapping genuine small rotations to zero.
    if b == a or b == {-w, -x, -y, -z},
      do: {0.0, 0.0, 0.0},
      else: multiply(b, inverse(a)) |> rotation_vector()
  end

  def distance_deg(a, b), do: Vector3.norm(delta(a, b))

  def rotate(q, v) do
    {w, x, y, z} = new!(q)
    u = {x, y, z}

    Vector3.add(
      v,
      Vector3.scale(
        Vector3.add(Vector3.scale(Vector3.cross(u, v), w), Vector3.cross(u, Vector3.cross(u, v))),
        2
      )
    )
  end

  @doc "Orientation with +Z along direction and +X along the projected inertial roll reference."
  def from_direction(direction, reference) do
    z = Input.unit!(direction, "pointing direction")
    reference = Input.unit!(reference, "roll reference")
    projection = Vector3.subtract(reference, Vector3.scale(z, Vector3.dot(reference, z)))

    if Vector3.norm(projection) < 1.0e-8 do
      {:unknown, :roll_reference_singular}
    else
      x = Input.unit!(projection, "roll projection")
      y = Vector3.cross(z, x)
      {:ok, from_axes(x, y, z)}
    end
  end

  defp from_axes({m00, m10, m20}, {m01, m11, m21}, {m02, m12, m22}) do
    trace = m00 + m11 + m22

    cond do
      trace > 0 ->
        s = 2 * :math.sqrt(trace + 1)
        new!({s / 4, (m21 - m12) / s, (m02 - m20) / s, (m10 - m01) / s})

      m00 > m11 and m00 > m22 ->
        s = 2 * :math.sqrt(1 + m00 - m11 - m22)
        new!({(m21 - m12) / s, s / 4, (m01 + m10) / s, (m02 + m20) / s})

      m11 > m22 ->
        s = 2 * :math.sqrt(1 + m11 - m00 - m22)
        new!({(m02 - m20) / s, (m01 + m10) / s, s / 4, (m12 + m21) / s})

      true ->
        s = 2 * :math.sqrt(1 + m22 - m00 - m11)
        new!({(m10 - m01) / s, (m02 + m20) / s, (m12 + m21) / s, s / 4})
    end
  end
end
