require 'blackbook/importer/page_scraper'

##
# Imports contacts from AOL

class Blackbook::Importer::Aol < Blackbook::Importer::PageScraper

  ##
  # Matches this importer to an user's name/address

  def =~( options )
    options && options[:username] =~ /@(aol|aim)\.com$/i ? true : false
  end
  
  ##
  # Login process:
  # - Get mail.aol.com which redirects to a page containing a javascript redirect
  # - Get the URL that the javascript is supposed to redirect you to
  # - Fill out and submit the login form
  # - Get the URL from *another* javascript redirect

  def login
    page = agent.get( 'http://webmail.aol.com/' )

    # This line seems to have problems, not sure why
    # form = page.forms.name('AOLLoginForm').first
    
    # Try this method
    form = nil
    page.forms.each do |f|
      if f.name == 'AOLLoginForm' then form = f end
    end
        
    form.loginId = options[:username].split('@').first # Drop the domain
    form.password = options[:password]
    page = agent.submit(form, form.buttons.first)

    # Fix by Tony Amoyal (I have seen forms with both of these names upon bad login)
    raise( Blackbook::BadCredentialsError, "That username and password was not accepted. Please check them and try again." ) if page.form('loginForm')
    raise( Blackbook::BadCredentialsError, "That username and password was not accepted. Please check them and try again." ) if page.form('AOLLoginForm')

    # Fix by Tony Amoyal (We don't seem to need this anymore)
    # aol bumps to a wait page while logging in.  if we can't scrape out the js then its a bad login
    # wait_url = page.body.scan(/onLoad="checkError[^\)]+/).first.scan(/'([^']+)'/).last.first
    # page = agent.get wait_url

    base_uri = page.body.scan(/^var gSuccessPath = \"(.+)\";/).first.first
    raise( Blackbook::BadCredentialsError, "You do not appear to be signed in." ) unless base_uri
    page = agent.get base_uri
  end
  
  ##
  # must login to prepare

  def prepare
    login
  end
  
  ##
  # The url to scrape contacts from has to be put together from the Auth cookie
  # and a known uri that hosts their contact service. An array of hashes with
  # :name and :email keys is returned.

  def scrape_contacts
    unless auth_cookie = agent.cookies.find{|c| c.name =~ /^Auth/}
      raise( Blackbook::BadCredentialsError, "Must be authenticated to access contacts." )
    end
    
    # jump through the hoops of formulating a request to get printable contacts
    uri = agent.current_page.uri.dup
    inputs = agent.current_page.search("//input")
    user = inputs.detect{|i| i['type'] == 'hidden' && i['name'] == 'user'}
    utoken = user['value']

    path = uri.path.split('/')
    path.pop
    path << 'addresslist-print.aspx'
    uri.path = path.join('/')
    uri.query = "command=all&sort=FirstLastNick&sortDir=Ascending&nameFormat=FirstLastNick&user=#{utoken}"
    page = agent.get uri.to_s

    contacts = []
    email, mobile = "",""
    
    names = page.search("//span[@class='fullName']")
    
    # Every contact has a fullName node, so for each fullName node, we grab the chunk of contact info
    names.each do |n|

      # next_sibling.next_sibling skips:
      # <tr>
      #   <td class=\"sectionHeader\">Contact</td>
      #	  <td class=\"sectionHeader\">Phone</td>
      #   <td class=\"sectionHeader\">Home</td>
      #	  <td class=\"sectionHeader\">Work</td>
      # </tr>
      # to give us the actual chunk of contact information
      # then taking the children of that chunk gives us rows of contact info
      contact_info_rows = n.parent.parent.next_sibling.next_sibling.children
      
      # Iterate through the rows of contact info
      contact_info_rows.each do |row|
        
        # Iterate through the contact info in each row
        row.children.each do |info|
          # Get Email. There are two ".next_siblings" because space after "Email 1" element is processed as a sibling
          if info.content.strip == "Email 1:" then email = info.next_sibling.next_sibling.content.strip end
          
          # If the contact info has a screen name but no email, use screenname@aol.com
          if (info.content.strip == "Screen Name:" && email == "") then email = info.next_sibling.next_sibling.content.strip + "@aol.com" end
          
          # Get Mobile #'s
          if info.content.strip == "Mobile:" then mobile = info.next_sibling.content.strip end
            
          # Maybe we can try and get zips later.  Right now the zip field can look like the street address field
          # so we can not tell the difference.  There is no label node
          #zip_match = /\A\D*(\d{5})-?\d{4}\D*\z/i.match(info.content.strip) 
          #zip_match = /\A\D*(\d{5})[^\d-]*\z/i.match(info.content.strip)     
        end  
        
      end
       
      contacts << { :name => n.content, :email => email, :mobile => mobile }
      
      # clear variables
      email, mobile = "", ""
    end
    
    contacts
  end
  
  Blackbook.register :aol, self
end
