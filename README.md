# Paysafecard

Basic library for paysafecard payments.

## Installation

Add it to your Gemfile:

```ruby
gem 'paysafecard'
```

You probably know the rest...

## Usage

Payments with paysafecard work like this:

1. You create (authorize) a transaction with paysafecard
2. You redirect the customer to the paysafecard payment panel where the customer enters the serial numbers of his debit cards
3. The customer is then redirected back to your website and you capture the transaction to your account

With this library this is done as follows:

```ruby
transaction = Paysafecard::Transaction.new do |t|
  t.username       = 'Your_SOAP_user'
  t.password       = 'Your_SOAP_password'
  t.ok_url         = 'https://example.om/payment-received'
  t.nok_url        = 'https://example.om/payment-aborted'
  t.pn_url         = 'https://example.om/paysafecard-ipn'
  t.client_id      = customer_id # This is the ID of your customer in your database
  t.shop_id        = 'myshop'
  t.shop_label     = 'my fancy shop'
  t.amount         = 10.00
  t.transaction_id = 'order-123'
  t.currency       = 'EUR' # defaults to EUR, so this is optional
end
```

Force use of production or test systems by adding a parameter to Paysafecard::Transaction.new:

```
Paysafecard::Transaction.new('development') do |t|
  # ...
end
```

The following options are possible and/or required:
     :currency, :amount, :ok_url, :nok_url, :pn_url, :client_id, :shop_id,
     :shop_label, :username, :password, :sub_id, :mid, :transaction_id

Methods will raise an ArgumentError if not all required options are set.

After that you can authorize the transaction (this will set the MID automatically, because the MID is needed for redirecting the customer to the customer panel):

```ruby
transaction.authorize
```

Then forward the user to the customer panel:

```ruby
redirect_to transaction.payment_panel_url
```

And after the customer came back from the payment panel you capture the transaction:

```ruby
transaction.capture
```

You can also capture multiple amounts per transaction (but in sum not more than you authorized) like this:

```ruby
# lets assume you authorized an amount of 3 EUR
transaction.amount = 1
transaction.capture(false)
transaction.amount = 2
transaction.capture
```

With `capture(false)` the transaction will not be closed. If you don't close the transaction it may not be captured!

*The `authorize` and `capture` methods will raise an error if the request is not successful or returned an error code.*

## Contributing

1. Fork it ( https://github.com/[my-github-username]/paysafecard/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
