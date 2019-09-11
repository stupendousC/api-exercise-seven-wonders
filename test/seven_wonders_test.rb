require_relative "test_helper"

####### If you expect the response data to change, you must delete the cassette file. #######

describe "TESTING get_location" do
  
  it "can find a location" do
    # VCR to check location_find.yml in the folder specified under config.cassette_library_dir in test_helper.rb
    
    VCR.use_cassette("location_find") do
      location = "Seattle"
      response = get_location(location)
      expect(response).wont_be_nil      
      expect(response[0]["lon"]).must_equal "-122.3300624"
      expect(response[0]["lat"]).must_equal "47.6038321"
    end
  end
  
  it "will raise an exception if the search fails" do
    VCR.use_cassette("location_find") do
      expect { response = get_location("") }.must_raise SearchError
    end
  end
end



describe "TESTING reverse_geocode" do
  it "Does reverse_geocode return expected location name?" do
    VCR.use_cassette("location_find") do
      numbers= [ { lat: 38.8976998, lon: -77.0365534886228}, {lat: 48.4283182, lon: -123.3649533 },  { lat: 41.8902614, lon: 12.493087103595503} ]
      answers = [ "1600, Pennsylvania Avenue Northwest, White House Grounds, Washington, District of Columbia, District of Columbia, United States, 20006", "The Hands of Time: Carrying Books, Chinatown, Victoria, Capital, British Columbia, Canada", "Colosseo/Salvi, San Paolo, Rome, Roma, Italy"]
      numbers.each_with_index do |coords_hash, index|
        location = reverse_geocode(coords_hash[:lon], coords_hash[:lat])
        # ap location
        assert(location == answers[index])
      end
    end
  end
end



describe "TESTING print_directions" do
  it "Does print_directions work?" do
    VCR.use_cassette("location_find") do
      result = a_to_b("Great Pyramid of Giza", "Great Pyramid of Giza")
      manual_coords = coords_a_to_b(result)
      httparty_response = get_directions(manual_coords)
      assert(httparty_response.class == HTTParty::Response)
      assert(httparty_response.code == 200)
      
      # will actually print out all the directions here... just eyeball it haha
      print_directions("Cairo, Egypt", "Great Pyramid of Giza")
    end
  end
end

