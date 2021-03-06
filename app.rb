require "sinatra"
require "pg"
require_relative "lib/space"

class MakersBnB < Sinatra::Base

  enable :sessions

  def db_connection()
    if ENV['RACK_ENV'] == 'test'
      PG.connect(dbname: 'makersbnb_test')
    else
      PG.connect(dbname: 'makersbnb')
    end
  end

  get '/' do
    erb :index
  end

  get "/register" do
    erb :register
  end

  post "/register_new_user" do
    user_name = params[:user_name]
    connection = db_connection()
    results = connection.exec("SELECT * FROM users WHERE name = '#{user_name}' ")
    #if ntuples is 0 then there are no entries in the table
    if results.ntuples == 0
      connection.exec("INSERT INTO users (name) VALUES ('#{user_name}');")
    end
    redirect "/login"
  end

  get "/login" do
    redirect "/user_home_page" if session[:name]
    erb :login
  end

  post "/login_user" do
    user_name = params[:user_name]
    connection = db_connection()
    results = connection.exec("SELECT * FROM users WHERE name = '#{user_name}' ")
    if results.ntuples == 1
      session[:id] = results.field_values("id")[0].to_i
      session[:name] = results.field_values("name")[0]
      redirect "/user_home_page"
    else
      redirect "/login"
    end
  end

  get "/user_home_page" do
    redirect "/login" unless session[:name]
    @username = session[:name]
    new_space = Space.new
    @results = new_space.list(session[:id])
    erb :user_home_page
  end

  get "/create_new_space" do
    redirect "/login" unless session[:name]
    erb :create_new_space
  end

  post "/submit_new_space" do
    new_space_name = params[:new_space_name]
    description = params[:description]
    price = params[:price]
    user_id = session[:id]
    connection = db_connection()
    connection.exec("INSERT INTO spaces (name, users_ref, description, price) VALUES ('#{new_space_name}', #{user_id}, '#{description}', #{price});")
    redirect "/"
  end

  post "/add_new_date" do
    new_date = params[:date]
    id = params[:id].to_i
    connection = db_connection()
    connection.exec("UPDATE spaces SET available = array_append(available, '#{new_date}') WHERE id = '#{id}';")
    redirect "/user_home_page"
  end

  get "/request_available_space" do
    redirect "/login" unless session[:name]
    request_date = params[:request_date]
    if request_date
      if !request_date.empty?
        connection = db_connection()
        results = connection.exec("SELECT name FROM spaces WHERE available @> '{#{request_date}}';")
        @dates = results.field_values("name")
      end
    end
    erb :request_available_space
  end

  

  run! if app_file == $0
end
