defmodule TelemetryWrappers do
  @moduledoc """
  Documentation for TelemetryWrappers.
  """

  defmacro __using__(_opts) do
    quote do
      import TelemetryWrappers, only: [deftimed: 2, deftimed: 3, deftimed: 4, deftimedp: 2, deftimedp: 3, deftimedp: 4]
      require TelemetryWrappers
    end
  end

  @doc """
  Defines a function that will have its execution time measured and sent as a telemetry event.

  As an example you can define the following module

    defmodule TelemetryWrappers.Support.TestModule do
      use TelemetryWrappers

      deftimed timed_function(a, b), [:a, :b] do
        a + b
      end

      deftimed timed_function2(a, b) do
        a + b
      end
    end

  Then both functions will work as expected:

      iex> TelemetryWrappers.Support.TestModule.timed_function(1, 2)
      3

      iex> TelemetryWrappers.Support.TestModule.timed_function2(1, 2)
      3

  but it will also emit a `:telemetry` event `[:a, :b]` with the contents `%{call: timing}`
  where `timing` is the time the function took to execute in microseconds.

  The metric name is optional and will default to `[:timing, name]` where `name` is the name of the function (without arity).

  Note that type specs can still be defined for function defined with `deftimed` just as you would normally, e.g.

      @spec timed_function(number(), number()) :: number()
      deftimed timed_function(a, b), [:a, :b] do
        a + b
      end

  You can also add metadata to the metrics.

    defmodule TelemetryWrappers.Support.TestModule do
      use TelemetryWrappers

      deftimed timed_function_with_meta(a, b), [:a, :b], %{a: a} do
        a + b
      end
    end

  This will emit a `:telemetry` event `[:a, :b]` with the contents `%{call: timing}` and the metadata '%{a: a}'
  """
  defmacro deftimed(function_name, metric_name \\ [], metadata \\ quote(do: %{}), do: expr) do
    {fname, _, _} = function_name
    actual_name = get_actual_name(metric_name, fname)

    quote do
      def unquote(function_name) do
        {timing, result} = :timer.tc(fn -> unquote(expr) end)
        :telemetry.execute(unquote(actual_name), %{call: timing}, unquote(metadata))
        result
      end
    end
  end

  @doc """
  Defines a private function that will have its execution time measured and sent as a telemetry event.

  In principle, same as `deftimed/3` but defines a private function instead.

  As an example you can define the following module

    defmodule TelemetryWrappers.Support.TestModule do
      use TelemetryWrappers

      def invoke_private(a) do
        private_fun(a)
      end

      deftimedp(private_fun(a), [:something], do: a)
    end

  And then invoke the function:

      iex> TelemetryWrappers.Support.TestModule.invoke_private(15)
      15

  which will also emit a `:telemetry` event `[:something]` with the contents `%{call: timing}`
  where `timing` is the time the function took to execute the private function in microseconds.

  The metric name is optional and will default to `[:timing, name]` where `name` is the name of the function (without arity),
   just like in `deftimed/3`

  """
  defmacro deftimedp(function_name, metric_name \\ [], metadata \\ quote(do: %{}), do: expr) do
    {fname, _, _} = function_name
    actual_name = get_actual_name(metric_name, fname)

    quote do
      defp unquote(function_name) do
        {timing, result} = :timer.tc(fn -> unquote(expr) end)
        :telemetry.execute(unquote(actual_name), %{call: timing}, unquote(metadata))
        result
      end
    end
  end

  defp get_actual_name([], name), do: [:timing, name]
  defp get_actual_name(metric, _), do: metric
end
