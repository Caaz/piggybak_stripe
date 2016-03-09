module PiggybakStripe
  module PaymentDecorator
    extend ActiveSupport::Concern

    included do
      attr_accessor :stripe_token
      #attr_accessible :stripe_token

      # validates :stripe_token, presence: true
      # validates_presence_of :stripe_token, :on => :create

      [:month, :year, :payment_method_id].each do |field|
        _validators.reject{ |key, _| key == field }

        _validate_callbacks.reject do |callback|
          callback.raw_filter.attributes == [field]
        end
      end

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

          self.attributes = { :transaction_id => charge.id,
                              :masked_number => charge.card.last4 }
          return true
        rescue Stripe::CardError, Stripe::InvalidRequestError => e
          self.errors.add :payment_method_id, e.message
          return false
        end
      end
    end
  end
end
