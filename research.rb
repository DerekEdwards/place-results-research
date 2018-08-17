require 'net/http'
require 'json'
require 'awesome_print'
require 'active_support/core_ext/hash'
require 'haversine'
require 'csv'

GOOGLE_API_KEY="YOURKEY"
PLACES_BASE_URL="https://maps.googleapis.com/maps/api/place/nearbysearch/json?"
DIRECTIONS_BASE_URL="https://maps.googleapis.com/maps/api/directions/json?"

  
def get_places place
  place = place.with_indifferent_access
  results = []
  next_page_token = nil
  while(true)
    url = PLACES_BASE_URL
    url += "location=#{place[:lat]},#{place[:lng]}"
    url += "&rankby=distance"
    url += "&type=library"
    url += "&fields=formatted_address,name,rating,geometry"
    url += "&key=#{GOOGLE_API_KEY}"
    if next_page_token
      url += "&pagetoken=#{next_page_token}"
    end
    uri = URI(url)
    result = JSON.parse(Net::HTTP.get(uri))
    results += result["results"]
    next_page_token = result["next_page_token"]
    sleep(2)
    if next_page_token.nil?
      break
    end
  end
  return results 
end

def get_directions origin, destination, mode="driving"
  origin = origin.with_indifferent_access
  destination = destination.with_indifferent_access
  url = DIRECTIONS_BASE_URL
  url += "origin=#{origin[:lat]},#{origin[:lng]}"
  url += "&destination=#{destination[:lat]},#{destination[:lng]}"
  url += "&mode=#{mode}"
  url += "&key=#{GOOGLE_API_KEY}"
  uri = URI(url)
  result = JSON.parse(Net::HTTP.get(uri))
  #puts result.ai 
  begin 
    return result['routes'].first["legs"].first["duration"]["value"]
  rescue
    return 10000
  end
end

def parse_results origin, results 
  CSV.open("test.csv", "wb") do |csv|
    csv << ["Origin", "Destination", "Drive", "Transit", "Distance"]
    results.each do |result|
      puts '-------------------------------------------------------------------------------'
      puts result.ai 
      destination = result["geometry"]["location"].with_indifferent_access
      driving_time = get_directions origin, destination
      transit_time = get_directions origin, destination, 'transit'
      straight_line = Haversine.distance(origin[:lat], origin[:lng], destination[:lat], destination[:lng]).to_meters
      csv << ["Work", result["name"], driving_time, transit_time, straight_line]
    end
  end
end

puts "Running Places Comparison"
#WORK origin = {lat: 42.401893, lng: -71.081521}
origin = {lat: 42.273254, lng: -71.825395}
results = get_places origin
puts "#{results.count} RESULTS WERE FOUND"
parse_results origin,results




