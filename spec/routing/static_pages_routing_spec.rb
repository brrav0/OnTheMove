require "rails_helper"

RSpec.describe StaticPagesController, type: :routing do
  describe "routing" do

    it "routes to #home" do
      expect(:get => "/home").to route_to("static_pages#home")
    end

    it "routes to #about" do
      expect(:get => "/about").to route_to("static_pages#about")
    end

    it "routes to #contact" do
      expect(:get => "/contact").to route_to("static_pages#contact")
    end

    it "routes to #terms and conditions" do
      expect(:get => "/terms_and_conditions").to route_to("static_pages#terms_and_conditions")
    end


  end
end

