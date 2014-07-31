require 'mechanize'
require 'dropbox_sdk'
require 'dotenv'
require 'date'

Dotenv.load

campfire_domain = ENV.fetch('CAMPFIRE_DOMAIN')

agent = Mechanize.new
sign_in_page = agent.get("https://#{campfire_domain}.campfirenow.com/login")
sign_in_page.form_with(action: 'https://launchpad.37signals.com/authentication') do |sign_in_form|
  sign_in_form['username'] = ENV.fetch('CAMPFIRE_EMAIL')
  sign_in_form['password'] = ENV.fetch('CAMPFIRE_PASSWORD')
end.submit

account_details_page = agent.get("https://#{campfire_domain}.campfirenow.com/subscription/manage")
latest_invoice_link_html = account_details_page.at('.section.invoices ul li:first a')
latest_invoice_link = Mechanize::Page::Link.new(latest_invoice_link_html, agent, account_details_page)
latest_invoice_file = latest_invoice_link.click

invoice_date = Date.parse(latest_invoice_link.text[-12..-1])
invoice_number = latest_invoice_file.body[/Invoice #: (\d+)$/, 1]
invoice_filename = "#{invoice_date} 37 Signals - Campfire - Invoice #{invoice_number}.txt"

dropbox_client = DropboxClient.new(ENV.fetch('DROPBOX_ACCESS_TOKEN'))
dropbox_client.put_file(invoice_filename, latest_invoice_file.body)
