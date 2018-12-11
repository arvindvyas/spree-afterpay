module Spree
  class Gateway::Afterpay < Gateway
    preference :login, :string
    preference :password, :string
    preference :merchant_code, :string
    preference :merchant_api_key, :string
    preference :endpoint, :string
    preference :shopper_portal_url, :string
    preference :merchant_url, :string
    preference :merchant_portal_user, :string
    preference :test_mode, :boolean

    def provider_class
      Spree::Gateway::Afterpay
    end

    ## change method type
    def method_type
      'afterpay'
    end

    def source_required?
      false
    end

    def header
      user_agent = '<pluginOrModuleOrClientLibrary>/<pluginVersion> (<platform>/<platformVersion>; Merchant/<merchantId>)'
      authorization = 'Basic' + ' ' + preferred_merchant_api_key
      header = { content_type: 'application/json', user_agent: user_agent, authorization: authorization, accept: 'application/json' }
    end

    def purchase(order)
      RestClient::Request.execute(method: :post, url: "#{preferred_endpoint}/orders", payload: JSON.dump(build_order(order)), headers: header)
    end


    def capture(order, token, payer_id)
       payment =  begin
        response = RestClient::Request.execute(method: :post, url: "#{preferred_endpoint}/payments/capture", payload: JSON.dump(valid_payments_token(order, token)), headers: header)
        payment = JSON.parse(response)
      rescue RestClient::PaymentRequired => e
        payment = {'status'=> e.to_s}
      end
      if payment['status'] == 'APPROVED'
        order.payments.create!(
          source: Spree::AfterpayCheckout.create(
            token: token,
            payer_id: payer_id,
            transaction_id: payment['id']
          ),
          amount: order.total,
          payment_method_id: self.id,
          state:  'completed'
        )
        payment['status']
      else
        payment['status']
      end
    end



    def refund(payment, amount)
      refund_type = payment.amount == amount.to_f ? "Full" : "Partial"
      refund_transaction_response = refund_order(payment, payment.order.number, amount)
      if refund_transaction_response.code == 201
        refund_transaction = JSON.parse(refund_transaction_response)

        payment.source.update_attributes({
          :refunded_at => Time.now,
          :refund_transaction_id => refund_transaction["refundId"],
          :state => "refunded",
          :refund_type => refund_type
        })

        payment.class.create!(
          :order => payment.order,
          :source => payment,
          :payment_method => payment.payment_method,
          :amount => amount.to_f.abs * -1,
          :response_code => refund_transaction["refundId"],
          :state => 'completed'
        )
        refund_transaction
      end
    end

    def cancel(authorization)
      if void_refund(authorization)
        ActiveMerchant::Billing::Response.new(true, 'Payment has successfully canceled', {}, {})
      else
        ActiveMerchant::Billing::Response.new(false, "Payment can't perform cancel", {}, {})
      end
    end

    def void(authorization, options = {})
      payment = Spree::Payment.find_by_response_code(authorization)
      if payment.refunds.present? && payment.refunds.map(&:amount).sum == payment.amount
        ActiveMerchant::Billing::Response.new(false, 'Payment has already been refunded.', {})
      elsif payment.state == 'completed'
        ActiveMerchant::Billing::Response.new(false, "Payment can't perform 'Void' action after 'Catpure'.", {})
      else
        provider(authorization, options).void(authorization, options)
      end
    end

    private

    def refund_order(payment, number, amount)
      request =  {
        requestId: payment.source.token,
          amount: {
            amount: amount,
            currency: payment.currency
          },
          merchantReference: number
      }
      RestClient::Request.execute(method: :post, url: "#{preferred_endpoint}/payments/#{payment.source.transaction_id}/refund", payload: JSON.dump(request), headers: header)
    end

    def build_order(order)
      { totalAmount: {
        amount: order.total.to_s,
        currency: order.currency
      },

        consumer: {
          phoneNumber: order.shipping_address.phone,
          givenNames: order.shipping_address.firstname,
          surname: order.shipping_address.lastname,
          email: order.email
        },
        billing: billing_address(order),
        shipping: shipping_address(order),
        items: line_items(order),
        discounts: promotions(order),
        merchant: {
          redirectConfirmUrl: "#{Spree::Store.current.url}/afterpay/confirm?payment_method_id=#{id}",
          redirectCancelUrl: "#{Spree::Store.current.url}/afterpay/cancel?payment_method_id=#{id}"
        },
        merchantReference: order.number,
        taxAmount: tax_amount(order),
        shippingAmount: shipping_amount(order) }
    end

    def line_items(order)
      line = []
      order.line_items.each do |item|
        line << { "name": item.name, "sku": item.sku, "quantity": item.quantity, "price": { "amount": item.price.to_s, "currency": item.currency } }
      end
      line
    end

    def promotions(order)
      promo = []
      if  order.promotions.present?
        promo << { "displayName": order.promotions.map(&:description), "amount": { "amount": order.promo_total.abs.to_f, "currency": order.currency } }
      end
      promo
    end

    def billing_address(order)
      billing = order.billing_address
      { name: billing.full_name, line1: billing.address1, ine2: billing.address2, suburb: billing.state.name, state: billing.state.abbr, postcode: billing.zipcode, countryCode: billing.country.iso, phoneNumber: billing.phone.to_s }
    end

    def shipping_address(order)
      billing = order.shipping_address
      { name: billing.full_name, line1: billing.address1, line2: billing.address2, suburb: billing.state.name, state: billing.state.abbr, postcode: billing.zipcode, countryCode: billing.country.iso, phoneNumber: billing.phone.to_s }
    end

    def valid_payments_token(order,token)
      { token: token, merchantReference: order.number }
    end

    def tax_amount(order)
      additional_adjustments = order.all_adjustments.additional
      tax_adjustments = additional_adjustments.tax
      if tax_adjustments.present?
        {  amount: tax_adjustments.map(&:amount).sum.to_f, currency: order.currenc }
      else
        {  "amount": '0', "currency": 'USD' }
      end
    end

    def shipping_amount(order)
      additional_adjustments = order.all_adjustments.additional
      shipping_adjustments = additional_adjustments.shipping
      if shipping_adjustments.present?
        {  amount: shipping_adjustments.map(&:amount).sum.to_f, currency: order.currency }
      else
        {  amount: '0', currency: 'USD' }
      end
    end

  end
end
