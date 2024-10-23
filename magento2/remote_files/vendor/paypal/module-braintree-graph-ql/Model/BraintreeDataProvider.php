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
class BraintreeDataProvider implements AdditionalDataProviderInterface
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
        if (!isset($data[ConfigProvider::CODE])) {
            throw new GraphQlInputException(
                __('Required parameter "braintree" for "payment_method" is missing.')
            );
        }

        return $data[ConfigProvider::CODE];
    }
}
