require 'sinatra'
require 'rss'
require 'httparty'
require 'feedjira'


class HNCryptoFeed < Sinatra::Base 

  configure do
    set :keywords, YAML.load_file('keywords.yaml')['keywords']
  end

  get '/' do
    url = 'https://news.ycombinator.com/rss'
    xml = HTTParty.get(url).body
    return 404 unless xml and xml != ''
    feed = Feedjira::Feed.parse(xml)
    filtered_feed = feed.entries.map do |entry|
      words = entry.title.downcase.split(' ') 
      settings.keywords.map { |keyword| entry if words.include?(keyword) }
    end
    entries = filtered_feed.flatten.compact

    rss = RSS::Maker.make('2.0') do |maker|
      maker.channel.author = 'Marcio Klepacz'
      maker.channel.link = request.url
      maker.channel.title = 'HN Crypto'
      maker.channel.description = 'Hacker News filter for cryptocurrencies related news'
      maker.channel.updated = Time.now.to_s

      entries.each do |entry|
        maker.items.new_item do |item|
          item.link = entry.url
          item.title =  entry.title
          item.updated = entry.published
        end
      end
    end

    rss.to_s
  end
end


