/**
 * Copyright © 2013-2017 Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */
define([
    'mage/translate',
    'Magento_Vault/js/view/payment/method-renderer/vault',
    'Magento_Checkout/js/model/full-screen-loader',
    'Magento_PaymentServicesPaypal/js/view/errors/response-error'
], function (
    $t,
    VaultComponent,
    loader,
    ResponseError
) {
   'use strict';

   return VaultComponent.extend({
       defaults: {
           template: 'Magento_PaymentServicesPaypal/payment/vault',
           paymentSource: 'vault',
           paypalOrderId: null,
           paymentsOrderId: null,
           generalErrorMessage: $t('An error occurred. Refresh the page and try again.'),
           paymentMethodValidationError: $t('Your payment was not successful. Try again.')
       },

       /**
        * Get card brand
        * @returns {String}
        */
       getCardBrand: function () {
           return this.mapCardBrand(this.details.brand);
       },

       /**
        * Map the credit card brand received from PayPal to the Commerce standard
        * @param payPalCardBrand
        * @returns {*}
        */
       mapCardBrand: function (payPalCardBrand) {
           const cardBrandMapping = {
               AMEX: 'AE',
               DISCOVER: 'DI',
               DINERS: 'DN',
               ELO: 'ELO',
               HIPER: 'HC',
               JCB: 'JCB',
               MAESTRO: 'MI',
               MASTER_CARD: 'MC',
               MASTERCARD: 'MC',
               VISA: 'VI'
           };

           return cardBrandMapping[payPalCardBrand];
       },

       /**
        * Get last 4 digits of card
        * @returns {String}
        */
       getMaskedCard: function () {
           return this.details.maskedCC;
       },

       /**
        * Get PayPal order ID
        */
       getData: function () {
          let data = this._super();

          data['additional_data']['paypal_order_id'] = this.paypalOrderId;
          data['additional_data']['payments_order_id'] = this.paymentsOrderId;
          data['additional_data']['public_hash'] = this.publicHash;
          data['additional_data']['payment_source'] = this.paymentSource;
          return data;
       },

       /**
        * Place order
        */
       onPlaceOrder: function () {
           loader.startLoader();
           this.createOrder()
               .then(function (order) {
                   this.onOrderSuccess(order);
               }.bind(this))
               .then(function () {
                   this.placeOrder();
               }.bind(this))
               .catch(this.onError.bind(this))
               .finally(loader.stopLoader);
       },

       /**
        * Create PayPal order
        * @returns {Promise<any>}
        */
       createOrder: function () {
           var orderData = new FormData();

           orderData.append('payment_source', this.paymentSource);

           return fetch(this.createOrderUrl, {
               method: 'POST',
               headers: {},
               body: orderData,
               credentials: 'same-origin'
           }).then(function (res) {
               return res.json();
           }).then(function (data) {
               if (data.response['is_successful']) {
                   return data.response['paypal-order'];
               }
           });
       },

       /**
        * populate PayPal order ID and trigger Commerce order flow
        * @param order
        */
       onOrderSuccess: function (order) {
           this.paypalOrderId = order['id'];
           this.paymentsOrderId = order['mp_order_id'];
       },

       /**
        * handle payment error
        * @param error
        */
       onError: function (error) {
           var message = this.generalErrorMessage;

           if (error instanceof ResponseError) {
               message = error.message;
           } else if (error['debug_id']) {
               message = this.paymentMethodValidationError;
           }

           this.messageContainer.addErrorMessage({
               message: message
           });
           console.log(error['debug_id'] ? 'Error' + JSON.stringify(error) : error.toString());
       }
   });
});
