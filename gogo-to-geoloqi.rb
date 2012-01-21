require 'geoloqi'
require 'httparty'
require 'date'

# Your permanent Geoloqi access token
# Get your access token from https://developers.geoloqi.com/client-libraries/Ruby
permanent_token = ''

geoloqi = Geoloqi::Session.new :access_token => permanent_token

while true do 
  flight_stats = HTTParty.get 'http://airborne.gogoinflight.com/abp/service/statusTray.do'

  # Parse the almost-JSON from the flight tracker. I couldn't actually figure out why a JSON parser complained about it
  data = {}
  if m=(flight_stats.scan /([a-zA-Z]+):'([^']+)'/m)
    m.each do |i|
      data[i[0]] = i[1]
    end
  end

  if data['latitude']
    # Now send the data to Geoloqi!
    puts geoloqi.post 'location/update', [{
      :date => DateTime.now.to_s,
      :location => {
        :position => {
          :latitude => data['latitude'],
          :longitude => data['longitude'],
          :speed => data['hSpeed'].to_i * 3.6,
          :altitude => data['altitude'],
          :horizontal_accuracy => 100
        },
        :type => 'point'
      },
      :raw => {
        :origin => data['origin'],
        :destination => data['destination'],
        :airlineName => data['airlineName'],
        :flightNumber => data['flightNumber'],
        :quality => data['quality'],
        :tailNumber => data['tailNumber'],
        :expectedArrival => (DateTime.parse data['expectedArrival']).to_s
      }
    }]
  end

  sleep 5
end
