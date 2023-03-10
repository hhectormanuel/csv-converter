defmodule Prueba do
  defp convert_csv(content, sep, space, has_columns) do
    {:ok, agent} = Agent.start_link(fn -> [] end)
    {columns, data} = get_columns_data(content, sep, space, has_columns)
    Enum.each(data, fn x -> add_data(columns, x, agent) end)
    chunk(length(columns), agent)
    {map, map_agent} = mapping(agent)
    iterator(map, map_agent)
    Agent.stop(agent)
    Agent.get(map_agent, fn x -> x end)
  end

  defp mapping(agent) do
    map = Agent.get(agent, fn data -> data end)
    {:ok, map_agent } = Agent.start_link(fn -> [] end)
    {map, map_agent}
  end

  defp iterator(maps, map_agent) do
    Enum.map(maps, fn x ->
      flat(%{}, x, map_agent)
    end)
  end

  defp flat(empty_map, [hd | tail] = _list_map, map_agent) when length(tail) == 0 do
    new_map = Map.merge(empty_map, hd)
    Agent.update(map_agent, fn list -> list ++ [new_map] end)
  end


  defp flat(empty_map, [hd | tail] = _list_map, map_agent) do
    new_map = Map.merge(empty_map, hd)
    flat(new_map, tail, map_agent)
  end

  def chunk(columns, agent) do
    Agent.update(agent, fn data ->
      Enum.chunk_every(data, columns)
    end)
  end

  defp put_agent(hd, hd2, agent) do
    Agent.update(agent, fn list -> list ++ [%{hd => hd2}] end)
  end

  defp add_data([hd | tail] = _columns, [hd2 | _tail2] = _data, agent) when length(tail) == 0  do
    put_agent(hd, hd2, agent)
  end

  defp add_data([hd | tail] = _columns, [hd2 | tail2] = _data, agent) do
    put_agent(hd, hd2, agent)
    add_data(tail, tail2, agent)
  end

  defp get_columns_data(content, sep, space, has_columns) do
    [hd | tail] = String.split(content, space)
    data = Enum.reduce(tail, [], fn x, acc ->
      acc ++ [String.split(x, sep)]
    end)
    if has_columns do
      {String.split(hd, sep), data}
    else
      data = List.delete_at(data, 3)
      data = [String.split(hd, sep)] ++ data
      columns = Enum.map(1..length(String.split(hd, sep)), fn x -> "columna #{x}" end)
      {columns, data}
    end
  end

  def read_csv_from_url(url, sep \\ ",", space \\ "\n", has_columns \\ true) do
    petition = HTTPotion.get(url)
    convert_csv(petition.body, sep, space, has_columns)
  end

  def read_csv_from_file(path, sep \\ ",", space \\ "\n", has_columns \\ true) do
    {:ok, content} = File.read(path)
    convert_csv(content, sep, space, has_columns)
  end

end
