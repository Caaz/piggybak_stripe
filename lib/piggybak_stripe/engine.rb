require 'piggybak_stripe/payment_decorator'

module PiggybakStripe
  class Engine < ::Rails::Engine
    isolate_namespace PiggybakStripe
    require 'stripe'

    config.to_prepare do
      Piggybak::Payment.send(:include, ::PiggybakStripe::PaymentDecorator)
      Piggybak::OrdersController.class_eval do
        # Bound to break everything if piggybak ever updates.
        private
        def orders_params
          nested_attributes = [
            shipment_attributes: [:shipping_method_id],
            payment_attributes: [:number, :verification_value, :month, :year, :stripe_token]
          ].first.merge(Piggybak.config.additional_line_item_attributes)
          line_item_attributes = [:sellable_id, :price, :unit_price, :description, :quantity, :line_item_type, nested_attributes]
          params.require(:order).permit(:user_id, :email, :phone, :ip_address,
            billing_address_attributes: [:firstname, :lastname, :address1, :location, :address2, :city, :state_id, :zip, :country_id],
            shipping_address_attributes: [:firstname, :lastname, :address1, :location, :address2, :city, :state_id, :zip, :country_id, :copy_from_billing],
            line_items_attributes: line_item_attributes)
        end
      end
    end

    initializer "piggybak_realtime_shipping.add_calculators" do
      Piggybak.config do |config|
        #Ensures that stripe is the only calculator because Piggybak
        #only supports one active calculator
        config.payment_calculators = ["::PiggybakStripe::PaymentCalculator::Stripe"]
      end
    end
  end
end
