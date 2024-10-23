<?php
/**
 * Copyright © Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */
declare(strict_types=1);

namespace PayPal\BraintreeGraphQl\Model\Resolver;

use Magento\Framework\Exception\InputException;
use Magento\Framework\Exception\NoSuchEntityException;
use Magento\Framework\GraphQl\Exception\GraphQlAuthorizationException;
use Magento\Framework\GraphQl\Query\Resolver\ContextInterface;
use Magento\Vault\Api\PaymentTokenManagementInterface;
use PayPal\Braintree\Gateway\Config\Config as CoreBraintreeConfig;
use PayPal\Braintree\Gateway\Config\PayPalVault\Config;
use PayPal\Braintree\Gateway\Request\PaymentDataBuilder;
use PayPal\Braintree\Model\Adapter\BraintreeAdapterFactory;
use Magento\Framework\GraphQl\Config\Element\Field;
use Magento\Framework\GraphQl\Exception\GraphQlInputException;
use Magento\Framework\GraphQl\Query\ResolverInterface;
use Magento\Framework\GraphQl\Schema\Type\ResolveInfo;
use PayPal\Braintree\Gateway\DataResolver\Customer\GetCustomerIdByPaymentTokenInterface;

/**
 * Resolver for generating Braintree client token
 *
 * @SuppressWarnings(PHPMD.CouplingBetweenObjects)
 */
class CreateBraintreePayPalVaultClientToken implements ResolverInterface
{
    /**
     * @var PaymentTokenManagementInterface
     */
    private PaymentTokenManagementInterface $paymentTokenManagement;

    /**
     * @var CoreBraintreeConfig
     */
    private CoreBraintreeConfig $braintreeConfig;

    /**
     * @var Config
     */
    private Config $config;

    /**
     * @var BraintreeAdapterFactory
     */
    private BraintreeAdapterFactory $adapterFactory;

    /**
     * @var GetCustomerIdByPaymentTokenInterface
     */
    private GetCustomerIdByPaymentTokenInterface $getCustomerIdByPaymentToken;

    /**
     * @param PaymentTokenManagementInterface $paymentTokenManagement
     * @param CoreBraintreeConfig $braintreeConfig
     * @param Config $config
     * @param BraintreeAdapterFactory $adapterFactory
     * @param GetCustomerIdByPaymentTokenInterface $getCustomerIdByPaymentToken
     */
    public function __construct(
        PaymentTokenManagementInterface $paymentTokenManagement,
        CoreBraintreeConfig $braintreeConfig,
        Config $config,
        BraintreeAdapterFactory $adapterFactory,
        GetCustomerIdByPaymentTokenInterface $getCustomerIdByPaymentToken
    ) {
        $this->paymentTokenManagement = $paymentTokenManagement;
        $this->braintreeConfig = $braintreeConfig;
        $this->config = $config;
        $this->adapterFactory = $adapterFactory;
        $this->getCustomerIdByPaymentToken = $getCustomerIdByPaymentToken;
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
        $customerId = $this->getCurrentCustomerId($context);

        $extensionAttributes = $context->getExtensionAttributes();

        // Vault sessions should be valid for logged in customers only.
        if ($customerId === null || $customerId === 0 || $extensionAttributes->getIsCustomer() === false) {
            throw new GraphQlAuthorizationException(__('The current customer isn\'t authorized.'));
        }

        $storeId = (int) $extensionAttributes->getStore()->getId();

        if (!$this->config->isActive($storeId)) {
            throw new GraphQlInputException(__('The Braintree PayPal payment method is not active.'));
        }

        // If public hash is not provided (should already be validated), throw exception.
        if (!isset($args['input']['public_hash'])) {
            throw new GraphQlInputException(__('The provided token hash is invalid.'));
        }

        // If provided, get token for customer.
        $token = $this->paymentTokenManagement->getByPublicHash($args['input']['public_hash'], $customerId);

        // Throw exception if token is not found or is not active.
        if ($token === null || !$token->getIsActive()) {
            throw new GraphQlInputException(__('The provided token hash is invalid.'));
        }

        return $this->getClientToken($storeId, $this->getCustomerIdByPaymentToken->execute($token));
    }

    /**
     * Get the Braintree Client Token.
     *
     * Generate using the braintree customer ID if provided.
     *
     * @param int $storeId
     * @param string|null $braintreeCustomerId
     * @return string
     * @throws InputException
     * @throws NoSuchEntityException
     */
    private function getClientToken(int $storeId, ?string $braintreeCustomerId): string
    {
        $params = [];

        if ($braintreeCustomerId !== null) {
            $params[PaymentDataBuilder::CUSTOMER_ID] = $braintreeCustomerId;
        }

        /** @var \PayPal\Braintree\Model\Adapter\BraintreeAdapter $braintreeAdapter */
        $braintreeAdapter = $this->adapterFactory->create();

        $merchantAccountId = $this->braintreeConfig->getMerchantAccountId($storeId);

        if (!empty($merchantAccountId)) {
            $params[PaymentDataBuilder::MERCHANT_ACCOUNT_ID] = $merchantAccountId;
        }

        return $braintreeAdapter->generate($params);
    }

    /**
     * Get the current customer ID from the context.
     *
     * @see \Magento\GraphQl\Model\Query\ContextFactory::create()
     *
     * @param ContextInterface $context
     * @return int|null
     */
    private function getCurrentCustomerId(ContextInterface $context): ?int
    {
        $customerId = $context->getUserId();

        return $customerId === null ? null : (int) $customerId;
    }
}
