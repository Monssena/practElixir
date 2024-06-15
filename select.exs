# Подгрузка необходимых пакетов.
Mix.install([:myxql, :plug, :plug_cowboy])

# Модуль для работы с базой данных.
defmodule ExDataBase do
  def init_conn() do
    children = [{MyXQL, hostname: "127.0.0.1", username: "root", password: "Lvbnhbq2001", database: "test", name: :mydb}]
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Функция инициализации.
  def init(sQuery) do
    init_conn()
    {:ok, result} = MyXQL.query(:mydb, sQuery)
    result
  end

  # Обернуть тегом одной ячейки <td> ... </td>.
  def btwTagTd(s, sDop) do
    sDop <> "<td>" <> to_string(s) <> "</td>"
  end

  # Обернуть тегом одной строки <tr> ... </tr>.
  def btwTagTr(s1, sDop) do
    sDop1 = Enum.map(s1, fn(s) -> ExDataBase.btwTagTd(s, sDop) end)
    "<tr>" <> to_string(sDop1) <> "</tr>"
  end

  # Разделение массива на отдельные строки.
  def sepRows(s1, sDop) do
    sDop <> ExDataBase.btwTagTr(s1, sDop)
  end

  # Возвращение заголовка с тегами HTML.
  def columns(result) do
    sDop1 = ""
    sDop1 = Enum.map(result.columns, fn(s) -> ExDataBase.btwTagTd(s, sDop1) end)
    "<tr>" <> to_string(sDop1) <> "</tr>"
  end

  # Возвращение всех строк SELECT с тегами HTML.
  def rows(result) do
    sDop2 = ""
    Enum.map(result.rows, fn(s) -> ExDataBase.sepRows(s, sDop2) end)
  end

  # Сравнение на ключевое слово в файле select.html и возврат заголовка с тегами <tr><td> ... </td></tr> для одной строки в таблице HTML.
  def if_columns(s1, s2) do
    if s1 =~ s2 do
      result = ExDataBase.init("SELECT * FROM Individuals ORDER BY id DESC")
      to_string(ExDataBase.columns(result))
    end
  end

  # То же самое, но для строк таблицы.
  def if_rows(s1, s2) do
    if s1 =~ s2 do
      result = ExDataBase.init("SELECT * FROM Individuals ORDER BY id DESC")
      to_string(ExDataBase.rows(result))
    end
  end

  # Возврат всего 1 ячейки, версии базы данных (БД).
  def if_one_row(s1, s2) do
    if s1 =~ s2 do
      result = ExDataBase.init("SELECT VERSION() AS ver")
      a1 = Enum.map(result.rows, fn(s) -> s end)
      to_string(a1)
    end
  end

  # Добавление одной строки при условии, если были параметры GET из формы.
  def if_param_insert(params) do
    if Enum.all?(params, fn {_, v} -> v != nil end) do
      init_conn()
      query = "INSERT INTO Individuals (first_name, last_name, middle_name, passport, taxpayer_number, insurance_number, driver_licence, extra_documents, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
      values = Enum.map(params, fn {_, v} -> v end)
      {:ok, result} = MyXQL.query(:mydb, query, values)
      ExDataBase.log("User added 1 row to table Individuals")
      result
    end
  end

  # Отображение событий от пользователей из браузера на экран.
  def log(sLine) do
    IO.puts to_string(NaiveDateTime.utc_now) <> " Event: " <> sLine
  end
end

# Модуль для работы из браузера.
defmodule MyPlug do
  use Plug.Router
  plug :match
  plug Plug.Parsers, parsers: [:urlencoded]
  plug :dispatch

  # Для совместимости с Plug.Router.
  get "/search" do
    IO.puts "/search is ok."
    fetch_query_params(conn)
  end

  # Функция выполняется в момент подключения из браузера.
  def call(conn, _opts) do

    # Добавление 1 строки из формы select.html.
    conn1 = fetch_query_params(conn)
    params = [
      {"first_name", conn1.params["first_name"]},
      {"last_name", conn1.params["last_name"]},
      {"middle_name", conn1.params["middle_name"]},
      {"passport", conn1.params["passport"]},
      {"taxpayer_number", conn1.params["taxpayer_number"]},
      {"insurance_number", conn1.params["insurance_number"]},
      {"driver_licence", conn1.params["driver_licence"]},
      {"extra_documents", conn1.params["extra_documents"]},
      {"notes", conn1.params["notes"]}
    ]

    ExDataBase.if_param_insert(params)

    # Открытие шаблона.
    {:ok, file} = File.open("select.html", [:read, :utf8])
    put_resp_content_type(conn, "text/plain")
    sText = "" # Инициализация строковой переменной.
    # Отправка сразу всего файла с данными из БД.
    send_resp(conn, 200, read_file(file, sText))
  end

  # Сложение строки и последовательности байт.
  def plusSrt(s1, a1) do
    s1 <> to_string(a1)
  end

  # Сложение двух строк, если нет ключевых слов.
  def plusSrtExcept(sMain, sNew, sTag1, sTag2) do
    if sNew =~ sTag1 || sNew =~ sTag2 do
      sMain
    else
      sMain <> sNew
    end
  end

  # Чтение шаблона и отправка пользователю в браузер.
  def read_file(file, sText) do
    aLine = IO.read(file, :line)
    stLine = to_string(aLine)

    # Проверка, если не конец файла select.html.
    if aLine != :eof do
      # Выполняется всегда, если нет ключевых слов: "@tr", "@ver"
      sText = plusSrtExcept(sText, stLine, "@tr", "@ver")

      # Добавляется заголовок таблицы.
      aLine2 = ExDataBase.if_columns(stLine, "@tr")
      sText = plusSrt(sText, aLine2)

      # Добавляются все строки таблицы.
      aLine2 = ExDataBase.if_rows(stLine, "@tr")
      sText = plusSrt(sText, aLine2)

      # Добавляется версия базы данных (БД).
      aLine2 = ExDataBase.if_one_row(stLine, "@ver")
      sText = plusSrt(sText, aLine2)

      # Чтение файла шаблона из select.html методом рекурсии, пока не :eof файла.
      read_file(file, sText)
    else
      ExDataBase.log("The user got a select.html page")
      # Возврат обработанного шаблона в браузер пользователю.
      sText
    end
  end
end

# Старт Web-сервера и ожидание подключений.
require Logger
webserver = {Plug.Cowboy, plug: MyPlug, scheme: :http, options: [port: 4000]}
{:ok, _} = Supervisor.start_link([webserver], strategy: :one_for_one)
Logger.info("Plug now running on http://localhost:4000/")
# Вечное ожидание новых подключений ...
Process.sleep(:infinity)
