Deface::Override.new(
  virtual_path: 'spree/checkout/_payment',
  name: 'Add afterpay script on payment page',
  insert_before: '[data-hook="payment_fieldset_wrapper"]',
  text: '<%= render "spree/checkout/payment/afterpay_checkout"%>'
)
