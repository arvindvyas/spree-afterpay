Deface::Override.new(
  virtual_path: 'spree/admin/payment_methods/_form',
  name: 'Use custom form partial for afterpay payment method',
  surround: '[data-hook="admin_payment_method_form_fields"]',
  text: '<% if @object.kind_of?(Spree::Gateway::Afterpay) %>
           <%= render "afterpay_form", f: f %>
         <% else %>
           <%= render_original %>
         <% end %>'
)
