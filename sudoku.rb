require 'sinatra'
require 'sinatra/partial'
require 'rack-flash'
require_relative './helpers/application.rb'
require_relative './lib/sudoku'
require_relative './lib/cell'
use Rack::Flash

enable :sessions
set :session_secret, "I'm the secret key to sign the cookie"
set :partial_template_engine, :erb



def random_sudoku
  seed = (1..9).to_a.shuffle + Array.new(81-9, 0)
  sudoku = Sudoku.new(seed.join)
  sudoku.solve!
  sudoku.to_s.chars
end

def puzzle(sudoku, difficulty)
  sudoku.each_slice(3).to_a.each{|e|
    e[[0,1,2].sample] = "0"
    e[[0,1,2].sample] = "0" if difficulty == :medium || difficulty == :hard
    e[[0,1,2].sample] = "0" if difficulty == :hard
  }.flatten
end

def generate_new_puzzle_if_necessary
  return if session[:current_solution]
  session[:difficulty] = session[:new_difficulty] || :medium
  sudoku = random_sudoku
  session[:solution] = sudoku
  session[:puzzle] = puzzle(sudoku, session[:difficulty])
  session[:current_solution] = session[:puzzle]
end

def prepare_to_check_solution
  @check_solution = session[:check_solution]
  if @check_solution
    flash[:notice] = "Incorrect values are highlighted in yellow"
  end
  session[:check_solution] = nil
end

def box_order_to_row_order(cells)
  boxes = cells.each_slice(9).to_a
  (0..8).to_a.inject([]) {|memo, i|
    first_box_index = i / 3 * 3
    three_boxes = boxes[first_box_index, 3]
    three_rows_of_three = three_boxes.map do |box|
      row_number_in_a_box = i % 3
      first_cell_in_the_row_index = row_number_in_a_box * 3
      box[first_cell_in_the_row_index, 3]
    end
    memo += three_rows_of_three.flatten
  }
end

get '/' do
  prepare_to_check_solution
  generate_new_puzzle_if_necessary
  @current_solution = session[:current_solution] || session[:puzzle]
  @solution = session[:solution]
  @puzzle = session[:puzzle]
  erb :index
end

get '/solution' do
  redirect to("/") if !session[:current_solution]
  @current_solution = session[:solution]
  @solution = session[:solution]
  @puzzle = session[:puzzle]
  erb :index
end

post '/' do
   cells = box_order_to_row_order(params["cell"])
  session[:current_solution] = cells.map{|value| value.to_i}.join if !params[:reset]
  session[:check_solution] = true if !params[:save] && !params[:reset]
  session[:current_solution] = session[:puzzle] if params[:reset]
  redirect to("/")
end

post '/set' do
  session[:new_difficulty] = params[:difficulty].to_sym
  session[:current_solution] = nil
  redirect to("/")
end
