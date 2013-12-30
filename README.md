Hypernova Block Notifier
=====
A ruby application to check if hypernova has found a new block.


Initial setup
-------------
Copy the ```config.yml.sample``` to ```~/.hypernova_notifier_config.yml```

Modify the config file to match your email configuration.

Requirements
---
* Ruby 2.0
* Bundler
* Redis

Running the app
---
You can run the app by simply running it with ruby. It will only run once, so you may wish to set up a cron job to run it ever hour or 15 minutes.