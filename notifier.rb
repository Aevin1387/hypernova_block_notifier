require_relative "emailer"
require "mechanize"
require "nokogiri"
require "redis"
require "yaml"

class HypernovaBlockNotifier
  STATISTICS_URL = "https://hypernova.pw/statistics/"
  REDIS_BLOCK_KEY = "HYPERNOVA_LATEST_BLOCK"

  attr_accessor :emailer, :agent, :redis, :latest_known_block

  def initialize
    configure
  end

  def lookup_and_email_latest_block
    blocks = lookup_latest_block
    latest_block = blocks[:latest_block]
    previous_block = blocks[:previous_block]
    if latest_block[:block_number] == self.latest_known_block
      puts "No new block found"
      return
    end

    email_latest_block(latest_block, previous_block)
    self.redis.set(REDIS_BLOCK_KEY, latest_block[:block_number])
  end

  def lookup_latest_block
    statistics_page = agent.get(STATISTICS_URL)
    document = Nokogiri.parse(statistics_page.body).document
    latest_block = document.css("#topSite").xpath("//div[2]/div/div[1]/table[2]/tr[2]").first
    previous_block = document.css("#topSite").xpath("//div[2]/div/div[1]/table[2]/tr[3]").first
    {
      latest_block: convert_block_to_hash(latest_block),
      previous_block: convert_block_to_hash(previous_block)
    }
  end

  def email_latest_block(latest_block, previous_block)
    subject = "New block found at #{latest_block[:found_at]}."
    latest_block_found_at = DateTime.parse(latest_block[:found_at])
    previous_block_found_at = DateTime.parse(previous_block[:found_at])
    seconds_between = ((latest_block_found_at - previous_block_found_at) * 24 * 60 * 60).to_i
    body = <<-EOF
      A new block was found at #{latest_block[:found_at]}.
      This block took #{latest_block[:shares]} shares to find.
      This block took #{seconds_to_human_time(seconds_between)} to find.
    EOF

    self.emailer.send_email(subject, body)
  end

  private
  def seconds_to_human_time(seconds)
    hours = seconds / (60 * 60)
    seconds = seconds % (60 * 60)
    minutes = seconds / 60
    seconds = seconds % 60
    "#{hours} hours, #{minutes} minutes, #{seconds} seconds"
  end

  def convert_block_to_hash(block)
    {
      block_number: block.children.first.text,
      coins_remaining: block.children.first.children.first.attributes["title"].value,
      found_at: block.children[4].children.first.attributes["title"].value,
      shares: block.children[6].text
    }
  end

  def configure
    configure_email
    configure_redis
    self.agent = Mechanize.new
  end

  def configure_email
    self.emailer = Emailer.new
  end

  def configure_redis
    self.redis = Redis.new
    self.latest_known_block = self.redis.get(REDIS_BLOCK_KEY)
  end
end

HypernovaBlockNotifier.new.lookup_and_email_latest_block
