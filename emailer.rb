require "pony"

class Emailer
  attr_accessor :to, :options
  def initialize
    config
  end

  def send_email(subject, body)
    Pony.mail({
      to: self.to,
      via: :smtp,
      via_options: self.options,
      subject: subject,
      body: body
    })
  end

  private

  def config
    config = YAML.load_file("#{Dir.home}/.hypernova_notifier_config.yml")
    email_config = config["email"]

    if email_config.nil?
      puts "Please set up email in the config.yml."
      exit
    end

    self.to = email_config["to"]
    self.options = email_config["options"]
    if self.to.nil?
      puts "Please set an email to in the config.yml."
      exit
    elsif self.options.nil?
      puts "Please set the email options in the config.yml."
      exit
    end

    self.options = self.options.each_with_object({}) { |(key, value), hash| hash[key.to_sym] = value }
  rescue Errno::ENOENT=> e
    if e.message.include? "No such file or directory"
      puts "Please create a .hypernova_notifier_config.yml file in your home directory. See config.yml.sample"
      exit
    end
  end
end
