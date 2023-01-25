defmodule FilesPath do
  # @test_path "/static/config_be_id/cdrs/service_dir/YYYYMMDD/*.add"
  alias CsvConverter

  def get_today_date() do
    Date.utc_today()
    |> Date.to_iso8601(:basic)
  end

  def default_path(date \\ get_today_date(), type \\ true) do
    sms = "/static/config_be_id/cdrs/bss-cbs_sms/#{date}"
    voice = "/static/config_be_id/cdrs/bss-cbs_voice/#{date}"
    data = "/static/config_be_id/cdrs/bss-cbs_data/#{date}"
    case type do
      "sms" -> [sms]
      "voice" -> [voice]
      "data" -> [data]
      _ -> [sms, voice, data]
    end
  end

  def find_folders(list_path) do
    Enum.map(list_path, fn x ->
      {data , _} = System.shell("ls #{x}")
      data
      |> String.split("\n")
      |> List.delete("")
      |> Enum.map(fn y -> "#{x}/#{y}"  end)
    end)
    |> List.flatten()
  end


  def search_in_files(list_path, _fecha) do
    {:ok, agent} = Agent.start_link fn -> [] end
    fecha = "20220823"
    Enum.each(list_path, fn x ->
      case System.shell("grep -w '#{fecha}' #{x}") do
        {_, 0} -> Agent.update(agent, fn list -> [x | list] end)
        _ -> :ok
      end
    end)
    Agent.get(agent, fn list -> list end)
  end



  # def get_data(date \\ get_today_date(), type \\ ["sms", "voice", "data"], [sep, space, has_columns]) do
  #   date
  #   |> default_path(type)
  #   |> find_folders()
  #   # |> search_in_files("!123")
  # end

  def get_data2(date \\ get_today_date(), type \\ ["sms", "voice", "data"], [sep, space, has_columns]) do
    date
    |> default_path(type)
    |> find_folders()
    |> all_files_data(sep, space, has_columns, type)
  end

  def get_files_prueba(paths, [sep, space, has_columns], type) do
    paths
    |> find_folders()
    |> all_files_data(sep, space, has_columns, type)
  end

  def all_files_data(paths, sep, space, has_columns, type) do
    Agent.start_link(fn  -> [] end)
    Enum.reduce(paths, [], fn file, acc ->
      CsvConverter.read_csv_from_file(file, sep, space, has_columns, type) ++ acc
    end)
    |> List.flatten()
  end

end
