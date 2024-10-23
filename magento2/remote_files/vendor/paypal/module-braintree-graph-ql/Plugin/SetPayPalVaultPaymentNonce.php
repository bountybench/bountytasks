<?php
/**
 * Copyright © Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */
declare(strict_types=1);

namespace PayPal\BraintreeGraphQl\Plugin;

use Exception;
use Magento\Quote\Model\Quote;
use Magento\QuoteGraphQl\Model\Cart\SetPaymentMethodOnCart;
use PayPal\Braintree\Gateway\Command\GetPaymentNonceCommand;
use Magento\Framework\GraphQl\Exception\GraphQlInputException;
use PayPal\Braintree\Model\Ui\PayPal\ConfigProvider;
use Psr\Log\LoggerInterface;

/**
 * Plugin creating nonce from Magento Vault Braintree PayPal public hash
 */
class SetPayPalVaultPaymentNonce
{
    /**
     * @var GetPaymentNonceCommand
     */
    private GetPaymentNonceCommand $command;

    /**
     * @var LoggerInterface
     */
    private LoggerInterface $logger;

    /**
     * @param GetPaymentNonceCommand $command
     * @param LoggerInterface $logger
     */
    public function __construct(GetPaymentNonceCommand $command, LoggerInterface $logger)
    {
        $this->command = $command;
        $this->logger = $logger;
    }

    /**
     * Set Braintree PayPal Vault nonce from the public hash
     *
     * @param SetPaymentMethodOnCart $subject
     * @param Quote $cart
     * @param array $paymentData
     * @return array
     * @throws GraphQlInputException
     * @SuppressWarnings(PHPMD.UnusedFormalParameter)
     */
    public function beforeExecute(
        SetPaymentMethodOnCart $subject,
        Quote $cart,
        array $paymentData
    ): array {
        if ($paymentData['code'] !== ConfigProvider::PAYPAL_VAULT_CODE
            || !isset($paymentData[ConfigProvider::PAYPAL_VAULT_CODE]['public_hash'])
        ) {
            return [$cart, $paymentData];
        }

        $nonceData = [
            'public_hash' => $paymentData[ConfigProvider::PAYPAL_VAULT_CODE]['public_hash'],
            'customer_id' => $cart->getCustomerId(),
            'store_id' => $cart->getStoreId(),
            'device_data' => $paymentData[ConfigProvider::PAYPAL_VAULT_CODE]['device_data'] ?? null
        ];

        try {
            $nonceResult = $this->command->execute($nonceData);

            if ($nonceResult === null) {
                $this->logger->critical('Failed to get Braintree PayPal Vault nonce');

                throw new GraphQlInputException(__('Sorry, but something went wrong'));
            }

            $result = $nonceResult->get();
            $paymentData[ConfigProvider::PAYPAL_VAULT_CODE]['payment_method_nonce'] = $result['paymentMethodNonce'];
        } catch (Exception $e) {
            $this->logger->critical($e);

            throw new GraphQlInputException(__('Sorry, but something went wrong'));
        }

        return [$cart, $paymentData];
    }
}
