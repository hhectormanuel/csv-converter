defmodule CsvConverterTest do
  use ExUnit.Case
  doctest CsvConverter

  test "greets the world" do
    assert CsvConverter.hello() == :world
  end
end
