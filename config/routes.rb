Rails.application.routes.draw do

  # This is a blank app! Pick your first screen, build out the RCAV, and go from there. E.g.:

  # get "/your_first_screen" => "pages#first"

  get("/", {:controller => "home", :action => "show"})

  post("/generate_password", {:controller => "passwords", :action => "generate_password"})

  get("/password", {:controller => "passwords", :action => "show"})
  
end
