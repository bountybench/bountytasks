<?php
/**
 * Copyright © Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */
declare(strict_types=1);

namespace PayPal\BraintreeGraphQl\Model;

use Magento\Framework\GraphQl\Exception\GraphQlInputException;
use Magento\QuoteGraphQl\Model\Cart\Payment\AdditionalDataProviderInterface;
use PayPal\Braintree\Model\Ui\ConfigProvider;

/**
 * Format Braintree input into value expected when setting payment method
 */
class BraintreeVaultDataProvider implements AdditionalDataProviderInterface
{
    /**
     * Format Braintree input into value expected when setting payment method
     *
     * @param array $data
     * @return array
     * @throws GraphQlInputException
     */
    public function getData(array $data): array
    {
        if (!isset($data[ConfigProvider::CC_VAULT_CODE])) {
            throw new GraphQlInputException(
                __('Required parameter "braintree_cc_vault" for "payment_method" is missing.')
            );
        }

        if (!isset($data[ConfigProvider::CC_VAULT_CODE]['public_hash'])) {
            throw new GraphQlInputException(
                __('Required parameter "public_hash" for "braintree_cc_vault" is missing.')
            );
        }

        return $data[ConfigProvider::CC_VAULT_CODE];
    }
}
