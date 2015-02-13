require 'savon'
require 'cgi'

module Paysafecard
  class Transaction
    ENVIRONMENT       = defined?(Rails) && Rails.respond_to?(:env) ? Rails.env : (ENV["RACK_ENV"] || 'development')

    TEST_WSDL          = 'https://soatest.paysafecard.com/psc/services/PscService?wsdl'
    TEST_PAYMENT_PANEL = 'https://customer.test.at.paysafecard.com/psccustomer/GetCustomerPanelServlet?'

    LIVE_WSDL          = 'https://soa.paysafecard.com/psc/services/PscService?wsdl'
    LIVE_PAYMENT_PANEL = 'https://customer.cc.at.paysafecard.com/psccustomer/GetCustomerPanelServlet?'

    attr_accessor :currency, :amount, :ok_url, :nok_url, :pn_url, :client_id,
                  :shop_id, :shop_label, :username, :password, :sub_id, :mid,
                  :transaction_id

    # Initializes a new +transaction+ that can be authorized and captured
    # You have to set all required parameters via a block like this:
    #
    # transaction = Paysafecard::Transaction.new do |t|
    #   t.username       = 'Your_SOAP_user'
    #   t.password       = 'Your_SOAP_password'
    #   t.amount         = 10.00
    #   t.transaction_id = 'order-123'
    #   t.currency       = 'USD' (defaults to EUR!!)
    # end
    #
    # The following options are possible and/or required:
    #      :currency, :amount, :ok_url, :nok_url, :pn_url, :client_id, :shop_id,
    #      :shop_label, :username, :password, :sub_id, :mid, :transaction_id
    #
    # Methods will raise an ArgumentError if not all required options are set
    #
    # After that you can authorize the transaction (this will set the +mid+):
    #
    # transaction.authorize
    #
    # Then forward the user to the customer panel:
    #
    # redirect_to transaction.payment_panel_url
    #
    # And after receiving the IPN request (at the pn_url) you can capture the
    # transaction:
    #
    # transaction.capture
    def initialize(environment = nil)
      production          = (environment || ENVIRONMENT) == 'production'
      @payment_panel_url  = production ? LIVE_PAYMENT_PANEL : TEST_PAYMENT_PANEL
      @wsdl_url           = production ? LIVE_WSDL : TEST_WSDL
      @client             = Savon.client(wsdl: @wsdl_url)
      @currency           = 'EUR'
      yield(self) if block_given?
    end

    def payment_panel_url
      require!(:transaction_id, :amount, :currency, :mid)
      @payment_panel_url + URI.encode(panel_options.map{|k,v| "#{k}=#{v}"}.join("&"))
    end

    def authorize(set_mid = true)
      require!(:username, :password, :transaction_id, :amount, :currency,
                :ok_url, :nok_url, :pn_url, :client_id, :shop_id, :shop_label)
      result = unpack_authorize_response(@client.call(:create_disposition, message: authorize_options))
      if result[:result_code].to_i == 0 && result[:error_code].to_i == 0
        @mid = result[:mid] if set_mid
        return true
      else
        raise "Authorization failed with #{result[:result_code]}, error #{result[:error_code]}"
      end
    end

    def capture(close_transaction = true)
      require!(:username, :password, :transaction_id, :amount, :currency)
      result = unpack_capture_response(@client.call(:execute_debit, message: capture_options(close_transaction)))
      if result[:result_code].to_i == 0 && result[:error_code].to_i == 0
        return true
      else
        raise "Capture failed with #{result[:result_code]}, error #{result[:error_code]}"
      end
    end

    def status
      require!(:username, :password, :transaction_id, :currency)
      result = unpack_status_response(@client.call(:get_serial_numbers, message: status_options))
      if result[:result_code].to_i == 0 && result[:error_code].to_i == 0
        return result
      else
        raise "Status failed with #{result[:result_code]}, error #{result[:error_code]}"
      end
    end

    private

    def require!(*options)
      not_found = []
      options.each do |option|
        not_found << option if self.send(option).nil?
      end
      raise ArgumentError, "Required options missing: #{not_found.join(', ')}" if not_found.any?
    end

    def authorize_options
      {
        username:         username,
        password:         password,
        mtid:             transaction_id,
        subId:            sub_id,
        amount:           formatted_amount,
        currency:         currency,
        okUrl:            CGI.escape(ok_url),
        nokUrl:           CGI.escape(nok_url),
        pnUrl:            CGI.escape(pn_url),
        merchantclientid: client_id,
        shopId:           shop_id,
        shopLabel:        shop_label
      }
    end

    def capture_options(close_transaction)
      {
        username: username,
        password: password,
        mtid:     transaction_id,
        subId:    sub_id,
        amount:   formatted_amount,
        currency: currency,
        close:    (close_transaction ? 1 : 0)
      }
    end

    def status_options
      {
        username: username,
        password: password,
        mtid:     transaction_id,
        subId:    sub_id,
        currency: currency,
      }
    end

    def panel_options
      {
        mid:      mid,
        mtid:     transaction_id,
        amount:   formatted_amount,
        currency: currency
      }
    end

    def unpack_authorize_response(response)
      begin
        response.to_hash[:create_disposition_response][:create_disposition_return]
      rescue
        raise "Response could not be unpacked"
      end
    end

    def unpack_capture_response(response)
      begin
        response.to_hash[:execute_debit_response][:execute_debit_return]
      rescue
        raise "Response could not be unpacked"
      end
    end

    def unpack_status_response(response)
      unpack(response, [:get_serial_numbers_response, :get_serial_numbers_return])
    end

    def unpack(response, key_list)
      h = response.to_hash
      while key = key_list.shift
        begin
          h = h.fetch(key)
        rescue KeyError
          raise "Could not unpack #{key} from response"
        end
      end
      return h
    end

    def formatted_amount
      sprintf("%0.02f", @amount)
    end
  end
end
