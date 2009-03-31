require 'blackbook/importer/page_scraper'
require 'fastercsv'

##
# contacts importer for Yahoo!

class Blackbook::Importer::Yahoo < Blackbook::Importer::PageScraper

  ##
  # Matches this importer to an user's name/address

  def =~(options = {})
    options && options[:username] =~ /@yahoo.com$/i ? true : false
  end
  
  ##
  # login for Yahoo!

  def login
    page = agent.get('https://login.yahoo.com/config/login_verify2?')
    form = page.forms.first
    form.login = options[:username].split("@").first
    form.passwd = options[:password]
    page = agent.submit(form, form.buttons.first)
    
    # Check for login success
    raise( Blackbook::BadCredentialsError, "That username and password was not accepted. Please check them and try again." ) if page.body =~ /Invalid ID or password./
    true
  end
  
  ##
  # prepare the importer

  def prepare
    login
  end
  
  ##
  # scrape yahoo contacts

  def scrape_contacts
    page = agent.get("http://address.yahoo.com/?1=&VPC=import_export")
    if page.body =~ /To access Yahoo! Address Book\.\.\..*Sign in./m
      raise( Blackbook::BadCredentialsError, "Must be authenticated to access contacts." )
    end
    form = page.forms.last
    csv = agent.submit(form, form.buttons[2]) # third button is Yahoo-format CSV
    
    contact_rows = FasterCSV.parse(csv.body)
    
    labels = contact_rows.shift # TODO: Actually use the labels to find the indexes of the data we want
    # puts labels.inspect
    
    _FIRST = labels.index("First")
    _LAST = labels.index("Last")
    _EMAIL = labels.index("Email")
    _MESSENGER_ID = labels.index("Messenger ID")
    _MOBILE = labels.index("Mobile")
    _HOME_ZIP = labels.index("Home ZIP")
    _WORK_ZIP = labels.index("Work ZIP")
    _HOME_CITY = labels.index("Home City")
    _WORK_CITY = labels.index("Work City")
    _HOME_STATE = labels.index("Home State")
    _WORK_STATE = labels.index("Work State")
    
    contact_rows.collect do |row|
      # Add this condition in the loop below if you care about collecting yourself
      # next if !row[7].empty? && options[:username] =~ /^#{row[7]}/ # Don't collect self
      
      #collect the contact if we have email address OR mobile #
      next if row[_EMAIL].empty? && row[_MESSENGER_ID].empty? && row[_MOBILE].empty? 
      {
        :name  => "#{row[_FIRST]} #{row[_LAST]}".to_s,
        :email => (row[_EMAIL] || "#{row[_MESSENGER_ID]}@yahoo.com"),
        :mobile => row[_MOBILE],
        :home_zip => row[_HOME_ZIP],
        :work_zip => row[_WORK_ZIP],
        :home_city => row[_HOME_CITY],
        :work_city => row[_WORK_CITY],
        :home_state => row[_HOME_STATE],
        :work_state => row[_WORK_STATE]
      }
    end
  end
  
  Blackbook.register(:yahoo, self)
end
