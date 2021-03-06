module PiggybakStripe
  module PaymentDecorator
    extend ActiveSupport::Concern

    included do
      validates :stripe_token, presence: true

      attr_accessor :stripe_token

      def process(order)
        return true if !self.new_record?
        calculator = ::PiggybakStripe::PaymentCalculator::Stripe.new(self.payment_method)
        Stripe.api_key = calculator.secret_key
        begin
          charge = Stripe::Charge.create({
            :source => self.stripe_token,
            :amount => (order.total_due * 100).to_i,
            :currency => "usd"
          })
          self.attributes = { :transaction_id => charge.id, :masked_number => charge.source.last4 }
          # self.send :remove_instance_variable, :stripe_token
          return true
        rescue Stripe::CardError, Stripe::InvalidRequestError => e
          self.errors.add :payment_method_id, e.message
          return false
        end
      end
    end
  end
end
