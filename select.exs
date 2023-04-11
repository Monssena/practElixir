# подгрузка необх. пакетов.
Mix.install([:myxql, :plug, :plug_cowboy])

# модуль для работы с базой данных.
defmodule ExDataBase do
  def init_conn() do
	children = [{MyXQL, hostname: "127.0.0.1", username: "root", password: "", database: "test", name: :mydb}]
	opts = [strategy: :one_for_one, name: MyApp.Supervisor]
	Supervisor.start_link(children, opts)
  end
  # функция инициализации.
  def init(sQuery) do
	init_conn()
    {:ok, result} = MyXQL.query(:mydb, sQuery)
	result
  end
  # окружить тегом одной ячейки <td> ... </td>.
  def btwTagTd(s, sDop) do
    sDop <> "<td>" <> to_string(s) <> "</td>"
  end
  # окружить тегом одной строки <tr> ... </tr>.
  def btwTagTr(s1, sDop) do
	sDop1 = Enum.map(s1, fn(s) -> ExDataBase.btwTagTd(s, sDop) end)
	"<tr>" <> to_string(sDop1) <> "</tr>"
  end
  # разделение массива на отдельные строки.
  def sepRows(s1, sDop) do
    sDop <> ExDataBase.btwTagTr(s1, sDop)
  end
  # возвращение заголовка с тегами HTML.
  def columns(result) do
    sDop1 = ""
    sDop1 = Enum.map(result.columns, fn(s) -> ExDataBase.btwTagTd(s, sDop1) end)
    "<tr>" <> to_string(sDop1) <> "</tr>"
  end
  # возвращение всех строк SELECT с тегами HTML.
  def rows(result) do
    sDop2 = ""
    Enum.map(result.rows, fn(s) -> ExDataBase.sepRows(s, sDop2) end)
  end
  
  # сравнение на ключевое слово в файле select.html и возврат заголовка с тегами <tr><td> ... </td></tr> для одной строки в таблице HTML.
  def if_columns(s1, s2) do
    if s1 =~ s2 do
	  result = ExDataBase.init("SELECT * FROM myarttable WHERE id>14 ORDER BY id DESC")
	  to_string(ExDataBase.columns(result))
	end
  end

  # то же самое, но для строк таблицы.
  def if_rows(s1, s2) do
    if s1 =~ s2 do
	  result = ExDataBase.init("SELECT * FROM myarttable WHERE id>14 ORDER BY id DESC")
	  to_string(ExDataBase.rows(result))
	end
  end
  
  # возврат всего 1 ячейки, версии базы данных (БД).
  def if_one_row(s1, s2) do
    if s1 =~ s2 do
	  result = ExDataBase.init("SELECT VERSION() AS ver")
	  a1 = Enum.map(result.rows, fn(s) -> s end)
	  to_string(a1)
	end
  end
  
  # добавление одной строки при условии, если были параметры GET из формы.
  def if_param_insert(s1, s2, s3) do
    if s1 != nil && s2 != nil && s3 != nil do
	  init_conn()
	  {:ok, result} = MyXQL.query(:mydb, "INSERT INTO myarttable (text, description, keywords) VALUES (?, ?, ?)", [s1, s2, s3])
	  ExDataBase.log("User added 1 row to table myarttable")
      result
	end
  end
  
  # отображение событий от пользователей из браузера на экран.
  def log(sLine) do
	IO.puts to_string(NaiveDateTime.utc_now) <> " Event: " <> sLine
  end
end

# модуль для работы из браузера.
defmodule MyPlug do
  use Plug.Router
  plug :match
  plug Plug.Parsers, parsers: [:urlencoded]
  plug :dispatch

  # для совместимости с Plug.Router.
  get "/search" do
    IO.puts "/search is ok."
	fetch_query_params(conn)
  end

  # функция выполняется в момент подключения из браузера.
  def call(conn, _opts) do

    # добавление 1 строки из формы select.html.
    conn1 = fetch_query_params(conn)
    col1 = conn1.params["col1"]
    col2 = conn1.params["col2"]
    col3 = conn1.params["col3"]
	# каждый параметр проверяется на nil.
    ExDataBase.if_param_insert(col1, col2, col3)
	
	
    # открытие шаблона.
	{:ok, file} = File.open("select.html", [:read, :utf8])
	put_resp_content_type(conn, "text/plain")
	sText = "" # инициализация строковой переменной.
	# отправка сразу всего файла с данными из БД.
	send_resp(conn, 200, read_file(file, sText))
  end
  
  # сложение строки и последовательности байт.
  def plusSrt(s1, a1) do
	  s1 <> to_string(a1)
  end
  # сложение двух строк, если нет ключевых слов.
  def plusSrtExcept(sMain, sNew, sTag1, sTag2) do
	  if sNew =~ sTag1 || sNew =~ sTag2 do
	    sMain
	  else
		sMain <> sNew
	  end
  end
  # чтение шаблона и отправка пользователю в браузер.
  def read_file(file, sText) do
	aLine = IO.read(file, :line)
	stLine = to_string(aLine)
	
	# проверка, если не конец файла select.html.
    if aLine != :eof do
	  # выполняется всегда, если нет ключ. слов: "@tr", "@ver"
	  sText = plusSrtExcept(sText, stLine, "@tr", "@ver")
#     sText = sText <> stLine

      # добавляется заголовок таблицы.
	  aLine2 = ExDataBase.if_columns(stLine, "@tr")
      sText = plusSrt(sText, aLine2)
	  
	  # добавляется все строки таблицы.
	  aLine2 = ExDataBase.if_rows(stLine, "@tr")
      sText = plusSrt(sText, aLine2)
	  
	  # добавляется версия базы данных (БД).
	  aLine2 = ExDataBase.if_one_row(stLine, "@ver")
      sText = plusSrt(sText, aLine2)


	  # чтение файла шаблона из select.html методом рекурсии, пока не :eof файла.
	  read_file(file, sText)
	else
	  ExDataBase.log("The user got a select.html page")
	  # возврат обработанного шаблона в браузер пользователю.
	  sText
    end
  end
end

# старт Web-сервера и ожидание подключений.
require Logger
webserver = {Plug.Cowboy, plug: MyPlug, scheme: :http, options: [port: 4000]}
{:ok, _} = Supervisor.start_link([webserver], strategy: :one_for_one)
Logger.info("Plug now running on http://localhost:4000/")
# вечное ожидание новых подключений ...
Process.sleep(:infinity)
