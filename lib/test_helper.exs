# Exclude all external tests from running
ExUnit.configure(exclude: [external: true])
# this can be reversed by running:
# mix test --include external:true

ExUnit.start(capture_log: true)

"test_support/bonny_plug/*.exs"
|> Path.wildcard()
|> Enum.each(&Code.compile_file/1)

defmodule CompileTimeAssertions do
  defmodule DidNotRaise, do: defstruct(message: nil)

  defmacro assert_compile_time_raise(expected_exception, expected_message, fun) do
    actual_exception =
      try do
        Code.eval_quoted(fun)
        %DidNotRaise{}
      rescue
        e -> e
      end

    quote do
      assert unquote(actual_exception.__struct__) == unquote(expected_exception)
      assert unquote(actual_exception.message) =~ unquote(expected_message)
    end
  end
end
