require "json"
require "uri"
require "net/http"
require "rexml/document"
require "open-uri"
require "csv"
require "date"

class Weather

  WEATHER_URL = 'http://weather.livedoor.com/forecast'

  def index
    url = "#{WEATHER_URL}/rss/primary_area.xml"
    doc = REXML::Document.new(open(url).read)
    loc_hash = {}
    doc.elements.each('//rss/channel/ldWeather:source/pref/city') do |elm|
      loc_hash[elm.attributes['id']] = elm.attributes['title']
    end
    return loc_hash
  end

  def execute
    weather_ins = Weather.new
    loc_hash = weather_ins.index
    array_list = []
    loc_hash.each do |key, val|
      json = weather_ins.get(key)
      array = [val, key]
      array += weather_ins.format(json)
      array_list.push(array)
    end
    weather_ins.create_file(array_list)
  end

  def get(loc_id)
    uri = URI.parse("#{WEATHER_URL}/webservice/json/v1?city=#{loc_id}")
    json = Net::HTTP.get(uri)
    return JSON.parse(json)
  end

  def format(json)
    date = json['forecasts'][0]['date']
    telop = json['forecasts'][0]['telop']
    tmp_max = json['forecasts'][0]['temperature']['max']
    tmp_max.nil? ? max = '' : max = tmp_max['celsius']
    return [date, telop, max]
  end

  def create_file(array_list)
    CSV.open("weather_#{Date.today.strftime("%Y-%m-%d")}.csv", "wb", encoding: "SJIS") do |row|
      row << ["地域名", "地域ID", "予報日", "天気", "最高気温"]
      array_list.each do |array|
        row << array
      end
    end
  end

end

Weather.new.execute