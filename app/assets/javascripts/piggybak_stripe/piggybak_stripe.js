function stripeResponseHandler(status, response) {
  console.log(status);
  console.log(response);
  if (response.error) {
    $('#new_order input:submit').removeAttr("disabled");
    $("#stripe_error").html(response.error.message);
  } else {
    var form$ = $("#new_order");
    var token = response['id'];
    $('.stripe_token').attr('value',token);
    form$.submit();
  }
}

function submitToStripe() {
  $('#new_order input:submit').attr("disabled", "disabled");
  var params = {
    number: $('.card-number').val(),
    cvc: $('.card-cvc').val(),
    exp_month: $('.card-expiry-month').val(),
    exp_year: $('.card-expiry-year').val()
  };
  console.log(params);
  Stripe.createToken(params, stripeResponseHandler);
  return false;
}
$(function() {
  $('#new_order input[type=submit]').bind('click', function(e) {
    e.preventDefault()
    submitToStripe();
  });
});
