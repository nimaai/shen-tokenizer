defmodule Shen.Tokenizer do
  # @symbol_chars ~r/[-=*\/+_?$!\@~><&%'#`;:{}a-zA-Z0-9.]/
  # require IEx

  def next(io_device, buffer) do
    Process.register(buffer, :buffer)
    drain_whitespace(io_device)
    c = getc(io_device)
    unless eof?(c) do
      case c do
        "(" -> "["
        ")" -> "]"
        "\"" -> consume_string(io_device, [])
        _  -> c
      end
    end
    Process.unregister(:buffer)
  end

  defp pop(buffer) do
    {List.first(buffer), Enum.drop(buffer, 1)}
  end

  defp empty?(buffer) do
    Enum.empty?(buffer)
  end

  defp eof?(c) do
    Agent.get(:buffer, &empty?/1) || c == :eof
  end

  defp getc(io_device) do
    if c = Agent.get_and_update(:buffer, &pop/1)
      c
    else
      IO.read(io_device, 1)
    end
  end

  defp ungetc(c) do
    Agent.update(:buffer, fn buffer -> [c | buffer] end)
  end

  defp consume_string(io_device, list_of_chars) do
    c = getc(io_device)
    if eof?(c) do: raise "unterminated string"
    case c do
      "\"" -> Enum.join(list_of_chars)
      _ -> consume_string(io_device, list_of_chars ++ [c])
    end
  end

  defp drain_whitespace(io_device) do
    c = getc(io_device)
    unless eof?(c) do
      if Regex.match?(~r/\s/, c) do
        drain_whitespace(io_device)
      else
        ungetc(c)
      end
    end
  end
end
