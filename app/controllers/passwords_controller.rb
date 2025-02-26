class PasswordsController < ApplicationController

  ### CONSTANTS ###

  LETTERS = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q",
           "r","s","t","u","v","w","x","y","z"]

  ALPHA_NUMER = {'a' => 1,'b' => 2,'c' => 3,'d' => 4,'e' => 5,'f' => 6,'g' => 7, 'h' => 8,'i' => 9,
                'j' => 10,'k' => 11,'l' => 12,'m' => 13,'n' => 14,'o' => 15,'p' => 16,'q' => 17,
                'r' => 18,'s' => 19,'t' => 20,'u' => 21,'v' => 22,'w' => 23,'x' => 24,'y' => 25,
                'z' => 26}

  ALPHA_NUMER_STRINGS = {'a' => '1','b' => '2','c' => '3','d' => '4','e' => '5','f' => '6',
                        'g' => '7','h' => '8','i' => '9','j' => '10','k' => '11','l' => '12',
                        'm' => '13','n' => '14','o' => '15','p' => '16','q' => '17','r' => '18',
                        's' => '19','t' => '20','u' => '21','v' => '22','w' => '23','x' => '24',
                        'y' => '25','z' => '26'}

  SAMPLE_TEXT = "The Lord is my shepherd, I shall not want."

  ##################


  # Building Blocks Functions #

  def calculate_anchor(year)
    if year % 400 < 100
      anchor = 2
    elsif (year - 100) % 400 < 100
      anchor = 0
    elsif (year - 200) % 400 < 100
      anchor = 5
    elsif (year - 300) % 400 < 100
      anchor = 3
    end
    return anchor
  end

  def doomsday(year)
    anchor = calculate_anchor(year)
    year_str = year.to_s
    y = (year_str[-2..]).to_i
    a = y / 12
    b = y % 12
    c = (y % 12) / 4

    doomsday = ((a+b+c) % 7 + anchor) % 7
    return doomsday
  end

  def mod7_mod10(num)
    """Convert a mod 7 number into mod 10"""
    mod7_str = num.to_s
    power = 0
    partial_sums = []

    (mod7_str.length - 1).downto(0) do |digit|
      partial_sum = mod7_str[digit].to_i * (7**power)
      partial_sums << partial_sum
      power += 1
    end
  
    mod10 = partial_sums.sum
    return mod10
  end

  def download_image(url, save_as="image.jpg"):
    urllib.request.urlretrieve(url, save_as)
  end

  
  ### Decoding Functions ###

    
  def text_to_number_first(text)
    number_string = ""
    text.chars.each do |char|
      if char.match?(/\A[a-zA-Z]+\z/)
        number_string += ALPHA_NUMER_STRINGS[char.downcase]
      end
    end
    return number_string
  end

  def image_to_number_first(im)
    width, height = im.size
    mid = height // 2
    number_str = ""
    for x in range(width):
      r,g,b = im.getpixel((x, mid))
      number_str += str(r+g+b)
    return number_str
  end

  def number_to_years(number_string: str, n: int) -> list[str]:
    years = [number_string[i:i+n] for i in range(0, len(number_string), n)]
    return years

  def years_list_to_doomsdays(years_list: list[str]) -> list[int]:
    doomsdays = []
    for year_str in years_list:
        year = int(year_str)
        doomsdays.append(doomsday(year))
    # print(f"These are the doomsdays: {doomsdays}")
    return doomsdays

  def ddays_modded_joined(ddays_list: list[int]) -> str:
    """
    Since the ddays only range from 0 to 6, we will modify the numbers, ensuring
    variety in all digits. We will do so by (1) joining the ddays into 3-digit
    numbers, and (2) converting these 3-digit mod7 numbers into mod10. Also, we
    will take this list of numbers and convert in into a joined string of numbers
    """
    ddays_strings = [str(dday) for dday in ddays_list]
    ddays_joined_str = "".join(ddays_strings)
    ddays_3s = number_to_years(ddays_joined_str, 3) # a list of 3dig str nums
    
    mod10_list = []
    for mod7 in ddays_3s:
        mod10_list.append(mod7_mod10(str(mod7)))

    mod10_strings = [str(mod10) for mod10 in mod10_list]
    modded_joined = "".join(mod10_strings)

    return modded_joined

  def number_str_to_ascii(number_string: str) -> list[int]:
    ### The characters we want range from 33 to 126 in ASCII codes
    # So, for simplicity, we will just take 2-digit numbers in the sequence,
    # and we will negate the number if it is greater than 93 (126-33)
    doubles = [int(number_string[i:i+2]) for i in range(0, len(number_string), 2)]
    for number in doubles:
        if number > 93:
            doubles.remove(number)
    ascii_codes = [number + 33 for number in doubles]
    return ascii_codes

  def ascii_codes_to_password(ascii_codes: list[int]) -> str:
    password = ""
    for code in ascii_codes:
        password += chr(code)
    return password


  # Execution of Decoding #

  def decode(input, complexity: int) -> str:
    """Given a sample body of text or image, use a special set of pre-dictated
    rules to reveal the secret code. The complexity is  the number of digits
    in the years computed in the early steps"""

    if isinstance(input, str):
        first_number_string = text_to_number_first(input)
    else:
        first_number_string = image_to_number_first(input)

    years_list = number_to_years(first_number_string, complexity)
    doomsdays = years_list_to_doomsdays(years_list)
    modded_joined = ddays_modded_joined(doomsdays)
    ascii_codes = number_str_to_ascii(modded_joined)

    password = ascii_codes_to_password(ascii_codes)
    return password

  def decode_url(url: str, complexity: int) -> str:
    download_image(url, "image.jpg")
    img = Image.open("image.jpg")
    password = decode(img, complexity)
    return password
  end




end





# Debugging Help #

def generate_rand_ddays(len: int):
    """Generates a list of random ddays of desired length"""
    ddays = []
    for _ in range(len):
        ddays.append(random.randint(0,6))
    return ddays
    
### Useful debug strategy below ###
# ddays_book = []
# for i in range(25):
#     ddays_book.append(generate_rand_ddays(30))

# for ddays in ddays_book:
#     print(ddays_modded_joined(ddays))
#####################




#%%
# Examples #
SAMPLE_TEXT = "The Lord is my shepherd, I shall not want."
print(decode(SAMPLE_TEXT, 4))

# SAMPLE_IMAGE = Image.open("ronald_reagan.jpg")
# print(decode(SAMPLE_IMAGE, 220))

###

# image_url = "https://www.baseball-reference.com/req/202408150/images/headshots/e/e463317c_sabr.jpg"

# decode_url(image_url, 100)
