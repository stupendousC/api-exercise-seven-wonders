require 'httparty'
require 'awesome_print'
require 'pry'

require "dotenv"
Dotenv.load
KEY = ENV["KEY"]

# for use in test.rb
class SearchError < StandardError; end



def get_location(string, my_key = KEY)
  base_url = "https://us1.locationiq.org/v1/search.php"
  query_parameters = { key: my_key, q: string, format: "json" }
  response = HTTParty.get(base_url, query: query_parameters)
  
  if response[0]
    lon = response[0]["lon"]
    lat = response[0]["lat"] 
    puts "LON = #{lon}, LAT = #{lat}"
  elsif response.code == 400
    raise SearchError, "You done messed up!"
  else
    puts "what. could. this. possibly. be...?"
  end

  return response
end

def get_locations(str_locations_in_array, my_key = KEY )
  #Example output:
  #{"Great Pyramind of Giza"=>{"lat"=>29.9792345, "lng"=>31.1342019}, "Hanging Gardens of Babylon"=>{"lat"=>32.5422374, "lng"=>44.42103609999999}, "Colossus of Rhodes"=>{"lat"=>36.45106560000001, "lng"=>28.2258333}, "Pharos of Alexandria"=>{"lat"=>38.7904054, "lng"=>-77.040581}, "Statue of Zeus at Olympia"=>{"lat"=>37.6379375, "lng"=>21.6302601}, "Temple of Artemis"=>{"lat"=>37.9498715, "lng"=>27.3633807}, "Mausoleum at Halicarnassus"=>{"lat"=>37.038132, "lng"=>27.4243849}}
  
  # This is the format locationiq.com wants for requests: 
  ### WEBSITE IS ACTUALLY .ORG!!! NOT .COM!!! TSK TSK!
  # GET https://us1.locationiq.com/v1/search.php?KEY=YOUR_PRIVATE_TOKEN&q=SEARCH_STRING&format=json
  
  base_url = "https://us1.locationiq.org/v1/search.php"
  giant_array = str_locations_in_array.map do |location|
    query_parameters = { key: my_key, q: location, format: "json" }
    response = HTTParty.get(base_url, query: query_parameters)
    puts
    puts location
    
    lat = response[0]["lat"]
    lon = response[0]["lon"]
    puts
    sleep(0.5)
    [location, lat, lon]
  end
  
  giant_hash = {}
  giant_array.each do |array|
    giant_hash[array[0]] = {"lat" => array[1].to_f, "lon" => array[2].to_f}
  end
  
  return giant_hash
end


seven_wonders = ["Great Pyramid of Giza", "Babylon Gardens", "Temple of Artemis", "Colossus of Rhodes", "Pharos of Alexandria", "Statue of Zeus at Olympia", "Mausoleum at Halicarnassus"]
# puts get_location("Seattle, WA")
# puts get_locations(seven_wonders)
# puts




# ########## OPTIONAL ENHANCEMENT #############
# # REVERSE GEOCODING
# # GET https://us1.locationiq.com/v1/reverse.php?KEY=YOUR_PRIVATE_TOKEN&lat=LATITUDE&lon=LONGITUDE&format=json

numbers= [ { lat: 38.8976998, lon: -77.0365534886228}, {lat: 48.4283182, lon: -123.3649533 },  { lat: 41.8902614, lon: 12.493087103595503} ]


def reverse_geocode(lon, lat, key = KEY)
  sleep(0.5)
  base_url = "https://us1.locationiq.org/v1/reverse.php"
  query_parameters = { key: key, lat: lat.to_s, lon: lon.to_s, format: "json" }
  response = HTTParty.get(base_url, query: query_parameters)
  return response["display_name"]
end

# puts "\nRUNNING reverse_geocode on 3 mystery coord sets..."
# numbers.each do |hash|
#   location_str = reverse_geocode(hash[:lon], hash[:lat])
#   puts location_str
# end

# puts "\n\n\n\n"



########## OPTIONAL ENHANCEMENT #############
# Make a request for driving directions from Cairo Egypt to the Great Pyramid of Giza.
# GET https://us1.locationiq.com/v1/directions/driving/{coordinates}?KEY=<YOUR_ACCESS_TOKEN>&sources={elem1};{elem2};..&destinations={elem1};{elem2};...&annotations={duration|distance|duration,distance}
# Coordinates format is... {longitude},{latitude};{longitude},{latitude}<;{longitude},{latitude} ...>

def a_to_b(place1, place2)
  result = []
  [place1, place2].each do |place|
    response = get_location(place)
    ap response
    lon = response[0]["lon"]
    lat = response[0]["lat"]
    result << {place: place, lon: lon, lat: lat}
  end
  return result
end

def coords_a_to_b (a_to_b_result)
  a_lon = a_to_b_result[0][:lon]
  a_lat = a_to_b_result[0][:lat]
  b_lon = a_to_b_result[1][:lon]
  b_lat = a_to_b_result[1][:lat]
  manual_coords = ""
  manual_coords << a_lon + "," + a_lat + ";" + b_lon + "," + b_lat
  return manual_coords
end

def get_directions(manual_coords, key = KEY)
  manual_url = "https://us1.locationiq.org/v1/directions/driving/#{manual_coords}?"
  query_parameters = { key: KEY, steps: true }
  return HTTParty.get(manual_url, query: query_parameters)
end

def print_directions(place1, place2)
  result = a_to_b(place1, place2)
  manual_coords = coords_a_to_b(result)
  httparty_response = get_directions(manual_coords)

  mess = httparty_response["routes"][0]["legs"][0]
  # KEYs = %w[steps weight distance summary duration]
  
  distance = mess["distance"]
  duration = mess["duration"]
  puts "TOTAL DISTANCE = #{distance} meters"
  puts "TOTAL DURATION = #{(duration.to_f/60).round} minutes"
  
  steps = mess["steps"]
  
  steps.each_with_index do |step, i|
    puts "\nSTEP ##{i+1}"
    distance = step["distance"]
    road = step["name"]
    type = step["maneuver"]["type"]
    direction = step["maneuver"]["modifier"]
    
    string = ""
    
    if type == "depart"
      string << "Depart location"
    elsif type == "arrive"
      string << "Arrived at location!"
      puts string
      break
    elsif type == "new name"
      string << "Continue #{direction}"
    else 
      string << "#{type.capitalize} #{direction}"
    end
    string << " and drive for #{distance} meters on road #{road}"
    puts string
  end
end

### THESE ARE THE EXPECTED INTERMEDIATE RESULTS
### manual_coords = "31.243666,30.048819;31.1342383751015,29.9791264"
### manual_url = "https://us1.locationiq.org/v1/directions/driving/#{manual_coords}?KEY=#{KEY}&steps=true"


# print_directions("Cairo, Egypt", "Great Pyramid of Giza")





