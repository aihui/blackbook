require './lib/blackbook'

def test_yahoo
  yahoo = Blackbook.get :username => '<insert email address>', :password => '<insert password>'
  puts "===== yahoo #{yahoo.inspect}"
  
  # example contact info test
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
  hotmail = Blackbook.get :username => '<insert email address>', :password => '<insert password>'
  puts "===== hotmail #{hotmail.inspect}"

# example contact info test
  unless hotmail.detect{|c| c[:name].downcase == 'Aaron Greenblatt'.downcase && c[:email] == 'green3521@erols.com'}
    puts "Hotmail not working"
    exit 1
  end
end

def test_aol
  aol = Blackbook.get :username => '<insert email address>', :password => '<insert password>'
  puts "===== aol #{aol.inspect}"

  # example contact info test
  unless aol.detect{ |c| c[:name] == 'Joseph Amoyal' && 
                         c[:email] == 'jamoyal@gmail.com' &&
                         c[:mobile] == '2404173112'
                    }

    puts "AOL not working"
    exit 1
  end
end

test_aol
# puts "-------------------------------------------------------"
test_yahoo
