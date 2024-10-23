/**
 * Copyright © Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */

/* eslint-disable no-undef */
define([
    'Magento_PaymentServicesPaypal/js/view/payment/smart-buttons-cart',
    'Magento_PaymentServicesPaypal/js/view/payment/methods/smart-buttons'
], function (Component, SmartButtons) {
    'use strict';

    return Component.extend({
        defaults: {
            sdkNamespace: 'paypalApplePay',
            sdkParamsKey: 'applepay',
            fundingSource: 'applepay',
            buttonsContainerId: 'apple-pay-${ $.uid }',
            paymentRequest: {
                applepay: {
                    requiredShippingContactFields: []
                }
            },
            contactFields: [
                'postalAddress',
                'name',
                'phone',
                'email'
            ],
            virtualContactFields: [
                'name',
                'phone',
                'email'
            ]
        },

        /**
         * Check if ApplePay is available.
         *
         * @return {Promise<Object>}
         */
        getSdkParams: function () {
            if (!window.ApplePaySession) {
                return Promise.reject('Apple Pay is not supported or not available');
            }
            return this._super();
        },

        /**
         * Create instance of smart buttons.
         */
        initSmartButtons: function () {
            this.paymentRequest.applepay.requiredShippingContactFields = this.isVirtual ?
                this.virtualContactFields : this.contactFields;
            this.buttons = new SmartButtons({
                sdkNamespace: this.sdkNamespace,
                scriptParams: this.sdkParams,
                styles: this.styles,
                fundingSource: this.fundingSource,
                paymentRequest: this.paymentRequest,
                createOrderUrl: this.createOrderUrl,
                authorizeOrderUrl: this.authorizeOrderUrl,
                beforeCreateOrder: this.beforeCreateOrder,
                afterCreateOrder: this.afterCreateOrder,
                catchCreateOrder: this.catchError,
                finallyCreateOrder: this.showLoader.bind(this, false),
                beforeOnAuthorize: this.beforeOnAuthorize,
                afterOnAuthorize: this.afterOnAuthorize,
                catchOnAuthorize: this.catchError,
                finallyOnAuthorize: this.showLoader.bind(this, false),
                onError: this.catchError,
                onCancel: this.onCancel
            });
        }
    });
});
