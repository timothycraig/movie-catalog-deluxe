require "sinatra"
require "pg"
require "pry"

configure :development do
  set :db_config, { dbname: "movies" }
end

configure :test do
  set :db_config, { dbname: "movies_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

def actors_all
  db_connection do |conn|
    sql_query = "SELECT * FROM actors ORDER BY name"
    conn.exec(sql_query)
  end
end

def actor_find(id)
  db_connection do |conn|
    sql_query = "SELECT movies.title, movies.year, movies.id, cast_members.character, actors.name
    FROM actors
    JOIN cast_members ON cast_members.actor_id = actors.id
    JOIN movies ON movies.id = cast_members.movie_id
    WHERE actors.id = $1"
    data = [id]
    conn.exec_params(sql_query, data)
  end
end

def movies_all
  db_connection do |conn|
    sql_query = "SELECT movies.*, genres.name AS genre, studios.name AS studio
    FROM movies
    LEFT JOIN genres ON movies.genre_id = genres.id
    LEFT JOIN studios ON movies.studio_id = studios.id
    ORDER BY movies.title"
    conn.exec(sql_query)
  end
end

def movie_find(id)
  db_connection do |conn|
    sql_query = "SELECT cast_members.character AS character, actors.name AS actor,
    genres.name AS genre, studios.name AS studio, movies.title, actors.id AS actor_id,
    movies.year, movies.rating
    FROM actors
    JOIN cast_members ON actors.id = cast_members.actor_id
    JOIN movies ON cast_members.movie_id = movies.id
    JOIN genres ON movies.genre_id = genres.id
    JOIN studios ON movies.studio_id = studios.id
    WHERE movies.id = $1"
    data = [id]
    conn.exec_params(sql_query, data)
  end
end

get "/" do
  erb :index
end

get "/actors" do
  @list_of_actors = actors_all
  erb :actors
end

get "/actors/:id" do
  @actors = actor_find(params[:id])
  erb :show_actor
end

get "/movies" do
  @list_of_movies = movies_all
  erb :movies
end

get "/movies/:id" do
  @movies = movie_find(params[:id])
  erb :show_movie
end
