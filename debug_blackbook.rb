require './lib/blackbook'

def test_yahoo
  yahoo = Blackbook.get :username => "tonyamoyal@yahoo.com", :password => "Jakids5981"
  # puts "===== yahoo #{yahoo.inspect}"
  
  unless yahoo.detect{ |c| c[:name].downcase == 'AAA AAB'.downcase &&
                           c[:email] == '2404173112@vtext.com' &&
                           c[:mobile] == '(240) 417 3112' &&
                           c[:home_zip] == '38947' &&
                           c[:work_zip] == '21093' &&
                           c[:home_city].downcase == 'San Jose'.downcase &&
                           c[:work_city].downcase == 'Baltimore'.downcase &&
                           c[:home_state].downcase == 'TX'.downcase &&
                           c[:work_state].downcase == 'MD'.downcase 
                      }
    puts "Yahoo import not working"
    exit 1
  end
end

def test_hotmail
  hotmail = Blackbook.get :username => "sauce2222@hotmail.com", :password => "heather"
  puts "===== hotmail #{hotmail.inspect}"

  unless hotmail.detect{|c| c[:name].downcase == 'Aaron Greenblatt'.downcase && c[:email] == 'green3521@erols.com'}
    puts "Hotmail not working"
    exit 1
  end
end

def test_aol
  aol = Blackbook.get :username => 'corgan1003@aol.com', :password => 'jakids'
  # puts "===== aol #{aol.inspect}"

  unless aol.detect{ |c| c[:name].downcase == 'Joseph Amoyal'.downcase && 
                         c[:email] == 'wiggles100@aol.com' &&
                         c[:mobile] == '4436109080'
                    }
    puts "AOL not working"
    exit 1
  end
end

test_aol
# puts "-------------------------------------------------------"
test_yahoo
