class HomeController < ApplicationController

  def show
    render({:template => "input_form"})
  end


end
