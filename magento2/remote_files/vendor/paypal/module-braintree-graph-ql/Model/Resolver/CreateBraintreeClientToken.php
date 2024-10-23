<?php
/**
 * Copyright © Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */
declare(strict_types=1);

namespace PayPal\BraintreeGraphQl\Model\Resolver;

use PayPal\Braintree\Gateway\Config\Config;
use PayPal\Braintree\Gateway\Request\PaymentDataBuilder;
use PayPal\Braintree\Model\Adapter\BraintreeAdapterFactory;
use Magento\Framework\GraphQl\Config\Element\Field;
use Magento\Framework\GraphQl\Exception\GraphQlInputException;
use Magento\Framework\GraphQl\Query\ResolverInterface;
use Magento\Framework\GraphQl\Schema\Type\ResolveInfo;

/**
 * Resolver for generating Braintree client token
 */
class CreateBraintreeClientToken implements ResolverInterface
{
    /**
     * @var Config
     */
    private Config $config;

    /**
     * @var BraintreeAdapterFactory
     */
    private BraintreeAdapterFactory $adapterFactory;

    /**
     * @param Config $config
     * @param BraintreeAdapterFactory $adapterFactory
     */
    public function __construct(
        Config $config,
        BraintreeAdapterFactory $adapterFactory
    ) {
        $this->config = $config;
        $this->adapterFactory = $adapterFactory;
    }

    /**
     * @inheritdoc
     */
    public function resolve(
        Field $field,
        $context,
        ResolveInfo $info,
        array $value = null,
        array $args = null
    ) {
        $storeId = (int) $context->getExtensionAttributes()->getStore()->getId();

        if (!$this->config->isActive($storeId)) {
            throw new GraphQlInputException(__('The Braintree payment method is not active.'));
        }

        $params = [];
        $merchantAccountId = $this->config->getMerchantAccountId($storeId);
        if (!empty($merchantAccountId)) {
            $params[PaymentDataBuilder::MERCHANT_ACCOUNT_ID] = $merchantAccountId;
        }

        return $this->adapterFactory->create()->generate($params);
    }
}
